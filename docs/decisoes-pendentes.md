# Decisões pendentes

Estas decisões impedem ou alteram significativamente a implementação. Elas não
devem ser resolvidas por acidente no primeiro commit de código.

## 1. Linguagem e framework do backend

Status: **Bloqueia a Fase 1**

Critérios:

- bom suporte a HTTP streaming e cancelamento;
- configuração e secret management simples;
- testes de integração sem dependências externas;
- suporte no serviço de hospedagem escolhido;
- observabilidade e rate limiting maduros;
- familiaridade do mantenedor;
- custo de build, cold start e memória aceitável.

Opções iniciais a avaliar incluem ASP.NET Core, Node.js/TypeScript e Rust. A ADR
deve comparar apenas as opções que o mantenedor realmente aceitaria manter.

## 2. Hospedagem do backend

Status: **Bloqueia a prova de deploy**

Validar com um protótipo:

- streaming sem buffering indevido;
- timeout máximo;
- cold start;
- variáveis secretas;
- domínio HTTPS;
- logs, health checks e rollback;
- limites e custo após o free tier.

## 3. Formato do streaming

Status: **Bloqueia a Fase 2**

Comparar SSE sobre `fetch`, NDJSON e resposta JSON não transmitida como fallback.
WebSocket só entra na análise se surgir comunicação bidirecional contínua que
HTTP não resolva.

## 4. Proteção antiabuso

Status: **Bloqueia a exposição pública da IA**

CORS não resolve abuso direto. Avaliar desafio anti-bot, sessão anônima curta,
rate limiting, orçamento diário, login GitHub ou combinação dessas medidas.

## 5. Provedor de IA

Status: **Bloqueia a Fase 3**

Definir modelo permitido, custo, streaming, limites, retenção de dados, timeout,
política de erro e processo para trocar a credencial.

## 6. Papel da integração GitHub

Status: **Não bloqueia o chat inicial**

Responder antes de implementar:

- GitHub será apenas o host do frontend?
- haverá login com GitHub?
- o chat poderá ler repositórios?
- haverá escrita em arquivos, issues ou pull requests?
- as operações serão em nome do usuário ou de uma GitHub App instalada?

Cada resposta altera permissões e riscos. O princípio será conceder o menor
escopo possível e separar leitura de escrita.

## 7. Persistência de conversas

Status: **Adiada após o MVP**

Se necessária, definir autenticação, proprietário, retenção, exclusão, backup,
criptografia e quais dados nunca serão armazenados.
