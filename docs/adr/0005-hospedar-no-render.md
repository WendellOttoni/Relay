# 0005 — Hospedar o experimento no Render

- Status: Aceita para o ambiente experimental
- Data: 2026-09-03

## Contexto

O primeiro deploy deve ser gratuito, aceitar Phoenix e WebSockets, fornecer HTTPS
e permitir secrets. Disponibilidade contínua e latência de produção ainda não são
requisitos do experimento.

## Decisão

Usar um Web Service gratuito do Render, conectado ao repositório GitHub. O app
será publicado como release do Elixir e ouvirá em `0.0.0.0:$PORT`.

O frontend tratará o estado de cold start e exibirá que o servidor experimental
está acordando. O Render não será considerado automaticamente a hospedagem de
produção.

## Consequências

- o serviço dorme após inatividade e a primeira conexão pode demorar;
- WebSockets ativos impedem o serviço de ser considerado ocioso;
- o filesystem é efêmero e não será usado para estado persistente;
- o plano pode ser interrompido ou alterado pelo provedor;
- a decisão será reavaliada antes de uma exposição com garantia de serviço.

## Alternativas consideradas

- **Koyeb Free:** cold start menor, mas possui limitações mais restritivas para a
  instância e para a conexão que a desperta.
- **Google Cloud Run:** portável e robusto, porém exige billing e possui semântica
  de custo menos conveniente para WebSockets sempre conectados.
- **Fly.io:** não mantém uma camada gratuita permanente adequada ao experimento.
- **Cloudflare Containers:** executa containers, mas requer plano pago.

## Referências

- [Deploy de Phoenix no Render](https://render.com/docs/deploy-phoenix)
- [Limitações do Render Free](https://render.com/docs/free)
- [WebSockets no Render](https://render.com/docs/websocket)
