# Plano de desenvolvimento

Status: **Planejado**  
Última revisão: **2026-09-02**

## 1. Objetivo

Construir uma API pequena e segura que permita a um frontend estático conversar
com um provedor de IA sem expor credenciais. Integrações com a API do GitHub
serão adicionadas somente quando o caso de uso exigir.

## 2. Ordem de desenvolvimento

```text
decisões técnicas
       |
       v
fundação HTTP + configuração + CI
       |
       v
chat simulado + contrato + streaming
       |
       v
provedor real + limites + cancelamento
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
| 0 — Decisões | Stack, hosting de prova e streaming definidos | ADRs aceitas |
| 1 — Fundação | API mínima, config, CORS, health, logs e CI | deploy acessível |
| 2 — Chat simulado | Contrato e streaming sem IA real | frontend recebe deltas |
| 3 — IA | Adaptador real, timeout, limites e cancelamento | conversa controlada |
| 4 — Integração | Site do Pages usando Relay | fluxo completo em produção |
| 5 — Proteção | Antiabuso, orçamento e autenticação necessária | uso sustentável |
| 6 — GitHub | Login ou ferramentas autorizadas, se necessário | permissões mínimas |
| 7 — Estabilização | testes, privacidade, métricas e documentação | release v1 |

## 4. Estrutura lógica

Independentemente da linguagem, o código deve separar:

- **API:** HTTP, validação, CORS e representação de erros;
- **Application:** caso de uso do chat e políticas de limite;
- **Domain:** tipos independentes de framework e provedor;
- **Integrations:** adaptadores de IA e GitHub;
- **Infrastructure:** configuração, logs, métricas e persistência;
- **Host:** composição, startup, prontidão e encerramento.

O MVP pode existir em um único projeto. Separação lógica não significa criar
vários pacotes, serviços ou repositórios prematuramente.

## 5. Regras de dependência

```text
HTTP ------> caso de uso ------> domínio
  |               |
  |               v
  +--------> porta do provedor <------ adaptador de IA

host ------> configuração / observabilidade
```

- O domínio não referencia framework web nem SDK de IA.
- O caso de uso depende de uma interface de provedor.
- O adaptador converte tipos externos para tipos internos.
- A API não retorna objetos do SDK de terceiros.
- A integração GitHub não é dependência obrigatória do chat.

## 6. Estratégia de testes

| Nível | Validação |
| --- | --- |
| Unitário | regras, limites, erros e montagem do pedido |
| Contrato | JSON, status HTTP e sequência de eventos |
| Integração | pipeline HTTP com provedor simulado |
| Segurança | CORS, tamanho máximo, headers e dados em logs |
| Falhas | timeout, cancelamento, rate limit e provedor indisponível |
| Ponta a ponta | frontend publicado chamando ambiente do Relay |

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
| Resposta interrompida | streaming com cancelamento e erro explícito |
| Acoplamento ao provedor | porta interna e adaptador |
| Dados sensíveis em logs | política deny-by-default e testes |
| Free tier incompatível | prova de streaming, timeout e cold start |
| Escopo crescer cedo | GitHub, banco e múltiplos modelos após o MVP |

## 11. Próxima ação

Resolver as decisões bloqueadoras e executar a
[Fase 1: fundação](fase-01-fundacao.md). Não iniciar autenticação GitHub ou banco
antes de validar o chat simulado entre o Pages e o Relay.
