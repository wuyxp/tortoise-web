#!/bin/bash
# acme.sh + 阿里云 DNS API + Let's Encrypt DNS-01 challenge — 免费 SSL 自动续期.
# 国内 IP HTTP-01 challenge 被拦, DNS-01 走阿里云 DNS API 加 TXT 验证, 100% 工作.
# MEETING-2026-05-11-06-docs-isolation
#
# 前置 (PL 必做):
#   1. 阿里云 RAM → 创建用户 (推荐 acme-dns-bot) → 拿 AccessKey ID + Secret
#   2. 给该用户加权限 AliyunDNSFullAccess
#
# ECS 上跑 (一行, AccessKey 通过 ENV 传, 不写入命令历史):
#   read -s -p 'Ali_Key (AccessKey ID): '       Ali_Key       && echo
#   read -s -p 'Ali_Secret (AccessKey Secret): ' Ali_Secret    && echo
#   export Ali_Key Ali_Secret
#   curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/setup-ssl-acme-aliyun.sh | bash
#
# 脚本做的事:
#   1. 装 acme.sh (持久, 自动 cron 续期)
#   2. 用 DNS-01 challenge 申请 Let's Encrypt cert
#   3. 装 cert 到 /etc/nginx/ssl/letsencrypt/$DOMAIN/
#   4. 写 nginx 443 ssl config
#   5. nginx -t + reload + 自检
#   6. cron 自动续期已由 acme.sh install 时自动加 (60 天一次)

set -euo pipefail

DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
CERT_EMAIL="${SETUP_CERT_EMAIL:-956826374@qq.com}"
CERT_DIR="/etc/nginx/ssl/letsencrypt/$DOMAIN"
ACME_HOME="${ACME_HOME:-$HOME/.acme.sh}"

# ===== 0. 验证 ENV =====
echo "==> 配置参数"
echo "    DOMAIN:      $DOMAIN"
echo "    DEPLOY_PATH: $DEPLOY_PATH"
echo "    CERT_EMAIL:  $CERT_EMAIL"
echo "    CERT_DIR:    $CERT_DIR"
echo ""

if [ -z "${Ali_Key:-}" ] || [ -z "${Ali_Secret:-}" ]; then
  echo "ERROR: Ali_Key 和 Ali_Secret 环境变量必须先 export"
  echo ""
  echo "在跑本脚本之前, ECS 上先跑:"
  echo "  read -s -p 'Ali_Key (AccessKey ID): '       Ali_Key       && echo"
  echo "  read -s -p 'Ali_Secret (AccessKey Secret): ' Ali_Secret    && echo"
  echo "  export Ali_Key Ali_Secret"
  echo ""
  echo "然后再跑本脚本 (用 read -s 不显示输入, AccessKey 不进 history)"
  exit 1
fi

# ===== 1. 装 acme.sh =====
echo "==> [1/5] 安装 acme.sh"
if [ ! -f "$ACME_HOME/acme.sh" ]; then
  curl -sSL https://get.acme.sh | sh -s email="$CERT_EMAIL" 2>&1 | tail -3
  echo "    ✓ acme.sh 已装到 $ACME_HOME"
else
  echo "    ✓ acme.sh 已存在 $ACME_HOME, 跳过装"
fi

# 确保 acme.sh 在 PATH
ACME="$ACME_HOME/acme.sh"
if [ ! -x "$ACME" ]; then
  echo "ERROR: $ACME 不存在或不可执行"
  exit 1
fi

# 默认 CA 用 Let's Encrypt (acme.sh 3.x 默认 ZeroSSL, 改回 LE)
"$ACME" --set-default-ca --server letsencrypt 2>&1 | tail -2

# ===== 2. 申请 cert (DNS-01) =====
echo "==> [2/5] 用 DNS-01 challenge 申请 Let's Encrypt cert"
echo "    (acme.sh 会调用阿里云 DNS API 加 TXT 记录, LE server 查 DNS 验证, 全程 ~30s)"

# Ali_Key + Ali_Secret 已 export, acme.sh dns_ali 插件自动读取
# 不加 --force: 已申请过的 cert 不会重新申请 (LE rate limit 5/week/domain), 仅
# 更新过期/即将过期的 cert
"$ACME" --issue --dns dns_ali \
  -d "$DOMAIN" -d "www.$DOMAIN" \
  --email "$CERT_EMAIL" \
  --keylength 2048 2>&1 | tail -20 || \
  echo "    (cert 已存在或 LE rate limit, 跳过 issue, 继续 install/nginx config)"

# ===== 3. 安装 cert 到 nginx 目录 =====
echo "==> [3/5] 安装 cert 到 $CERT_DIR/"
mkdir -p "$CERT_DIR"

"$ACME" --install-cert -d "$DOMAIN" \
  --key-file       "$CERT_DIR/privkey.pem" \
  --fullchain-file "$CERT_DIR/fullchain.pem" \
  --reloadcmd      "systemctl reload nginx"

chmod 600 "$CERT_DIR/privkey.pem"
echo "    ✓ cert + key 已装到 $CERT_DIR/"
echo "    续期回调: systemctl reload nginx (acme.sh 续期后自动跑)"

# ===== 4. 写 nginx config =====
echo "==> [4/5] 写 nginx HTTPS config"
cat > /etc/nginx/sites-available/tortoise-web <<EOF
# HTTP 80 → HTTPS 301
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    # ACME challenge 兼容路径 (虽然 DNS-01 不用, 留备用)
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root $DEPLOY_PATH;
        allow all;
        try_files \$uri =404;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS 443
# 注: 用 'listen 443 ssl http2;' 旧语法兼容 nginx <1.25.1 (Ubuntu 22.04 默认 1.18-1.24);
# nginx 1.25.1+ 推荐独立 http2 on; 但旧语法会 deprecation warning 不报错, 兼容性更好
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    root $DEPLOY_PATH;
    index index.html;

    ssl_certificate $CERT_DIR/fullchain.pem;
    ssl_certificate_key $CERT_DIR/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    location / {
        try_files \$uri \$uri/ \$uri.html /index.html;
    }

    location ~* \.(css|js|woff2?|png|jpg|jpeg|webp|svg|ico)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/css application/javascript application/json text/plain image/svg+xml;
    gzip_min_length 1024;
    gzip_vary on;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
EOF

ln -sf /etc/nginx/sites-available/tortoise-web /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
echo "    ✓ nginx reload OK"

# ===== 5. 自检 + 续期信息 =====
echo "==> [5/5] 自检"
echo "    HTTP 80 (应 301):"
curl -sI --max-time 5 -H "Host: $DOMAIN" "http://localhost/" 2>&1 | head -2
echo ""
echo "    HTTPS 443 localhost (应 200):"
curl -skI --max-time 5 -H "Host: $DOMAIN" "https://localhost/" 2>&1 | head -2
echo ""
echo "    HTTPS 443 公网 (应 200):"
curl -sI --max-time 8 "https://$DOMAIN" 2>&1 | head -3
echo ""
echo "    续期 cron (acme.sh install 时自动加, 60 天一次):"
crontab -l 2>&1 | grep -i acme || echo "    (未找到 acme cron, 检查 systemd timer)"

# ===== 6. AccessKey 提示 =====
echo ""
echo "==> 安全提醒"
echo "    Ali_Key + Ali_Secret 已被 acme.sh 持久化到 $ACME_HOME/account.conf (内部用, 不外传)"
echo "    续期时 acme.sh 自动用这对 key 调用阿里云 DNS API, 全自动"
echo ""
echo "    若你将来想 revoke 这对 AccessKey:"
echo "    1. 阿里云 RAM → 用户 acme-dns-bot → AccessKey 管理 → 禁用/删除"
echo "    2. ECS 上重跑本脚本 (用新 key)"

echo ""
echo "✓ 全部完成. 浏览器开 https://$DOMAIN 应看到 Tortoise 主页, 锁标志绿色."
echo "  cert 90 天到期前 acme.sh 自动续期 + 自动 reload nginx, 完全无人工."
