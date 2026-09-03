# Configuração

Status: **Contrato inicial**

Toda configuração de produção vem do ambiente. Arquivos versionados contêm
somente valores locais seguros e exemplos sem credenciais.

## Variáveis

| Nome | Obrigatória | Finalidade |
| --- | --- | --- |
| `PHX_HOST` | produção | host público do Relay |
| `PORT` | deploy | porta fornecida pela plataforma |
| `SECRET_KEY_BASE` | produção | assinatura e segurança do Phoenix |
| `ALLOWED_ORIGINS` | sim | origens HTTP e WebSocket separadas por vírgula |
| `PUBLIC_SITE_URL` | sim | URL canônica do frontend |
| `OPENROUTER_API_KEY` | Fase 3 | chave secreta da OpenRouter |
| `OPENROUTER_MODEL` | Fase 3 | modelo permitido |
| `SYSTEM_PROMPT` | Fase 3 | instrução controlada pelo servidor |
| `TURNSTILE_SECRET_KEY` | chat público | validação server-side |
| `TURNSTILE_EXPECTED_HOSTNAME` | chat público | hostname autorizado |
| `TURNSTILE_EXPECTED_ACTION` | chat público | action esperada |
| `CHAT_ENABLED` | não | chave de emergência; padrão `false` em produção nova |
| `CHAT_ALLOW_UNPROTECTED_DEMO` | não | **somente demonstração privada**; desativa Turnstile temporariamente |
| `CHAT_SESSION_TTL_SECONDS` | não | duração da sessão anônima |
| `CHAT_MAX_MESSAGES` | não | quantidade máxima no histórico |
| `CHAT_MAX_MESSAGE_BYTES` | não | tamanho máximo por mensagem |
| `CHAT_MAX_REQUEST_BYTES` | não | tamanho máximo do payload lógico |
| `CHAT_MAX_OUTPUT_TOKENS` | não | limite enviado ao provedor |
| `CHAT_TIMEOUT_MS` | não | duração máxima da geração |
| `CHAT_MAX_CONCURRENT_GENERATIONS` | não | máximo de gerações simultâneas por instância |
| `LOG_LEVEL` | não | nível de log estruturado |

## Valores iniciais para o experimento

| Limite | Valor inicial |
| --- | --- |
| sessão anônima | 30 minutos |
| mensagens no histórico | 20 |
| conteúdo por mensagem | 8 KiB em UTF-8 |
| payload lógico | 64 KiB |
| gerações simultâneas por sessão | 1 |
| timeout total | 90 segundos |
| tokens de saída | 1.000 |
| gerações simultâneas por instância | 8 |

São valores de partida, não garantias permanentes. Mudanças em produção devem ser
feitas por configuração e acompanhadas por testes de fronteira.

## Validação de startup e readiness

- valores ausentes, malformados ou fora de faixa tornam `/health/ready` não
  saudável;
- `SECRET_KEY_BASE` e secrets nunca aparecem na mensagem de erro;
- produção rejeita origem curinga, `localhost` e esquemas diferentes de HTTPS;
- `CHAT_ENABLED=true` exige OpenRouter e, exceto se `CHAT_ALLOW_UNPROTECTED_DEMO=true`, todas as configurações do Turnstile;
- a aplicação inicia com chat desabilitado para permitir diagnóstico seguro,
  podendo responder saudável em `/health/ready`, mas não atende sessão nem
  geração enquanto o chat estiver desabilitado;
- `CHAT_ENABLED=true` só se torna efetivo se a configuração base, os limites,
  Turnstile e OpenRouter forem válidos. Em caso de erro, o processo conserva o
  modo seguro com chat indisponível; não há fallback para o provedor real.

## Estados operacionais

| Estado | Configuração | Efeito para o consumidor |
| --- | --- | --- |
| Serviço disponível, chat desligado | `CHAT_ENABLED=false` | health pode estar pronto; sessão responde `503 sessions_unavailable` |
| Serviço pronto para chat | `CHAT_ENABLED=true` e todos os valores exigidos válidos | sessão Turnstile e geração podem ser atendidas |
| Configuração inválida | erro de validação em runtime | `/health/ready` responde `503`; o chat não é habilitado |

Mudar `CHAT_ENABLED` ou qualquer segredo requer aplicar a alteração pela
plataforma de hospedagem e reiniciar/reimplantar de forma controlada. Nunca
transmita um segredo ao frontend para tentar ativar o serviço.

## Ambientes

- **local:** frontend local explícito, chave OpenRouter opcional e adaptador falso
  por padrão;
- **preview:** origem própria, Turnstile de teste e sem chave de produção;
- **produção experimental:** URL do Pages, secrets do Render e limites baixos.
