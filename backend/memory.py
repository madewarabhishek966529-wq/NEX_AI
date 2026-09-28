from typing import List, Dict, Any, Tuple, Optional
try:
    from backend.config import settings, get_system_prompt
    from backend.database import db
except ImportError:
    from config import settings, get_system_prompt
    from database import db

class MemoryManager:
    def __init__(self, window_size: int = settings.SLIDING_WINDOW_SIZE):
        self.window_size = window_size

    def get_context_for_prompt(
        self, 
        conversation_id: str, 
        companion_name: str = settings.COMPANION_NAME,
        tone: str = settings.COMPANION_TONE,
        user_id: Optional[str] = None
    ) -> Tuple[str, List[Dict[str, str]]]:
        """
        Builds the system prompt and conversation history list.
        Prepends user profile memories and rolling summary if available.
        """
        base_prompt = get_system_prompt(companion_name, tone)

        # Inject persistent user memories
        if user_id:
            user_facts = db.get_user_memories(user_id)
            if user_facts:
                facts_str = "\n".join([f"- {f['key']}: {f['value']}" for f in user_facts])
                base_prompt += f"\n\nPermanent Known Facts About This User (Always remember):\n{facts_str}\n"
        
        # Check if a rolling summary exists
        summary = db.get_conversation_summary(conversation_id)
        if summary:
            base_prompt += f"\n\nContext & Long-Term Memory from earlier conversation:\n{summary}\n"
        
        # Fetch the sliding window of recent messages
        raw_history = db.get_messages(conversation_id, limit=self.window_size)
        formatted_history: List[Dict[str, str]] = []
        
        for msg in raw_history:
            role = "user" if msg["role"] == "user" else "assistant"
            formatted_history.append({
                "role": role,
                "content": msg["text"]
            })
            
        return base_prompt, formatted_history

    def should_update_summary(self, conversation_id: str) -> bool:
        """
        Determines if the conversation has enough new messages to update rolling summary.
        """
        all_messages = db.get_messages(conversation_id)
        total_count = len(all_messages)
        return total_count > 0 and (total_count % settings.SUMMARY_INTERVAL == 0)

memory_manager = MemoryManager()
