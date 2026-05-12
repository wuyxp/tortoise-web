#!/bin/bash
# 一次性配置阿里云 ECS nginx + Let's Encrypt SSL
# MEETING-2026-05-11-04-static-website-v1
#
# 用法 (在本地终端执行):
#   ssh root@<aliyun-ip> 'bash -s' < scripts/setup-aliyun.sh
#
# 或上传到服务器后执行:
#   ssh root@<aliyun-ip>
#   bash setup-aliyun.sh
#
# 前置:
#   1. 域名 A 记录已指向 ECS 公网 IP (阿里云 DNS 控制台)
#   2. ECS 安全组已开放 80 + 443 端口
#   3. ICP 备案已生效

set -euo pipefail

# ===== 变量化 (PL 换域名时改这里, 或从 ENV 注入) =====
DOMAIN="${SETUP_DOMAIN:-serpilo.com}"
DEPLOY_PATH="${SETUP_DEPLOY_PATH:-/var/www/serpilo}"
CERT_EMAIL="${SETUP_CERT_EMAIL:-tortoise@example.com}"

echo "==> 配置参数"
echo "    DOMAIN:      $DOMAIN"
echo "    DEPLOY_PATH: $DEPLOY_PATH"
echo "    CERT_EMAIL:  $CERT_EMAIL"
echo ""

# ===== 1. 装 nginx + certbot + rsync =====
echo "==> [1/5] 安装 nginx + certbot + rsync"
if command -v apt-get &>/dev/null; then
  apt-get update -y
  apt-get install -y nginx certbot python3-certbot-nginx rsync
elif command -v yum &>/dev/null; then
  yum install -y nginx certbot python3-certbot-nginx rsync
else
  echo "ERROR: 不支持的包管理器 (仅 apt/yum). 阿里云 Ubuntu/CentOS 都支持."
  exit 1
fi

# ===== 2. 准备目录 =====
echo "==> [2/5] 准备 deploy 目录 $DEPLOY_PATH"
mkdir -p "$DEPLOY_PATH"
# 默认 web 用户 (Ubuntu: www-data; CentOS: nginx)
if id www-data &>/dev/null; then
  chown -R www-data:www-data "$DEPLOY_PATH"
elif id nginx &>/dev/null; then
  chown -R nginx:nginx "$DEPLOY_PATH"
fi

# 占位 index.html (DNS 验证 + 首次访问不 404)
if [ ! -f "$DEPLOY_PATH/index.html" ]; then
  cat > "$DEPLOY_PATH/index.html" <<EOF
<!doctype html><html><head><meta charset="utf-8"><title>$DOMAIN</title></head>
<body><h1>$DOMAIN</h1><p>Tortoise 主页部署中, 请稍后再访问.</p></body></html>
EOF
fi

# ===== 3. nginx server block =====
echo "==> [3/5] 写 nginx config"
cat > /etc/nginx/sites-available/tortoise-web <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    root $DEPLOY_PATH;
    index index.html;

    # SPA fallback
    location / {
        try_files \$uri \$uri/ \$uri.html /index.html;
    }

    # 静态资源缓存 1 年 (Astro 自带 hash, 安全)
    location ~* \.(css|js|woff2?|png|jpg|jpeg|webp|svg|ico)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # gzip
    gzip on;
    gzip_types text/css application/javascript application/json text/plain image/svg+xml;
    gzip_min_length 1024;
    gzip_vary on;

    # 安全 headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # ACME challenge (Let's Encrypt 续期需要)
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}
EOF

# 启用 + 禁用默认
ln -sf /etc/nginx/sites-available/tortoise-web /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试 + 重启
nginx -t
systemctl restart nginx
systemctl enable nginx

# ===== 4. Let's Encrypt SSL =====
echo "==> [4/5] 申请 Let's Encrypt SSL"
certbot --nginx \
  -d "$DOMAIN" -d "www.$DOMAIN" \
  --non-interactive --agree-tos \
  --email "$CERT_EMAIL" \
  --redirect

# ===== 5. 验证 + 续期 cron =====
echo "==> [5/5] 验证续期 cron"
systemctl status certbot.timer --no-pager || true

echo ""
echo "✓ 配置完成"
echo "  访问 https://$DOMAIN"
echo "  证书自动续期: systemctl status certbot.timer"
echo "  GitHub Actions 部署: 推 main 触发 deploy.yml → rsync 到 $DEPLOY_PATH"
echo ""
echo "  PL 下一步:"
echo "    1. tortoise-web 仓 Settings → Secrets 配 ALIYUN_HOST + ALIYUN_SSH_KEY (本机 SSH 私钥)"
echo "    2. tortoise-web 仓 Settings → Pages → Source: GitHub Actions"
echo "    3. push 触发首次部署"
