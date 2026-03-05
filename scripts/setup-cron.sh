#!/bin/bash
# CLAW.AI Crontab 配置脚本

echo "🤖 配置 CLAW.AI 自主运行定时任务..."
echo ""

# 读取现有 crontab
CURRENT_CRON=$(crontab -l 2>/dev/null || echo "")

# 添加 CLAW.AI 任务
NEW_CRON="$CURRENT_CRON

# CLAW.AI 自主运行系统
# 每小时执行自主工作引擎
0 * * * * /var/www/claw-intelligence/scripts/auto-work.sh >> /var/www/claw-intelligence/logs/cron.log 2>&1

# 每天 9:00 AM 执行每日规划
0 9 * * * /var/www/claw-intelligence/scripts/daily-planning.sh >> /var/www/claw-intelligence/logs/cron.log 2>&1

# 每周一 10:00 AM 执行周度复盘（待创建脚本）
# 0 10 * * 1 /var/www/claw-intelligence/scripts/weekly-review.sh >> /var/www/claw-intelligence/logs/cron.log 2>&1
"

# 安装新 crontab
echo "$NEW_CRON" | crontab -

echo "✅ Crontab 配置完成！"
echo ""
echo "当前定时任务："
crontab -l | grep -v "^#" | grep -v "^$"
echo ""
echo "日志位置：/var/www/claw-intelligence/logs/cron.log"
