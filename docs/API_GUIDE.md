# CLAW.AI API 使用指南

**版本：** v1.0.0
**基础 URL：** `http://localhost:8000/api/v1`
**文档：** http://localhost:8000/docs

---

## 📋 目录

1. [概述](#概述)
2. [认证](#认证)
3. [用户管理](#用户管理)
4. [对话管理](#对话管理)
5. [知识库管理](#知识库管理)
6. [RAG 查询](#rag-查询)
7. [配置管理](#配置管理)
8. [WebSocket](#websocket)
9. [错误码](#错误码)
10. [示例代码](#示例代码)

---

## 概述

CLAW.AI 提供基于 RESTful API 的接口，支持：

- **用户认证** - 注册、登录、Token 刷新
- **对话管理** - 创建对话、发送消息、获取历史
- **知识库管理** - 创建知识库、上传文档、RAG 查询
- **配置管理** - 系统配置、用户配置
- **WebSocket** - 实时消息推送

### 基础信息

- **Base URL:** `http://localhost:8000/api/v1`
- **内容类型:** `application/json`
- **字符编码:** `UTF-8`
- **认证方式:** Bearer Token

### 通用响应格式

成功响应：
```json
{
  "success": true,
  "data": { ... },
  "message": "操作成功"
}
```

错误响应：
```json
{
  "success": false,
  "error": "错误信息",
  "code": "ERROR_CODE"
}
```

---

## 认证

### 1. 用户注册

注册新用户账号。

**端点：** `POST /auth/register`

**请求体：**
```json
{
  "username": "string",      // 用户名（必填，3-20字符）
  "password": "string",      // 密码（必填，最少8字符）
  "email": "string"          // 邮箱（可选）
}
```

**响应：**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "2026-02-26T12:00:00Z"
}
```

**状态码：**
- `201` - 注册成功
- `400` - 请求参数错误
- `409` - 用户名已存在

**示例：**
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Test123!","email":"test@example.com"}'
```

---

### 2. 用户登录

使用用户名和密码登录，获取访问 Token。

**端点：** `POST /auth/login`

**请求体：**
```json
{
  "username": "string",      // 用户名（必填）
  "password": "string"       // 密码（必填）
}
```

**响应：**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

**状态码：**
- `200` - 登录成功
- `401` - 用户名或密码错误

**示例：**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"Test123!"}'
```

---

### 3. Token 刷新

使用 Refresh Token 获取新的 Access Token。

**端点：** `POST /auth/refresh`

**请求体：**
```json
{
  "refresh_token": "string"   // Refresh Token（必填）
}
```

**响应：**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

**状态码：**
- `200` - 刷新成功
- `401` - Refresh Token 无效或过期

---

### 4. 获取当前用户信息

获取当前登录用户的信息。

**端点：** `GET /users/me`

**请求头：**
```
Authorization: Bearer <access_token>
```

**响应：**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "2026-02-26T12:00:00Z"
}
```

**状态码：**
- `200` - 成功
- `401` - 未认证

---

## 用户管理

### 1. 获取用户列表

获取所有用户列表（需要管理员权限）。

**端点：** `GET /users`

**查询参数：**
- `skip` - 跳过数量（默认：0）
- `limit` - 返回数量（默认：100）

**响应：**
```json
[
  {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "is_active": true
  }
]
```

---

### 2. 获取用户详情

获取指定用户的详细信息。

**端点：** `GET /users/{user_id}`

**路径参数：**
- `user_id` - 用户 ID（必填）

**响应：**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "is_active": true,
  "created_at": "2026-02-26T12:00:00Z"
}
```

---

### 3. 更新用户信息

更新用户信息。

**端点：** `PUT /users/{user_id}`

**路径参数：**
- `user_id` - 用户 ID（必填）

**请求体：**
```json
{
  "email": "new@example.com",      // 邮箱（可选）
  "is_active": true                // 是否激活（可选）
}
```

**响应：**
```json
{
  "id": 1,
  "username": "testuser",
  "email": "new@example.com",
  "is_active": true,
  "created_at": "2026-02-26T12:00:00Z"
}
```

---

## 对话管理

### 1. 创建对话

创建新的对话。

**端点：** `POST /conversations`

**请求头：**
```
Authorization: Bearer <access_token>
```

**请求体：**
```json
{
  "title": "string"           // 对话标题（必填）
}
```

**响应：**
```json
{
  "id": "conv_123",
  "user_id": 1,
  "title": "测试对话",
  "created_at": "2026-02-26T12:00:00Z",
  "updated_at": "2026-02-26T12:00:00Z"
}
```

**状态码：**
- `201` - 创建成功
- `400` - 请求参数错误

---

### 2. 获取对话列表

获取当前用户的所有对话。

**端点：** `GET /conversations`

**查询参数：**
- `skip` - 跳过数量（默认：0）
- `limit` - 返回数量（默认：100）

**响应：**
```json
[
  {
    "id": "conv_123",
    "title": "测试对话",
    "created_at": "2026-02-26T12:00:00Z"
  }
]
```

---

### 3. 获取对话详情

获取指定对话的详细信息。

**端点：** `GET /conversations/{conversation_id}`

**路径参数：**
- `conversation_id` - 对话 ID（必填）

**响应：**
```json
{
  "id": "conv_123",
  "user_id": 1,
  "title": "测试对话",
  "messages": [
    {
      "id": "msg_123",
      "content": "你好",
      "role": "user",
      "created_at": "2026-02-26T12:00:00Z"
    }
  ],
  "created_at": "2026-02-26T12:00:00Z"
}
```

---

### 4. 发送消息

向对话发送消息。

**端点：** `POST /conversations/{conversation_id}/messages`

**请求头：**
```
Authorization: Bearer <access_token>
```

**请求体：**
```json
{
  "content": "string",        // 消息内容（必填）
  "knowledge_base_ids": []    // 知识库 ID 列表（可选）
}
```

**响应：**
```json
{
  "id": "msg_123",
  "conversation_id": "conv_123",
  "content": "你好",
  "role": "user",
  "created_at": "2026-02-26T12:00:00Z"
}
```

---

### 5. 获取对话消息

获取对话的所有消息。

**端点：** `GET /conversations/{conversation_id}/messages`

**查询参数：**
- `skip` - 跳过数量（默认：0）
- `limit` - 返回数量（默认：100）

**响应：**
```json
{
  "messages": [
    {
      "id": "msg_123",
      "content": "你好",
      "role": "user",
      "created_at": "2026-02-26T12:00:00Z"
    }
  ],
  "total": 1
}
```

---

### 6. 删除对话

删除指定对话。

**端点：** `DELETE /conversations/{conversation_id}`

**请求头：**
```
Authorization: Bearer <access_token>
```

**响应：**
```json
{
  "message": "对话删除成功"
}
```

---

## 知识库管理

### 1. 创建知识库

创建新的知识库。

**端点：** `POST /knowledge`

**请求头：**
```
Authorization: Bearer <access_token>
```

**请求体：**
```json
{
  "name": "string",              // 知识库名称（必填）
  "description": "string",        // 描述（可选）
  "embedding_model": "string"    // Embedding 模型（可选，默认：text-embedding-ada-002）
}
```

**响应：**
```json
{
  "id": 1,
  "user_id": 1,
  "name": "测试知识库",
  "description": "这是一个测试知识库",
  "embedding_model": "text-embedding-ada-002",
  "created_at": "2026-02-26T12:00:00Z"
}
```

---

### 2. 获取知识库列表

获取当前用户的所有知识库。

**端点：** `GET /knowledge`

**查询参数：**
- `skip` - 跳过数量（默认：0）
- `limit` - 返回数量（默认：100）

**响应：**
```json
[
  {
    "id": 1,
    "name": "测试知识库",
    "document_count": 10,
    "created_at": "2026-02-26T12:00:00Z"
  }
]
```

---

### 3. 获取知识库详情

获取指定知识库的详细信息。

**端点：** `GET /knowledge/{knowledge_base_id}`

**路径参数：**
- `knowledge_base_id` - 知识库 ID（必填）

**响应：**
```json
{
  "id": 1,
  "name": "测试知识库",
  "description": "这是一个测试知识库",
  "embedding_model": "text-embedding-ada-002",
  "documents": [
    {
      "id": 1,
      "title": "测试文档",
      "file_type": "txt",
      "created_at": "2026-02-26T12:00:00Z"
    }
  ],
  "document_count": 1
}
```

---

### 4. 更新知识库

更新知识库信息。

**端点：** `PUT /knowledge/{knowledge_base_id}`

**请求头：**
```
Authorization: Bearer <access_token>
```

**请求体：**
```json
{
  "name": "string",          // 知识库名称（可选）
  "description": "string"     // 描述（可选）
}
```

**响应：**
```json
{
  "id": 1,
  "name": "更新后的名称",
  "description": "更新后的描述",
  "document_count": 1
}
```

---

### 5. 删除知识库

删除指定知识库（包括所有文档和向量索引）。

**端点：** `DELETE /knowledge/{knowledge_base_id}`

**请求头：**
```
Authorization: Bearer <access_token>
```

**响应：**
```json
{
  "message": "知识库删除成功"
}
```

---

### 6. 上传文档

上传文档到知识库。

**端点：** `POST /knowledge/{knowledge_base_id}/documents/upload`

**请求头：**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**表单数据：**
```
file: <file>          // 文件（必填）
title: string         // 文档标题（可选）
```

**响应：**
```json
{
  "id": 1,
  "knowledge_base_id": 1,
  "title": "测试文档",
  "file_type": "txt",
  "chunk_count": 5,
  "created_at": "2026-02-26T12:00:00Z"
}
```

**支持的文件格式：**
- `.txt` - 纯文本
- `.md`, `.markdown` - Markdown
- `.pdf` - PDF

---

### 7. 创建文档（直接提供内容）

创建文档并直接提供文本内容。

**端点：** `POST /knowledge/{knowledge_base_id}/documents`

**请求头：**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**请求体：**
```json
{
  "title": "string",      // 文档标题（必填）
  "content": "string",    // 文档内容（必填）
  "file_type": "string"   // 文件类型（必填，支持：txt, markdown）
}
```

**响应：**
```json
{
  "id": 1,
  "knowledge_base_id": 1,
  "title": "测试文档",
  "file_type": "txt",
  "chunk_count": 5,
  "created_at": "2026-02-26T12:00:00Z"
}
```

---

### 8. 获取文档列表

获取知识库的所有文档。

**端点：** `GET /knowledge/{knowledge_base_id}/documents`

**查询参数：**
- `skip` - 跳过数量（默认：0）
- `limit` - 返回数量（默认：100）

**响应：**
```json
{
  "documents": [
    {
      "id": 1,
      "title": "测试文档",
      "file_type": "txt",
      "chunk_count": 5,
      "created_at": "2026-02-26T12:00:00Z"
    }
  ],
  "total": 1
}
```

---

### 9. 删除文档

删除指定文档。

**端点：** `DELETE /knowledge/{knowledge_base_id}/documents/{document_id}`

**请求头：**
```
Authorization: Bearer <access_token>
```

**响应：**
```json
{
  "message": "文档删除成功"
}
```

---

## RAG 查询

### 1. 基于知识库的 RAG 查询

使用指定知识库进行 RAG 查询。

**端点：** `POST /knowledge/{knowledge_base_id}/query`

**请求头：**
```
Authorization: Bearer <access_token>
```

**查询参数：**
- `question` - 用户问题（必填）
- `top_k` - 返回最相似的前 K 个片段（可选，默认：5）

**响应：**
```json
{
  "success": true,
  "answer": "基于知识库的回答...",
  "sources": [
    {
      "document_id": 1,
      "title": "测试文档",
      "score": 0.92
    }
  ],
  "context": "检索到的上下文...",
  "tokens": 150,
  "cost": 0.001,
  "rag_enabled": true,
  "search_results_count": 5
}
```

**示例：**
```bash
curl -X POST "http://localhost:8000/api/v1/knowledge/1/query?question=如何使用%20Python&top_k=5" \
  -H "Authorization: Bearer <access_token>"
```

---

### 2. 全局 RAG 查询

跨所有知识库进行 RAG 查询。

**端点：** `POST /knowledge/query`

**请求头：**
```
Authorization: Bearer <access_token>
```

**查询参数：**
- `question` - 用户问题（必填）
- `top_k` - 返回最相似的前 K 个片段（可选，默认：5）

**响应：**
```json
{
  "success": true,
  "answer": "基于所有知识库的回答...",
  "sources": [
    {
      "knowledge_base_id": 1,
      "document_id": 1,
      "title": "测试文档",
      "score": 0.92
    }
  ],
  "rag_enabled": true
}
```

---

## 配置管理

### 1. 获取系统配置

获取系统配置信息。

**端点：** `GET /configs/system`

**响应：**
```json
{
  "app_name": "CLAW.AI",
  "app_version": "1.0.0",
  "embedding_models": [
    "text-embedding-ada-002",
    "text-embedding-3-small"
  ],
  "max_upload_size": 10485760
}
```

---

### 2. 获取用户配置

获取当前用户的配置。

**端点：** `GET /configs/user`

**请求头：**
```
Authorization: Bearer <access_token>
```

**响应：**
```json
{
  "default_embedding_model": "text-embedding-ada-002",
  "theme": "light",
  "language": "zh-CN"
}
```

---

### 3. 更新用户配置

更新用户配置。

**端点：** `PUT /configs/user`

**请求头：**
```
Authorization: Bearer <access_token>
```

**请求体：**
```json
{
  "default_embedding_model": "string",
  "theme": "string",
  "language": "string"
}
```

**响应：**
```json
{
  "default_embedding_model": "text-embedding-ada-002",
  "theme": "dark",
  "language": "en-US"
}
```

---

## WebSocket

### 连接 WebSocket

**端点：** `ws://localhost:8000/api/v1/ws`

**查询参数：**
- `token` - Access Token（必填）

**连接示例（JavaScript）：**
```javascript
const socket = new WebSocket('ws://localhost:8000/api/v1/ws?token=<access_token>');

socket.onopen = () => {
  console.log('WebSocket 连接已建立');
};

socket.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('收到消息:', message);
};

socket.onerror = (error) => {
  console.error('WebSocket 错误:', error);
};

socket.onclose = () => {
  console.log('WebSocket 连接已关闭');
};
```

**消息格式：**
```json
{
  "type": "message",
  "data": {
    "conversation_id": "conv_123",
    "content": "消息内容",
    "role": "assistant",
    "timestamp": "2026-02-26T12:00:00Z"
  }
}
```

---

## 错误码

| 状态码 | 错误码 | 说明 |
|--------|--------|------|
| 400 | BAD_REQUEST | 请求参数错误 |
| 401 | UNAUTHORIZED | 未认证或 Token 无效 |
| 403 | FORBIDDEN | 无权限访问 |
| 404 | NOT_FOUND | 资源不存在 |
| 409 | CONFLICT | 资源冲突（如用户名已存在）|
| 422 | VALIDATION_ERROR | 数据验证失败 |
| 429 | RATE_LIMIT_EXCEEDED | 请求过于频繁 |
| 500 | INTERNAL_ERROR | 服务器内部错误 |

---

## 示例代码

### JavaScript (Fetch)

```javascript
// 1. 登录获取 Token
const loginResponse = await fetch('http://localhost:8000/api/v1/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'testuser',
    password: 'Test123!'
  })
});
const loginData = await loginResponse.json();
const token = loginData.access_token;

// 2. 创建知识库
const kbResponse = await fetch('http://localhost:8000/api/v1/knowledge', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    name: '测试知识库',
    description: '这是一个测试知识库'
  })
});
const kbData = await kbResponse.json();
console.log('知识库创建成功:', kbData);

// 3. RAG 查询
const queryResponse = await fetch(
  `http://localhost:8000/api/v1/knowledge/${kbData.id}/query?question=如何使用&top_k=5`,
  {
    headers: { 'Authorization': `Bearer ${token}` }
  }
);
const queryData = await queryResponse.json();
console.log('RAG 查询结果:', queryData);
```

### Python (Requests)

```python
import requests

# 1. 登录获取 Token
login_response = requests.post(
    'http://localhost:8000/api/v1/auth/login',
    json={
        'username': 'testuser',
        'password': 'Test123!'
    }
)
login_data = login_response.json()
token = login_data['access_token']

# 2. 创建知识库
kb_response = requests.post(
    'http://localhost:8000/api/v1/knowledge',
    headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    },
    json={
        'name': '测试知识库',
        'description': '这是一个测试知识库'
    }
)
kb_data = kb_response.json()
print('知识库创建成功:', kb_data)

# 3. RAG 查询
query_response = requests.get(
    f'http://localhost:8000/api/v1/knowledge/{kb_data["id"]}/query',
    params={
        'question': '如何使用',
        'top_k': 5
    },
    headers={'Authorization': f'Bearer {token}'}
)
query_data = query_response.json()
print('RAG 查询结果:', query_data)
```

---

## 相关文档

- [API 文档](http://localhost:8000/docs)
- [本地开发环境搭建指南](./LOCAL_DEPLOYMENT_SETUP.md)
- [部署检查清单](./DEPLOYMENT_CHECKLIST.md)

---

**文档更新日期：** 2026-02-26
**版本：** v1.0.0
**负责人：** CEO OpenClaw
