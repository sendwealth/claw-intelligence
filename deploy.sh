#!/bin/bash

# OpenSpark 智能科技 - 一键部署脚本
# 适用于宝塔面板服务器

set -e

echo "========================================="
echo "  OpenSpark 智能科技 - 网站一键部署"
echo "========================================="
echo ""

# 检测操作系统
if [ -f /etc/redhat-release ]; then
    OS="centos"
elif [ -f /etc/debian_version ]; then
    OS="ubuntu"
else
    echo "❌ 不支持的操作系统"
    exit 1
fi

echo "✅ 检测到操作系统: $OS"
echo ""

# 安装基础工具
echo "📦 安装基础工具..."
if [ "$OS" = "centos" ]; then
    yum install -y wget curl git unzip
else
    apt update && apt install -y wget curl git unzip
fi
echo ""

# 检查 Nginx 是否安装
if ! command -v nginx &> /dev/null; then
    echo "📦 安装 Nginx..."
    if [ "$OS" = "centos" ]; then
        yum install -y nginx
    else
        apt install -y nginx
    fi
    systemctl start nginx
    systemctl enable nginx
else
    echo "✅ Nginx 已安装"
fi
echo ""

# 创建网站目录
echo "📁 创建网站目录..."
mkdir -p /var/www/openspark
cd /var/www/openspark
echo ""

# 下载网站文件
echo "⬇️ 下载网站文件..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="OpenSpark 智能科技 - 提供人工智能技术咨询服务、智能客服机器人开发、企业数字化转型解决方案">
    <meta name="keywords" content="人工智能,AI咨询,智能客服,软件开发,企业数字化转型">
    <title>OpenSpark 智能科技 - 人工智能技术服务</title>
    <style>
        * {margin: 0; padding: 0; box-sizing: border-box;}
        body {font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif; line-height: 1.7; color: #333; background: #f8f9fa;}
        .container {max-width: 1200px; margin: 0 auto; padding: 0 20px;}
        header {background: white; box-shadow: 0 2px 10px rgba(0,0,0,0.1); position: sticky; top: 0; z-index: 100;}
        nav {display: flex; justify-content: space-between; align-items: center; padding: 20px 0;}
        .logo {font-size: 24px; font-weight: bold; color: #2563eb; text-decoration: none;}
        .nav-links {display: flex; gap: 30px;}
        .nav-links a {text-decoration: none; color: #666; font-weight: 500; transition: color 0.3s;}
        .nav-links a:hover {color: #2563eb;}
        .hero {background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 100px 0; text-align: center;}
        .hero h1 {font-size: 48px; margin-bottom: 20px;}
        .hero p {font-size: 20px; opacity: 0.9; max-width: 600px; margin: 0 auto 30px;}
        .cta-btn {display: inline-block; background: white; color: #667eea; padding: 15px 40px; border-radius: 30px; text-decoration: none; font-weight: bold; transition: transform 0.3s;}
        .cta-btn:hover {transform: translateY(-3px); box-shadow: 0 5px 20px rgba(0,0,0,0.2);}
        section {padding: 80px 0;}
        .section-title {text-align: center; font-size: 36px; margin-bottom: 60px; color: #333;}
        .about-content {display: grid; grid-template-columns: 1fr 1fr; gap: 60px; align-items: center;}
        .about-text p {margin-bottom: 20px; color: #666;}
        .about-features {display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;}
        .feature {background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.05);}
        .feature h3 {color: #2563eb; margin-bottom: 10px;}
        .services {background: white;}
        .services-grid {display: grid; grid-template-columns: repeat(3, 1fr); gap: 30px;}
        .service-card {background: #f8f9fa; padding: 40px; border-radius: 10px; transition: transform 0.3s;}
        .service-card:hover {transform: translateY(-10px);}
        .service-icon {font-size: 48px; margin-bottom: 20px;}
        .service-card h3 {font-size: 24px; margin-bottom: 15px; color: #333;}
        .service-card p {color: #666;}
        .contact {background: #667eea; color: white;}
        .contact .section-title {color: white;}
        .contact-info {display: grid; grid-template-columns: repeat(3, 1fr); gap: 40px; text-align: center;}
        .contact-item h3 {font-size: 24px; margin-bottom: 15px;}
        .contact-item p {font-size: 18px; opacity: 0.9;}
        footer {background: #1a1a2e; color: #999; padding: 40px 0; text-align: center;}
        .icp {margin-top: 20px; font-size: 14px;}
        @media (max-width: 768px) {
            .nav-links {display: none;}
            .hero h1 {font-size: 32px;}
            .about-content, .services-grid, .contact-info {grid-template-columns: 1fr;}
        }
    </style>
</head>
<body>
    <header><div class="container"><nav><a href="#" class="logo">OpenSpark 智能科技</a><div class="nav-links"><a href="#about">关于我们</a><a href="#services">服务介绍</a><a href="#contact">联系我们</a></div></nav></div></header>
    <section class="hero"><div class="container"><h1>OpenSpark 智能科技</h1><p>让 AI 技术惠及每一个企业<br>提供人工智能技术咨询服务、智能客服机器人开发、企业数字化转型解决方案</p><a href="#contact" class="cta-btn">立即咨询</a></div></section>
    <section id="about" class="about"><div class="container"><h2 class="section-title">关于我们</h2><div class="about-content"><div class="about-text"><p>OpenSpark 智能科技是一家专注于人工智能技术服务的高科技企业。我们致力于通过 AI 技术，帮助中小企业降低成本、提高效率、实现数字化转型。</p><p>我们的团队由经验丰富的 AI 技术专家和行业顾问组成，为客户提供从咨询、设计到实施、维护的一站式服务。</p><p>我们相信，AI 技术不应该只是大企业的专利。通过我们的专业服务，每一个中小企业都能够享受到 AI 带来的便利和优势。</p></div><div class="about-features"><div class="feature"><h3>🎯 专业团队</h3><p>经验丰富的 AI 技术专家</p></div><div class="feature"><h3>💡 创新驱动</h3><p>持续关注 AI 技术前沿</p></div><div class="feature"><h3>🤝 客户至上</h3><p>量身定制的解决方案</p></div><div class="feature"><h3>📈 价值导向</h3><p>以结果为导向的服务</p></div></div></div></div></section>
    <section id="services" class="services"><div class="container"><h2 class="section-title">服务介绍</h2><div class="services-grid"><div class="service-card"><div class="service-icon">🤖</div><h3>AI 咨询服务</h3><p>为中小企业提供人工智能战略咨询、技术选型建议、实施方案设计等服务。帮助企业快速了解 AI 技术，制定合适的落地策略。</p></div><div class="service-card"><div class="service-icon">💬</div><h3>智能客服机器人</h3><p>开发企业级智能客服系统，支持多渠道接入、知识库管理、智能问答等功能。帮助企业降低客服成本，提升用户体验。</p></div><div class="service-card"><div class="service-icon">🚀</div><h3>软件开发服务</h3><p>提供企业级软件定制开发服务，包括 Web 应用、移动应用、管理系统等。从需求分析到上线运维，全流程服务。</p></div></div></div></section>
    <section id="contact" class="contact"><div class="container"><h2 class="section-title">联系我们</h2><div class="contact-info"><div class="contact-item"><h3>📧 电子邮箱</h3><p>contact@openspark.online</p></div><div class="contact-item"><h3>🌐 官方网站</h3><p>openspark.online</p></div><div class="contact-item"><h3>📍 公司地址</h3><p>中国 · 浙江 · 杭州</p></div></div></div></section>
    <footer><div class="container"><p>&copy; 2026 OpenSpark 智能科技 版权所有</p><div class="icp">备案号：备案中</div></div></footer>
    <script>
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function(e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {target.scrollIntoView({behavior: 'smooth'});}
            });
        });
    </script>
</body>
</html>
EOF
echo "✅ 网站文件创建成功"
echo ""

# 配置 Nginx
echo "⚙️  配置 Nginx..."
cat > /etc/nginx/conf.d/openspark.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name openspark.online www.openspark.online 111.229.40.25;

    root /var/www/openspark;
    index index.html;

    charset utf-8;

    # 访问日志
    access_log /var/log/nginx/openspark_access.log;
    error_log /var/log/nginx/openspark_error.log;

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
NGINX_EOF
echo "✅ Nginx 配置成功"
echo ""

# 设置权限
echo "🔒 设置文件权限..."
chown -R www-data:www-data /var/www/openspark 2>/dev/null || chown -R nginx:nginx /var/www/openspark
chmod -R 755 /var/www/openspark
echo ""

# 测试 Nginx 配置
echo "🧪 测试 Nginx 配置..."
nginx -t
echo ""

# 重启 Nginx
echo "🔄 重启 Nginx..."
systemctl restart nginx
echo ""

# 检查服务状态
echo "📊 检查服务状态..."
systemctl status nginx --no-pager | head -10
echo ""

echo "========================================="
echo "  ✅ 部署完成！"
echo "========================================="
echo ""
echo "📱 访问方式："
echo "   1. 通过域名: http://openspark.online"
echo "   2. 通过IP: http://111.229.40.25"
echo ""
echo "🔍 测试访问："
echo "   在浏览器中打开上面的地址"
echo ""
echo "📋 后续操作："
echo "   1. 检查网站是否正常显示"
echo "   2. 等待备案审核通过"
echo "   3. 备案通过后，更新 ICP 备案号"
echo ""
echo "========================================="
