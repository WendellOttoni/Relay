# Arquitetura de deploy

## 1. Separação obrigatória

```text
Repositório do frontend       Repositório Relay
          |                          |
          v                          v
    GitHub Pages             Serviço de backend
    arquivos estáticos       processo ou função HTTPS
          |                          |
          +---------- HTTPS --------+
```

O GitHub Pages não executa o Relay. Ele apenas entrega o frontend, que recebe a
URL pública do backend durante o build.

## 2. Requisitos da hospedagem do Relay

O serviço escolhido precisa oferecer:

- endpoint HTTPS público;
- variáveis de ambiente secretas;
- suporte a respostas transmitidas por streaming;
- logs e métricas operacionais;
- configuração de domínio e CORS;
- timeout suficiente para uma resposta de IA;
- limites de CPU, memória e concorrência conhecidos;
- processo claro para rollback.

Planos gratuitos podem suspender a aplicação, provocar cold start ou limitar
streaming e tempo de execução. Essas restrições devem ser testadas com uma prova
de conceito antes da escolha definitiva.

## 3. Configuração pública do frontend

O frontend pode conter:

```text
RELAY_API_URL=https://api.exemplo.com
```

Essa URL não é segredo. Chaves de IA, client secrets, tokens do GitHub e strings
de conexão não podem fazer parte do build do Pages, nem mesmo com nomes de
variáveis de ambiente usados por ferramentas frontend.

## 4. Configuração secreta do backend

Exemplos conceituais:

```text
AI_API_KEY=<segredo>
ALLOWED_ORIGINS=https://usuario.github.io
GITHUB_CLIENT_ID=<quando necessário>
GITHUB_CLIENT_SECRET=<quando necessário>
```

Nomes finais dependem da tecnologia. Produção deve falhar na inicialização se
uma configuração obrigatória estiver ausente ou inválida.

## 5. Ambientes

| Ambiente | Frontend | Backend | Dados |
| --- | --- | --- | --- |
| Local | servidor local | API local | credenciais de desenvolvimento |
| Preview | URL temporária | ambiente isolado | sem dados de produção |
| Produção | GitHub Pages | URL estável HTTPS | segredos de produção |

Cada ambiente possui origens e credenciais próprias. Um deploy de preview não
deve conseguir utilizar segredos ou dados de produção.

## 6. Checklist de produção

- segredo não aparece em bundle, log ou histórico Git;
- origem do Pages está explicitamente permitida;
- endpoint rejeita origens inesperadas no navegador;
- rate limiting e orçamento estão habilitados;
- timeout e cancelamento foram testados;
- health checks refletem prontidão real;
- rollback foi ensaiado;
- custo e limites do provedor possuem alertas;
- política de privacidade explica o envio de mensagens à IA.
