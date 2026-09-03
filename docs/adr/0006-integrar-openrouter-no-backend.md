# 0006 — Integrar a OpenRouter somente pelo backend

- Status: Aceita
- Data: 2026-09-03

## Contexto

O primeiro chatbot usará modelos acessados pela OpenRouter. A credencial pertence
ao projeto e o custo não pode ser controlado pelo navegador.

## Decisão

O Relay chamará `POST https://openrouter.ai/api/v1/chat/completions` com `Req`,
autenticação Bearer e `stream: true`. A chave, o modelo, o prompt de sistema e os
limites serão configuração exclusiva do backend.

O adaptador OpenRouter implementará uma porta interna. Testes comuns usarão um
adaptador falso e nunca consumirão uma API paga.

## Consequências

- nenhuma credencial será entregue ao GitHub Pages;
- visitantes não poderão escolher livremente modelo ou parâmetros caros;
- erros e eventos externos serão convertidos para o protocolo estável do Relay;
- limites técnicos e financeiros são obrigatórios antes da chave real;
- trocar de provedor não deverá alterar o protocolo do frontend.

## Alternativas consideradas

- **Chamada direta do navegador:** rejeitada por expor a chave do projeto.
- **OAuth/BYOK da OpenRouter por visitante:** pode ser avaliado futuramente, mas
  adiciona autenticação e transfere ao usuário uma decisão desnecessária no MVP.
- **SDK acoplado à camada web:** rejeitado para manter o provedor substituível.

## Referências

- [API de chat da OpenRouter](https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request)
- [Quickstart e streaming](https://openrouter.ai/docs/quickstart)
- [Req](https://hex.pm/packages/req)
