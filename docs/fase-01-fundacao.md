# Fase 1 — Fundação da API

Status: **Implementação concluída no código; publicação real no Render (F1.9) segue pendente**

## 1. Objetivo

Criar e publicar uma aplicação Phoenix mínima, sem chamar IA e sem acessar o
GitHub. Essa base deve provar toolchain, release, configuração, HTTPS, origem do
Pages, observabilidade, health checks, CI e o ciclo de deploy do Render.

## 2. Pré-requisitos

As decisões bloqueadoras foram aceitas nas ADRs 0003 a 0008. Para executar a
fase, ainda é necessário informar a URL real do GitHub Pages; até lá, exemplos e
testes usam uma origem sintética.

## 3. Dentro do escopo

- projeto Elixir/Phoenix sem HTML, assets, LiveView, mailer, Ecto ou banco;
- Elixir 1.20, Erlang/OTP 29 e Phoenix 1.8 com patches fixados;
- configuração por ambiente;
- endpoint `GET /health/live`;
- endpoint `GET /health/ready`;
- middleware de request ID;
- formato comum de erros;
- CORS com lista explícita;
- origem HTTP e WebSocket derivada da mesma configuração;
- limites básicos de requisição;
- logs estruturados e seguros;
- testes unitários e de integração;
- CI e primeiro deploy de desenvolvimento;
- documentação para execução local.

## 4. Fora do escopo

- chamada a qualquer modelo de IA;
- endpoint real de chat;
- autenticação GitHub;
- leitura ou escrita em repositórios;
- banco de dados e histórico;
- contas de usuário;
- painel administrativo;
- múltiplos serviços ou microsserviços.

## 5. Backlog executável

### F1.1 — Fixar toolchain e decisões

Entregáveis:

- versões patch de Erlang/OTP, Elixir e Phoenix registradas;
- gerenciador de toolchain escolhido e arquivo versionado;
- ADRs 0003 a 0008 referenciadas pelo README;
- processo explícito para atualizar dependências.

Aceite: um clone limpo instala a mesma toolchain e todas as decisões necessárias
para gerar o projeto estão documentadas.

### F1.2 — Inicializar o projeto

Entregáveis:

- aplicação OTP `relay` e namespace `Relay`;
- Phoenix sem camadas de frontend e sem Repo;
- Bandit/Endpoint, Router e supervisão padrão reconhecíveis;
- `mix format`, compilação com warnings como erro e `mix test` documentados.

Aceite: `mix deps.get`, formatação, compilação e testes passam sem warnings.

### F1.3 — Configurar ambientes

Configurações conceituais iniciais:

| Chave | Finalidade |
| --- | --- |
| ambiente | desenvolvimento, preview ou experimento |
| URL/origem permitida | CORS e `check_origin` explícitos |
| nível de log | diagnóstico sem conteúdo |
| timeout da requisição | trabalho externo limitado |
| tamanho máximo | proteção de entrada |
| request concurrency | proteção de recursos |

O contrato completo está em [configuração](configuracao.md).

Aceite: valores ausentes ou inválidos impedem prontidão e exibem erro seguro.

### F1.4 — Padronizar respostas e erros

Entregáveis:

- request ID aceito ou gerado pelo servidor;
- formato JSON comum de erro;
- mapeamento mínimo para `400`, `403`, `404`, `413`, `429` e `5xx`;
- tratamento global sem stack trace público.

Aceite: testes de contrato validam status, content type, código e request ID.

### F1.5 — Implementar health checks

Entregáveis:

- liveness que verifica somente o processo;
- readiness que considera configuração obrigatória;
- comportamento correto durante startup e encerramento.

Aceite: a plataforma de hospedagem consegue decidir quando enviar tráfego.

### F1.6 — Configurar origens

Entregáveis:

- origens permitidas por configuração;
- métodos e headers mínimos;
- política distinta para desenvolvimento e produção;
- `check_origin` do Phoenix Endpoint usando a mesma lista validada;

Aceite: a origem do Pages funciona em HTTP e WebSocket; origem inesperada não
recebe autorização; produção não aceita curinga, origem nula ou localhost.

### F1.7 — Adicionar observabilidade

Entregáveis:

- logs estruturados de startup, request e encerramento;
- duração e status por requisição;
- redaction de headers sensíveis;
- teste que procura um segredo conhecido na saída capturada.

Aceite: uma falha pode ser correlacionada pelo request ID sem registrar conteúdo.

### F1.8 — Configurar CI

Entregáveis:

- `mix format --check-formatted`, compilação com warnings como erro e testes;
- auditoria de dependências;
- análise estática de segurança adequada ao Phoenix;
- proteção contra commit acidental de segredos, quando viável.

Aceite: uma falha impede integração no `main` e a suíte não requer serviço pago.

### F1.9 — Publicar experimento no Render

Entregáveis:

- release Phoenix e deploy reproduzível por configuração versionada;
- segredos/configuração pela plataforma;
- health checks acessíveis por HTTPS;
- rollback documentado.

Aceite: após inclusive um cold start, o navegador acessa health checks por HTTPS
e uma origem não permitida continua recusada.

### F1.10 — Documentar desenvolvimento local

Entregáveis:

- pré-requisitos, build, execução e testes;
- exemplo de configuração sem segredo;
- forma de apontar um frontend local e o cliente Phoenix para a API;
- diagnóstico de erros comuns.

Aceite: instruções funcionam a partir de um clone limpo.

## 6. Testes mínimos

- configuração padrão de desenvolvimento;
- rejeição de configuração do experimento incompleta;
- geração e propagação de request ID;
- formato seguro para erro não tratado;
- liveness e readiness;
- preflight da origem permitida;
- ausência de autorização CORS para origem inesperada;
- recusa de handshake WebSocket vindo de origem inesperada;
- rejeição de corpo acima do limite;
- ausência de segredo conhecido nos logs;
- encerramento sem aceitar novas requisições.

## 7. Critério de saída

A fase termina quando o Phoenix está publicado por HTTPS, health checks
funcionam, as origens HTTP/WebSocket estão protegidas, logs são seguros, a CI
está verde e o processo é reproduzível a partir de um clone limpo. Nenhuma
chamada de IA, sessão real, Channel de chat ou integração GitHub deve ter sido
implementada antecipadamente.

O passo seguinte será criar sessão anônima, socket e Channel com provedor
simulado, validando eventos, reconexão e cancelamento antes de usar uma chave
real.
