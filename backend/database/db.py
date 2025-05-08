import psycopg2
from psycopg2.extras import Json
import json
from config.settings import POSTGRES_DB, POSTGRES_USER, DB_PASSWORD, POSTGRES_HOST, POSTGRES_PORT, logger


class Database:
    def __init__(self):
        self.conn = psycopg2.connect(
            dbname=POSTGRES_DB,
            user=POSTGRES_USER,
            password=DB_PASSWORD,
            host=POSTGRES_HOST,
            port=POSTGRES_PORT,
        )
        self.cursor = self.conn.cursor()

    def insert_embedding(self, chunk_text: str, embedding: list, source: str):
        try:
            self.cursor.execute(
                """
                INSERT INTO pdf_embeddings (chunk_text, embedding, source)
                VALUES (%s, %s, %s)
                """,
                (chunk_text, json.dumps(embedding), source)
            )
            self.conn.commit()
        except Exception as e:
            logger.error(f"Error inserting embedding: {e}")
            self.conn.rollback()
            raise

    def fetch_embeddings(self):
        try:
            self.cursor.execute("SELECT id, chunk_text, embedding, source FROM pdf_embeddings")
            return self.cursor.fetchall()
        except Exception as e:
            logger.error(f"Error fetching embeddings: {e}")
            raise

    def close(self):
        self.cursor.close()
        self.conn.close()