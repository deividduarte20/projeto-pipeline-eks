# Bem vindo ao projeto

### Este projeto implementa uma pipeline para automatizar a criação, implantação e o monitoramento de aplicação em um cluster Amazon EKS. A pipeline utiliza ferramentas como helm, kube-prometheus e Grafana para fornecer um ambiente completo e gerenciável.

![Alt text here](diagrama/projeto-eks.drawio.svg)

## Pré-requisitos

* Conta AWS com acesso à CLI da AWS.
* Bucket para utilização de armazenamento do terraform state.
* Repo do ECR criado
* Route53 com zona hosteada

## Passos da Pipeline

### 3. Criação do Cluster EKS

* Executa o build e push da imagem para o repositório no AWS ECR
* Executa o terraform provisionando eks + AWS load balancer controller + Karpenter + Externaldns
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

### Aqui estão alguns exemplos visuais do projeto:

#### Grafana
![Grafana](diagrama/grafana1.png)

#### Métricas
![Metricas](diagrama/metrics.png)

#### Swagger
![Swagger](diagrama/swagger.png)

#### Prometheus
![Swagger-get](diagrama/prometheus.png).
