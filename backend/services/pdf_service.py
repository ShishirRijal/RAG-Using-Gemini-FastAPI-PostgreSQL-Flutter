import os
from pdf_processing import extract_text_from_pdf, chunk_text
from config.settings import PDF_STORAGE_DIR, logger


class PDFService:
    @staticmethod
    async def process_pdf(file, filename: str):
        try:
            os.makedirs(PDF_STORAGE_DIR, exist_ok=True)
            file_path = os.path.join(PDF_STORAGE_DIR, filename)
            with open(file_path, "wb") as f:
                f.write(await file.read())

            text = extract_text_from_pdf(file_path)
            chunks = chunk_text(text)
            return chunks
        except Exception as e:
            logger.error(f"Error processing PDF {filename}: {e}")
            raise