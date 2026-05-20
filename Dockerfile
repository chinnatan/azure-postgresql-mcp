# Azure PostgreSQL MCP — dependencies อยู่ใน image ไม่ต้องติดตั้งบน host
FROM python:3.12-slim-bookworm

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

# MCP ใช้ stdio — ต้องรันด้วย docker run -i
CMD ["python", "-u", "src/azure_postgresql_mcp.py"]
