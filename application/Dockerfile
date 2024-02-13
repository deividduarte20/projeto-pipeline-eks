# Estágio 1: Construção da aplicação
FROM python:3.7.4-alpine AS builder

WORKDIR /app

# Copie os arquivos necessários para o diretório de trabalho
COPY app /app
COPY requirements.txt /app

# Instale as dependências
RUN pip install --upgrade pip && pip install -r requirements.txt

# Estágio 2: Imagem final
FROM python:3.7.4-alpine

WORKDIR /app

# Copie os arquivos necessários do estágio de construção
COPY --from=builder /app /app

# Instale o gunicorn e o Flask
RUN pip install gunicorn==20.0.4 Flask==2.0.1 flask_restful==0.3.9 prometheus-client==0.11.0 flasgger==0.9.5

# Exponha a porta em que a aplicação será executada
EXPOSE 8000

# Comando para iniciar a aplicação usando gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8000", "--log-level", "debug", "api:app"]
