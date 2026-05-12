#!/bin/bash
# Aliyun ECS nginx + Let's Encrypt SSL 一键修复 (覆盖之前 setup-aliyun.sh 残留 ACME location 冲突).
# MEETING-2026-05-11-06-docs-isolation
#
# 用法 (ECS web SSH 直接 paste 一行):
#   curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/fix-aliyun-ssl.sh | bash
#
# 做的事:
#   1. 重写 nginx config (无 ACME challenge location 冲突, ^~ 优先级正确)
#   2. 准备 ACME webroot 目录
#   3. certbot certonly --webroot 申请 cert (避开 --nginx auto-patch 不稳)
#   4. 重写 nginx config 加 443 ssl + http→https 重定向
#   5. reload + 自检 curl

set -euo pipefail

DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
CERT_EMAIL="${SETUP_CERT_EMAIL:-956826374@qq.com}"

echo "==> 配置参数 DOMAIN=$DOMAIN DEPLOY_PATH=$DEPLOY_PATH CERT_EMAIL=$CERT_EMAIL"
echo ""

# ===== 1. 准备 webroot =====
echo "==> [1/6] 准备 ACME webroot $DEPLOY_PATH/.well-known/acme-challenge/"
mkdir -p "$DEPLOY_PATH/.well-known/acme-challenge"
chown -R www-data:www-data "$DEPLOY_PATH/.well-known" 2>/dev/null || \
  chown -R nginx:nginx "$DEPLOY_PATH/.well-known" 2>/dev/null || true
echo "    OK"

# ===== 2. 写 HTTP 80 only nginx config (cert 申请阶段) =====
echo "==> [2/6] 写 nginx HTTP 80 config (cert 申请前)"
cat > /etc/nginx/sites-available/tortoise-web <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    root $DEPLOY_PATH;
    index index.html;

    # ACME challenge: ^~ 优先匹配, 防 SPA fallback try_files 拦截
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root $DEPLOY_PATH;
        allow all;
        try_files \$uri =404;
    }

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

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
}
EOF

ln -sf /etc/nginx/sites-available/tortoise-web /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
echo "    OK"

# ===== 3. 自检 ACME path 80 端口可达 =====
echo "==> [3/6] 自检 ACME path 80 端口"
echo "test-ok" > "$DEPLOY_PATH/.well-known/acme-challenge/_self_test"
SELF=$(curl -sf --max-time 5 "http://localhost/.well-known/acme-challenge/_self_test" 2>&1) || SELF="FAIL"
PUBLIC=$(curl -sf --max-time 8 "http://$DOMAIN/.well-known/acme-challenge/_self_test" 2>&1) || PUBLIC="FAIL"
rm -f "$DEPLOY_PATH/.well-known/acme-challenge/_self_test"
echo "    localhost: $SELF"
echo "    $DOMAIN:    $PUBLIC"
if [ "$PUBLIC" != "test-ok" ]; then
  echo ""
  echo "⚠ 公网 80 端口不可达或返回不对. 可能原因:"
  echo "  (a) 阿里云 ECS 安全组没开 80 入站 (检查 ECS 控制台)"
  echo "  (b) DNS A 记录还没生效 (dig +short $DOMAIN @8.8.8.8)"
  echo "  (c) ECS 公网 IP 变了 (curl ifconfig.me)"
  echo "  本机自检 IP: $(curl -s --max-time 5 ifconfig.me 2>&1 || echo unknown)"
  echo "  DNS 解析 $DOMAIN: $(dig +short $DOMAIN @8.8.8.8 2>&1 || echo unknown)"
  echo ""
  echo "  ACME server 拉不到 → cert 申请会 fail. 修这些再 re-run 本脚本."
  exit 1
fi
echo "    ✓ ACME path 公网可达"

# ===== 4. 申请 cert (webroot 模式, 比 --nginx auto-patch 稳) =====
echo "==> [4/6] certbot certonly --webroot 申请 cert"
certbot certonly --webroot \
  -w "$DEPLOY_PATH" \
  -d "$DOMAIN" -d "www.$DOMAIN" \
  --non-interactive --agree-tos \
  --email "$CERT_EMAIL" \
  --keep-until-expiring

# ===== 5. 写 HTTPS 443 + redirect 80→443 nginx config =====
echo "==> [5/6] 写 nginx HTTPS 443 config + redirect"
# 检查 ssl-dhparams.pem 是否存在 (certbot 装时一般会建)
DHPARAMS=""
if [ -f /etc/letsencrypt/ssl-dhparams.pem ]; then
  DHPARAMS="ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;"
fi

cat > /etc/nginx/sites-available/tortoise-web <<EOF
# HTTP 80 → HTTPS 301 + ACME challenge (续期需要)
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

# HTTPS 443
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name $DOMAIN www.$DOMAIN;
    root $DEPLOY_PATH;
    index index.html;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    $DHPARAMS

    # APK 下载支持 (MEETING-2026-05-12-02-apk-distribution)
    location ^~ /downloads/ {
        types {
            application/vnd.android.package-archive apk;
            text/plain sha256;
        }
        add_header Content-Disposition 'attachment' always;
        add_header X-Content-Type-Options 'nosniff' always;
        autoindex off;
    }

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
    # HSTS preload (hstspreload.org 提交要求)
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}
EOF

nginx -t
systemctl reload nginx
echo "    OK"

# ===== 6. 验证 + 续期 cron =====
echo "==> [6/6] 验证"
echo "    HTTP 80 → 应 301:"
curl -sI --max-time 5 "http://$DOMAIN" 2>&1 | head -3
echo ""
echo "    HTTPS 443 → 应 200:"
curl -sI --max-time 5 "https://$DOMAIN" 2>&1 | head -3
echo ""
echo "    续期 cron:"
systemctl status certbot.timer --no-pager 2>&1 | head -5 || true

echo ""
echo "✓ 全部完成. 浏览器开 https://$DOMAIN 应看到 Tortoise 主页."
echo "  cert 90 天到期前 certbot.timer 会自动续期 (--keep-until-expiring 模式)."
