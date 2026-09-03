# Roadmap

O roadmap não possui datas artificiais. Cada marco termina quando seu
comportamento pode ser demonstrado e seus critérios estão automatizados.

## v0.1 — Fundação

- Elixir/Phoenix, Channels e Render registrados em ADRs;
- aplicação OTP mínima com configuração validada;
- health checks, request ID, erros e logs;
- CORS e origem do socket restritos;
- CI e release publicados no Render Free.

**Saída:** o frontend consegue acordar e acessar um Phoenix vazio por HTTPS.

## v0.2 — Channel com chat simulado

- sessão anônima, socket e protocolo versionado;
- provedor falso determinístico;
- eventos por Phoenix Channels e cancelamento da Task;
- estados de loading, sucesso e erro no frontend de teste;
- Turnstile simulado, limites locais e testes de desconexão.

**Saída:** o Pages conversa por WebSocket com o Relay sem chave ou custo externo.

## v0.3 — OpenRouter

- adaptador Req/SSE da OpenRouter;
- segredo apenas no backend;
- timeout, limites de contexto e saída;
- erros normalizados;
- Turnstile real, teto financeiro e chave de emergência;
- métricas agregadas de duração e consumo, sem conteúdo.

**Saída:** chat real funciona dentro de um orçamento baixo sem expor credenciais
nem conteúdo em logs.

## v0.4 — Integração com GitHub Pages

- URLs HTTP/WebSocket configuradas no build do frontend;
- CORS e `check_origin` do Pages;
- cold start, heartbeat e reconexão validados no navegador;
- mensagens de erro e retry adequadas;
- documentação de deploy e rollback.

**Saída:** usuário acessa o Pages e conversa pelo Relay em produção.

## v0.5 — Proteção pública

- revisão do mecanismo antiabuso experimental;
- limites distribuídos se houver múltiplas instâncias;
- orçamento, alertas e resposta a incidentes;
- tratamento de indisponibilidade e overload;
- política de privacidade.

**Saída:** o endpoint pode permanecer público dentro de limites conhecidos.

## v0.6 — Integração GitHub opcional

- autenticação adequada ao caso de uso;
- permissões mínimas;
- consentimento explícito;
- contexto de repositório delimitado;
- auditoria de operações sensíveis.

**Saída:** caso de uso GitHub definido funciona sem ampliar permissões do chat.

## v0.7 — Persistência opcional

- contas e propriedade dos dados;
- armazenamento de conversas, se necessário;
- retenção, exclusão e exportação;
- migrações e backup;
- testes de autorização.

**Saída:** dados persistidos possuem ciclo de vida e dono claros.

## v1.0 — Estabilização

- contrato e política de compatibilidade;
- segurança e privacidade revisadas;
- observabilidade e runbooks;
- testes de carga e limites publicados;
- instalação, operação e contribuição documentadas.

**Saída:** garantias e limitações estão documentadas e verificadas.
