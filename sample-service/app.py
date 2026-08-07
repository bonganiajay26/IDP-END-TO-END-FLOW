from fastapi import FastAPI, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
import time

app = FastAPI(title="IDP Sample API", version="1.0.0")

REQUESTS = Counter(
    "sample_api_http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)
LATENCY = Histogram(
    "sample_api_http_request_duration_seconds",
    "HTTP request latency",
    ["method", "path"],
)


@app.middleware("http")
async def metrics_middleware(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    elapsed = time.perf_counter() - start
    REQUESTS.labels(request.method, request.url.path, response.status_code).inc()
    LATENCY.labels(request.method, request.url.path).observe(elapsed)
    return response


@app.get("/")
def root():
    return {
        "service": "sample-api",
        "message": "Hello from the Internal Developer Platform",
        "version": "1.0.0",
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    return {"ready": True}


@app.get("/metrics", include_in_schema=False)
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
