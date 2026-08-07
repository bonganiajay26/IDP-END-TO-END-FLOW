from fastapi import FastAPI
from prometheus_client import Counter, generate_latest
from starlette.responses import Response
app = FastAPI(title="${{ values.name }}")
requests = Counter("http_requests_total", "Total HTTP requests")
@app.get("/")
def root():
    requests.inc(); return {"service": "${{ values.name }}", "status": "ok"}
@app.get("/health")
def health(): return {"status": "healthy"}
@app.get("/ready")
def ready(): return {"status": "ready"}
@app.get("/metrics")
def metrics(): return Response(generate_latest(), media_type="text/plain")
