from fastapi import FastAPI
from api.endpoints import setup_endpoints

app = FastAPI()

# Setup endpoints
setup_endpoints(app)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)