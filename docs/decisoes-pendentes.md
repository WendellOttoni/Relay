# Decisões pendentes e evolutivas

As decisões técnicas necessárias para iniciar foram aceitas em ADRs. Este
documento separa o que já foi resolvido do que depende de evidência do produto.

## 1. Linguagem e framework do backend

Status: **Resolvida pela ADR 0003**

Critérios:

- bom suporte a HTTP streaming e cancelamento;
- configuração e secret management simples;
- testes de integração sem dependências externas;
- suporte no serviço de hospedagem escolhido;
- observabilidade e rate limiting maduros;
- familiaridade do mantenedor;
- custo de build, cold start e memória aceitável.

Decisão: Elixir 1.20, Erlang/OTP 29 e Phoenix 1.8, sem Ecto no primeiro projeto.

## 2. Hospedagem do backend

Status: **Resolvida para o experimento pela ADR 0005**

Validar com um protótipo:

- streaming sem buffering indevido;
- timeout máximo;
- cold start;
- variáveis secretas;
- domínio HTTPS;
- logs, health checks e rollback;
- limites e custo após o free tier.

Decisão atual: Render Free. A validação acima é o critério para mantê-lo, não um
bloqueio para iniciar o código.

## 3. Formato do streaming

Status: **Resolvida pela ADR 0004**

Decisão: Phoenix Channels/WebSocket entre navegador e Relay; SSE apenas entre
OpenRouter e seu adaptador. O experimento avaliará se o benefício de Channels
justifica a conexão persistente.

## 4. Proteção antiabuso

Status: **Estratégia inicial aceita pela ADR 0008**

CORS não resolve abuso direto. O experimento usa sessão anônima
curta, limites locais e teto financeiro. Antes de múltiplas instâncias, decidir
onde manter contadores distribuídos.

## 5. Provedor e modelo de IA

Status: **Provedor e modelo inicial resolvidos; validação operacional pendente**

OpenRouter foi aceita pela ADR 0006. O experimento inicial usará o identificador
configurado em `OPENROUTER_MODEL`; a escolha atual é `minimax/minimax-m3:free`.
Antes de expor a chave, ainda é necessário validar o modelo com perguntas
representativas e registrar custo, retenção, timeout e processo de rotação da
credencial.

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

Status: **Adiada pela ADR 0007**

Se necessária, definir autenticação, proprietário, retenção, exclusão, backup,
criptografia e quais dados nunca serão armazenados.

## 8. Função e personalidade do chatbot

Status: **Bloqueia a seleção final do modelo e prompt**

Definir:

- público e domínio de conhecimento;
- comportamento esperado e recusas;
- idiomas;
- necessidade de responder sobre documentos próprios;
- exemplos reais para avaliação;
- aviso de que a resposta pode conter erros.

O esqueleto, provedor falso e contrato podem ser implementados antes disso.

## 9. Orçamento do experimento

Status: **Bloqueia a exposição da chave real**

Definir valor máximo por dia ou mês, volume esperado, ação quando o teto for
atingido e quem recebe alertas. O chat deve falhar fechado quando desabilitado ou
sem orçamento.
