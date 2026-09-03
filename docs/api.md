# Contrato inicial da API

Status: **Aceito para o experimento**

Este documento define endpoints HTTP auxiliares. O chat usa Phoenix Channels e
está especificado em [protocolo-channels.md](protocolo-channels.md).

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

## Sessão anônima

### `POST /api/v1/sessions`

Valida um desafio Turnstile e emite credenciais curtas para o socket.

Requisição:

```json
{
  "turnstileToken": "token gerado no navegador"
}
```

Resposta `201 Created`:

```json
{
  "sessionId": "01J...",
  "socketToken": "token assinado pelo Relay",
  "expiresAt": "2026-09-03T18:30:00Z"
}
```

O endpoint valida token, hostname e action do Turnstile. Tokens ausentes,
expirados, reutilizados ou inválidos recebem `403`. Limites de criação de sessão
podem produzir `429`.

O token de socket não contém credenciais externas, mensagem ou informação
pessoal. A expiração inicial é definida em [configuração](configuracao.md).

## Erros

Formato aceito:

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

Códigos HTTP iniciais:

| Status | Uso |
| --- | --- |
| `400` | JSON ou campos inválidos |
| `403` | origem ou desafio Turnstile recusado |
| `404` | rota inexistente |
| `413` | corpo acima do limite |
| `429` | limite temporário atingido |
| `500` | falha interna normalizada |
| `503` | aplicação não pronta ou chat desabilitado |

## CORS

Produção aceita somente as origens configuradas para o site. Métodos, headers e
tempo de preflight são mínimos. Origem nula e curingas são recusados. A política
HTTP e o `check_origin` do socket derivam da mesma configuração validada.

CORS não impede chamadas feitas fora de um navegador. O endpoint público ainda
precisa de rate limiting, orçamento e um mecanismo antiabuso.

## Versionamento

Mudanças incompatíveis criam uma nova versão no caminho. Adições compatíveis
podem ocorrer na mesma versão durante a fase experimental, desde que documentadas.
