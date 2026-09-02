# Fase 1 — Fundação da API

Status: **Aguardando decisões da Fase 0**

## 1. Objetivo

Criar e publicar uma API mínima, sem chamar IA e sem acessar o GitHub. Essa base
deve provar configuração, HTTPS, CORS, observabilidade, health checks, CI e o
ciclo de deploy que será usado pelo chat.

## 2. Pré-requisitos

Antes da primeira implementação:

- aceitar uma ADR de linguagem e framework;
- escolher um serviço para a prova de deploy;
- definir a origem de desenvolvimento e a origem do GitHub Pages;
- escolher o formato inicial de streaming;
- definir a política mínima de versões e dependências.

Consulte [decisões pendentes](decisoes-pendentes.md).

## 3. Dentro do escopo

- projeto executável do backend;
- configuração por ambiente;
- endpoint `GET /health/live`;
- endpoint `GET /health/ready`;
- middleware de request ID;
- formato comum de erros;
- CORS com lista explícita;
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

### F1.1 — Aceitar decisões técnicas

Entregáveis:

- ADR da stack;
- ADR do streaming;
- registro do ambiente de deploy para a prova.

Aceite: outra pessoa consegue explicar por que as escolhas atendem streaming,
segredos, testes, custo e experiência do mantenedor.

### F1.2 — Inicializar o projeto

Entregáveis:

- solução/projeto mínimo;
- configuração de versão da ferramenta;
- build, lint e testes locais documentados.

Aceite: um clone limpo compila sem warnings e executa os testes.

### F1.3 — Configurar ambientes

Configurações conceituais iniciais:

| Chave | Finalidade |
| --- | --- |
| ambiente | desenvolvimento, preview ou produção |
| URL/origem permitida | CORS explícito |
| nível de log | diagnóstico sem conteúdo |
| timeout da requisição | trabalho externo limitado |
| tamanho máximo | proteção de entrada |
| request concurrency | proteção de recursos |

Aceite: valores ausentes ou inválidos impedem prontidão e exibem erro seguro.

### F1.4 — Padronizar respostas e erros

Entregáveis:

- request ID aceito ou gerado pelo servidor;
- formato JSON comum de erro;
- mapeamento mínimo para `400`, `401`, `403`, `404`, `429` e `5xx`;
- tratamento global sem stack trace público.

Aceite: testes de contrato validam status, content type, código e request ID.

### F1.5 — Implementar health checks

Entregáveis:

- liveness que verifica somente o processo;
- readiness que considera configuração obrigatória;
- comportamento correto durante startup e encerramento.

Aceite: a plataforma de hospedagem consegue decidir quando enviar tráfego.

### F1.6 — Configurar CORS

Entregáveis:

- origens permitidas por configuração;
- métodos e headers mínimos;
- política distinta para desenvolvimento e produção.

Aceite: a origem do Pages funciona; origem inesperada não recebe autorização do
navegador; não existe curinga com credenciais.

### F1.7 — Adicionar observabilidade

Entregáveis:

- logs estruturados de startup, request e encerramento;
- duração e status por requisição;
- redaction de headers sensíveis;
- teste que procura um segredo conhecido na saída capturada.

Aceite: uma falha pode ser correlacionada pelo request ID sem registrar conteúdo.

### F1.8 — Configurar CI

Entregáveis:

- build, formatação, lint e testes em pull requests;
- auditoria de dependências;
- proteção contra commit acidental de segredos, quando viável.

Aceite: uma falha impede integração no `main` e a suíte não requer serviço pago.

### F1.9 — Publicar ambiente de desenvolvimento

Entregáveis:

- deploy reproduzível;
- segredos/configuração pela plataforma;
- health checks acessíveis por HTTPS;
- rollback documentado.

Aceite: o frontend ou um navegador consegue acessar a API respeitando CORS.

### F1.10 — Documentar desenvolvimento local

Entregáveis:

- pré-requisitos, build, execução e testes;
- exemplo de configuração sem segredo;
- forma de apontar um frontend local para a API;
- diagnóstico de erros comuns.

Aceite: instruções funcionam a partir de um clone limpo.

## 6. Testes mínimos

- configuração padrão de desenvolvimento;
- rejeição de configuração de produção incompleta;
- geração e propagação de request ID;
- formato seguro para erro não tratado;
- liveness e readiness;
- preflight da origem permitida;
- ausência de autorização CORS para origem inesperada;
- rejeição de corpo acima do limite;
- ausência de segredo conhecido nos logs;
- encerramento sem aceitar novas requisições.

## 7. Critério de saída

A fase termina quando a API está publicada por HTTPS, health checks funcionam,
CORS permite o frontend esperado, logs são seguros, a CI está verde e o processo
é reproduzível a partir de um clone limpo. Nenhuma chamada de IA ou GitHub deve
ter sido implementada antecipadamente.

O passo seguinte será criar um endpoint de chat com provedor simulado e validar
streaming e cancelamento antes de usar uma chave real.
