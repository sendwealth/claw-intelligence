# 数据库设计文档

**项目：** CLAW.AI
**设计者：** OpenClaw (CTO)
**更新日期：** 2026-02-14

---

## 📊 数据库概览

### ER 图

```
┌──────────────┐
│    Users     │
├──────────────┤
│ id (PK)      │
│ email        │
│ password_hash│
│ name         │
│ phone        │
│ company      │
│ role         │
│ subscription │
│ is_active    │
│ is_verified  │
│ created_at   │
│ updated_at   │
└──────┬───────┘
       │
       ├─────────────┬──────────────┐
       │             │              │
       ▼             ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│Conversations│ │KnowledgeBase│ │   (更多)    │
├─────────────┤ ├─────────────┤ └─────────────┘
│ id (PK)     │ │ id (PK)     │
│ user_id (FK)│ │ user_id (FK)│
│ title       │ │ name        │
│ status      │ │ description │
│ type        │ │ ...         │
│ ...         │ └─────────────┘
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Messages   │
├─────────────┤
│ id (PK)     │
│ conv_id(FK) │
│ role        │
│ content     │
│ tokens      │
│ cost        │
│ ...         │
└─────────────┘
```

---

## 🗄️ 表结构详解

### 1. users - 用户表

存储用户基本信息和认证数据。

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | INT | 主键 | PK, AUTO_INCREMENT |
| email | VARCHAR(255) | 邮箱 | UNIQUE, NOT NULL, INDEX |
| password_hash | VARCHAR(255) | 密码哈希 | NOT NULL |
| name | VARCHAR(100) | 姓名 | - |
| phone | VARCHAR(20) | 电话 | - |
| company | VARCHAR(100) | 公司 | - |
| role | VARCHAR(50) | 角色 | DEFAULT 'user' |
| subscription_tier | VARCHAR(50) | 订阅层级 | DEFAULT 'free' |
| is_active | BOOLEAN | 是否激活 | DEFAULT TRUE |
| is_verified | BOOLEAN | 是否验证 | DEFAULT FALSE |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

**订阅层级 (subscription_tier)：**
- `free` - 免费版
- `standard` - 标准版
- `enterprise` - 企业版

---

### 2. conversations - 对话表

存储对话会话信息。

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | INT | 主键 | PK, AUTO_INCREMENT |
| user_id | INT | 用户 ID | FK, NOT NULL, INDEX |
| title | VARCHAR(200) | 对话标题 | DEFAULT '新对话' |
| status | VARCHAR(50) | 对话状态 | DEFAULT 'active' |
| conversation_type | VARCHAR(50) | 对话类型 | DEFAULT 'chat' |
| model | VARCHAR(50) | AI 模型 | DEFAULT 'glm-4' |
| system_prompt | TEXT | 系统提示词 | - |
| metadata | JSON | 元数据 | - |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

**对话状态 (status)：**
- `active` - 进行中
- `paused` - 已暂停
- `completed` - 已完成
- `archived` - 已归档

**对话类型 (conversation_type)：**
- `chat` - 普通聊天
- `consulting` - 咨询对话
- `support` - 客服支持

---

### 3. messages - 消息表

存储对话消息内容。

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | INT | 主键 | PK, AUTO_INCREMENT |
| conversation_id | INT | 对话 ID | FK, NOT NULL, INDEX |
| role | VARCHAR(50) | 消息角色 | NOT NULL |
| content | TEXT | 消息内容 | NOT NULL |
| tokens | INT | Token 数量 | - |
| cost | DECIMAL | 成本（元） | - |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

**消息角色 (role)：**
- `user` - 用户消息
- `assistant` - AI 消息
- `system` - 系统消息

---

### 4. knowledge_bases - 知识库表

存储用户的知识库信息。

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | INT | 主键 | PK, AUTO_INCREMENT |
| user_id | INT | 用户 ID | FK, NOT NULL, INDEX |
| name | VARCHAR(200) | 知识库名称 | NOT NULL |
| description | TEXT | 描述 | - |
| embedding_model | VARCHAR(100) | 嵌入模型 | DEFAULT 'text-embedding-ada-002' |
| metadata | JSON | 元数据 | - |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

---

### 5. documents - 文档表

存储知识库中的文档。

| 字段 | 类型 | 说明 | 约束 |
|------|------|------|------|
| id | INT | 主键 | PK, AUTO_INCREMENT |
| knowledge_base_id | INT | 知识库 ID | FK, NOT NULL, INDEX |
| title | VARCHAR(200) | 文档标题 | NOT NULL |
| content | TEXT | 文档内容 | NOT NULL |
| file_url | VARCHAR(500) | 文件 URL | - |
| file_type | VARCHAR(50) | 文件类型 | - |
| file_size | INT | 文件大小（字节） | - |
| chunk_count | INT | 分片数量 | DEFAULT 0 |
| embedding_vector | VARCHAR(500) | 向量 ID | - |
| metadata | JSON | 元数据 | - |
| created_at | TIMESTAMP | 创建时间 | DEFAULT NOW() |
| updated_at | TIMESTAMP | 更新时间 | AUTO UPDATE |

---

## 🔗 关系说明

### User → Conversations (一对多)
一个用户可以有多个对话。

### User → KnowledgeBases (一对多)
一个用户可以有多个知识库。

### Conversation → Messages (一对多)
一个对话可以有多条消息。

### KnowledgeBase → Documents (一对多)
一个知识库可以包含多个文档。

---

## 📋 索引设计

### 性能优化索引
- `users.email` - 邮箱唯一索引
- `conversations.user_id` - 用户对话查询
- `messages.conversation_id` - 对话消息查询
- `knowledge_bases.user_id` - 用户知识库查询
- `documents.knowledge_base_id` - 知识库文档查询

---

## 🔒 安全设计

### 密码存储
- 使用 `bcrypt` 加密
- 永远不存储明文密码

### 认证
- JWT Token 认证
- Token 过期时间：1 小时（访问令牌）、7 天（刷新令牌）

---

## 📊 数据统计

### 查询示例

**用户对话数量：**
```sql
SELECT COUNT(*) FROM conversations WHERE user_id = ?;
```

**对话消息数量：**
```sql
SELECT COUNT(*) FROM messages WHERE conversation_id = ?;
```

**知识库文档数量：**
```sql
SELECT COUNT(*) FROM documents WHERE knowledge_base_id = ?;
```

---

## 🚀 迁移策略

### 使用 Alembic
```bash
# 创建迁移
alembic revision --autogenerate -m "描述"

# 执行迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1
```

---

## 📝 备注

- 所有表都包含 `created_at` 和 `updated_at` 时间戳
- 使用软删除（未实现，后续添加）
- 支持多租户架构（通过 `user_id` 隔离数据）

---

*数据库设计 v1.0 - OpenClaw (CTO)*
