#!/bin/bash
# 装 GoAccess + 配 nginx log 实时流量统计 + basic auth 保护 /goaccess/ 路径.
# 议题: MEETING-2026-05-11-06-docs-isolation Phase B (P3-8)
#
# 用法 (PL ECS web SSH 一行 paste):
#   read -s -p 'GoAccess 用户名: ' GA_USER && echo
#   read -s -p 'GoAccess 密码: ' GA_PASS && echo
#   export GA_USER GA_PASS
#   curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/setup-goaccess.sh | bash
#
# 完成后访问: https://serpilo.com/goaccess/  (用刚才设的用户名密码登)
#
# 报表更新: cron 每 10 分钟把 nginx access.log 跑过 goaccess 输出 HTML 到
# /var/www/serpilo/goaccess/index.html

set -euo pipefail

DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
GA_USER="${GA_USER:-}"
GA_PASS="${GA_PASS:-}"

if [ -z "$GA_USER" ] || [ -z "$GA_PASS" ]; then
  echo "ERROR: GA_USER + GA_PASS env 必须先 export"
  echo ""
  echo "  read -s -p 'GoAccess 用户名: ' GA_USER && echo"
  echo "  read -s -p 'GoAccess 密码: ' GA_PASS && echo"
  echo "  export GA_USER GA_PASS"
  exit 1
fi

echo "==> [1/5] 装 goaccess + apache2-utils (htpasswd)"
apt-get update -qq
apt-get install -y -qq goaccess apache2-utils

echo "==> [2/5] 准备 goaccess 输出目录"
mkdir -p "$DEPLOY_PATH/goaccess"
chown -R www-data:www-data "$DEPLOY_PATH/goaccess"

echo "==> [3/5] 创建 basic auth"
htpasswd -bc /etc/nginx/.goaccess_htpasswd "$GA_USER" "$GA_PASS"
chmod 644 /etc/nginx/.goaccess_htpasswd

echo "==> [4/5] 写 nginx /goaccess/ location (basic auth + 静态 html)"
# 找当前 nginx config 文件 + 在 server 443 块内插入 location /goaccess/
NGINX_CONF="/etc/nginx/sites-available/tortoise-web"

# 检查是否已有 /goaccess location, 已加跳过
if grep -q "location /goaccess/" "$NGINX_CONF"; then
  echo "    /goaccess/ location 已存在, 跳过"
else
  # 在 listen 443 server 块内 'location /' 之前插入 (sed 范围替换)
  python3 <<PYTHON_SCRIPT
import re

with open("$NGINX_CONF") as f:
    content = f.read()

# 找 server { listen 443 ... } 块内的 'location /' 行, 之前插入
goaccess_block = '''
    # GoAccess 流量统计 (basic auth 保护)
    location /goaccess/ {
        auth_basic "GoAccess Stats";
        auth_basic_user_file /etc/nginx/.goaccess_htpasswd;
        alias $DEPLOY_PATH/goaccess/;
        try_files \$uri \$uri/ /goaccess/index.html;
    }

'''

# 简单策略: 在 443 块内第一个 'location /' 前插入
# 找到 'listen 443 ssl' 后下一个 'location /' (空格开头)
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

echo "==> [5/5] 配置 cron — 每 10 分钟生成报表"
cat > /usr/local/bin/run-goaccess.sh <<EOF
#!/bin/bash
# 跑 goaccess 把 nginx access.log 转成 HTML 报表 (含历史 access.log.1.gz)
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

# 加 cron (每 10 分钟; 如已存在则更新)
(crontab -l 2>/dev/null | grep -v 'run-goaccess.sh' ; echo '*/10 * * * * /usr/local/bin/run-goaccess.sh') | crontab -

# 立即跑一次
/usr/local/bin/run-goaccess.sh

echo ""
echo "✓ 全部完成"
echo "  访问: https://$DOMAIN/goaccess/"
echo "  用户名/密码: 刚才 read -s 设的"
echo "  报表自动更新: 每 10 分钟"
echo ""
echo "  改密码: htpasswd -b /etc/nginx/.goaccess_htpasswd 用户名 新密码"
echo "  停用统计: crontab -e 删 run-goaccess.sh 行 + nginx 删 location /goaccess/"
