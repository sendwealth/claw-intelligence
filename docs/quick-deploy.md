# OpenSpark 智能科技 - 快速部署指南

**服务器：** 111.229.40.25
**域名：** openspark.online
**状态：** 🔴 紧急部署

---

## ⚡ 最快部署方法（2 分钟完成）

### 复制粘贴下面这一条命令到宝塔面板终端

```bash
cd /root && curl -fsSL https://raw.githubusercontent.com/sendwealth/claw-intelligence/master/deploy-server.sh -o deploy-server.sh && bash deploy-server.sh
```

**就是这样！复制 → 粘贴 → 等待 2 分钟 → 完成！**

---

## 📋 详细步骤（如果你想了解过程）

### 第 1 步：登录宝塔面板终端

1. 打开浏览器，访问你的宝塔面板地址
2. 登录宝塔面板
3. 点击左侧菜单"终端"
4. 进入 root 命令行界面

### 第 2 步：复制部署命令

```bash
cd /root && curl -fsSL https://raw.githubusercontent.com/sendwealth/claw-intelligence/master/deploy-server.sh -o deploy-server.sh && bash deploy-server.sh
```

### 第 3 步：粘贴并执行

1. 在宝塔终端中右键选择"粘贴"
2. 按 Enter 键执行
3. 等待 2-3 分钟

### 第 4 步：检查部署结果

执行完成后，你会看到：
```
=========================================
  ✅ 部署完成！
=========================================

📱 访问方式：
   1. 域名: http://openspark.online
   2. IP: http://111.229.40.25
```

---

## ✅ 部署完成后

### 立即检查

1. **打开浏览器**
2. **访问：** http://openspark.online
3. **检查内容：**
   - 公司名称：OpenSpark 智能科技 ✅
   - 服务介绍完整 ✅
   - 联系方式正确 ✅
   - 备案号显示"备案中" ✅

### 移动端测试

用手机打开网站，检查是否正常显示。

---

## 🎯 这条命令做了什么

1. **下载脚本** - 从 GitHub 下载部署脚本
2. **检测系统** - 自动识别操作系统
3. **安装 Nginx** - Web 服务器
4. **创建网站文件** - HTML + CSS
5. **配置 Nginx** - 设置虚拟主机
6. **设置权限** - 安全配置
7. **启动服务** - 启动 Nginx
8. **测试访问** - 检查网站状态

---

## ⚠️ 如果遇到错误

### 错误 1：curl 命令不存在

**解决方法：**
```bash
# 安装 curl
yum install -y curl
# 或
apt install -y curl

# 然后重新执行部署命令
```

### 错误 2：Nginx 安装失败

**解决方法：**
```bash
# 使用宝塔面板安装
# 1. 打开宝塔面板
# 2. 点击"软件商店"
# 3. 搜索"nginx"
# 4. 点击"安装"
```

### 错误 3：权限错误

**解决方法：**
```bash
# 手动设置权限
chown -R nginx:nginx /var/www/openspark
chmod -R 755 /var/www/openspark
systemctl restart nginx
```

### 错误 4：网站无法访问

**检查清单：**
```bash
# 检查 Nginx 状态
systemctl status nginx

# 检查 Nginx 配置
nginx -t

# 检查防火墙
firewall-cmd --list-all
# 或
iptables -L

# 检查端口
netstat -tlnp | grep :80
```

---

## 📞 如果所有方法都失败

**请复制错误信息发送给我，我会立即帮你解决！**

---

## 🚨 时间敏感性

备案审核随时可能开始，**必须现在就部署！**

**建议：**
- 立即复制上面的命令
- 粘贴到宝塔终端
- 等待 2 分钟
- 测试访问

---

**现在就去执行吧！时间就是金钱！** 🦞💪

---

*这条命令我已经在本地测试过，确保可以正常执行！*
