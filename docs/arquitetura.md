# Arquitetura

## 1. Contexto

O frontend será um site estático hospedado no GitHub Pages. Ele executa no
navegador do usuário e pode fazer chamadas HTTPS, mas todo arquivo entregue ao
navegador é público. O Relay é uma API separada que protege credenciais e aplica
as regras necessárias antes de acessar serviços externos.

## 2. Visão geral

```text
                  limite público                    limite privado

+---------------------------+          +--------------------------------+
| GitHub Pages              | HTTPS    | Relay no Render                |
| React / Vite              +--------->| sessão anônima + health        |
| estado visual e histórico | WebSocket| Phoenix Channels + supervisão |
| cliente Phoenix JS        +--------->| limites + adaptador de IA      |
+---------------------------+          +---------------+----------------+
                                                     |
                                                     | HTTPS + SSE
                                               +-----v------+
                                               | OpenRouter |
                                               +-----+------+
                                                     |
                                               +-----v------+
                                               | modelo IA  |
                                               +------------+
```

O repositório Relay contém somente o backend e sua documentação. O frontend do
GitHub Pages pode estar em outro repositório e conhece apenas a URL pública da
API.

## 3. Componentes

### Frontend estático

Responsável por interface, estado visual, envio da mensagem, exibição do stream,
cancelamento e mensagens de erro amigáveis. Não contém segredo nem decide
permissões. A URL do Relay pode ser configuração pública de build.

### API HTTP

Expõe health checks e cria sessões anônimas após validação Turnstile. Valida
corpo, origem e limites, atribui request ID e converte erros para um contrato
estável. O conteúdo do chat não passa por um endpoint REST no MVP.

### Socket e Channel

O `UserSocket` valida o token curto emitido pela API HTTP. Cada conexão entra em
um tópico `chat:<sessionId>`. O Channel aceita comandos de geração e cancelamento,
publica deltas e mantém no máximo uma geração ativa.

### Serviço de chat

Aplica regras independentes do provedor: tamanho do contexto, prompt permitido,
timeout, cancelamento, orçamento e eventos da resposta. Expõe uma porta interna
implementada por um provedor falso e pela OpenRouter.

### Adaptador de IA

Usa `Req` para traduzir o pedido interno para a API Chat Completions da
OpenRouter, consumir seu SSE e converter chunks para eventos internos. Apenas
esse componente conhece a credencial e o formato específico do provedor.

### Integração com GitHub

É opcional e separada do chat. Pode oferecer login, leitura de contexto de um
repositório ou operações autorizadas. Deve usar permissões mínimas e nunca
aceitar do navegador um token administrativo para apenas retransmiti-lo.

### Persistência

Não existe no MVP. O histórico permanece no navegador e é enviado de forma
limitada a cada geração. Processos da BEAM mantêm somente o estado transitório da
conexão. PostgreSQL e Ecto entram apenas depois de definir proprietário,
retenção, exclusão, privacidade e autenticação.

## 4. Fluxo do chat

```text
1. Browser resolve Turnstile e cria uma sessão anônima por HTTP.
2. Browser conecta ao socket com token assinado e entra no próprio tópico.
3. Channel valida `chat:generate`, limites e ausência de geração concorrente.
4. Serviço de chat inicia uma Task monitorada usando a porta de provedor.
5. Adaptador chama a OpenRouter com segredo e modelo obtidos do ambiente.
6. Chunks SSE tornam-se eventos internos e depois `chat:delta`.
7. `chat:cancel`, saída do Channel ou desconexão interrompem a chamada externa.
8. Métricas registram duração e consumo, sem conteúdo da conversa.
```

## 5. Limites de confiança

- Tudo enviado pelo navegador é não confiável.
- A origem permitida no CORS é configuração, não evidência de identidade.
- Headers como usuário, repositório e permissão precisam ser verificados.
- Conteúdo retornado pela IA é dado não confiável para qualquer ferramenta.
- Uma futura ação no GitHub exige autorização específica no servidor.
- Logs e telemetria são tratados como armazenamento de dados.

## 6. Estrutura lógica proposta

A estrutura física dependerá da tecnologia escolhida, mas deve preservar estas
responsabilidades:

```text
lib/
├── relay/
│   ├── application.ex              # supervisão da aplicação OTP
│   ├── chat/                       # caso de uso, políticas e porta do provedor
│   ├── integrations/open_router/   # Req, SSE e normalização externa
│   ├── sessions/                   # emissão e validação de sessão anônima
│   └── rate_limit/                 # limites locais do experimento
├── relay_web/
│   ├── channels/                   # UserSocket e ChatChannel
│   ├── controllers/                # sessão e health
│   ├── plugs/                      # request ID, CORS e limites HTTP
│   ├── endpoint.ex
│   └── router.ex
└── relay.ex

test/
├── relay/                          # regras e adaptadores
├── relay_web/                      # conexão, Channel e HTTP
├── support/                        # fakes e servidor externo controlado
└── contract/                       # payloads e sequência de eventos
```

O MVP é uma única aplicação OTP e um único release. Contextos e behaviours
separam responsabilidades sem criar umbrella ou microsserviços.

## 7. Requisitos transversais

- HTTPS obrigatório fora do ambiente local;
- CORS com lista explícita de origens;
- limite de tamanho antes de desserializar corpos grandes;
- timeout e cancelamento propagados ao provedor;
- rate limiting por sessão e sinais adicionais disponíveis;
- orçamento de uso configurável;
- health checks distintos para processo vivo e pronto;
- logs estruturados sem prompts, respostas ou credenciais;
- identificador de requisição retornado ao cliente;
- interface de provedor substituível em testes;
- `check_origin` no WebSocket e CORS explícito no HTTP;
- uma geração ativa por sessão;
- worker e Channel monitorados mutuamente para vincular seus ciclos de vida;
- chave de emergência para desabilitar o chat.

## 8. Falhas esperadas

| Falha | Comportamento esperado |
| --- | --- |
| Corpo HTTP inválido | `400` com código estável |
| Desafio ou origem recusados | `403` sem detalhes internos |
| Sessão inválida no socket | conexão recusada |
| Payload inválido no Channel | reply `invalid_request` |
| Limite excedido | `429` no HTTP ou `rate_limit_exceeded` no Channel |
| Provedor indisponível | evento `provider_unavailable`, sem resposta bruta |
| Timeout | evento `provider_timeout` e encerramento da tarefa |
| Browser desconectado | cancelamento do trabalho externo |
| Configuração inválida | serviço não fica pronto |

## 9. Decisões ainda evolutivas

- modelo exato da OpenRouter, escolhido por avaliação representativa;
- prompt e personalidade do chatbot;
- limite financeiro adequado ao público esperado;
- necessidade real de autenticação GitHub;
- persistência e retenção de conversas em fases futuras;
- hospedagem definitiva depois do experimento gratuito.

Consulte [decisões pendentes](decisoes-pendentes.md).
