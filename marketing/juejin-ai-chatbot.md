# 从零开始：我用 FastAPI + 智谱AI 搭建智能客服系统的技术实践

## 前言

作为一个独立开发者，我一直想给客户做一个智能客服系统。经过两周的摸索，终于上线了一个能处理 80% 常见问题的 AI 客服。今天分享一下技术实现和踩坑经验。

## 技术架构

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   用户端    │──────▶   FastAPI    │──────▶│  智谱AI API │
│  (Web/App)  │◀──────│   后端服务   │◀──────│   GLM-4     │
└─────────────┘      └──────────────┘      └─────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  PostgreSQL  │
                     │  对话历史存储 │
                     └──────────────┘
```

**技术栈选型：**
- **FastAPI**: 异步高性能，自带 OpenAPI 文档
- **智谱AI GLM-4**: 中文理解强，价格实惠
- **PostgreSQL**: 存储对话历史，支持向量扩展
- **Redis**: 缓存热门问题，提升响应速度

## 核心代码实现

### 1. 项目结构

```
ai-customer-service/
├── app/
│   ├── main.py          # FastAPI 入口
│   ├── config.py        # 配置管理
│   ├── models/          # 数据模型
│   ├── services/        # 业务逻辑
│   └── utils/           # 工具函数
├── requirements.txt
└── docker-compose.yml
```

### 2. FastAPI 主入口

```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.services.chat_service import ChatService

app = FastAPI(title="AI Customer Service")

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    message: str
    user_id: str
    session_id: str = None

class ChatResponse(BaseModel):
    reply: str
    confidence: float
    should_transfer: bool = False  # 是否转人工

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        chat_service = ChatService()
        result = await chat_service.process_message(
            request.message,
            request.user_id,
            request.session_id
        )
        return ChatResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "ok"}
```

### 3. 智谱AI 对话服务

```python
from zhipuai import ZhipuAI
from typing import Optional
import os

class ZhipuService:
    def __init__(self):
        self.client = ZhipuAI(api_key=os.getenv("ZHIPU_API_KEY"))
        self.model = "glm-4"
        
    async def chat(
        self, 
        message: str, 
        history: list = None,
        system_prompt: str = None
    ) -> str:
        """
        调用智谱AI进行对话
        """
        messages = []
        
        # 添加系统提示词
        if system_prompt:
            messages.append({
                "role": "system",
                "content": system_prompt
            })
        
        # 添加历史对话
        if history:
            messages.extend(history)
        
        # 添加当前消息
        messages.append({
            "role": "user",
            "content": message
        })
        
        response = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            temperature=0.7,
            max_tokens=500
        )
        
        return response.choices[0].message.content
```

### 4. 对话管理服务

```python
from app.services.zhipu_service import ZhipuService
from app.services.cache_service import CacheService
from app.services.db_service import DatabaseService

class ChatService:
    def __init__(self):
        self.zhipu = ZhipuService()
        self.cache = CacheService()
        self.db = DatabaseService()
        
    async def process_message(
        self, 
        message: str, 
        user_id: str,
        session_id: Optional[str] = None
    ) -> dict:
        """
        处理用户消息
        """
        # 1. 检查缓存（热门问题）
        cached_reply = await self.cache.get(message)
        if cached_reply:
            return {
                "reply": cached_reply,
                "confidence": 1.0,
                "should_transfer": False
            }
        
        # 2. 获取对话历史
        history = await self.db.get_history(session_id)
        
        # 3. 调用智谱AI
        system_prompt = self._build_system_prompt()
        reply = await self.zhipu.chat(
            message, 
            history, 
            system_prompt
        )
        
        # 4. 保存对话历史
        await self.db.save_message(session_id, message, reply)
        
        # 5. 判断是否需要转人工
        should_transfer = self._check_transfer_needed(reply)
        
        return {
            "reply": reply,
            "confidence": 0.85,
            "should_transfer": should_transfer
        }
    
    def _build_system_prompt(self) -> str:
        """
        构建系统提示词
        """
        return """你是一个专业的客服助手。请遵循以下规则：
1. 回答要简洁明了，控制在100字以内
2. 如果不确定答案，礼貌地建议转人工
3. 保持友好和专业的语气
4. 如果用户情绪激动，建议转人工客服"""
    
    def _check_transfer_needed(self, reply: str) -> bool:
        """
        检查是否需要转人工
        """
        keywords = ["转人工", "人工客服", "无法解决"]
        return any(kw in reply for kw in keywords)
```

## 踩坑经验分享

### 坑1：智谱AI 的 rate limit

**问题**: 刚上线时频繁触发 429 错误

**解决**: 
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10)
)
async def call_zhipu_with_retry(self, messages):
    return await self.zhipu.chat(messages)
```

### 坑2：对话历史过长导致成本飙升

**问题**: 一周后发现 token 消耗异常高

**解决**: 实现滑动窗口，只保留最近 5 轮对话
```python
MAX_HISTORY = 5
history = history[-MAX_HISTORY * 2:]  # 一轮=用户+助手两条
```

### 坑3：用户输入过长导致超时

**问题**: 有用户粘贴了 5000+ 字的问题

**解决**: 添加输入长度限制
```python
class ChatRequest(BaseModel):
    message: str
    
    @validator('message')
    def validate_message(cls, v):
        if len(v) > 1000:
            raise ValueError('消息长度不能超过1000字')
        return v
```

## 性能优化技巧

### 1. 热门问题缓存

```python
# 使用 Redis 缓存热门问答
async def get_cached_reply(self, question: str) -> Optional[str]:
    cache_key = f"faq:{hashlib.md5(question.encode()).hexdigest()}"
    return await self.cache.get(cache_key)

# 异步更新缓存
async def update_cache(self, question: str, answer: str):
    cache_key = f"faq:{hashlib.md5(question.encode()).hexdigest()}"
    await self.cache.set(cache_key, answer, expire=3600)
```

**效果**: 缓存命中率 35%，响应时间从 2s 降到 50ms

### 2. 数据库索引优化

```sql
-- 对话历史表添加索引
CREATE INDEX idx_session_created ON chat_history(session_id, created_at DESC);

-- 定期归档旧数据
DELETE FROM chat_history WHERE created_at < NOW() - INTERVAL '30 days';
```

### 3. 异步并发处理

```python
# 使用 asyncio.gather 并发处理
async def batch_process(self, messages: list) -> list:
    tasks = [self.process_message(msg) for msg in messages]
    return await asyncio.gather(*tasks)
```

## 部署方案

使用 Docker Compose 一键部署：

```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - ZHIPU_API_KEY=${ZHIPU_API_KEY}
    depends_on:
      - postgres
      - redis
      
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: chatbot
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
      
  redis:
    image: redis:7-alpine
    
volumes:
  pgdata:
```

## 成本分析

运行一个月后的数据：
- **日均对话量**: 500 次
- **智谱AI 费用**: ¥300/月
- **服务器费用**: ¥200/月（2核4G）
- **总计**: ¥500/月

相比之前 3 个客服（¥15000/月），节省了 **96%** 的成本！

## 总结

这个方案适合中小企业的智能客服场景。核心要点：
1. **选对模型**: 智谱AI 中文能力强，性价比高
2. **做好缓存**: 热门问题缓存能大幅降低成本
3. **控制历史**: 滑动窗口避免 token 爆炸
4. **监控告警**: 关注失败率和成本异常

完整代码已开源：[GitHub 链接]

---

**需要帮助搭建自己的 AI 客服系统？**

CLAW.AI 提供：
- 📞 技术咨询：¥200/小时
- 🤖 AI 客服系统定制：¥3000 起
- 💻 定制开发：¥2000/天

联系方式：[CLAW.AI 官网] | 微信：claw_ai

---

*如果这篇文章对你有帮助，欢迎点赞收藏！有问题可以在评论区讨论~*
