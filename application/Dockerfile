# Estágio 1: Construção da aplicação
FROM python:3.7.4-alpine AS builder

WORKDIR /app

# Copie os arquivos necessários para o diretório de trabalho
COPY app /app
COPY requirements.txt /app

# Instale as dependências do Jaeger
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Estágio 2: Imagem final
FROM python:3.7.4-alpine

WORKDIR /app

# Copie os arquivos necessários do estágio de construção
COPY --from=builder /app /app

# Instale as dependências necessárias apenas para a execução (não de construção)
RUN pip install --upgrade pip && pip install -r requirements.txt && pip install flask-restful==0.3.9 flasgger==0.9.5 opentelemetry-api==1.22.0 flask_opentracing==1.1.0 opentelemetry-api==1.22.0 opentelemetry-sdk==1.22.0 opentelemetry-exporter-jaeger==1.21.0 opentelemetry-instrumentation==0.43b0 opentelemetry-instrumentation-flask==0.43b0 prometheus-client==0.11.0

# Exponha a porta em que a aplicação será executada
EXPOSE 8000

# Comando para iniciar a aplicação usando gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8000", "--log-level", "debug", "api:app"]
