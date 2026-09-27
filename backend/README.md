# NEX_AI Companion Backend

A voice-first AI companion backend built with **FastAPI**, **SQLite**, and **Gemini/Groq** supporting sliding-window and rolling-summary conversation memory.

## Features
- **FastAPI Endpoints**: `/health`, `/chat`, `/history/{conversation_id}`, `/conversation/new`, `/conversations/{user_id}`
- **Memory Architecture**: Sliding-window context + automatic rolling summary generation
- **Personality Engine**: Configurable companion name & tone (supportive, hype-friend, chill, intellectual)
- **Zero-Setup Database**: Embedded SQLite database (`companion.db`) with zero external infrastructure required
- **Graceful Fallback**: Intelligent offline conversational responses when external API keys are not configured

## Quick Start

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure Environment (Optional)
Copy `.env.example` to `.env` and insert your Gemini or Groq API key:
```bash
cp .env.example .env
```

### 3. Run Server
```bash
python main.py
```
or:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Testing with cURL

### Health Check
```bash
curl -X GET http://localhost:8000/health
```

### Start New Conversation
```bash
curl -X POST http://localhost:8000/conversation/new \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user_demo"}'
```

### Send Chat Message
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_demo",
    "conversation_id": "conv_demo123",
    "message": "Hey Aura! How are you feeling today?"
  }'
```

### Get Conversation History
```bash
curl -X GET http://localhost:8000/history/conv_demo123
```
