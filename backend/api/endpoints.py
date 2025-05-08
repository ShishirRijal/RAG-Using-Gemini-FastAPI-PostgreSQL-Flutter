from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from typing import List, Dict, Any
from scipy.spatial.distance import cosine
import numpy as np
import json
import os
from services.pdf_service import PDFService
from services.embedding_service import EmbeddingService
from database.db import Database
from config.settings import PDF_STORAGE_DIR, BASE_URL, logger

def setup_endpoints(app: FastAPI):
    db = Database()
    embedding_service = EmbeddingService()

    @app.post("/upload/")
    async def upload_pdf(file: UploadFile = File(...)):
        try:
            chunks = await PDFService.process_pdf(file, file.filename)
            for chunk in chunks:
                embedding = await embedding_service.generate_embedding(chunk)
                if embedding:
                    db.insert_embedding(chunk, embedding, file.filename)
            return {"message": "PDF uploaded and processed successfully."}
        except Exception as e:
            logger.error(f"Error in upload_pdf: {e}")
            raise HTTPException(status_code=500, detail="Failed to process PDF")

    @app.get("/query/")
    async def query_pdf(query: str):
        try:
            query_embedding = await embedding_service.generate_embedding(query)
            if not query_embedding:
                raise HTTPException(status_code=500, detail="Query embedding failed")

            rows = db.fetch_embeddings()
            similarities: List[Dict[str, Any]] = []
            for row in rows:
                chunk_id, chunk_text, stored_embedding, source_file = row
                try:
                    stored_embedding = np.array(json.loads(stored_embedding)).flatten()
                    query_embedding = np.array(query_embedding).flatten()

                    if stored_embedding.shape != query_embedding.shape:
                        logger.warning(f"Embedding dimension mismatch for chunk {chunk_id}")
                        continue

                    similarity = 1 - cosine(query_embedding, stored_embedding)
                    similarities.append({
                        "chunk_text": chunk_text,
                        "similarity": similarity,
                        "source_file": source_file
                    })
                except Exception as e:
                    logger.error(f"Error processing embedding for chunk {chunk_id}: {e}")
                    continue

            similarities = sorted(similarities, key=lambda x: x["similarity"], reverse=True)[:3]
            relevant_chunks = [item["chunk_text"] for item in similarities]
            citation_links = [
                {
                    "url": f"{BASE_URL}/pdf/{item['source_file']}",
                    "title": item['source_file']
                }
                for item in similarities
            ]

            context = "\n\n".join(relevant_chunks)
            prompt = f"Context:\n{context}\n\nUser Query: {query}\n\nAnswer:"
            answer = await embedding_service.ask_gemini(prompt)
            return {"answer": answer, "citations": citation_links}
        except Exception as e:
            logger.error(f"Error processing query: {e}")
            raise HTTPException(status_code=500, detail="Internal server error")

    @app.get("/pdf/{filename}")
    async def serve_pdf(filename: str):
        file_path = os.path.join(PDF_STORAGE_DIR, filename)
        if os.path.exists(file_path):
            return FileResponse(file_path, media_type="application/pdf")
        return {"error": "File not found"}

    @app.on_event("shutdown")
    async def shutdown_event():
        db.close()