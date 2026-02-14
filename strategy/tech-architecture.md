# 技术架构设计

**项目：** CLAW.AI MVP（AI 咨询 + AI 客服）
**版本：** v1.0
**日期：** 2026-02-14

---

## 🏗️ 系统架构图

```
┌─────────────────────────────────────────────────────────┐
│                        用户层                            │
├──────────────┬──────────────┬──────────────┬────────────┤
│  网站聊天窗口  │  管理后台      │  微信公众号    │  企业微信   │
└──────┬───────┴──────┬───────┴──────┬───────┴──────┬──────┘
       │              │              │              │
       │              │              │              │
┌──────▼──────────────▼──────────────▼──────────────▼──────┐
│                      API 网关层                          │
│              (Nginx + Rate Limiting)                     │
└──────┬──────────────┬──────────────┬──────────────┬──────┘
       │              │              │              │
┌──────▼──────┐  ┌────▼──────┐  ┌───▼──────┐  ┌───▼──────┐
│  咨询服务    │  │ 客服服务  │  │ 用户服务  │  │ 计费服务  │
│  (FastAPI) │  │ (FastAPI) │  │(FastAPI) │  │(FastAPI) │
└───┬────────┘  └───┬────────┘  └───┬──────┘  └───┬──────┘
    │               │               │              │
    └───────────────┴───────────────┴──────────────┘
                    │
┌───────────────────▼───────────────────┐
│              业务逻辑层                 │
│  - 对话管理                            │
│  - 知识库检索                          │
│  - 数据分析                            │
└───────────────────┬───────────────────┘
                    │
┌───────────────────▼───────────────────┐
│              AI 引擎层                 │
│  - Zhipu AI API                      │
│  - LangChain                         │
│  - Prompt 模板                        │
└───────────────────┬───────────────────┘
                    │
┌───────────────────▼───────────────────┐
│              数据层                    │
│  ┌─────────┐  ┌─────────┐           │
│  │PostgreSQL│  │  Redis  │           │
│  │(主数据)   │  │ (缓存)   │           │
│  └─────────┘  └─────────┘           │
│  ┌─────────┐                        │
│  │Pinecone  │                        │
│  │(向量库)   │                        │
│  └─────────┘                        │
└──────────────────────────────────────┘
```

---

## 📦 技术栈选择

### 后端

| 组件 | 技术选型 | 理由 |
|------|---------|------|
| 框架 | **FastAPI (Python)** | 快速开发、异步支持、自动文档 |
| 运行时 | Python 3.11+ | 成熟稳定、生态丰富 |
| ORM | **SQLAlchemy** | 强大的 ORM、支持 PostgreSQL |
| API 文档 | Swagger UI (内置) | 自动生成、易维护 |

### 前端

| 组件 | 技术选型 | 理由 |
|------|---------|------|
| 框架 | **React + TypeScript** | 组件化、类型安全 |
| UI 库 | **shadcn/ui** | 美观、易定制、Tailwind CSS |
| 实时通信 | **Socket.io** | 简单易用、支持重连 |
| 状态管理 | Zustand | 轻量、简单 |

### 数据库

| 组件 | 技术选型 | 理由 |
|------|---------|------|
| 主数据库 | **PostgreSQL 15** | 开源、功能强大、支持 JSON |
| 缓存 | **Redis 7** | 高性能、支持 Pub/Sub |
| 向量数据库 | **Pinecone** | 专为向量搜索优化、易用 |

### AI/ML

| 组件 | 技术选型 | 理由 |
|------|---------|------|
| AI 模型 | **Zhipu AI (GLM-4)** | 中文能力强、性价比高 |
| 框架 | **LangChain** | 功能丰富、社区活跃 |
| 向量化 | Sentence Transformers | 开源、效果好 |

### 基础设施

| 组件 | 技术选型 | 理由 |
|------|---------|------|
| 服务器 | 阿里云轻量应用服务器 | 成本低、够用 |
| 反向代理 | Nginx | 稳定、高性能 |
| 容器化 | Docker | 环境一致、易部署 |
| CI/CD | GitHub Actions | 免费、易用 |
| 监控 | UptimeRobot + 日志 | 免费、简单 |

---

## 🗄️ 数据库设计

### PostgreSQL Schema

#### 用户表 (users)

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    name VARCHAR(100),
    phone VARCHAR(20),
    company VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user',
    subscription_tier VARCHAR(50) DEFAULT 'free',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription ON users(subscription_tier);
```

#### 对话表 (conversations)

```sql
CREATE TABLE conversations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    bot_id INTEGER NOT NULL,
    title VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_bot_id ON conversations(bot_id);
```

#### 消息表 (messages)

```sql
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER REFERENCES conversations(id),
    role VARCHAR(50) NOT NULL, -- 'user' or 'assistant'
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
```

#### 知识库表 (knowledge_base)

```sql
CREATE TABLE knowledge_base (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_knowledge_base_user_id ON knowledge_base(user_id);
```

#### 文档表 (documents)

```sql
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    knowledge_base_id INTEGER REFERENCES knowledge_base(id),
    title VARCHAR(255) NOT NULL,
    content TEXT,
    file_path VARCHAR(500),
    status VARCHAR(50) DEFAULT 'processed',
    chunk_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_documents_kb_id ON documents(knowledge_base_id);
```

#### 咨询项目表 (consulting_projects)

```sql
CREATE TABLE consulting_projects (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    price DECIMAL(10, 2),
    deliverables TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consulting_user_id ON consulting_projects(user_id);
CREATE INDEX idx_consulting_status ON consulting_projects(status);
```

#### 订单表 (orders)

```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    type VARCHAR(50) NOT NULL, -- 'subscription' or 'consulting'
    item_id INTEGER, -- subscription_tier or consulting_project_id
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
```

---

## 🔄 API 设计

### 基础规范

- Base URL: `https://api.claw.ai/v1`
- 认证: Bearer Token (JWT)
- 请求格式: JSON
- 响应格式: JSON

### 通用响应格式

```json
{
  "success": true,
  "data": {},
  "message": "操作成功",
  "error": null
}
```

### 核心接口

#### 用户认证

```
POST /auth/register     # 注册
POST /auth/login        # 登录
POST /auth/logout       # 登出
POST /auth/refresh      # 刷新 token
```

#### 用户管理

```
GET  /users/profile           # 获取个人信息
PUT  /users/profile           # 更新个人信息
GET  /users/subscription      # 获取订阅信息
```

#### 对话管理

```
POST /conversations                # 创建对话
GET  /conversations                # 获取对话列表
GET  /conversations/:id            # 获取对话详情
PUT  /conversations/:id            # 更新对话
DELETE /conversations/:id          # 删除对话
POST /conversations/:id/messages   # 发送消息
GET  /conversations/:id/messages   # 获取消息历史
```

#### 知识库

```
POST /knowledge-bases          # 创建知识库
GET  /knowledge-bases          # 获取知识库列表
PUT  /knowledge-bases/:id      # 更新知识库
DELETE /knowledge-bases/:id    # 删除知识库
POST /knowledge-bases/:id/documents  # 上传文档
GET  /knowledge-bases/:id/documents  # 获取文档列表
```

#### 咨询服务

```
POST /consulting/projects          # 创建咨询项目
GET  /consulting/projects          # 获取项目列表
GET  /consulting/projects/:id      # 获取项目详情
PUT  /consulting/projects/:id      # 更新项目
POST /consulting/projects/:id/pay   # 支付项目
```

#### 计费

```
GET  /billing/orders          # 获取订单列表
GET  /billing/orders/:id      # 获取订单详情
POST /billing/webhook         # 支付回调
```

---

## 🔐 安全设计

### 认证与授权

- **JWT Token:** Access Token (1h) + Refresh Token (7d)
- **密码加密:** bcrypt 哈希
- **API 限流:** Nginx 速率限制
- **CORS:** 严格配置白名单

### 数据安全

- **HTTPS:** 强制 SSL
- **SQL 注入防护:** 参数化查询
- **XSS 防护:** 输入验证和转义
- **敏感数据:** 加密存储

---

## 📊 监控和日志

### 应用监控

- **健康检查:** `/health`
- **性能监控:** 日志分析
- **错误追踪:** Sentry (可选)

### 日志

- **访问日志:** Nginx 日志
- **应用日志:** Python logging
- **错误日志:** 单独记录

---

## 🚀 部署架构

### 服务器配置

```
阿里云轻量应用服务器:
- CPU: 2 核
- 内存: 4 GB
- 磁盘: 60 GB SSD
- 带宽: 5 Mbps
- 价格: 约 ¥300/年
```

### 容器化

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### CI/CD Pipeline

```
GitHub Actions:
1. 代码推送
2. 运行测试
3. 构建 Docker 镜像
4. 推送到阿里云容器镜像
5. 部署到生产环境
```

---

## 📋 开发环境搭建

### 前置要求

```bash
Python 3.11+
Node.js 18+
Docker
Git
```

### 后端开发

```bash
# 克隆仓库
git clone https://github.com/sendwealth/claw-ai-backend.git
cd claw-ai-backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入配置

# 启动数据库
docker-compose up -d

# 运行迁移
alembic upgrade head

# 启动开发服务器
uvicorn main:app --reload
```

### 前端开发

```bash
# 克隆仓库
git clone https://github.com/sendwealth/claw-ai-frontend.git
cd claw-ai-frontend

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env.local
# 编辑 .env.local 填入 API 地址

# 启动开发服务器
npm run dev
```

---

## 🎯 下一步

### 立即开始

1. ✅ 创建后端代码仓库
2. ✅ 创建前端代码仓库
3. ⏳ 搭建开发环境
4. ⏳ 实现数据库 Schema
5. ⏳ 实现 API 框架

### 本周完成

- [ ] 核心接口实现
- [ ] Zhipu AI 对接
- [ ] 前端聊天窗口
- [ ] 管理后台基础功能

---

*本技术架构将根据开发进展持续优化*
