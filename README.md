# Considerações Gerais

Você deverá usar este repositório como o repo principal do projeto, i.e., todos os seus commits devem estar registrados aqui, pois queremos ver como você trabalha.

A escolha de tecnologias é livre para a resolução do problema. Utilize os componentes e serviços que melhor domina pois a apresentação na entrega do desafio deverá ser como uma aula em que você explica em detalhes cada decisão que tomou.

Registre tudo: testes que foram executados, ideias que gostaria de implementar se tivesse tempo (explique como você as resolveria, se houvesse tempo), decisões que foram tomadas e seus porquês, arquiteturas que foram testadas e os motivos de terem sido modificadas ou abandonadas. Crie um arquivo COMMENTS.md ou HISTORY.md no repositório para registrar essas reflexões e decisões.


## O Problema

O desafio que você deve resolver é a implantação da aplicação de Comentários em versão API (backend) usando ferramentas open source da sua preferência.

Você precisa criar o ambiente de execução desta API com o maior número de passos automatizados possível, inclusive a esteira de deploy.

A aplicação será uma API REST que está disponível neste repositório. Através dela os internautas enviam comentários em texto de uma máteria e acompanham o que outras pessoas estão falando sobre o assunto em destaque. O funcionamento básico da API consiste em uma rota para inserção dos comentários e uma rota para listagem.

Os comandos de interação com a API são os seguintes:

* Start da app

```bash
cd app
gunicorn --log-level debug api:app
```

* Criando e listando comentários por matéria

```
# matéria 1
curl -sv localhost:8000/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"alice@example.com","comment":"first post!","content_id":1}'
curl -sv localhost:8000/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"alice@example.com","comment":"ok, now I am gonna say something more useful","content_id":1}'
curl -sv localhost:8000/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"bob@example.com","comment":"I agree","content_id":1}'

# matéria 2
curl -sv localhost:8000/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"bob@example.com","comment":"I guess this is a good thing","content_id":2}'
curl -sv localhost:8000/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"charlie@example.com","comment":"Indeed, dear Bob, I believe so as well","content_id":2}'
curl -sv localhost:8000/api/comment/new -X POST -H 'Content-Type: application/json' -d '{"email":"eve@example.com","comment":"Nah, you both are wrong","content_id":2}'

# listagem matéria 1
curl -sv localhost:8000/api/comment/list/1

# listagem matéria 2
curl -sv localhost:8000/api/comment/list/2
```


# O que será avaliado na sua solução?

* Automação da infra, provisionamento dos hosts (IaaS)

* Automação de setup e configuração dos hosts (IaC)

* Pipeline de deploy automatizado

* Monitoramento dos serviços e métricas da aplicação


# Dicas

Use ferramentas e bibliotecas open source, mas documente as decisões e porquês;

Automatize o máximo possível;

Em caso de dúvidas, pergunte.


# Bem vindo ao projeto

### Este repositório contém um exemplo de implementação de uma pipeline de CI/CD para um cluster EKS (Amazon Elastic Kubernetes Service)

## Introdução

### Este projeto implementa uma pipeline para automatizar a criação, a implantação e o monitoramento de aplicações em um cluster Amazon EKS. A pipeline utiliza ferramentas como kube-prometheus e Grafana para fornecer um ambiente completo e gerenciável.

## Pré-requisitos

* Conta AWS com acesso à CLI da AWS.
* Ferramenta `kubectl`, `aws-cli` e `git` instalada localmente.

## 1. Clone o repositório
```bash
git clone https://github.com/deividduarte20/projeto-pipeline-eks.git
```

## 2. Entre no diretório
```bash
cd projeto-pipeline-eks
```

## 3. Preencha informações importantes para a pipeline de forma automatizada provida pelo shell script 
```bash
./start.sh
```

## 4. Adicione todos os arquivos não rastreados pelo git
```bash
git add .
```
## 4.1 Registra commit com mensagem
```bash
git commit -m "Add pipeline eks and manifests"
```
## 4.2 Cria nova branch
```bash
git checkout -b add/pipe
```
## 4.3 Envia alterações para o repositório remoto
```bash
git push origin add/pipe
```

## Passos da Pipeline

### 3. Criação do Cluster EKS

* Executa o build e push da imagem para o repositório no AWS ECR
* Executa o terraform provisionando eks
* Atualiza o kube-config
* Instala o metrics-server
* Deploy da aplicação python no namespace app
* Instala helm
* Instala kube-prometheus no namespace monitoring

### 4. Monitoramento

* O Prometheus coleta métricas do cluster EKS.
* O Grafana visualiza as métricas coletadas pelo Prometheus.

### 5. Rotas da API

**Health:** `/` </br>
**Métricas:** `/metrics`</br>
**Swagger:** `/apidocs` </br>
**Comentário:** `/api/comment/new` </br>
**Lista comentário:** `/api/comment/list/id` </br> 

