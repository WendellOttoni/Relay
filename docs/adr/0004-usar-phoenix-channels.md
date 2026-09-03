# 0004 — Usar Phoenix Channels para o chat

- Status: Aceita
- Data: 2026-09-03

## Contexto

O fluxo inicial envia uma mensagem e recebe texto incremental. SSE seria
suficiente para essa direção única, mas o experimento também precisa exercitar
cancelamento explícito, reconexão e o modelo concorrente do Phoenix.

## Decisão

Usar Phoenix Channels sobre WebSocket entre o frontend e o Relay. O frontend
usará o cliente JavaScript oficial do Phoenix. A conexão será autenticada por um
token de sessão anônima, curto e assinado pelo Relay.

O Relay consumirá o streaming SSE da OpenRouter, converterá os chunks em eventos
internos e os publicará no Channel. O protocolo público não reproduzirá o formato
da OpenRouter.

## Consequências

- o cliente poderá iniciar e cancelar uma geração pela mesma conexão;
- heartbeat e reconexão serão tratados pelo cliente Phoenix;
- cada Channel poderá supervisionar uma única geração ativa;
- o deploy precisará aceitar WebSockets;
- clientes devem tolerar desconexão e não presumir retomada de um stream;
- uma implementação futura com múltiplas instâncias exigirá PubSub distribuído,
  mas o MVP de instância única não precisa de Redis.

## Alternativas consideradas

- **SSE sobre `fetch`:** mais simples e permanece como alternativa caso Channels
  não tragam benefício suficiente após o experimento.
- **NDJSON:** framing simples, mas não exercita a comunicação bidirecional.
- **WebSocket manual:** evita o protocolo Phoenix, porém recria tópicos,
  heartbeat, push e reconexão já disponíveis.

## Referências

- [Phoenix Channels](https://hexdocs.pm/phoenix/channels.html)
- [Cliente JavaScript oficial](https://hexdocs.pm/phoenix/js/index.html)
