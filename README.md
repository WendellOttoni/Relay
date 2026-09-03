# Relay

> Backend experimental em Elixir/Phoenix para conectar um frontend estático a
> modelos de IA pela OpenRouter.

O Relay será a API utilizada por um frontend hospedado no GitHub Pages. O site
continua estático e gratuito; operações que exigem segredos, autenticação,
controle de uso ou acesso a APIs externas são executadas pelo Relay, hospedado
separadamente.

> [!IMPORTANT]
> O Relay não oferece interface de usuário. Ele é um serviço de backend que
> permanece inativo por padrão (`CHAT_ENABLED=false`) e só atende gerações
> quando um consumidor autorizado — inicialmente o GitHub Pages — o utiliza.
> A fundação, o protocolo e o adaptador OpenRouter existem no código; não há
> deploy público validado nem consumidor frontend integrado.

## Por que existe um backend?

O GitHub Pages entrega HTML, CSS, JavaScript e arquivos gerados durante o build,
mas não executa um servidor de aplicação. O JavaScript do navegador consegue
chamar uma API externa, porém não pode guardar com segurança chaves de IA,
segredos OAuth ou tokens administrativos.

O Relay cria essa fronteira segura:

```text
Usuário
   |
   v
Frontend no GitHub Pages
   |
   | HTTPS
   v
Relay em Elixir/Phoenix no Render
   |
   +----> OpenRouter / modelo configurado
   |
   +----> GitHub API / GitHub App (quando necessário)
   |
   +----> Banco ou cache (fase posterior)
```

Hospedar o frontend gratuitamente não torna gratuitas as APIs consumidas. O
serviço de IA, o backend ou o banco podem possuir limites ou custos próprios.

## Stack escolhida

| Área | Decisão |
| --- | --- |
| Frontend | React/Vite no GitHub Pages, em repositório separado |
| Backend | Elixir 1.20, Erlang/OTP 29 e Phoenix 1.8 |
| Tempo real | Phoenix Channels sobre WebSocket |
| Cliente HTTP | Req |
| IA | OpenRouter, com chave e modelo controlados pelo Relay |
| Deploy experimental | Web Service gratuito do Render |
| Proteção | Turnstile, sessão anônima curta, limites e teto financeiro |
| Persistência | nenhuma no MVP; PostgreSQL/Ecto ficam adiados |

As versões patch serão fixadas ao inicializar o projeto. Somente versões estáveis
serão usadas.

## Primeiro caso de uso: chat

O fluxo inicial planejado é:

1. o frontend obtém um desafio Cloudflare Turnstile;
2. `POST /api/v1/sessions` valida o desafio e cria uma sessão anônima curta;
3. o cliente conecta ao socket Phoenix e entra em `chat:<sessionId>`;
4. `chat:generate` envia um histórico validado e limitado;
5. o Relay adiciona o prompt de sistema e chama a OpenRouter com streaming;
6. cada delta é convertido para um evento do Channel;
7. cancelamento ou desconexão encerram a tarefa e a chamada externa;
8. nenhum conteúdo da conversa é persistido ou registrado pelo Relay.

```text
Browser                Phoenix Channel               OpenRouter
   |                          |                           |
   |--- chat:generate ------>|                           |
   |                          |--- stream: true -------->|
   |<---- chat:delta --------|<------ delta -------------|
   |--- chat:cancel -------->|--- encerra requisição ---->|
```

Nenhuma chave do provedor será enviada ao frontend ou versionada no repositório.

## GitHub: hospedagem e integração são coisas diferentes

O GitHub participa do projeto de duas formas independentes:

- **GitHub Pages:** hospeda os arquivos estáticos do frontend.
- **GitHub API/GitHub App:** integração opcional para login, leitura de
  repositórios ou alterações autorizadas.

O chat pode funcionar sem acessar a API do GitHub. A integração com repositórios
só será adicionada quando houver um caso de uso e permissões claramente definidos.

## Escopo do MVP

| Área | Entrega inicial |
| --- | --- |
| API | Sessão anônima e health checks versionados |
| Resposta | Phoenix Channels com eventos versionados |
| Segurança | Segredos no servidor, validação e limites |
| Navegador | CORS restrito ao domínio configurado |
| Operação | Health checks, logs e identificador de requisição |
| Integração | Adaptador OpenRouter substituível por um provedor falso |
| Deploy | Release Phoenix no Render Free |

Login com GitHub, histórico persistente, múltiplos provedores, ferramentas para
repositórios e painel administrativo não bloqueiam o primeiro MVP.

## Princípios

1. **Segredos somente no backend.** O bundle do Pages é público.
2. **CORS não é autenticação.** Requisições precisam de proteção contra abuso.
3. **Poucos dados por padrão.** Não registrar prompts, respostas ou tokens.
4. **Provedor substituível.** A API pública não depende do formato de uma IA.
5. **Limites explícitos.** Tamanho, duração, concorrência e uso devem ser limitados.
6. **Streaming cancelável.** Desconectar o navegador cancela o trabalho restante.

## Planejamento

Antes de iniciar o código:

1. leia o [índice da documentação](docs/README.md);
2. consulte a [arquitetura](docs/arquitetura.md);
3. confira as decisões aceitas nos [ADRs](docs/adr/README.md);
4. implemente a [Fase 1: fundação](docs/fase-01-fundacao.md);
5. execute a [Fase 2: chat simulado](docs/fase-02-chat-simulado.md);
6. siga o [protocolo dos Channels](docs/protocolo-channels.md);
7. integre a OpenRouter na [Fase 3](docs/fase-03-openrouter.md).

## Situação atual

- [x] Propósito e fronteiras definidos.
- [x] Arquitetura inicial documentada.
- [x] MVP e fases planejados.
- [x] Riscos de segurança registrados.
- [x] Elixir/Phoenix e Phoenix Channels escolhidos.
- [x] OpenRouter, protocolo e hospedagem experimental definidos.
- [x] Persistência adiada conscientemente.
- [x] Contratos HTTP e WebSocket documentados.
- [x] Fundação HTTP, configuração, segurança de origem e CI implementadas.
- [x] Sessão anônima, socket, Channel e provedor falso implementados.
- [x] Adaptador Req/SSE da OpenRouter implementado.
- [x] Serviço seguro por padrão: chat desabilitado até configuração e decisão operacional explícitas.
- [ ] Deploy público no Render validado.
- [ ] Integração com o frontend do GitHub Pages.
- [ ] Aprovar orçamento/teto financeiro e executar o smoke manual da OpenRouter.

Consulte o [runbook operacional](docs/operacao.md) antes de habilitar o chat e
a [nota mínima de privacidade](docs/privacidade.md) antes de publicar um
consumidor.

## Licença

Relay está disponível sob a [Licença MIT](LICENSE).
