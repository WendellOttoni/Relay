# Protocolo do chat por Phoenix Channels

Status: **Aceito para o experimento**
Versão: **1**

Este documento é o contrato entre o frontend estático e o Relay. Tipos internos
da OpenRouter não fazem parte deste protocolo.

## 1. Preparação da sessão

### `POST /api/v1/sessions`

Cria uma sessão anônima curta antes da conexão WebSocket.

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

Regras:

- o token Turnstile é validado no servidor, inclusive `hostname` e `action`;
- cada token Turnstile só pode criar uma sessão;
- o token do socket contém somente identificadores não sensíveis;
- a expiração inicial recomendada é 30 minutos;
- renovar uma sessão exige um novo desafio Turnstile;
- falhas usam o formato comum de erro HTTP.

## 2. Conexão

Endpoint Phoenix:

```text
wss://<relay-host>/socket/websocket?token=<socketToken>&vsn=2.0.0
```

O `UserSocket.connect/3` valida assinatura e expiração, atribui `session_id` ao
socket e rejeita tokens inválidos. O endpoint configura `check_origin` com a URL
exata do GitHub Pages e as origens locais permitidas no ambiente de
desenvolvimento.

Após conectar, o cliente entra no tópico:

```text
chat:<sessionId>
```

O Channel aceita o tópico somente quando o identificador coincide com a sessão
atribuída ao socket.

## 3. Eventos enviados pelo cliente

O protocolo só está disponível após a criação de sessão. Se o serviço estiver
com `CHAT_ENABLED=false`, a API de sessão não emite token de socket e o cliente
não deve tentar conectar ou repetir em laço.

### `chat:generate`

Inicia uma geração.

```json
{
  "messages": [
    {"role": "user", "content": "Olá"},
    {"role": "assistant", "content": "Como posso ajudar?"},
    {"role": "user", "content": "Explique OTP"}
  ]
}
```

Regras:

- `role` aceita apenas `user` e `assistant`;
- o cliente nunca envia mensagem `system`;
- conteúdo vazio, campos desconhecidos e tipos inválidos são rejeitados;
- limites de quantidade e tamanho são aplicados antes de chamar o provedor;
- existe no máximo uma geração ativa por Channel;
- uma segunda tentativa recebe `generation_in_progress`.

Resposta imediata ao push:

```json
{
  "status": "accepted",
  "generationId": "01J...",
  "requestId": "01J..."
}
```

### `chat:cancel`

Cancela a geração ativa.

```json
{
  "generationId": "01J..."
}
```

Cancelar uma geração inexistente ou já encerrada é idempotente e responde com o
estado atual, sem iniciar trabalho adicional.

## 4. Eventos enviados pelo Relay

Todos os eventos de uma geração incluem `generationId` e `requestId`.

### `chat:started`

```json
{
  "generationId": "01J...",
  "requestId": "01J..."
}
```

### `chat:delta`

```json
{
  "generationId": "01J...",
  "requestId": "01J...",
  "sequence": 1,
  "text": "fragmento de texto"
}
```

`sequence` começa em 1 e cresce por geração. O cliente ignora duplicatas e nunca
presume que um fragmento contém palavra ou caractere completo.

### `chat:usage`

```json
{
  "generationId": "01J...",
  "requestId": "01J...",
  "inputTokens": 120,
  "outputTokens": 48
}
```

O evento é opcional. Campos indisponíveis podem ser omitidos; custo interno e
detalhes de roteamento não são expostos por padrão.

### `chat:completed`

```json
{
  "generationId": "01J...",
  "requestId": "01J...",
  "finishReason": "stop"
}
```

Razões públicas iniciais: `stop`, `length` e `cancelled`.

### `chat:error`

```json
{
  "generationId": "01J...",
  "requestId": "01J...",
  "error": {
    "code": "provider_unavailable",
    "message": "O serviço de IA está temporariamente indisponível.",
    "retryable": true
  }
}
```

Códigos iniciais:

| Código | Significado |
| --- | --- |
| `invalid_request` | mensagem ou histórico inválido |
| `generation_in_progress` | já existe trabalho na sessão |
| `rate_limit_exceeded` | limite local ou externo atingido |
| `service_overloaded` | capacidade simultânea da instância esgotada; tente novamente |
| `provider_unavailable` | OpenRouter ou modelo indisponível |
| `provider_timeout` | limite de duração excedido |
| `session_expired` | sessão anônima não é mais válida |
| `chat_disabled` | geração foi desabilitada operacionalmente; tente mais tarde |
| `internal_error` | falha segura e rastreável |

Mensagens públicas não incluem stack trace, resposta bruta do provedor, prompt
de sistema, URL interna ou credencial.

## 5. Ciclo de vida e falhas

- o Channel inicia a geração em um processo supervisionado;
- Channel e worker monitoram um ao outro para que a queda de qualquer lado
  encerre o trabalho restante;
- o processo envia eventos internos ao Channel, que é o único responsável por
  publicar ao socket;
- `chat:cancel`, saída normal, queda do Channel ou desconexão encerram a tarefa e
  a requisição HTTP externa;
- não há retomada do meio de um stream após reconexão;
- depois de reconectar, o cliente pode reenviar o histórico e iniciar nova
  geração;
- o backend não repete automaticamente uma chamada após receber o primeiro
  delta, evitando resposta duplicada e custo adicional;
- heartbeat e reconexão seguem o comportamento do cliente Phoenix.

## 6. Compatibilidade

Mudanças incompatíveis criam novo socket ou tópico versionado. Durante o
experimento, adições compatíveis podem ocorrer na versão 1 quando forem
documentadas e toleradas pelo frontend.
