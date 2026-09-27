# FastAPI Endpoint Spec

## POST /chat

Request:
```json
{
  "user_id": "abc123",
  "conversation_id": "conv_456",
  "message": "hey, how's it going"
}
```

Response:
```json
{
  "response": "Hey! Doing good — what's on your mind today?",
  "conversation_id": "conv_456"
}
```

Server logic:
1. Fetch last N (e.g. 10) messages for `conversation_id` from Firestore/Supabase
2. Build message list: `[system_prompt, ...history, {role: user, content: message}]`
3. Call Gemini/Groq with that list
4. Save both the user message and the AI response to the database
5. Return response text

## GET /history/{conversation_id}

Returns full message list for a conversation — used to repopulate the chat screen on app reopen.

```json
{
  "messages": [
    {"role": "user", "text": "...", "timestamp": "..."},
    {"role": "assistant", "text": "...", "timestamp": "..."}
  ]
}
```

## POST /conversation/new

Creates a new conversation ID for a user (fresh session while keeping history of past ones accessible).

```json
{ "user_id": "abc123" }
```
Response: `{ "conversation_id": "conv_789" }`

## Minimal FastAPI skeleton

```python
from fastapi import FastAPI
from pydantic import BaseModel
import google.generativeai as genai
import os

app = FastAPI()
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-1.5-flash")

SYSTEM_PROMPT = "You are a warm, supportive friend..."  # see PROMPTS.md

class ChatRequest(BaseModel):
    user_id: str
    conversation_id: str
    message: str

@app.post("/chat")
async def chat(req: ChatRequest):
    history = fetch_history(req.conversation_id)  # implement via Firestore/Supabase
    full_prompt = build_prompt(SYSTEM_PROMPT, history, req.message)
    response = model.generate_content(full_prompt)
    save_message(req.conversation_id, "user", req.message)
    save_message(req.conversation_id, "assistant", response.text)
    return {"response": response.text, "conversation_id": req.conversation_id}
```

Note: always verify current Gemini/Groq SDK method names against their docs before shipping — SDKs change.
