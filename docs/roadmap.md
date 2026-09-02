# Roadmap

O roadmap não possui datas artificiais. Cada marco termina quando seu
comportamento pode ser demonstrado e seus critérios estão automatizados.

## v0.1 — Fundação

- stack e deploy decididos;
- API mínima com configuração validada;
- health checks, request ID, erros e logs;
- CORS restrito e limites básicos;
- CI e ambiente de desenvolvimento publicado.

**Saída:** o frontend consegue acessar uma API vazia e segura por HTTPS.

## v0.2 — Chat simulado

- contrato versionado;
- provedor falso determinístico;
- streaming e cancelamento;
- estados de loading, sucesso e erro no frontend de teste;
- testes de contrato e desconexão.

**Saída:** fluxo completo funciona sem chave e sem custo externo.

## v0.3 — Provedor de IA

- primeiro adaptador real;
- segredo apenas no backend;
- timeout, limites de contexto e saída;
- erros normalizados;
- métricas agregadas de duração e consumo.

**Saída:** chat real funciona sem expor credenciais nem conteúdo em logs.

## v0.4 — Integração com GitHub Pages

- URL do Relay configurada no build do frontend;
- CORS de produção;
- streaming validado no navegador;
- mensagens de erro e retry adequadas;
- documentação de deploy e rollback.

**Saída:** usuário acessa o Pages e conversa pelo Relay em produção.

## v0.5 — Proteção pública

- mecanismo antiabuso;
- limites por sessão e globais;
- orçamento e alertas;
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
