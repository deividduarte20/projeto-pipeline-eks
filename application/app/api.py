from flask import Flask, jsonify, request
from flask_restful import Api, Resource
from flasgger import Swagger
from prometheus_client import Counter, generate_latest, REGISTRY, CollectorRegistry, CONTENT_TYPE_LATEST

REQUESTS = Counter('http_requests_total', 'Total number of requests received')

app_name = 'comentarios'
app = Flask(app_name)
api = Api(app)
swagger = Swagger(app)

app.debug = True

comments = {}
comments_counter = Counter('comments_created_total', 'Total number of comments created')

@app.route('/metrics')
def metrics():
    registry = CollectorRegistry()
    data = generate_latest(registry)
    REQUESTS.inc()
    return data, 200, {'Content-Type': CONTENT_TYPE_LATEST}

class HealthCheck(Resource):
    def get(self):
        """
        Endpoint que verifica a saúde da aplicação.
        ---
        responses:
          200:
            description: OK
        """
        REQUESTS.inc()
        return {'status': 'healthy'}

class Comment(Resource):
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
        REQUESTS.inc()
        request_data = request.get_json()

        email = request_data['email']
        comment = request_data['comment']
        content_id = '{}'.format(request_data['content_id'])

        new_comment = {
            'email': email,
            'comment': comment,
        }

        comments_counter.inc()

        if content_id in comments:
            comments[content_id].append(new_comment)
        else:
            comments[content_id] = [new_comment]

        message = 'comment created and associated with content_id {}'.format(content_id)
        response = {
            'status': 'SUCCESS',
            'message': message,
        }
        return jsonify(response)

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
        content_id = '{}'.format(content_id)
        REQUESTS.inc()
        if content_id in comments:
            return jsonify(comments[content_id])
        else:
            message = 'content_id {} not found'.format(content_id)
            response = {
                'status': 'NOT-FOUND',
                'message': message,
            }
            return jsonify(response), 404

api.add_resource(HealthCheck, '/')
api.add_resource(Comment, '/api/comment/new', '/api/comment/list/<content_id>')

if __name__ == '__main__':
    app.run()
