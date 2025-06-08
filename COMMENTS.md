# Reflexões, Decisões e Obstáculos do Projeto

## Otimização da API e Docker

- **Endpoint de Health Check**: Adicionei um endpoint no path `/` para verificar a funcionalidade da API.
- **Otimização do Docker**: 
  - Imagem inicial: 950MB
  - Após multi-stage build: 190MB
  - Após push para AWS ECR: 84MB

## Documentação e Testes da API

- **Swagger UI**: Implementado no path `/apidocs` para facilitar testes e documentação da API
  - Permite testes via interface web
  - Elimina necessidade de ferramentas externas (curl/Postman)

## Infraestrutura como Código

- **EKS Provisioning**:
  - Ferramenta escolhida: Terraform com módulos
  - Motivação: Melhor representação de cenários reais empresariais
  - Desafio: Conexão com cluster Kubernetes após pipeline
  - Solução: Implementação de `null_resource` para atualização do kubeconfig

## Pipeline CI/CD

### Estrutura
1. **pipe.yaml**
   - CI/CD principal
   - Acionado em merge requests
   - Executa deploy completo

2. **pr.yaml**
   - Pipeline de Pull Request
   - Executa: `terraform init`, `fmt`, `plan`
   - Exibe recursos a serem criados

3. **destroy.yaml**
   - Pipeline manual
   - Executa `terraform destroy`

## Monitoramento e Observabilidade

### Stack de Monitoramento
- **Prometheus + Grafana**
  - Solução: kube-prometheus
  - Benefício: Stack completa pré-configurada

### Auto-scaling
- Implementado HPA (Horizontal Pod Autoscaler)
- Requisito: Metrics Server para métricas de CPU/Memória

### Observabilidade
- **Solução**: Jaeger
- **Desafios**:
  - Substituiu Elastic Stack (muito pesado)
  - Problemas de recursos resolvidos com:
    - Configuração de requests/limits
    - Implementação de réplicas

## Melhorias Futuras

1. **Tracing**
   - Finalizar implementação do Jaeger
   - Integrar com aplicação

2. **DNS**
   - Implementar external-dns
   - Automação de registros DNS via Ingress

3. **Resiliência**
   - Implementar Chaos Mesh para testes de stress
   - Adicionar retry na API
   - Configurar retry no deployment

4. **Segurança**
   - Implementar lock do state do Terraform
   - Utilizar DynamoDB para proteção do state
