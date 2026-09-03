# Fase 3 — Integração com a OpenRouter

Status: **Parcialmente implementada.** F3.2 (cliente Req/SSE), F3.3
(cancelamento e falhas), F3.5 (observabilidade sem conteúdo, contadores locais
e alerta por falhas repetidas) e a parte técnica
de F3.4 (Turnstile server-side, sessão de uso único e chave de emergência)
estão implementadas. O modelo inicial foi escolhido, mas a sua avaliação
operacional, o teto financeiro, a rotação da chave e o smoke test com orçamento
real continuam pendentes. A fase não pode ser encerrada enquanto essas decisões
operacionais não forem tomadas.

## 1. Objetivo

Substituir o provedor falso pela OpenRouter preservando o protocolo, propagando
streaming e cancelamento e limitando o custo do experimento.

## 2. Pré-requisitos

- Fase 2 concluída no Render;
- função e público do chatbot definidos;
- conjunto de perguntas representativas preparado;
- orçamento diário ou mensal aprovado;
- chave OpenRouter própria do experimento criada com limite financeiro baixo;
- política de dados do modelo escolhido revisada.

## 3. Backlog executável

### F3.1 — Selecionar modelo

- comparar ao menos dois modelos adequados ao caso de uso;
- medir qualidade, latência, tamanho de contexto e preço;
- escolher identificador explícito, sem seleção livre pelo cliente;
- registrar decisão e condições para reavaliá-la.

### F3.2 — Implementar cliente Req/SSE

- montar headers e corpo somente a partir de configuração e tipos internos;
- consumir incrementalmente sem acumular a resposta;
- implementar parser que suporte linhas divididas entre chunks;
- converter delta, usage, término e erros para tipos internos;
- impor timeouts de conexão, inatividade e duração total.

Aceite: servidor HTTP local cobre streams completos, fragmentados, truncados e
lentos sem acessar a internet.

### F3.3 — Propagar cancelamento e falhas

- encerrar a conexão externa quando a Task for cancelada;
- não repetir chamadas depois do primeiro delta;
- mapear autenticação, saldo, `429`, timeout e `5xx`;
- nunca publicar nem registrar corpo bruto de erro;
- manter o Channel utilizável depois de uma falha.

### F3.4 — Ativar proteção real

- validar Turnstile pelo endpoint Siteverify;
- conferir hostname e action;
- configurar limites por sessão e sinal de rede;
- ativar teto financeiro da chave;
- implementar `CHAT_ENABLED` como desligamento de emergência;
- documentar rotação e revogação da chave.

### F3.5 — Observar sem armazenar conteúdo

- registrar request ID, generation ID, modelo, duração e resultado categorizado;
- coletar usage agregado quando fornecido;
- testar redaction com segredo e texto sentinela;
- criar alertas ou inspeção simples para limites e falhas repetidas.

O Relay emite o evento Telemetry `[:relay, :chat, :generation, :stop]` com
somente `duration_ms`, `input_tokens` e `output_tokens`; o único metadado é o
resultado categorizado. `Relay.Chat.GenerationMetrics.snapshot/0` expõe
contadores locais agregados para inspeção. Eles são reiniciados junto com a
instância e não servem como registro de cobrança. Cinco falhas de provedor em
cinco minutos (configuráveis por aplicação) geram um aviso estruturado sem
identificadores, conteúdo ou credenciais.

### F3.6 — Executar smoke test controlado

- habilitar teste manual separado da suíte padrão;
- fazer uma geração curta com orçamento mínimo;
- confirmar deltas, cancelamento, usage e logs;
- desabilitar chat automaticamente se configuração crítica falhar.

O comando manual é `RELAY_RUN_OPENROUTER_SMOKE=true mix relay.smoke_openrouter`.
Ele permanece fora de `mix test` e `mix check`, exige que o runtime já tenha
habilitado o adaptador OpenRouter, faz uma única pergunta sintética curta e só
imprime resultado, quantidade de deltas e presença de usage. Antes de rodá-lo,
defina e aprove o teto financeiro; para validar cancelamento, use o cliente de
staging e envie `chat:cancel` logo depois de `chat:started`, verificando o
evento terminal `cancelled` e a interrupção do stream no log seguro.

## 4. Critério de saída

O Pages conversa com o modelo escolhido via OpenRouter sem mudança no protocolo.
Chave, prompt e conteúdo não aparecem no cliente ou nos logs; cancelamento
interrompe a chamada; limites técnicos e financeiros estão ativos; a suíte padrão
continua totalmente offline.
