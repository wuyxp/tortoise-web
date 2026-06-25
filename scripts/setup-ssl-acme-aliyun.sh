#!/bin/bash
# 源站 SSL = 10 年自签证书 (方案 B, MEETING-2026-06-25).
#
# 背景: NS 已迁阿里云 ESA, 访客 HTTPS 由 ESA 边缘免费证书承载 (ESA 自动续期).
#   ESA 回源到本机 ECS 时【源站证书校验已关闭】(方案 B), 故源站证书不需要是受信 CA、
#   也不需要不过期 → 用 10 年自签即可, 彻底甩掉 acme.sh + DNS/HTTP-01 + 续期依赖.
#
# 为什么不用 acme.sh/Let's Encrypt (历史): 原 DNS-01 走云解析, NS 迁 ESA 后失效;
#   改 HTTP-01 又被 ESA 安全防护拦掉 LE 验证节点 (MEETING-2026-06-24-01 实测). 既然回源
#   不校验, 自签是最稳的解.
#
# ⚠️ 前提: ESA「SSL/TLS → 源站证书 → 源站证书校验」必须保持【关闭】.
#   若将来要重新打开校验, 这张自签会过不了根校验 → 需改回受信 CA 方案 (见 git 历史 acme 版).
#
# ECS 上跑 (一行, 无需任何凭证):
#   curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/setup-ssl-acme-aliyun.sh | bash
#
# 脚本做的事:
#   1. 生成 10 年自签证书 (SAN: serpilo + www + dl) 到 /etc/nginx/ssl/letsencrypt/$DOMAIN/
#   2. 写 nginx config (server_name 含 dl) + reload
#   3. 停掉残留的 acme.sh 续期 cron (方案 B 不再需要, 防它每天失败刷日志)
#   4. 自检

set -euo pipefail

DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
CERT_DIR="/etc/nginx/ssl/letsencrypt/$DOMAIN"
NGINX_ONLY="${NGINX_ONLY:-0}"  # 1 = 仅刷 nginx config (证书不动)

echo "==> 配置参数"
echo "    DOMAIN:      $DOMAIN (+ www + dl)"
echo "    DEPLOY_PATH: $DEPLOY_PATH"
echo "    CERT_DIR:    $CERT_DIR"
echo "    NGINX_ONLY:  $NGINX_ONLY"
echo ""

# ===== 函数: 写 nginx config + reload (幂等) =====
write_nginx_and_reload() {
  echo "==> 写 nginx config (server_name 含 dl) + reload"
  cat > /etc/nginx/sites-available/tortoise-web <<EOF
# HTTP 80 → HTTPS 301
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN dl.$DOMAIN;
    location / { return 301 https://\$host\$request_uri; }
}

# HTTPS 443 (源站证书 = 自签, 回源不校验, 方案 B)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN dl.$DOMAIN;
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

    # version.json — UpdateChecker fetch 目标, 必须永远拿最新 (MEETING-2026-06-05-09 F5 no-cache).
    location = /downloads/version.json {
        default_type application/json;
        add_header Cache-Control 'no-cache, no-store, must-revalidate' always;
        add_header X-Content-Type-Options 'nosniff' always;
        autoindex off;
    }

    # APK 下载 (MEETING-2026-05-12-02). ^~ 防 SPA fallback 误吞 .apk.
    location ^~ /downloads/ {
        types {
            application/vnd.android.package-archive apk;
            text/plain sha256;
        }
        add_header Content-Disposition 'attachment' always;
        add_header X-Content-Type-Options 'nosniff' always;
        add_header Cache-Control 'no-cache' always;
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
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}
EOF
  ln -sf /etc/nginx/sites-available/tortoise-web /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  mkdir -p "$DEPLOY_PATH/downloads"
  chown -R www-data:www-data "$DEPLOY_PATH/downloads" 2>/dev/null || true
  nginx -t
  systemctl reload nginx
  echo "    ✓ nginx reload OK"
}

# ============================================================
# NGINX_ONLY: 仅刷 nginx config
# ============================================================
if [ "$NGINX_ONLY" = "1" ]; then
  echo "==> [NGINX_ONLY=1] 仅刷 nginx config"
  [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ] || { echo "ERROR: $CERT_DIR 无证书, 先跑完整模式"; exit 1; }
  write_nginx_and_reload
  echo "✓ nginx config 已刷新 (证书未动)."
  exit 0
fi

# ===== 1. 生成 10 年自签证书 (SAN: serpilo + www + dl) =====
echo "==> [1/4] 生成 10 年自签证书 (SAN: $DOMAIN, www.$DOMAIN, dl.$DOMAIN)"
mkdir -p "$CERT_DIR"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$CERT_DIR/privkey.pem" -out "$CERT_DIR/fullchain.pem" \
  -subj "/CN=$DOMAIN" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,DNS:dl.$DOMAIN" 2>/dev/null
chmod 600 "$CERT_DIR/privkey.pem"
echo "    ✓ 自签证书已写到 $CERT_DIR/ (10 年, 永不续期)"

# ===== 2. 写 nginx config + reload =====
echo "==> [2/4] 写 nginx config + reload"
write_nginx_and_reload

# ===== 3. 停掉残留 acme.sh 续期 cron (方案 B 不再需要) =====
echo "==> [3/4] 停掉 acme.sh 续期 cron (防每天失败刷日志)"
if [ -f "$HOME/.acme.sh/acme.sh" ]; then
  "$HOME/.acme.sh/acme.sh" --uninstall-cronjob 2>/dev/null && echo "    ✓ acme cron 已卸" || echo "    (acme cron 已不存在/卸载跳过)"
else
  crontab -l 2>/dev/null | grep -v 'acme.sh' | crontab - 2>/dev/null || true
  echo "    ✓ 已清 crontab 中的 acme 行 (若有)"
fi

# ===== 4. 自检 =====
echo "==> [4/4] 自检"
echo "    证书 SAN (应含 serpilo + www + dl):"
openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -ext subjectAltName 2>/dev/null | tail -1
echo "    证书到期 (应 ~10 年后):"
openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -enddate 2>/dev/null
echo "    本机 HTTPS 443 (应 200): $(curl -skI --max-time 5 -H "Host: $DOMAIN" https://localhost/ 2>&1 | head -1)"
echo ""
echo "✓ 完成. 源站 = 10 年自签 (回源不校验, 方案 B), 无 acme/无续期/无凭证."
echo "  访客侧 HTTPS 由 ESA 边缘证书承载 (ESA 自动续期). 保持 ESA 源站证书校验【关闭】."
