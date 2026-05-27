#!/bin/bash
# 装 GoAccess + 配 nginx log 实时流量统计 + basic auth 保护 /goaccess/ 路径
# + daily summary cron (写本地日志, 可选发邮件).
#
# 议题: MEETING-2026-05-11-06-docs-isolation Phase B (P3-8)
#
# === 用法 ===
#
# 方式 A (推荐, 交互式, 适合第一次跑) — SSH 到 ECS 后直接跑:
#
#   curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/setup-goaccess.sh | sudo bash
#
#   脚本会**提示你创建一个新用户名 + 新密码** (你随便起, 之后访问
#   https://serpilo.com/goaccess/ 时用这套登). 这两个值会被 nginx 的 htpasswd
#   存到 ECS 本地, 不上传任何外部, 仅你自己用.
#
# 方式 B (自动化, 适合写脚本/CI) — 预先设环境变量:
#
#   export GA_USER="tortoise"     # 你想起的用户名
#   export GA_PASS="你的密码"      # 你想设的密码
#   export GA_EMAIL="..."         # 可选: 设了就每天发 summary 邮件
#   sudo -E bash setup-goaccess.sh
#
# === 完成后 ===
# - 网页 dashboard:  https://serpilo.com/goaccess/  (用刚才设的用户名/密码登)
# - 报表更新:        cron 每 10 分钟跑一次 (报表覆盖前一次)
# - 每日 summary:    /var/log/tortoise-daily-stats.log (cron 每天 08:00 追加一行)
# - 改密码:          sudo htpasswd /etc/nginx/.goaccess_htpasswd <用户名>
# - 停用:            sudo crontab -e 删 run-goaccess.sh + daily-summary.sh 两行
#                    + sudo nano /etc/nginx/sites-available/tortoise-web 删 location /goaccess/

set -euo pipefail

# 防 apt 装包时弹 dpkg 交互配置 (postfix / iptables-persistent 等会卡住)
export DEBIAN_FRONTEND=noninteractive

DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
GA_USER="${GA_USER:-}"
GA_PASS="${GA_PASS:-}"
GA_EMAIL="${GA_EMAIL:-}"
DAILY_LOG="/var/log/tortoise-daily-stats.log"

# ---------- 交互式收集账号密码 (方式 A) ----------
if [ -z "$GA_USER" ] || [ -z "$GA_PASS" ]; then
  echo ""
  echo "============================================================"
  echo "  GoAccess 流量统计 — 首次安装"
  echo "============================================================"
  echo ""
  echo "  现在要给 /goaccess/ 这个统计页**创建一套新登录账号**."
  echo "  注意: 这不是登录已有账号, 是**你自己起一个用户名和密码**,"
  echo "        以后只有你一个人会用它登 https://$DOMAIN/goaccess/."
  echo ""
  echo "  例子: 用户名 tortoise / 密码 随便一串你能记住的字符."
  echo ""

  # stdin 被 pipe 占用 (curl ... | bash 模式) 时, fallback 到 /dev/tty 读终端
  # 这是 curl-pipe-bash 安装脚本的标准做法
  if [ ! -t 0 ]; then
    if [ -r /dev/tty ]; then
      exec < /dev/tty
    else
      echo "ERROR: 没有可用的终端 (stdin 被 pipe + /dev/tty 不可读)."
      echo ""
      echo "解决方法 (任选一种):"
      echo ""
      echo "方式 1 — process substitution (推荐, 同样的一行):"
      echo "  sudo bash <(curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/setup-goaccess.sh)"
      echo ""
      echo "方式 2 — 先下载再跑:"
      echo "  curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/setup-goaccess.sh -o /tmp/setup-goaccess.sh"
      echo "  sudo bash /tmp/setup-goaccess.sh"
      echo ""
      echo "方式 3 — 预设环境变量 (无 prompt):"
      echo "  export GA_USER='tortoise'"
      echo "  export GA_PASS='你的密码'"
      echo "  curl -sSL ... | sudo -E bash"
      exit 2
    fi
  fi

  read -p "请起一个用户名: " GA_USER
  read -s -p "请设一个密码 (打字时不显示): " GA_PASS
  echo ""

  if [ -z "$GA_USER" ] || [ -z "$GA_PASS" ]; then
    echo "ERROR: 用户名或密码不能为空"
    exit 2
  fi

  # 不再 prompt 邮件 — mailutils 拉 postfix 太重, 改成默认只本地日志
  # (你想要邮件的话, 跑完手动: sudo apt-get install -y msmtp-mta + 配 /etc/msmtprc)
fi

echo ""
echo "==> [1/6] 装 goaccess + apache2-utils"
echo "    (跳过 mailutils — 它会拉 postfix 弹 dpkg 对话框卡死. 想要邮件? 见脚本末尾提示)"
echo ""
echo "    -- apt-get update (1-3 min, 看进度) --"
apt-get update
echo ""
echo "    -- apt-get install goaccess apache2-utils --"
apt-get install -y --no-install-recommends goaccess apache2-utils

echo "==> [2/6] 准备 goaccess 输出目录"
mkdir -p "$DEPLOY_PATH/goaccess"
chown -R www-data:www-data "$DEPLOY_PATH/goaccess"
touch "$DAILY_LOG"
chmod 644 "$DAILY_LOG"

echo "==> [3/6] 创建 basic auth (用户: $GA_USER)"
htpasswd -bc /etc/nginx/.goaccess_htpasswd "$GA_USER" "$GA_PASS"
chmod 644 /etc/nginx/.goaccess_htpasswd

echo "==> [4/6] 写 nginx /goaccess/ location (basic auth + 静态 html)"
NGINX_CONF="/etc/nginx/sites-available/tortoise-web"

if grep -q "location /goaccess/" "$NGINX_CONF"; then
  echo "    /goaccess/ location 已存在, 跳过"
else
  python3 <<PYTHON_SCRIPT
import re

with open("$NGINX_CONF") as f:
    content = f.read()

goaccess_block = '''
    # GoAccess 流量统计 (basic auth 保护)
    location /goaccess/ {
        auth_basic "GoAccess Stats";
        auth_basic_user_file /etc/nginx/.goaccess_htpasswd;
        alias $DEPLOY_PATH/goaccess/;
        try_files \$uri \$uri/ /goaccess/index.html;
    }

'''

pattern = r'(listen 443 ssl http2;.*?)(\n    location /\s*\{)'
new_content, n = re.subn(pattern, r'\1' + goaccess_block.rstrip() + r'\n\2', content, count=1, flags=re.DOTALL)
if n != 1:
    print("ERROR: 未找到 listen 443 + location / 插入点")
    exit(1)

with open("$NGINX_CONF", "w") as f:
    f.write(new_content)
print("    插入 location /goaccess/ OK")
PYTHON_SCRIPT
fi

nginx -t
systemctl reload nginx

echo "==> [5/6] 配置 cron — 每 10 分钟刷新 dashboard"
cat > /usr/local/bin/run-goaccess.sh <<EOF
#!/bin/bash
# 跑 goaccess 把 nginx access.log 转成 HTML 报表
LOG_FILES=\$(ls /var/log/nginx/access.log* 2>/dev/null | sort)
zcat -f \$LOG_FILES 2>/dev/null | goaccess - \\
  --log-format=COMBINED \\
  --output=$DEPLOY_PATH/goaccess/index.html \\
  --html-prefs='{"theme":"darkBlue","layout":"horizontal"}' \\
  --no-global-config \\
  2>/dev/null || true
chown www-data:www-data $DEPLOY_PATH/goaccess/index.html 2>/dev/null || true
EOF
chmod +x /usr/local/bin/run-goaccess.sh

echo "==> [6/6] 配置 daily summary cron (08:00 每天写一行 + 可选邮件)"
cat > /usr/local/bin/tortoise-daily-summary.sh <<EOF
#!/bin/bash
# 每天 08:00 跑一次, 输出昨天的访问统计
# 写到本地日志 ($DAILY_LOG), 你 SSH 上来 tail 即可看
# 可选: 发邮件给 GA_EMAIL (如设了)

YESTERDAY=\$(date -u -d 'yesterday' +%d/%b/%Y)
ACCESS_LOG=/var/log/nginx/access.log

# awk 单遍统计 (PV / UV / top 路径) — 不依赖 goaccess
PV=\$(awk -v d="\$YESTERDAY" '\$0 ~ d' \$ACCESS_LOG 2>/dev/null | wc -l)
UV=\$(awk -v d="\$YESTERDAY" '\$0 ~ d' \$ACCESS_LOG 2>/dev/null | awk '{print \$1}' | sort -u | wc -l)
TOP5=\$(awk -v d="\$YESTERDAY" '\$0 ~ d' \$ACCESS_LOG 2>/dev/null | awk '{print \$7}' | sort | uniq -c | sort -rn | head -5)

SUMMARY="===== Tortoise serpilo.com 昨日 (\$YESTERDAY UTC) 访问 =====
PV (页面访问总数): \$PV
UV (独立 IP 数):    \$UV

Top 5 访问路径:
\$TOP5

详细 dashboard: https://$DOMAIN/goaccess/
====================================================="

# 写本地日志 (追加, PL ssh 后 tail 看)
echo "" >> $DAILY_LOG
echo "\$SUMMARY" >> $DAILY_LOG

# 发邮件 (如果配了 GA_EMAIL + mail 命令存在)
if [ -n "${GA_EMAIL}" ] && command -v mail >/dev/null 2>&1; then
  echo "\$SUMMARY" | mail -s "Tortoise 昨日访问 \$YESTERDAY" "${GA_EMAIL}" 2>/dev/null || \\
    echo "[\$(date)] mail 命令失败, 跳过邮件" >> $DAILY_LOG
fi
EOF
chmod +x /usr/local/bin/tortoise-daily-summary.sh

# 加 cron — 两个 cron job (避免重复)
(crontab -l 2>/dev/null | grep -v -e 'run-goaccess.sh' -e 'tortoise-daily-summary.sh'
 echo '*/10 * * * * /usr/local/bin/run-goaccess.sh'
 echo '0 8 * * * /usr/local/bin/tortoise-daily-summary.sh') | crontab -

# 立即跑一次 dashboard
/usr/local/bin/run-goaccess.sh

echo ""
echo "============================================================"
echo "  ✓ 安装完成"
echo "============================================================"
echo ""
echo "  📊 实时 dashboard:  https://$DOMAIN/goaccess/"
echo "     用户名:  $GA_USER"
echo "     密码:    刚才设的那个 (没存别处, 自己记好)"
echo ""
echo "  📅 每日 summary 本地日志:  $DAILY_LOG"
echo "     SSH 上来后看: tail -50 $DAILY_LOG"
echo "     第一份会在明天 08:00 (UTC) 后生成"
echo ""
echo "  🔄 dashboard 每 10 分钟自动刷新"
echo ""
echo "  改密码:  sudo htpasswd /etc/nginx/.goaccess_htpasswd $GA_USER"
echo "  停用:    sudo crontab -e 删两行 + nginx 删 location"
echo ""
echo "  想要每日邮件: 跑完后单独装 msmtp (轻量, 不拉 postfix):"
echo "      sudo apt-get install -y msmtp-mta bsd-mailx"
echo "      sudo nano /etc/msmtprc   # 配 SMTP relay"
echo "      然后改 /usr/local/bin/tortoise-daily-summary.sh 末尾加:"
echo "          echo \"\$SUMMARY\" | mail -s 'Tortoise daily' your@email"
echo ""
