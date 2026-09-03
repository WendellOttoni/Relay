# Fase 2 — Chat simulado por Phoenix Channels

Status: **Implementada (backend, F2.1–F2.6); F2.7 depende do cliente
JavaScript no repositório do frontend, fora deste backend**

## 1. Objetivo

Provar sessão anônima, WebSocket, eventos incrementais, supervisão, reconexão e
cancelamento sem acessar a OpenRouter ou qualquer serviço pago.

## 2. Dentro do escopo

- endpoint de criação de sessão com validador Turnstile substituível;
- token Phoenix curto e conexão autenticada;
- `UserSocket` e `ChatChannel`;
- porta interna de provedor e implementação falsa;
- Task Supervisor para gerações;
- eventos definidos em [protocolo-channels.md](protocolo-channels.md);
- limites por sessão em memória;
- página ou cliente mínimo de teste fora do backend;
- testes de contrato, falha e desconexão.

Ficam fora: chave OpenRouter, banco, login, ferramentas e persistência.

## 3. Backlog executável

### F2.1 — Criar sessões anônimas

- definir behaviour para validação Turnstile;
- usar implementação sempre controlável nos testes;
- emitir `sessionId`, token assinado e expiração;
- rejeitar payload, origem, hostname, action e token inválidos;
- limitar criação repetida de sessões.

Aceite: testes HTTP cobrem sucesso, expiração, reutilização, `403` e `429` sem
chamar a Cloudflare.

### F2.2 — Autenticar socket e tópico

- configurar `/socket` somente com WebSocket;
- validar token e expiração em `connect/3`;
- atribuir `session_id` sem copiar o token para logs;
- permitir somente o tópico pertencente à sessão;
- recusar origem inesperada antes de entrar no Channel.

Aceite: testes de Channel provam isolamento entre duas sessões.

### F2.3 — Definir porta e provedor falso

- criar tipos internos de mensagem e evento;
- criar behaviour do provedor sem dependência de Phoenix;
- implementar fake determinístico configurável por teste;
- simular deltas, usage, término, falha, lentidão e espera infinita cancelável.

Aceite: testes unitários não usam timer real desnecessário nem internet.

### F2.4 — Executar geração supervisionada

- adicionar `Task.Supervisor` à árvore da aplicação;
- iniciar tarefa monitorada e desacoplada do processo do Channel;
- fazer Channel e worker monitorarem um ao outro;
- enviar eventos internos ao Channel por mensagens;
- publicar sequência monotônica de deltas;
- manter uma geração ativa por sessão.

Aceite: falha do fake não derruba o Channel nem o Endpoint e produz erro seguro.

### F2.5 — Cancelar e encerrar

- implementar `chat:cancel` idempotente;
- cancelar na saída normal e também quando o worker detectar `DOWN` do Channel;
- limpar monitor e estado em sucesso, erro ou cancelamento;
- garantir que eventos tardios de uma tarefa antiga sejam ignorados.

Aceite: testes comprovam encerramento da tarefa e ausência de deltas depois do
cancelamento.

### F2.6 — Aplicar contrato e limites

- validar roles, conteúdo, quantidade, bytes e campos desconhecidos;
- gerar `requestId` e `generationId` no servidor;
- implementar replies e pushes exatamente conforme o protocolo;
- limitar frequência e concorrência com contadores locais;
- não registrar payloads de eventos.

Aceite: testes de contrato cobrem sequência feliz e cada erro público.

### F2.7 — Validar cliente do frontend

- instalar o cliente JavaScript oficial do Phoenix no frontend;
- criar sessão, conectar, entrar no tópico e enviar `chat:generate`;
- montar texto sem presumir fronteiras de palavras;
- cancelar, tratar heartbeat e reconectar;
- exibir estados acordando, conectando, gerando, concluído e erro.

Aceite: um navegador recebe deltas do fake hospedado no Render e consegue
cancelar uma geração lenta.

## 4. Testes mínimos

- sessão válida, inválida, expirada e limitada;
- token de socket inválido e tópico de outra sessão;
- origem WebSocket aceita e recusada;
- geração feliz com ordenação de eventos;
- segunda geração concorrente recusada;
- histórico e conteúdo nos limites e além deles;
- falha antes e depois de deltas;
- cancelamento explícito, saída e desconexão;
- queda da Task sem queda do Channel;
- nenhum conteúdo sensível na captura de logs.

## 5. Critério de saída

O frontend hospedado consegue acordar o Render, criar sessão, conectar ao
Phoenix, receber texto incremental de um fake e cancelar a geração. Todos os
testes passam sem Cloudflare, OpenRouter, banco ou serviço pago.
