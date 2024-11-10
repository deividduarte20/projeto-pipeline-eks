# Estágio 1: Construção da aplicação
FROM python:3.8-alpine AS builder

WORKDIR /app

# Copie os arquivos necessários para o diretório de trabalho
COPY app /app
COPY requirements.txt /app

# Instale as dependências como o usuário app
RUN adduser -D app \
    && chown -R app:app /app \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir  -r requirements.txt

# Estágio 2: Imagem final
FROM python:3.7.4-alpine

WORKDIR /app

# Copie os arquivos necessários do estágio de construção
COPY --from=builder /app /app

# Copie o usuário app criado no estágio de construção
COPY --from=builder /etc/passwd /etc/passwd

# Atualize o pip antes de mudar para o usuário não privilegiado
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir gunicorn flask-restful==0.3.9 flasgger==0.9.5 opentelemetry-api==1.22.0 flask_opentracing==1.1.0 opentelemetry-api==1.22.0 opentelemetry-sdk==1.22.0 opentelemetry-exporter-jaeger==1.21.0 opentelemetry-instrumentation==0.43b0 opentelemetry-instrumentation-flask==0.43b0 prometheus-client==0.11.0

# Defina o usuário app como o usuário padrão
USER app

# Adicione o diretório onde o Gunicorn foi instalado ao $PATH
ENV PATH="/home/app/.local/bin:${PATH}"

# Exponha a porta em que a aplicação será executada
EXPOSE 8000

# Comando para iniciar a aplicação usando gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8000", "--log-level", "debug", "api:app"]
