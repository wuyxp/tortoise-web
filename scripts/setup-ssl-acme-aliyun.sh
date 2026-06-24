#!/bin/bash
# acme.sh + Let's Encrypt HTTP-01 (webroot) challenge — 免费 SSL 自动续期.
# MEETING-2026-06-24-01: NS 已迁阿里云 ESA, 原 DNS-01(dns_ali/云解析) 续期失效
#   (acme 写 TXT 到云解析, 但权威 NS 现在是 ESA → LE 查不到 → 续期静默失败).
#   acme.sh 无 ESA DNS 插件 → 改 HTTP-01 webroot, 验证请求穿 ESA 边缘回源到本机
#   webroot, 不再依赖任何 DNS API / AccessKey.
# 原 MEETING-2026-05-11-06-docs-isolation (DNS-01 版本, 已废)
#
# ⚠️ 前置 (PL 必做, 因为开了 ESA「源站证书校验」会鸡生蛋):
#   1. 跑本脚本前, 在 ESA 控制台「SSL/TLS → 源站证书」临时**关闭**源站证书校验
#      (否则签发 dl 时 LE 验证回源, 而此刻证书还不含 dl → 校验 525, 签不下来).
#   2. 跑完、cert 装好后, 再把源站证书校验**重新打开** (此后证书已含三域名, 回源校验全过).
#   3. 确认 ESA 安全防护放行 LE 对 /.well-known/acme-challenge/ 的访问 (实测应可回源).
#
# ECS 上跑 (一行, HTTP-01 不需要任何凭证):
#   curl -sSL https://raw.githubusercontent.com/wuyxp/tortoise-web/main/scripts/setup-ssl-acme-aliyun.sh | bash
#
# 关键顺序 (HTTP-01 与旧 DNS-01 不同): 必须**先写 nginx config 并 reload**, 让 443 能应答
#   /.well-known/acme-challenge/, **再签发** (LE 经 ESA 回源 443 拉验证文件). 旧脚本"先签后写"
#   在 webroot 模式下签不下来. 流程: 装 acme → (无证书则临时自签兜底) → 写 nginx+reload →
#   签发 → 装新证书+reload → 自检.

set -euo pipefail

DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
CERT_EMAIL="${SETUP_CERT_EMAIL:-support@serpilo.com}"
CERT_DIR="/etc/nginx/ssl/letsencrypt/$DOMAIN"
ACME_HOME="${ACME_HOME:-$HOME/.acme.sh}"
NGINX_ONLY="${NGINX_ONLY:-0}"  # 1 = 仅刷 nginx config (cert 已存在, 不碰 cert), 不需凭证

# ===== 0. 参数 =====
echo "==> 配置参数"
echo "    DOMAIN:      $DOMAIN (+ www + dl)"
echo "    DEPLOY_PATH: $DEPLOY_PATH"
echo "    CERT_EMAIL:  $CERT_EMAIL"
echo "    CERT_DIR:    $CERT_DIR"
echo "    NGINX_ONLY:  $NGINX_ONLY  ($([ "$NGINX_ONLY" = "1" ] && echo '仅刷 nginx config' || echo '完整模式 (含 HTTP-01 申请/续期)'))"
echo ""
echo "    HTTP-01 webroot, 不需要任何 DNS 凭证 (MEETING-2026-06-24-01)."
echo ""

# ===== 函数: 写 nginx config + reload (幂等, 用 $CERT_DIR 现有证书) =====
write_nginx_and_reload() {
  echo "==> 写 nginx config (server_name 含 dl + 443 块带 acme-challenge location) + reload"
  cat > /etc/nginx/sites-available/tortoise-web <<EOF
# HTTP 80 → HTTPS 301
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN dl.$DOMAIN;

    # ACME HTTP-01 challenge (80 直连兜底; ESA 回源走 443 见下)
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
# 注: 用 'listen 443 ssl http2;' 旧语法兼容 nginx <1.25.1 (Ubuntu 22.04 默认 1.18-1.24).
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

    # ACME HTTP-01 challenge (MEETING-2026-06-24-01): ESA 回源协议=HTTPS → LE 验证请求
    # 经 ESA 301 到 HTTPS 后回源打到本机 443, 故 443 块也必须能应答 acme-challenge
    # (原仅 80 块有, 回源走不到). ^~ 高优先, 压过下面 SPA fallback. 永不缓存.
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root $DEPLOY_PATH;
        allow all;
        try_files \$uri =404;
        add_header Cache-Control 'no-cache, no-store' always;
    }

    # version.json — UpdateChecker fetch 目标, 必须永远拿最新 (改了立即生效).
    # MEETING-2026-06-05-09 F5: no-cache 防 nginx/CDN 缓存住旧 version.json → 致"坏包改回了客户端却还读旧的、恢复失效".
    location = /downloads/version.json {
        default_type application/json;
        add_header Cache-Control 'no-cache, no-store, must-revalidate' always;
        add_header X-Content-Type-Options 'nosniff' always;
        autoindex off;
    }

    # APK 下载支持 (MEETING-2026-05-12-02-apk-distribution)
    # ^~ 优先匹配, 防 SPA fallback try_files 误把 .apk 当 SPA 路由
    location ^~ /downloads/ {
        types {
            application/vnd.android.package-archive apk;
            text/plain sha256;
        }
        add_header Content-Disposition 'attachment' always;
        add_header X-Content-Type-Options 'nosniff' always;
        # MEETING-2026-06-05-09 F5: APK/sha256 也 no-cache, 防缓存住旧 APK 而 version.json(no-cache)已换新 sha → 装时 sha256 mismatch.
        add_header Cache-Control 'no-cache' always;
        autoindex off;  # 防列表泄露版本历史
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

  ln -sf /etc/nginx/sites-available/tortoise-web /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  mkdir -p "$DEPLOY_PATH/downloads" "$DEPLOY_PATH/.well-known/acme-challenge"
  chown -R www-data:www-data "$DEPLOY_PATH/downloads" "$DEPLOY_PATH/.well-known" 2>/dev/null || true
  nginx -t
  systemctl reload nginx
  echo "    ✓ nginx reload OK"
}

# ============================================================
# NGINX_ONLY 模式: 仅刷 nginx config (cert 必须已存在)
# ============================================================
if [ "$NGINX_ONLY" = "1" ]; then
  echo "==> [NGINX_ONLY=1] 仅刷 nginx config"
  if [ ! -f "$CERT_DIR/fullchain.pem" ] || [ ! -f "$CERT_DIR/privkey.pem" ]; then
    echo "ERROR: NGINX_ONLY=1 要求 $CERT_DIR/{fullchain,privkey}.pem 已存在; 当前不存在 → 先跑完整模式"
    exit 1
  fi
  write_nginx_and_reload
  echo "✓ nginx config 已刷新 (cert 未动)."
  exit 0
fi

# ============================================================
# 完整模式: HTTP-01 申请/续期 + 写 nginx config
# ============================================================

# ===== 1. 装 acme.sh =====
echo "==> [1/6] 安装 acme.sh"
if [ ! -f "$ACME_HOME/acme.sh" ]; then
  curl -sSL https://get.acme.sh | sh -s email="$CERT_EMAIL" 2>&1 | tail -3
  echo "    ✓ acme.sh 已装到 $ACME_HOME"
else
  echo "    ✓ acme.sh 已存在 $ACME_HOME, 跳过装"
fi
ACME="$ACME_HOME/acme.sh"
[ -x "$ACME" ] || { echo "ERROR: $ACME 不存在或不可执行"; exit 1; }
# 默认 CA 用 Let's Encrypt (acme.sh 3.x 默认 ZeroSSL, 改回 LE)
"$ACME" --set-default-ca --server letsencrypt 2>&1 | tail -2

# ===== 2. 无证书兜底: 临时自签, 让 nginx 443 起得来 (后面被 LE 证书替换) =====
echo "==> [2/6] 检查 $CERT_DIR (无证书则临时自签, 让 nginx 能起来收 acme-challenge)"
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/fullchain.pem" ] || [ ! -f "$CERT_DIR/privkey.pem" ]; then
  echo "    无现成证书 → 生成临时自签 (10 年, 仅为让 443 启动, 随后被 LE 证书覆盖)"
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$CERT_DIR/privkey.pem" -out "$CERT_DIR/fullchain.pem" \
    -days 3650 -subj "/CN=$DOMAIN" 2>/dev/null
  chmod 600 "$CERT_DIR/privkey.pem"
else
  echo "    ✓ 已有证书 (本次会被新签的三域名证书替换)"
fi

# ===== 3. 先写 nginx config + reload (让 443 能应答 acme-challenge, 再签发) =====
echo "==> [3/6] 写 nginx config + reload (HTTP-01 前置: 443 必须先能服务验证路径)"
write_nginx_and_reload

# ===== 4. 申请 cert (HTTP-01 webroot, 三域名) =====
echo "==> [4/6] HTTP-01 webroot 申请 Let's Encrypt cert (serpilo + www + dl)"
echo "    LE 经 ESA 边缘回源拉 $DEPLOY_PATH/.well-known/acme-challenge/ 验证"
echo "    ⚠️ 此刻 ESA「源站证书校验」必须临时关闭, 否则 dl 验证回源 525 (见脚本头前置)"
# --force: 域名集从 (serpilo+www) 变 (serpilo+www+dl) 需强制重签; 日常 cron 续期按到期判定不受影响.
"$ACME" --issue -w "$DEPLOY_PATH" \
  -d "$DOMAIN" -d "www.$DOMAIN" -d "dl.$DOMAIN" \
  --email "$CERT_EMAIL" \
  --keylength 2048 --force 2>&1 | tail -25 || {
    echo "ERROR: 签发失败. 排查: (1) ESA 源站证书校验是否已临时关? (2) ESA 安全防护是否拦了 /.well-known/acme-challenge/?"
    echo "       (3) curl -I http://$DOMAIN/.well-known/acme-challenge/test 看能否穿 ESA 回源到本机"
    exit 1
  }

# ===== 5. 装新 cert + reload (续期 reloadcmd 一并设好) =====
echo "==> [5/6] 安装新证书到 $CERT_DIR/ + reload (续期 reloadcmd=reload nginx)"
"$ACME" --install-cert -d "$DOMAIN" \
  --key-file       "$CERT_DIR/privkey.pem" \
  --fullchain-file "$CERT_DIR/fullchain.pem" \
  --reloadcmd      "systemctl reload nginx" 2>&1 | tail -3
chmod 600 "$CERT_DIR/privkey.pem"
echo "    ✓ 三域名证书已装 + 续期 reloadcmd 已设 (60 天后自动续期 + reload)"

# ===== 6. 自检 =====
echo "==> [6/6] 自检"
echo "    源站证书覆盖域名 (应含 serpilo + www + dl):"
openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -ext subjectAltName 2>/dev/null | tail -1
echo "    源站证书到期:"
openssl x509 -in "$CERT_DIR/fullchain.pem" -noout -enddate 2>/dev/null
echo ""
echo "    本机 HTTP 80 (应 301): $(curl -sI --max-time 5 -H "Host: $DOMAIN" http://localhost/ 2>&1 | head -1)"
echo "    本机 HTTPS 443 (应 200): $(curl -skI --max-time 5 -H "Host: $DOMAIN" https://localhost/ 2>&1 | head -1)"
echo ""
echo "    续期任务:"
crontab -l 2>&1 | grep -i acme || echo "    (crontab 无 acme, 检查 systemd timer: systemctl list-timers | grep acme)"

# ===== 收尾提醒 =====
echo ""
echo "==> ⚠️ 跑完必做 (MEETING-2026-06-24-01):"
echo "    1. 回 ESA 控制台「SSL/TLS → 源站证书」把【源站证书校验】重新打开"
echo "       (此时 cert 已含 serpilo+www+dl, 回源校验会全过; dl 的 525 也随之消失)"
echo "    2. 验证: curl -sI https://serpilo.com / https://www.serpilo.com / https://dl.serpilo.com 应全 200"
echo ""
echo "    续期: acme.sh cron 每 60 天经 HTTP-01 自动续期 + reload nginx, 不需任何凭证."
echo "    监控: cert-check.yml (每周) 已改探源站证书(直连源站 IP, 非 serpilo.com 边缘), 续期失败 < 30 天会开 issue 告警."
echo ""
echo "✓ 全部完成. cert 覆盖 serpilo + www + dl 三域名, HTTP-01 自动续期, 无人工无凭证."
