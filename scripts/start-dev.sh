#!/bin/bash
# CLAW.AI 本地开发环境启动脚本
# CEO: uc 🍋

set -e

echo "🍋 CLAW.AI 开发环境启动"
echo "========================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker 环境检查通过${NC}"

# 启动后端
echo ""
echo "📦 启动后端服务..."
cd ~/clawd/claw-ai-backend

# 检查 .env 文件
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env 文件不存在，从示例创建...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️  请编辑 .env 文件配置必要参数！${NC}"
fi

# 使用 Docker Compose 启动
if command -v docker-compose &> /dev/null; then
    docker-compose up -d postgres redis 2>/dev/null || true
else
    docker compose up -d postgres redis 2>/dev/null || true
fi

echo -e "${GREEN}✅ 数据库服务启动完成${NC}"

# 启动前端
echo ""
echo "🎨 启动前端服务..."
cd ~/clawd/claw-ai-frontend

# 检查 node_modules
if [ ! -d node_modules ]; then
    echo "安装前端依赖..."
    npm install
fi

echo ""
echo "========================"
echo -e "${GREEN}✅ 环境准备完成！${NC}"
echo ""
echo "🚀 启动命令："
echo "  后端: cd ~/clawd/claw-ai-backend && uvicorn app.main:app --reload"
echo "  前端: cd ~/clawd/claw-ai-frontend && npm run dev"
echo ""
echo "📍 访问地址："
echo "  后端 API: http://localhost:8000"
echo "  API 文档: http://localhost:8000/docs"
echo "  前端:     http://localhost:5173"
echo ""
