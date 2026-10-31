from flask import Flask, jsonify, request, Response
from flask_restful import Api, Resource
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from flasgger import Swagger
import logging
import sys
import time
import psutil
import threading

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
api = Api(app)

comments = {}

# Métricas de Requisições
REQUESTS = Counter('http_requests_total', 'Total number of requests received', ['method', 'endpoint', 'status'])
LATENCY = Histogram('http_request_latency_seconds', 'HTTP request latency in seconds', ['method', 'endpoint'])
COMMENT_COUNTER = Counter('comments_total', 'Total number of comments', ['operation'])
ERROR_COUNTER = Counter('http_errors_total', 'Total number of errors', ['method', 'endpoint', 'error_type'])

# Métricas de Sistema
CPU_USAGE = Gauge('cpu_usage_percent', 'CPU usage in percent')
MEMORY_USAGE = Gauge('memory_usage_bytes', 'Memory usage in bytes')
DISK_USAGE = Gauge('disk_usage_percent', 'Disk usage in percent')
UPTIME = Gauge('application_uptime_seconds', 'Application uptime in seconds')

# Métricas de Tráfego
ACTIVE_REQUESTS = Gauge('active_requests', 'Number of active requests')
RESPONSE_SIZE = Histogram('response_size_bytes', 'Size of HTTP responses in bytes', ['method', 'endpoint'])

# Métricas de Saturação
THREAD_COUNT = Gauge('thread_count', 'Number of threads')
CONNECTION_COUNT = Gauge('connection_count', 'Number of active connections')
QUEUE_SIZE = Gauge('request_queue_size', 'Size of request queue')

def update_system_metrics():
    """Atualiza métricas do sistema periodicamente"""
    while True:
        try:
            # CPU
            CPU_USAGE.set(psutil.cpu_percent())
            
            # Memória
            memory = psutil.virtual_memory()
            MEMORY_USAGE.set(memory.used)
            
            # Disco
            disk = psutil.disk_usage('/')
            DISK_USAGE.set(disk.percent)
            
            # Uptime
            UPTIME.set(time.time() - app.start_time)
            
            # Threads
            THREAD_COUNT.set(threading.active_count())
            
            time.sleep(5)  # Atualiza a cada 5 segundos
        except Exception as e:
            logger.error(f"Erro ao atualizar métricas do sistema: {str(e)}")

app.start_time = time.time()

# Inicia thread para atualização de métricas do sistema
metrics_thread = threading.Thread(target=update_system_metrics, daemon=True)
metrics_thread.start()

# Swagger
swagger = Swagger(app)

@app.route('/health')
def health_check():
    """
    Endpoint que verifica a saúde da aplicação.
    ---
    responses:
      200:
        description: OK
    """
    logger.debug("Health check endpoint called")
    try:
        REQUESTS.labels(method='GET', endpoint='/health', status='200').inc()
        ACTIVE_REQUESTS.inc()
        response = jsonify({'status': 'ok'})
        RESPONSE_SIZE.labels(method='GET', endpoint='/health').observe(len(response.get_data()))
        ACTIVE_REQUESTS.dec()
        return response
    except Exception as e:
        logger.error(f"Erro no health check: {str(e)}")
        REQUESTS.labels(method='GET', endpoint='/health', status='500').inc()
        ERROR_COUNTER.labels(method='GET', endpoint='/health', error_type=type(e).__name__).inc()
        ACTIVE_REQUESTS.dec()
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
        }), 500

class Comment(Resource):
    @LATENCY.labels(method='POST', endpoint='/api/comment/new').time()
    def post(self):
        """
        Endpoint para criar um novo comentário.
        ---
        parameters:
          - name: body
            in: body
            required: true
            schema:
              type: object
              properties:
                email:
                  type: string
                  description: Email do usuário.
                comment:
                  type: string
                  description: Conteúdo do comentário.
                content_id:
                  type: string
                  description: ID do conteúdo associado ao comentário.
        responses:
          200:
            description: Comentário criado com sucesso.
        """
        ACTIVE_REQUESTS.inc()
        try:
            request_data = request.get_json(silent=True)
            if not isinstance(request_data, dict):
                REQUESTS.labels(method='POST', endpoint='/api/comment/new', status='400').inc()
                ERROR_COUNTER.labels(method='POST', endpoint='/api/comment/new', error_type='ValidationError').inc()
                ACTIVE_REQUESTS.dec()
                return {'status': 'ERROR', 'message': 'request body must be a JSON object'}, 400

            missing_fields = [
                field for field in ('email', 'comment', 'content_id')
                if request_data.get(field) in (None, '')
            ]
            if missing_fields:
                message = f"missing required fields: {', '.join(missing_fields)}"
                REQUESTS.labels(method='POST', endpoint='/api/comment/new', status='400').inc()
                ERROR_COUNTER.labels(method='POST', endpoint='/api/comment/new', error_type='ValidationError').inc()
                ACTIVE_REQUESTS.dec()
                return {'status': 'ERROR', 'message': message}, 400

            email = str(request_data['email'])
            comment = str(request_data['comment'])
            content_id = str(request_data['content_id'])

            if len(email) > 320 or len(comment) > 10000 or len(content_id) > 128:
                REQUESTS.labels(method='POST', endpoint='/api/comment/new', status='400').inc()
                ERROR_COUNTER.labels(method='POST', endpoint='/api/comment/new', error_type='ValidationError').inc()
                ACTIVE_REQUESTS.dec()
                return {'status': 'ERROR', 'message': 'input exceeds maximum allowed length'}, 400

            new_comment = {'email': email, 'comment': comment}
            comments.setdefault(content_id, []).append(new_comment)
            
            REQUESTS.labels(method='POST', endpoint='/api/comment/new', status='200').inc()
            COMMENT_COUNTER.labels(operation='create').inc()
            
            response = jsonify({'status': 'SUCCESS', 'message': f'comment created and associated with content_id {content_id}'})
            RESPONSE_SIZE.labels(method='POST', endpoint='/api/comment/new').observe(len(response.get_data()))
            ACTIVE_REQUESTS.dec()
            return response
        except Exception as e:
            logger.error(f"Erro ao criar comentário: {str(e)}")
            REQUESTS.labels(method='POST', endpoint='/api/comment/new', status='500').inc()
            ERROR_COUNTER.labels(method='POST', endpoint='/api/comment/new', error_type=type(e).__name__).inc()
            ACTIVE_REQUESTS.dec()
            return {'status': 'ERROR', 'message': str(e)}, 500

    @LATENCY.labels(method='GET', endpoint='/api/comment/list').time()
    def get(self, content_id):
        """
        Endpoint para listar comentários associados a um ID de conteúdo.
        ---
        parameters:
          - name: content_id
            in: path
            type: string
            required: true
            description: ID do conteúdo.
        responses:
          200:
            description: Lista de comentários associados ao ID do conteúdo.
          404:
            description: Conteúdo não encontrado.
        """
        ACTIVE_REQUESTS.inc()
        content_id = str(content_id)
        try:
            if content_id in comments:
                REQUESTS.labels(method='GET', endpoint='/api/comment/list', status='200').inc()
                response = jsonify(comments.get(content_id, []))
                RESPONSE_SIZE.labels(method='GET', endpoint='/api/comment/list').observe(len(response.get_data()))
                ACTIVE_REQUESTS.dec()
                return response
            else:
                message = f'content_id {content_id} not found'
                REQUESTS.labels(method='GET', endpoint='/api/comment/list', status='404').inc()
                ERROR_COUNTER.labels(method='GET', endpoint='/api/comment/list', error_type='NotFound').inc()
                ACTIVE_REQUESTS.dec()
                return {'status': 'NOT-FOUND', 'message': message}, 404
        except Exception as e:
            logger.error(f"Erro ao listar comentários: {str(e)}")
            REQUESTS.labels(method='GET', endpoint='/api/comment/list', status='500').inc()
            ERROR_COUNTER.labels(method='GET', endpoint='/api/comment/list', error_type=type(e).__name__).inc()
            ACTIVE_REQUESTS.dec()
            return {'status': 'ERROR', 'message': str(e)}, 500

# Adiciona recursos à API
api.add_resource(Comment, '/api/comment/new', '/api/comment/list/<content_id>')

@app.route('/metrics')
def metrics():
    """
    Endpoint que expõe as métricas do Prometheus.
    ---
    responses:
      200:
        description: Métricas do Prometheus
    """
    try:
        # Incrementa contador de requisições
        REQUESTS.labels(method='GET', endpoint='/metrics', status='200').inc()
        
        # Gera métricas
        metrics_data = generate_latest()
        
        # Cria resposta
        response = Response(metrics_data, mimetype=CONTENT_TYPE_LATEST)
        
        # Registra tamanho da resposta
        RESPONSE_SIZE.labels(method='GET', endpoint='/metrics').observe(len(metrics_data))
        
        return response
    except Exception as e:
        logger.error(f"Erro ao gerar métricas: {str(e)}")
        REQUESTS.labels(method='GET', endpoint='/metrics', status='500').inc()
        ERROR_COUNTER.labels(method='GET', endpoint='/metrics', error_type=type(e).__name__).inc()
        return jsonify({'status': 'ERROR', 'message': str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting application...")
    app.run(host='0.0.0.0', port=8000)
