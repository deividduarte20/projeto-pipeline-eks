# Estágio 1: Construção da aplicação
FROM python:3.7.4-alpine AS builder

WORKDIR /app

# Copie os arquivos necessários para o diretório de trabalho
COPY app /app
COPY requirements.txt /app

# Instale as dependências da aplicação
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Estágio 2: Imagem final
FROM python:3.7.4-alpine

# Adicione um usuário chamado "deivid" e conceda permissões para a pasta de trabalho
RUN adduser -D deivid

# Crie a pasta de trabalho e conceda permissões
RUN mkdir -p /app && \
    chown -R deivid:deivid /app && \
    chmod -R 755 /app

WORKDIR /app

USER deivid

# Copie os arquivos necessários do estágio de construção
COPY --from=builder --chown=deivid:deivid /app /app

# Instale as dependências necessárias apenas para a execução (não de construção)
RUN pip install --no-cache-dir --user --upgrade pip && \
    pip install --no-cache-dir --user -r requirements.txt && \
    pip install --no-cache-dir --user gunicorn flask-restful==0.3.9 flasgger==0.9.5 opentelemetry-api==1.22.0 flask_opentracing==1.1.0 opentelemetry-api==1.22.0 opentelemetry-sdk==1.22.0 opentelemetry-exporter-jaeger==1.21.0 opentelemetry-instrumentation==0.43b0 opentelemetry-instrumentation-flask==0.43b0 prometheus-client==0.11.0

# Exponha a porta em que a aplicação será executada
EXPOSE 80

# Comando para iniciar a aplicação usando gunicorn
CMD ["/home/deivid/.local/bin/gunicorn", "-b", "0.0.0.0:80", "--log-level", "debug", "api:app"]
