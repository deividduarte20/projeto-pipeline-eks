# Reflexões, decisões e obstaculos

- Ao verificar a api python disponibilizada para esse projeto senti a necessidade de adicionar um output no path / com o intuito de identificar se a api está funcional, após a criação do Dockerfile e build efetuada notei que o tamanho da imagem docker estava com 950mb então decidi efetuar a configuração de multi-stage afim de diminuir o tamanho da imagem e ao fim ficou com o tamanho de 190mb e ao subir no aws ECR ficou com tamanho de 84mb.

- Referente a input na api utilizando metodo post e consulta com get, foi pensado em uma forma de não precisar utilizar o comando curl ou postman, decidi inclui o swagger com path /apidocs na aplicação pois via interface web conseguimos efetuar os mesmos.

- A ferramenta escolhida para criar o eks foi o eksctl, mas com pensamento em um uso mais próximo do real de empresas então decidi utilizar o terraform com modulo para efetuar o provisionamento do eks.

- A primeira dificuldade identificada era ao termino da execução da pipeline no estágio da execução do terraform era conectar cluster kubernetes, como solução foi utilizar o bloco de null_resource para que o mesmo executa o comando de update do kubeconfig

- Sobre a decisão da escolha de pipeline foi pensado em ter a principio apenas 2 arquivos para pipeline sendo um chamado pipe.yaml que faz o CI/CD acionado quando é criada uma pull request e o outro arquivo é chamado destroy.yaml que permite o acionamento manual da pipeline para efetuar o terraform destroy, com relação ao acionamento da pipeline do arquivo pipe.yaml foi efetuada uma alteração para inicializar quando feito o merge request, e foi adicionado mais um arquivo de pipeline chamado pr.yaml o mesmo é acionado quando criada uma pr apenas efetuando o terraform init, fmt e terraform plan exibindo os recursos que podem ser criado caso seja feito o merge.

- Com relação a ferramenta para monitoração do cluster kubernetes escolhi o prometheus + grafana porém notei que precisaria configurar o dashboard de forma manual, como solução foi decidido implantar o kube-prometheus que já vem com a stack pronta.

- Ao criar os manifestos de deployment e service que foram adicionados em uma etapa da piepline, foi pensado em adicionar um manifesto de hpa então o mesmo foi inserido na etapa da pipeline com isso foi necessário incluir em uma etapa anterior da pipeline a instalação do metrics server para que o mesmo proporcione a visualização de métricas como consumo de memória e cpu.

- Uma última dificuldade encontrada foi escolher uma ferramenta para observabilidade da aplicação a pricipio foi escolhido Elastic stack porém como exige uma estrutura grande foi necessário repensar sobre uma outra ferramenta que no caso foi escolhida o jaeger, ao subir o jaeger ocorreu um problema de falta de recurso então foi necessario efetuar as correções no manifesto incluindo um bloco de requests e limites e implementado réplicas assim corrigindo o problema.

- Algumas ideias que ficaram pendente por falta de tempo, foi a conclusão do tracing da aplicação com jaeger, iria adicionar um external-dns para efetuar o cadastro automático de domínios configurados em regras de ingress. Outro plus que poderia incluir seria uma ferramenta tipo chaos mesh para efetuar teste de stress na aplicação e incluir um retry na api e na sequência no manifesto do deployment.