# Arquitetura de deploy

## 1. Separação obrigatória

```text
Repositório do frontend       Repositório Relay
          |                          |
          v                          v
    GitHub Pages             Render Web Service
    React / Vite             release Elixir/Phoenix
          |                          |
          +----- HTTPS/WebSocket ---+
```

O GitHub Pages não executa o Relay. Ele apenas entrega o frontend, que recebe a
URL pública do backend durante o build.

## 2. Ambiente experimental escolhido

O primeiro deploy usa um Web Service gratuito do Render porque oferece:

- endpoint HTTPS público;
- variáveis de ambiente secretas;
- suporte a WebSockets;
- logs e métricas operacionais;
- configuração de domínio e CORS;
- processo Phoenix convencional com porta configurável;
- deploy ligado ao GitHub;
- processo claro para rollback.

Essa é uma decisão para experimento, não uma garantia de produção. No plano
gratuito, o serviço dorme após inatividade, tem cold start, filesystem efêmero e
pode ser reiniciado. O frontend deve exibir o estado "acordando servidor" e
tentar reconectar com backoff limitado.

WebSockets ativos mantêm o serviço ocupado. O cliente Phoenix usa heartbeat e
reconexão, mas o protocolo não promete recuperar uma geração interrompida.

## 3. Build e execução no Render

O deploy produzirá um release com `mix phx.gen.release`. O serviço deve:

- compilar com versões fixadas de Elixir e Erlang/OTP;
- ouvir em `0.0.0.0` e na variável `PORT`;
- definir `PHX_SERVER=true`, `PHX_HOST` e `SECRET_KEY_BASE`;
- executar sem filesystem persistente;
- expor `/health/live` e `/health/ready`;
- executar testes na CI antes do deploy;
- permitir rollback para uma revisão anterior.

O comando exato de build será validado no primeiro deploy e versionado em um
arquivo de infraestrutura do Render, evitando configuração somente no painel.

## 4. Configuração pública do frontend

O frontend pode conter:

```text
RELAY_API_URL=https://api.exemplo.com
RELAY_SOCKET_URL=wss://api.exemplo.com/socket
TURNSTILE_SITE_KEY=<identificador público>
```

Essa URL não é segredo. Chaves de IA, client secrets, tokens do GitHub e strings
de conexão não podem fazer parte do build do Pages, nem mesmo com nomes de
variáveis de ambiente usados por ferramentas frontend.

## 5. Configuração secreta do backend

Exemplos conceituais:

```text
OPENROUTER_API_KEY=<segredo>
OPENROUTER_MODEL=<modelo permitido>
SECRET_KEY_BASE=<segredo Phoenix>
TURNSTILE_SECRET_KEY=<segredo>
ALLOWED_ORIGINS=https://usuario.github.io
GITHUB_CLIENT_ID=<quando necessário>
GITHUB_CLIENT_SECRET=<quando necessário>
```

Consulte o contrato completo em [configuração](configuracao.md). Secrets são
configurados no Render e nunca incluídos no repositório, imagem, frontend ou
saída de build.

## 6. Ambientes

| Ambiente | Frontend | Backend | Dados |
| --- | --- | --- | --- |
| Local | servidor local | API local | credenciais de desenvolvimento |
| Preview | URL temporária | serviço isolado quando disponível | adaptador falso |
| Experimento | GitHub Pages | Render Free | secrets próprios, sem banco |
| Produção futura | URL estável | hospedagem reavaliada | política ainda pendente |

Cada ambiente possui origens e credenciais próprias. Um deploy de preview não
deve conseguir utilizar segredos ou dados de produção.

## 7. Estratégia de cold start

Antes de abrir o socket, o frontend consulta `/health/ready` com timeout curto.
Enquanto o Render inicia a instância, a interface informa o estado ao usuário.
Quando a API responder, o frontend cria a sessão e conecta o socket. Tentativas
possuem backoff e limite; não haverá serviço externo de ping artificial apenas
para contornar a política do plano gratuito.

## 8. Checklist do experimento público

- segredo não aparece em bundle, log ou histórico Git;
- origem do Pages está explicitamente permitida;
- HTTP e socket rejeitam origens inesperadas;
- rate limiting e orçamento estão habilitados;
- timeout e cancelamento foram testados;
- health checks refletem prontidão real;
- rollback foi ensaiado;
- custo e limites do provedor possuem alertas;
- política de privacidade explica o envio de mensagens à IA.

## 9. Evolução

Render será reavaliado se cold start, limites de saída, estabilidade de WebSocket
ou custo deixarem de servir ao projeto. Alternativas registradas são Koyeb,
Cloud Run, Fly.io e Cloudflare Containers. A aplicação permanece portável por
usar release/container Phoenix e configuração pelo ambiente.
