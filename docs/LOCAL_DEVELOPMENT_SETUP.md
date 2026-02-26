# 本地开发环境搭建指南

本文档介绍如何在本地启动 CLAW.AI 前后端开发环境。

---

## 前置要求

- Node.js 18+ (推荐 20+)
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Docker (可选，用于部署 Qdrant)

---

## 一、后端启动

### 1.1 安装依赖

```bash
cd claw-ai-backend
pip install -r requirements.txt
```

### 1.2 配置环境变量

复制 `.env.example` 到 `.env` 并编辑：

```bash
cp .env.example .env
```

**关键配置项：**

```bash
# 数据库配置
DATABASE_URL=postgresql://postgres:password@localhost:5432/claw_ai

# Redis 配置
REDIS_URL=redis://localhost:6379/0

# 智谱 AI API（必需）
ZHIPUAI_API_KEY=your-zhipu-ai-api-key-here
ZHIPUAI_MODEL=glm-4

# Qdrant 配置
QDRANT_HOST=localhost
QDRANT_PORT=6333
```

### 1.3 启动 Qdrant（Docker）

```bash
# 使用 Docker 启动 Qdrant
docker run -d \
  --name claw-qdrant \
  -p 6333:6333 \
  -p 6334:6334 \
  qdrant/qdrant:latest
```

### 1.4 初始化数据库

```bash
# 运行数据库迁移
alembic upgrade head
```

### 1.5 启动后端服务

```bash
# 开发模式（支持热重载）
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 生产模式
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 1.6 验证后端服务

访问以下地址验证：

- API 文档: http://localhost:8000/docs
- 健康检查: http://localhost:8000/health

---

## 二、前端启动

### 2.1 安装依赖

```bash
cd claw-ai-frontend
npm install
```

### 2.2 配置环境变量

创建 `.env` 文件：

```bash
# 开发环境使用代理，无需配置完整 URL
VITE_API_BASE_URL=/api/v1
VITE_APP_NAME=CLAW.AI
VITE_APP_VERSION=1.0.0
VITE_WS_URL=ws://localhost:8000
VITE_ENABLE_ANALYTICS=false
```

### 2.3 启动前端开发服务器

```bash
npm run dev
```

前端将运行在：http://localhost:3000

---

## 三、前后端联调

### 3.1 代理配置

Vite 已配置代理，会自动将 `/api` 请求转发到 `http://localhost:8000`：

```typescript
// vite.config.ts
server: {
  port: 3000,
  proxy: {
    '/api': {
      target: 'http://localhost:8000',
      changeOrigin: true,
    },
    '/ws': {
      target: 'ws://localhost:8000',
      ws: true,
    },
  },
}
```

### 3.2 测试 API 连接

1. 启动后端（端口 8000）
2. 启动前端（端口 3000）
3. 访问 http://localhost:3000
4. 测试登录/注册功能

---

## 四、Docker 一键部署

### 4.1 使用 Docker Compose

```bash
cd claw-ai-backend

# 启动所有服务（Qdrant + PostgreSQL + Redis）
docker compose -f docker-compose.rag.yml up -d

# 查看服务状态
docker compose -f docker-compose.rag.yml ps

# 停止所有服务
docker compose -f docker-compose.rag.yml down
```

### 4.2 服务说明

| 服务 | 端口 | 说明 |
|------|------|------|
| Qdrant | 6333, 6334 | 向量数据库 |
| PostgreSQL | 5432 | 关系数据库 |
| Redis | 6379 | 缓存 |

---

## 五、常见问题

### 5.1 Qdrant 连接失败

**问题：** `Connection refused` 错误

**解决方案：**
```bash
# 检查 Qdrant 是否运行
docker ps | grep qdrant

# 重启 Qdrant
docker restart claw-qdrant

# 查看日志
docker logs claw-qdrant
```

### 5.2 数据库连接失败

**问题：** `psycopg2.OperationalError`

**解决方案：**
```bash
# 检查 PostgreSQL 是否运行
systemctl status postgresql

# 或使用 Docker 启动
docker run -d \
  --name claw-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=claw_ai \
  -p 5432:5432 \
  postgres:15-alpine
```

### 5.3 Redis 连接失败

**问题：** `redis.exceptions.ConnectionError`

**解决方案：**
```bash
# 检查 Redis 是否运行
systemctl status redis

# 或使用 Docker 启动
docker run -d \
  --name claw-redis \
  -p 6379:6379 \
  redis:7-alpine
```

### 5.4 智谱 API 错误

**问题：** `ZHIPUAI_API_KEY` 配置错误

**解决方案：**
```bash
# 1. 获取 API Key
# 访问 https://open.bigmodel.cn/

# 2. 编辑 .env 文件
ZHIPUAI_API_KEY=your-actual-api-key-here

# 3. 重启后端服务
```

### 5.5 前端跨域问题

**问题：** CORS 错误

**解决方案：**

检查后端 CORS 配置：

```python
# app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 六、生产环境部署

### 6.1 后端部署

```bash
# 构建生产镜像
cd claw-ai-backend
docker build -t claw-ai-backend .

# 运行容器
docker run -d \
  --name claw-backend \
  -p 8000:8000 \
  --env-file .env \
  claw-ai-backend
```

### 6.2 前端部署

```bash
# 构建生产版本
cd claw-ai-frontend
npm run build

# 使用 Docker
docker build -t claw-ai-frontend .

# 运行容器
docker run -d \
  --name claw-frontend \
  -p 80:80 \
  claw-ai-frontend
```

### 6.3 使用 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name openspark.online;

    # 前端
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # 后端 API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # WebSocket
    location /ws {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## 七、开发工具

### 7.1 数据库管理

推荐使用 pgAdmin 或 DBeaver 管理 PostgreSQL 数据库。

### 7.2 Redis 管理

推荐使用 RedisInsight 管理 Redis。

### 7.3 Qdrant 管理

访问 Qdrant Web UI: http://localhost:6333/dashboard

### 7.4 API 测试

使用 Swagger UI 测试 API: http://localhost:8000/docs

---

## 八、日志和调试

### 8.1 后端日志

```bash
# 查看实时日志
tail -f claw-ai-backend/logs/app.log

# 使用 Docker
docker logs -f claw-backend
```

### 8.2 前端日志

打开浏览器开发者工具（F12），查看 Console 标签。

---

## 九、性能优化

### 9.1 后端优化

- 启用 Redis 缓存
- 使用 Gunicorn 多进程部署
- 启用数据库连接池

### 9.2 前端优化

- 使用代码分割（React.lazy）
- 启用 Gzip 压缩
- 使用 CDN 加载静态资源

---

## 十、故障排查流程

遇到问题时，按以下步骤排查：

1. **检查服务状态**
   ```bash
   # 检查后端
   curl http://localhost:8000/health

   # 检查前端
   curl http://localhost:3000
   ```

2. **查看日志**
   ```bash
   # 后端日志
   tail -f claw-ai-backend/logs/app.log

   # Docker 日志
   docker logs claw-backend
   ```

3. **检查依赖服务**
   ```bash
   # PostgreSQL
   psql -h localhost -U postgres -d claw_ai

   # Redis
   redis-cli ping

   # Qdrant
   curl http://localhost:6333/health
   ```

4. **重启服务**
   ```bash
   # 重启后端
   systemctl restart claw-backend

   # 重启前端
   npm run dev
   ```

---

**文档更新日期：** 2026-02-26
**负责人：** CEO OpenClaw
