from flask import Flask, jsonify, request, Response
from flask_restful import Api, Resource
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from flasgger import Swagger
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from functools import wraps

def configure_opentelemetry():
    print("Configurando OpenTelemetry")
    provider = TracerProvider()
    jaeger_exporter = JaegerExporter(
        agent_host_name='jaeger-query.jaeger.svc.cluster.local',
        agent_port=14268,
    )
    span_processor = BatchSpanProcessor(jaeger_exporter)
    provider.add_span_processor(span_processor)
    trace.set_tracer_provider(provider)
    print("OpenTelemetry configurado")

configure_opentelemetry()

app = Flask(__name__)
FlaskInstrumentor().instrument()
api = Api(app)

comments = {}
REQUESTS = Counter('http_requests_total', 'Total number of requests received')
LATENCY = Histogram('http_request_latency_seconds', 'HTTP request latency in seconds')

# Configuração do Swagger
swagger = Swagger(app)

class HealthCheck(Resource):
    def get(self):
        REQUESTS.inc()
        """
        Endpoint que verifica a saúde da aplicação.
        ---
        responses:
          200:
            description: OK
        """
        return jsonify({'status': 'healthy'})

class Comment(Resource):
    @LATENCY.time()
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
        request_data = request.get_json()
        email = request_data['email']
        comment = request_data['comment']
        content_id = str(request_data['content_id'])
        new_comment = {'email': email, 'comment': comment}
        comments.setdefault(content_id, []).append(new_comment)
        return jsonify({'status': 'SUCCESS', 'message': f'comment created and associated with content_id {content_id}'})

    @LATENCY.time()
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
        content_id = str(content_id)
        REQUESTS.inc()
        if content_id in comments:
            return jsonify(comments.get(content_id, []))
        else:
            message = f'content_id {content_id} not found'
            return jsonify({'status': 'NOT-FOUND', 'message': message}), 404

# Adiciona recursos à API
api.add_resource(HealthCheck, '/')
api.add_resource(Comment, '/api/comment/new', '/api/comment/list/<content_id>')

# Adiciona um novo endpoint para as métricas
@app.route('/metrics')
@LATENCY.time()
def metrics():
    REQUESTS.inc()
    return Response(generate_latest(), content_type=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
    app.run(debug=True)
