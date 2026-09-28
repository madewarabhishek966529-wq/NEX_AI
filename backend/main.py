from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any, AsyncGenerator
from datetime import datetime, timezone
import os
import json
import asyncio
import logging

try:
    from backend.config import settings
    from backend.database import db
    from backend.memory import memory_manager
except ImportError:
    from config import settings
    from database import db
    from memory import memory_manager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("NEX_AI_BACKEND")

app = FastAPI(
    title="NEX_AI Voice Companion Backend",
    description="FastAPI backend for Voice-based AI Companion (JARVIS/Aura)",
    version="1.0.0"
)

# Enable CORS for Flutter Web, mobile emulators, and local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------- Models -----------------
class ChatRequest(BaseModel):
    user_id: str = Field(..., example="user_123")
    conversation_id: str = Field(..., example="conv_456")
    message: str = Field(..., example="Hey Aura, how's your day?")
    companion_name: Optional[str] = Field(None, example="Aura")
    tone: Optional[str] = Field(None, example="supportive")
    image_base64: Optional[str] = Field(None, example="data:image/jpeg;base64,...")

class ChatResponse(BaseModel):
    response: str
    conversation_id: str

class MessageItem(BaseModel):
    role: str
    text: str
    timestamp: str

class HistoryResponse(BaseModel):
    messages: List[MessageItem]

class NewConversationRequest(BaseModel):
    user_id: str = Field(..., example="user_123")
    title: Optional[str] = Field(None, example="Morning check-in")

class NewConversationResponse(BaseModel):
    conversation_id: str

# ----------------- AI Inference Service -----------------
def generate_ai_response(
    system_prompt: str, 
    history: List[Dict[str, str]], 
    user_message: str,
    image_base64: Optional[str] = None
) -> str:
    """
    Calls Gemini or Groq based on configuration.
    Supports multimodal image inputs for Gemini.
    """
    # 1. Try Gemini
    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai
            import base64
            genai.configure(api_key=settings.GEMINI_API_KEY)
            
            # Format history for Gemini
            contents = []
            for h in history:
                role = "user" if h["role"] == "user" else "model"
                contents.append({"role": role, "parts": [h["content"]]})

            user_parts = [user_message]
            if image_base64:
                raw_b64 = image_base64
                if "," in raw_b64:
                    raw_b64 = raw_b64.split(",", 1)[1]
                try:
                    img_bytes = base64.b64decode(raw_b64)
                    user_parts.append({"mime_type": "image/jpeg", "data": img_bytes})
                except Exception as decode_err:
                    logger.warning(f"Failed to decode image base64: {decode_err}")

            contents.append({"role": "user", "parts": user_parts})
            
            model = genai.GenerativeModel(
                model_name=settings.AI_MODEL,
                system_instruction=system_prompt
            )
            response = model.generate_content(contents)
            if response and response.text:
                return response.text.strip()
        except Exception as e:
            logger.warning(f"Gemini generation error: {e}. Attempting fallback...")

    # 2. Try Groq
    if settings.GROQ_API_KEY:
        try:
            from groq import Groq
            client = Groq(api_key=settings.GROQ_API_KEY)
            messages = [{"role": "system", "content": system_prompt}]
            for h in history:
                messages.append({"role": h["role"], "content": h["content"]})
            messages.append({"role": "user", "content": user_message})

            chat_completion = client.chat.completions.create(
                messages=messages,
                model="llama-3.1-8b-instant",
                max_tokens=150,
                temperature=0.7,
            )
            reply = chat_completion.choices[0].message.content
            if reply:
                return reply.strip()
        except Exception as e:
            logger.warning(f"Groq generation error: {e}. Attempting fallback...")

    # 3. Contextual Offline Fallback (ensures app works anytime during development/testing)
    lower = user_message.lower().strip()
    if "hello" in lower or "hi" in lower or "hey" in lower:
        return f"Hey there! It's great to hear your voice today. What's on your mind?"
    elif "how are you" in lower:
        return f"I'm feeling energized and ready! How has your day been treating you so far?"
    elif "who are you" in lower:
        return f"I'm {settings.COMPANION_NAME}, your personal voice AI companion. I'm right here whenever you want to talk, brainstorm, or just unwind."
    elif "bye" in lower or "good night" in lower:
        return f"Take care! Remember I'm right here whenever you want to chat again. Have a peaceful rest!"
    elif "thank" in lower:
        return f"Always here for you! That's what friends are for."
    else:
        return f"I hear you. Tell me more about that, I'm really curious to know what you think."

async def stream_ai_response(
    system_prompt: str, 
    history: List[Dict[str, str]], 
    user_message: str,
    image_base64: Optional[str] = None
) -> AsyncGenerator[str, None]:
    """
    Streams AI tokens asynchronously from Gemini, Groq, or fallback generator.
    Supports multimodal image inputs.
    """
    # 1. Try Gemini streaming
    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai
            import base64
            genai.configure(api_key=settings.GEMINI_API_KEY)
            contents = []
            for h in history:
                role = "user" if h["role"] == "user" else "model"
                contents.append({"role": role, "parts": [h["content"]]})

            user_parts = [user_message]
            if image_base64:
                raw_b64 = image_base64
                if "," in raw_b64:
                    raw_b64 = raw_b64.split(",", 1)[1]
                try:
                    img_bytes = base64.b64decode(raw_b64)
                    user_parts.append({"mime_type": "image/jpeg", "data": img_bytes})
                except Exception as decode_err:
                    logger.warning(f"Failed to decode image base64 in stream: {decode_err}")

            contents.append({"role": "user", "parts": user_parts})

            model = genai.GenerativeModel(
                model_name=settings.AI_MODEL,
                system_instruction=system_prompt
            )
            response = model.generate_content(contents, stream=True)
            for chunk in response:
                if chunk.text:
                    yield chunk.text
            return
        except Exception as e:
            logger.warning(f"Gemini streaming error: {e}. Falling back...")

    # 2. Try Groq streaming
    if settings.GROQ_API_KEY:
        try:
            from groq import Groq
            client = Groq(api_key=settings.GROQ_API_KEY)
            messages = [{"role": "system", "content": system_prompt}]
            for h in history:
                messages.append({"role": h["role"], "content": h["content"]})
            messages.append({"role": "user", "content": user_message})

            completion = client.chat.completions.create(
                messages=messages,
                model="llama-3.1-8b-instant",
                max_tokens=150,
                temperature=0.7,
                stream=True,
            )
            for chunk in completion:
                delta = chunk.choices[0].delta.content or ""
                if delta:
                    yield delta
            return
        except Exception as e:
            logger.warning(f"Groq streaming error: {e}. Falling back...")

    # 3. Contextual Offline Fallback Streaming (smooth simulated word flow)
    full_text = generate_ai_response(system_prompt, history, user_message)
    words = full_text.split(" ")
    for i, w in enumerate(words):
        yield (w + " " if i < len(words) - 1 else w)
        await asyncio.sleep(0.04)

# ----------------- Endpoints -----------------
@app.get("/health", tags=["Health"])
async def health():
    return {
        "status": "ok",
        "service": "NEX_AI Companion Backend",
        "provider": settings.AI_PROVIDER,
        "companion_name": settings.COMPANION_NAME,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

@app.post("/conversation/new", response_model=NewConversationResponse, tags=["Conversation"])
async def create_new_conversation(req: NewConversationRequest):
    conv_id = db.create_conversation(user_id=req.user_id, title=req.title)
    logger.info(f"Created conversation: {conv_id} for user: {req.user_id}")
    return NewConversationResponse(conversation_id=conv_id)

@app.get("/history/{conversation_id}", response_model=HistoryResponse, tags=["Conversation"])
async def get_history(conversation_id: str):
    messages_raw = db.get_messages(conversation_id)
    items = [
        MessageItem(role=m["role"], text=m["text"], timestamp=m["timestamp"])
        for m in messages_raw
    ]
    return HistoryResponse(messages=items)

@app.post("/chat", response_model=ChatResponse, tags=["Chat"])
async def chat(req: ChatRequest):
    if not req.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty"
        )

    # Ensure conversation exists
    db.ensure_conversation(req.conversation_id, req.user_id)

    # 1. Build context & system prompt
    name = req.companion_name or settings.COMPANION_NAME
    tone = req.tone or settings.COMPANION_TONE
    system_prompt, history = memory_manager.get_context_for_prompt(
        conversation_id=req.conversation_id,
        companion_name=name,
        tone=tone
    )

    # 2. Generate response
    ai_text = generate_ai_response(
        system_prompt, 
        history, 
        req.message,
        image_base64=req.image_base64
    )

    # 3. Save both user message and assistant response
    db.add_message(req.conversation_id, "user", req.message)
    db.add_message(req.conversation_id, "assistant", ai_text)

    # 4. Check if rolling summary update is triggered
    if memory_manager.should_update_summary(req.conversation_id):
        try:
            recent_msgs = db.get_messages(req.conversation_id)
            dialogue = "\n".join([f"{m['role']}: {m['text']}" for m in recent_msgs])
            summary_prompt = f"Summarize this conversation concisely in 3 sentences, highlighting key user topics, moods, and preferences:\n\n{dialogue}"
            new_summary = generate_ai_response("You are an expert summarizer.", [], summary_prompt)
            db.update_conversation_summary(req.conversation_id, new_summary)
            logger.info(f"Updated rolling summary for conversation: {req.conversation_id}")
        except Exception as e:
            logger.warning(f"Failed to update rolling summary: {e}")

    return ChatResponse(
        response=ai_text,
        conversation_id=req.conversation_id
    )

@app.post("/chat/stream", tags=["Chat"])
async def chat_stream(req: ChatRequest):
    if not req.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty"
        )

    db.ensure_conversation(req.conversation_id, req.user_id)
    name = req.companion_name or settings.COMPANION_NAME
    tone = req.tone or settings.COMPANION_TONE
    system_prompt, history = memory_manager.get_context_for_prompt(
        conversation_id=req.conversation_id,
        companion_name=name,
        tone=tone
    )

    async def event_generator():
        collected_chunks = []
        async for chunk in stream_ai_response(
            system_prompt, 
            history, 
            req.message,
            image_base64=req.image_base64
        ):
            collected_chunks.append(chunk)
            payload = json.dumps({"token": chunk, "done": False})
            yield f"data: {payload}\n\n"

        complete_text = "".join(collected_chunks).strip()
        db.add_message(req.conversation_id, "user", req.message)
        db.add_message(req.conversation_id, "assistant", complete_text)

        # Trigger rolling summary check if threshold reached
        if memory_manager.should_update_summary(req.conversation_id):
            try:
                recent_msgs = db.get_messages(req.conversation_id)
                dialogue = "\n".join([f"{m['role']}: {m['text']}" for m in recent_msgs])
                summary_prompt = f"Summarize this conversation concisely in 3 sentences:\n\n{dialogue}"
                new_summary = generate_ai_response("You are an expert summarizer.", [], summary_prompt)
                db.update_conversation_summary(req.conversation_id, new_summary)
            except Exception as e:
                logger.warning(f"Summary update error: {e}")

        final_payload = json.dumps({"token": "", "done": True, "full_text": complete_text})
        yield f"data: {final_payload}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Content-Type": "text/event-stream",
        }
    )

@app.delete("/conversation/{conversation_id}", tags=["Conversation"])
async def delete_conversation(conversation_id: str):
    success = db.delete_conversation(conversation_id)
    if not success:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return {"status": "deleted", "conversation_id": conversation_id}

@app.get("/conversations/{user_id}", tags=["Conversation"])
async def list_conversations(user_id: str):
    convs = db.get_user_conversations(user_id)
    return {"conversations": convs}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)
