# Contrato inicial da API

Status: **Proposta para validação**

Este documento define o comportamento necessário para que o frontend possa ser
desenvolvido sem depender diretamente do formato de um provedor de IA.

## Convenções

- Base: `https://<relay-host>/api/v1`.
- Corpos JSON em UTF-8.
- Horários em UTC no formato ISO 8601.
- Cada resposta inclui `X-Request-Id`.
- Erros possuem código estável e mensagem segura.
- Tamanhos e tempos máximos são configuração do servidor.

## Saúde

### `GET /health/live`

Indica que o processo está vivo. Não acessa o provedor externo.

### `GET /health/ready`

Indica que configuração e dependências obrigatórias permitem receber tráfego.

## Chat

### `POST /api/v1/chat`

Requisição proposta:

```json
{
  "conversationId": "opcional",
  "messages": [
    {
      "role": "user",
      "content": "Explique este trecho de código"
    }
  ]
}
```

Regras:

- `role` aceita somente valores definidos pelo Relay;
- número de mensagens, tamanho individual e tamanho total são limitados;
- o cliente não escolhe livremente modelo, prompt de sistema ou ferramentas;
- campos desconhecidos podem ser rejeitados durante a fase experimental;
- conteúdo vazio é inválido.

## Streaming

A resposta deve chegar incrementalmente usando streaming HTTP compatível com
`fetch`. O formato exato ainda será decidido, mas os eventos lógicos são:

| Evento | Finalidade |
| --- | --- |
| `start` | informa IDs e metadados seguros |
| `delta` | adiciona texto à resposta |
| `usage` | informa consumo permitido ao cliente |
| `complete` | encerra normalmente |
| `error` | encerra com código tratável |

Exemplo conceitual:

```text
event: start
data: {"requestId":"..."}

event: delta
data: {"text":"Olá"}

event: complete
data: {}
```

Uma ADR decidirá entre SSE sobre `fetch`, NDJSON ou outro framing antes da
implementação. WebSocket não é necessário para o primeiro chat, pois a
requisição do usuário pode ser HTTP e apenas a resposta precisa ser transmitida.

## Erros

Formato proposto:

```json
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Limite temporário atingido.",
    "requestId": "01..."
  }
}
```

O contrato nunca inclui stack trace, chave, prompt de sistema, URL interna ou
corpo bruto devolvido pelo provedor.

## CORS

Produção aceita somente as origens configuradas para o site. Métodos, headers e
tempo de preflight devem ser mínimos. Origem nula e curingas não são permitidos
quando houver credenciais.

CORS não impede chamadas feitas fora de um navegador. O endpoint público ainda
precisa de rate limiting, orçamento e um mecanismo antiabuso.

## Versionamento

Mudanças incompatíveis criam uma nova versão no caminho. Adições compatíveis
podem ocorrer na mesma versão durante a fase experimental, desde que documentadas.
