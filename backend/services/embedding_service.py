import google.generativeai as genai
from sentence_transformers import SentenceTransformer
from config.settings import GOOGLE_API_KEY, logger

class EmbeddingService:
    def __init__(self):
        genai.configure(api_key=GOOGLE_API_KEY)
        self.gemini_model = genai.GenerativeModel("gemini-1.5-flash")
        self.embed_model = SentenceTransformer("all-MiniLM-L6-v2")

    async def generate_embedding(self, text: str):
        try:
            embedding = self.embed_model.encode(text).tolist()
            logger.info(f"Generated embedding with {len(embedding)} dimensions")
            return embedding
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return None

    async def ask_gemini(self, prompt: str) -> str:
        try:
            response = self.gemini_model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Error in Gemini API call: {e}")
            return f"Error: {e}"