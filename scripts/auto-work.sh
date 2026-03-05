#!/bin/bash
# CLAW.AI 自主工作引擎
# 每小时执行一次，无需人工干预

set -e

REPO_DIR="/var/www/claw-intelligence"
MEMORY_DIR="$REPO_DIR/memory"
REPORTS_DIR="$REPO_DIR/reports"
LOG_FILE="$REPO_DIR/logs/auto-work.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 创建必要目录
mkdir -p "$MEMORY_DIR" "$REPORTS_DIR/daily" "$REPORTS_DIR/weekly" "$REPORTS_DIR/monthly" "$REPO_DIR/logs"

log "${BLUE}🤖 CLAW.AI 自主工作引擎启动${NC}"
log "======================================"

# 1. 环境感知 - 检查 GitHub 仓库
log "${YELLOW}📡 任务 1: 环境感知${NC}"
cd "$REPO_DIR"
git fetch origin 2>/dev/null || true
CHANGES=$(git log HEAD..origin/main --oneline 2>/dev/null | wc -l)
if [ "$CHANGES" -gt 0 ]; then
    log "${GREEN}✅ 发现 $CHANGES 个新提交，开始拉取...${NC}"
    git pull origin main
else
    log "✅ 仓库已是最新"
fi

# 2. 检查 GitHub Issues
log "${YELLOW}📋 任务 2: 检查 Issues${NC}"
ISSUES=$(gh issue list --state open --json number,title 2>/dev/null || echo "[]")
ISSUE_COUNT=$(echo "$ISSUES" | jq length 2>/dev/null || echo "0")
log "📊 当前开放 Issues: $ISSUE_COUNT 个"

# 3. 服务器健康检查
log "${YELLOW}💻 任务 3: 服务器健康检查${NC}"
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

log "CPU: ${CPU_USAGE}% | 内存: ${MEM_USAGE}% | 磁盘: ${DISK_USAGE}%"

if (( $(echo "$CPU_USAGE > 80" | bc -l) )) || (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
    log "${RED}⚠️  资源使用率过高！${NC}"
fi

# 4. 更新 memory 记录
TODAY=$(date '+%Y-%m-%d')
MEMORY_FILE="$MEMORY_DIR/$TODAY.md"

if [ ! -f "$MEMORY_FILE" ]; then
    cat > "$MEMORY_FILE" <<EOF
# 工作日志 - $TODAY

## 📊 今日数据
- 开放 Issues: $ISSUE_COUNT
- CPU 使用: ${CPU_USAGE}%
- 内存使用: ${MEM_USAGE}%
- 磁盘使用: ${DISK_USAGE}%

## 📝 工作记录

### $(date '+%H:%M') - 自主工作引擎
- ✅ 环境感知完成
- ✅ Issues 检查完成
- ✅ 服务器健康检查完成

EOF
    log "${GREEN}✅ 创建今日工作日志${NC}"
else
    echo -e "\n### $(date '+%H:%M') - 自主工作引擎" >> "$MEMORY_FILE"
    echo "- ✅ 环境感知完成 (Issues: $ISSUE_COUNT)" >> "$MEMORY_FILE"
    echo "- ✅ 服务器健康检查 (CPU: ${CPU_USAGE}%, MEM: ${MEM_USAGE}%)" >> "$MEMORY_FILE"
    log "${GREEN}✅ 更新今日工作日志${NC}"
fi

# 5. 提交更改
if [ -n "$(git status --porcelain)" ]; then
    log "${YELLOW}📦 提交工作记录...${NC}"
    git add .
    git commit -m "🤖 自动提交: 工作日志更新 $(date '+%Y-%m-%d %H:%M')" || true
    git push origin main || log "${RED}⚠️  推送失败，下次重试${NC}"
fi

log "${GREEN}✅ 自主工作引擎执行完成${NC}"
log "======================================"
