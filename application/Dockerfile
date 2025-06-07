FROM python:3.8-alpine

WORKDIR /app

# Instale dependências do sistema
RUN apk add --no-cache gcc musl-dev linux-headers

# Copie os arquivos da aplicação
COPY app/main.py /app/
COPY requirements.txt /app/

# Instale dependências do Python
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Crie usuário não-root
RUN adduser -D app && chown -R app:app /app

# Use o usuário criado
USER app

# Exponha a porta
EXPOSE 8000

# Inicie com Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--threads", "1", "--timeout", "30", "--log-level", "debug", "--access-logfile", "-", "--error-logfile", "-", "main:app"]
