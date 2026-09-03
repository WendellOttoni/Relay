# Plano de desenvolvimento

Status: **Fases 1–3 implementadas no código (backend); Fase 3 aguarda decisão de modelo e orçamento antes da chave real; próximo passo é a Fase 4 (integração com o Pages)**
Última revisão: **2026-09-03**

## 1. Objetivo

Construir uma aplicação Phoenix pequena e segura que permita ao frontend do
GitHub Pages conversar em tempo real com um modelo acessado pela OpenRouter, sem
expor credenciais. O projeto também serve para experimentar concorrência,
supervisão e Channels na BEAM.

## 2. Ordem de desenvolvimento

```text
ADRs e toolchain
       |
       v
fundação Phoenix + configuração + CI + Render
       |
       v
sessão + Channel + provedor falso
       |
       v
OpenRouter SSE + limites + cancelamento
       |
       v
integração com frontend no GitHub Pages
       |
       v
autenticação / GitHub / persistência, se necessários
```

O contrato e os controles do Relay devem funcionar primeiro com um provedor
simulado. Isso evita usar custo externo para validar CORS, streaming, erros e
cancelamento.

## 3. Fases

| Fase | Entrega | Critério principal |
| --- | --- | --- |
| 0 — Decisões | Phoenix, Channels, Render e OpenRouter | concluída |
| 1 — Fundação | app OTP, config, origens, health, logs e CI | Render acessível |
| 2 — Chat simulado | sessão, socket, Channel e fake determinístico | frontend recebe eventos |
| 3 — OpenRouter | Req/SSE, timeout, limites e cancelamento | conversa controlada |
| 4 — Integração | Site do Pages usando Relay | fluxo completo em produção |
| 5 — Proteção | endurecer antiabuso, orçamento e autenticação necessária | uso sustentável |
| 6 — GitHub | Login ou ferramentas autorizadas, se necessário | permissões mínimas |
| 7 — Estabilização | testes, privacidade, métricas e documentação | release v1 |

## 4. Estrutura lógica

O código será uma aplicação OTP única, organizada por responsabilidade:

- **Relay.Chat:** tipos, caso de uso, limites e behaviour do provedor;
- **Relay.Integrations.OpenRouter:** Req, parsing SSE e tradução externa;
- **Relay.Sessions:** Turnstile e tokens anônimos;
- **Relay.RateLimit:** limites locais do experimento;
- **RelayWeb:** HTTP, socket, Channels, plugs e representação de erros;
- **supervision tree:** Task Supervisor e processos de infraestrutura.

Não criar umbrella, microsserviços, Repo ou abstrações genéricas sem necessidade.

## 5. Regras de dependência

```text
HTTP sessão ------> sessões / Turnstile

Channel ----------> caso de uso ------> tipos internos
   |                    |
   |                    v
   +--------------> porta do provedor <------ OpenRouter / fake

Application ------> supervisão / configuração / observabilidade
```

- Regras e tipos do chat não referenciam Phoenix nem o formato OpenRouter.
- O caso de uso depende de uma interface de provedor.
- O adaptador converte tipos externos para tipos internos.
- O Channel não publica objetos de biblioteca externa.
- A integração GitHub não é dependência obrigatória do chat.

## 6. Estratégia de testes

| Nível | Validação |
| --- | --- |
| Unitário | regras, limites, erros e montagem do pedido |
| Contrato | JSON HTTP, pushes, replies e sequência de eventos do Channel |
| Integração | Endpoint/Channel com provedor simulado e servidor SSE local |
| Segurança | CORS, tamanho máximo, headers e dados em logs |
| Falhas | timeout, cancelamento, rate limit e provedor indisponível |
| Ponta a ponta | frontend publicado criando sessão e conectando ao socket |

Testes comuns não devem consumir uma API paga. O adaptador real terá poucos
testes controlados, separados da suíte padrão e sem registrar conteúdo.

## 7. Processo por tarefa

1. confirmar fase e critérios de aceite;
2. registrar decisão difícil de reverter;
3. definir teste e impacto de segurança;
4. implementar o menor incremento observável;
5. executar formatação, lint, testes e auditoria;
6. verificar que nenhum segredo ou conteúdo foi registrado;
7. atualizar contrato e documentação;
8. integrar por pull request pequeno.

## 8. Definition of Done

Uma tarefa termina quando:

- critérios de aceite estão comprovados;
- entradas, tempo e recursos possuem limites;
- cancelamento é propagado quando aplicável;
- erros públicos são estáveis e seguros;
- logs possuem request ID e não possuem conteúdo sensível;
- testes não dependem desnecessariamente de internet ou API paga;
- documentação representa o comportamento entregue;
- CI está verde e o deploy pode ser revertido.

## 9. Observabilidade mínima

Registrar:

- request ID;
- rota e método;
- evento do Channel por nome, nunca seu payload;
- status e duração;
- provedor e modelo por identificador não secreto;
- sucesso, timeout, cancelamento ou erro categorizado;
- métricas agregadas de uso quando fornecidas.

Não registrar:

- mensagem, histórico ou resposta;
- prompts internos;
- headers de autenticação;
- chaves, cookies ou tokens;
- resposta bruta de erro do provedor.

## 10. Riscos

| Risco | Controle |
| --- | --- |
| Chave exposta no Pages | segredo existe apenas no ambiente do Relay |
| Endpoint público usado por terceiros | antiabuso, rate limit e orçamento |
| Custo inesperado de IA | limites por requisição e alertas agregados |
| Resposta interrompida | Task monitorada, cancelamento e erro explícito |
| Acoplamento ao provedor | porta interna e adaptador |
| Dados sensíveis em logs | política deny-by-default e testes |
| Free tier incompatível | prova de streaming, timeout e cold start |
| Escopo crescer cedo | GitHub, banco e múltiplos modelos após o MVP |

## 11. Próxima ação

As Fases 1 a 3 estão implementadas no backend (código e testes). A Fase 1
(fundação) só falta a publicação real no Render (F1.9); a Fase 2 (sessão,
socket e Channel com adaptador falso) está completa; a Fase 3 (OpenRouter) tem
o adaptador Req/SSE, cancelamento e observabilidade prontos, mas a chave real
segue bloqueada até a escolha do modelo e a definição de orçamento (ver
[decisões pendentes](decisoes-pendentes.md), seções 5 e 9).

O próximo passo é a [Fase 4: integração com o GitHub Pages](roadmap.md), que
depende do frontend estático apontar para o Relay publicado. Não ativar a chave
OpenRouter real, autenticação GitHub ou banco antes dessas decisões.
