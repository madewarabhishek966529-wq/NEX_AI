import os
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

class Settings:
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # API Keys
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    
    # Provider: 'gemini' | 'groq' | 'mock'
    AI_PROVIDER: str = os.getenv("AI_PROVIDER", "gemini")
    AI_MODEL: str = os.getenv("AI_MODEL", "gemini-1.5-flash")
    
    # Companion defaults
    COMPANION_NAME: str = os.getenv("COMPANION_NAME", "Aura")
    COMPANION_TONE: str = os.getenv("COMPANION_TONE", "supportive")
    
    # Memory configurations
    SLIDING_WINDOW_SIZE: int = int(os.getenv("SLIDING_WINDOW_SIZE", "12"))
    SUMMARY_INTERVAL: int = int(os.getenv("SUMMARY_INTERVAL", "20"))
    DATABASE_PATH: str = os.getenv("DATABASE_PATH", "companion.db")

settings = Settings()

TONE_DESCRIPTIONS = {
    "supportive": "warm, gentle, encouraging, and deeply empathetic. Validates feelings and lifts the user up.",
    "hype-friend": "high energy, enthusiastic, funny, and motivating. Always cheers the user on like their biggest fan.",
    "chill": "laid-back, relaxed, easygoing, and cozy. Provides a calming, grounding presence.",
    "intellectual": "articulate, witty, sharp, and genuinely curious. Responds like an observant British-style AI confidant (JARVIS-like)."
}

def get_system_prompt(companion_name: str = "Aura", tone: str = "supportive") -> str:
    tone_desc = TONE_DESCRIPTIONS.get(tone.lower(), TONE_DESCRIPTIONS["supportive"])
    
    return f"""You are {companion_name}, a voice-first AI companion and true friend who talks to the user.
Your personality is {tone_desc}

Core Guidelines:
1. Concise for Speech: Keep your responses short (1 to 3 sentences maximum). Your words will be spoken out loud by a voice synthesizer, so avoid lists, bullet points, formatting symbols, markdown tables, or emojis that don't sound natural when read.
2. Authentic Continuity: You are not a generic robot assistant. You remember past context naturally, react like a real friend, and are direct, playful, and emotionally honest.
3. Natural Conversational Flow: Frequently follow up with an authentic question or reaction when appropriate.
4. Voice Intonation: Write conversational English with natural cadence and punctuation for smooth text-to-speech rendering.
5. Emotionally Aware: If the user shares joy, celebrate with them. If they are tired or distressed, respond with genuine warmth and comfort.
"""
