# Relay

> Backend seguro para conectar aplicações estáticas a serviços de IA e ao GitHub.

O Relay será a API utilizada por um frontend hospedado no GitHub Pages. O site
continua estático e gratuito; operações que exigem segredos, autenticação,
controle de uso ou acesso a APIs externas são executadas pelo Relay, hospedado
separadamente.

> [!IMPORTANT]
> O projeto está na fase de planejamento. Ainda não existe uma API pronta para
> uso e a tecnologia do backend ainda será decidida.

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
Relay API em outro serviço
   |
   +----> Provedor de IA
   |
   +----> GitHub API / GitHub App (quando necessário)
   |
   +----> Banco ou cache (fase posterior)
```

Hospedar o frontend gratuitamente não torna gratuitas as APIs consumidas. O
serviço de IA, o backend ou o banco podem possuir limites ou custos próprios.

## Primeiro caso de uso: chat

O fluxo inicial planejado é:

1. o usuário abre o site no GitHub Pages;
2. o frontend envia a mensagem por HTTPS ao Relay;
3. o Relay valida origem, sessão, tamanho e limite de uso;
4. o Relay adiciona apenas o contexto permitido e chama o provedor de IA;
5. a resposta é transmitida gradualmente ao navegador;
6. erros são convertidos para um formato seguro e rastreável.

```text
Browser                  Relay                 Provedor de IA
   |                       |                          |
   |--- POST /api/chat --->|                          |
   |                       |------ request --------->|
   |<------ stream --------|<----- stream -----------|
   |                       |                          |
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
| API | Endpoint versionado de chat |
| Resposta | Streaming para o navegador |
| Segurança | Segredos no servidor, validação e limites |
| Navegador | CORS restrito ao domínio configurado |
| Operação | Health checks, logs e identificador de requisição |
| Integração | Adaptador para um provedor de IA |
| Deploy | Backend HTTPS configurado por variáveis de ambiente |

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
2. valide a [arquitetura](docs/arquitetura.md);
3. decida a tecnologia usando os critérios registrados em
   [decisões pendentes](docs/decisoes-pendentes.md);
4. execute a [Fase 1: fundação](docs/fase-01-fundacao.md);
5. siga o [plano de desenvolvimento](docs/plano-de-desenvolvimento.md).

## Situação atual

- [x] Propósito e fronteiras definidos.
- [x] Arquitetura inicial documentada.
- [x] MVP e fases planejados.
- [x] Riscos de segurança registrados.
- [ ] Tecnologia do backend escolhida.
- [ ] Contrato HTTP validado.
- [ ] Implementação iniciada.

## Licença

Relay está disponível sob a [Licença MIT](LICENSE).
