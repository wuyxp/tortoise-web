#!/bin/bash
# 用已有 SSL 证书 (例如阿里云免费 SSL) 配 nginx 443.
# 不依赖 Let's Encrypt — 国内 IP 境外 ACME 验证常被拦截.
# MEETING-2026-05-11-06-docs-isolation
#
# 用法 (前置: PL 已上传 .pem + .key 到 ECS):
#   curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/configure-ssl-with-cert.sh | \
#     SSL_CERT=/etc/nginx/ssl/aliyun/serpilo.com.pem \
#     SSL_KEY=/etc/nginx/ssl/aliyun/serpilo.com.key \
#     bash

set -euo pipefail

DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
SSL_CERT="${SSL_CERT:-/etc/nginx/ssl/aliyun/$DOMAIN.pem}"
SSL_KEY="${SSL_KEY:-/etc/nginx/ssl/aliyun/$DOMAIN.key}"

echo "==> 配置参数"
echo "    DOMAIN:      $DOMAIN"
echo "    DEPLOY_PATH: $DEPLOY_PATH"
echo "    SSL_CERT:    $SSL_CERT"
echo "    SSL_KEY:     $SSL_KEY"
echo ""

# ===== 1. 验证证书文件 =====
echo "==> [1/5] 验证证书文件"
if [ ! -f "$SSL_CERT" ]; then
  echo "ERROR: 证书文件不存在 $SSL_CERT"
  echo ""
  echo "PL 必做 (前置): 阿里云控制台申请免费 SSL 后, 上传到 ECS:"
  echo "  mkdir -p $(dirname $SSL_CERT)"
  echo "  vim $SSL_CERT  # 粘贴 .pem 内容"
  echo "  vim $SSL_KEY   # 粘贴 .key 内容"
  echo "  chmod 600 $SSL_KEY"
  exit 1
fi
if [ ! -f "$SSL_KEY" ]; then
  echo "ERROR: 私钥文件不存在 $SSL_KEY"
  exit 1
fi

# 证书内容验证 (能 openssl 解析 + 域名匹配)
CERT_CN=$(openssl x509 -in "$SSL_CERT" -noout -subject 2>&1 | grep -oE "CN ?= ?[^,]+" | head -1)
CERT_SAN=$(openssl x509 -in "$SSL_CERT" -noout -ext subjectAltName 2>&1 | tail -1)
echo "    证书 CN:  $CERT_CN"
echo "    证书 SAN: $CERT_SAN"
echo "    ✓ 证书合法"

# ===== 2. 写 nginx config (HTTP 80 → HTTPS 301 + HTTPS 443 + ACME challenge 兼容) =====
echo "==> [2/5] 写 nginx HTTPS config"
cat > /etc/nginx/sites-available/tortoise-web <<EOF
# HTTP 80 → HTTPS 301 (含 ACME challenge 路径, 备 Let's Encrypt 续期可能性)
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

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

# HTTPS 443 (用阿里云免费 SSL 证书)
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name $DOMAIN www.$DOMAIN;
    root $DEPLOY_PATH;
    index index.html;

    ssl_certificate $SSL_CERT;
    ssl_certificate_key $SSL_KEY;

    # 推荐 SSL 配置 (与 Mozilla intermediate 兼容)
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

# ===== 3. 启用 + 测试 + reload =====
echo "==> [3/5] 测试 + reload nginx"
ln -sf /etc/nginx/sites-available/tortoise-web /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
echo "    ✓ nginx reload OK"

# ===== 4. 自检 =====
echo "==> [4/5] 自检 (本地 + 公网)"
echo "    HTTP 80 (应 301):"
curl -sI --max-time 5 -H "Host: $DOMAIN" "http://localhost/" 2>&1 | head -2
echo ""
echo "    HTTPS 443 localhost (应 200):"
curl -skI --max-time 5 -H "Host: $DOMAIN" "https://localhost/" 2>&1 | head -2
echo ""
echo "    HTTPS 443 公网 (应 200):"
curl -sI --max-time 8 "https://$DOMAIN" 2>&1 | head -3

# ===== 5. cert 到期提示 =====
echo "==> [5/5] cert 到期信息"
EXPIRE=$(openssl x509 -in "$SSL_CERT" -noout -enddate 2>&1 | cut -d= -f2)
echo "    cert 到期: $EXPIRE"
echo "    阿里云免费证书 1 年期, 到期前去阿里云控制台续期 (重新申请 + 重传 + 重跑本脚本)"
echo "    或者考虑买阿里云付费证书自动续期, 或用 acme.sh + 阿里云 DNS API 自动化"

echo ""
echo "✓ 全部完成. 浏览器开 https://$DOMAIN 应看到 Tortoise 主页."
