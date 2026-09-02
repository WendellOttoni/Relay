# Arquitetura

## 1. Contexto

O frontend será um site estático hospedado no GitHub Pages. Ele executa no
navegador do usuário e pode fazer chamadas HTTPS, mas todo arquivo entregue ao
navegador é público. O Relay é uma API separada que protege credenciais e aplica
as regras necessárias antes de acessar serviços externos.

## 2. Visão geral

```text
                  limite público                    limite privado

+---------------------------+        +----------------------------------+
| GitHub Pages              | HTTPS  | Relay                            |
|                           +------->|                                  |
| HTML / CSS / JavaScript   |        | API + validação + limites        |
| estado visual do chat     |<-------+ streaming + tratamento de erros  |
+---------------------------+        +-----------+----------------------+
                                                |
                                      +---------+---------+
                                      |                   |
                                +-----v------+      +-----v------+
                                | Provedor  |      | GitHub API |
                                | de IA     |      | opcional   |
                                +-----------+      +------------+
```

O repositório Relay contém somente o backend e sua documentação. O frontend do
GitHub Pages pode estar em outro repositório e conhece apenas a URL pública da
API.

## 3. Componentes

### Frontend estático

Responsável por interface, estado visual, envio da mensagem, exibição do stream,
cancelamento e mensagens de erro amigáveis. Não contém segredo nem decide
permissões. A URL do Relay pode ser configuração pública de build.

### API HTTP

Recebe requisições versionadas, valida corpo e headers, atribui um identificador,
aplica autenticação quando existir, limita abuso e converte erros para um
contrato estável.

### Serviço de chat

Aplica regras independentes do provedor: tamanho do contexto, seleção de modelo
permitido, timeout, cancelamento, orçamento e formato da resposta. Não deve
conhecer detalhes do framework HTTP.

### Adaptador de IA

Traduz o pedido interno para o SDK ou HTTP do provedor e converte sua resposta
para eventos internos. Apenas esse componente conhece a credencial e o formato
específico do provedor.

### Integração com GitHub

É opcional e separada do chat. Pode oferecer login, leitura de contexto de um
repositório ou operações autorizadas. Deve usar permissões mínimas e nunca
aceitar do navegador um token administrativo para apenas retransmiti-lo.

### Persistência

Não é necessária para o primeiro chat. Inicialmente, o histórico pode permanecer
no navegador e ser enviado de forma limitada a cada interação. Persistência no
servidor exige política de retenção, exclusão, privacidade e autenticação.

## 4. Fluxo do chat

```text
1. Browser envia mensagem e contexto permitido.
2. API valida formato, origem, sessão, tamanho e limite.
3. Serviço de chat cria uma solicitação independente do provedor.
4. Adaptador chama a IA com segredo obtido do ambiente.
5. Eventos de texto são transmitidos ao browser.
6. Cancelamento ou desconexão interrompe a chamada externa.
7. Métricas registram duração e consumo, sem conteúdo da conversa.
```

## 5. Limites de confiança

- Tudo enviado pelo navegador é não confiável.
- A origem permitida no CORS é configuração, não evidência de identidade.
- Headers como usuário, repositório e permissão precisam ser verificados.
- Conteúdo retornado pela IA é dado não confiável para qualquer ferramenta.
- Uma futura ação no GitHub exige autorização específica no servidor.
- Logs e telemetria são tratados como armazenamento de dados.

## 6. Estrutura lógica proposta

A estrutura física dependerá da tecnologia escolhida, mas deve preservar estas
responsabilidades:

```text
src/
├── api/                # endpoints, contratos e middleware
├── application/        # casos de uso e políticas do chat
├── domain/             # tipos e regras independentes de infraestrutura
├── integrations/
│   ├── ai/             # adaptadores de provedores
│   └── github/         # autenticação e API do GitHub
├── infrastructure/     # configuração, observabilidade e persistência
└── host/               # composição e ciclo de vida

tests/
├── unit/
├── integration/
└── contract/
```

Isso não exige múltiplos projetos ou pacotes desde o primeiro dia. A separação
pode começar por pastas e evoluir quando houver necessidade real.

## 7. Requisitos transversais

- HTTPS obrigatório fora do ambiente local.
- CORS com lista explícita de origens.
- limite de tamanho antes de desserializar corpos grandes.
- timeout e cancelamento propagados ao provedor.
- rate limiting por sessão e sinais adicionais disponíveis.
- budgets de uso configuráveis.
- health checks distintos para processo vivo e pronto.
- logs estruturados sem prompts, respostas ou credenciais.
- identificador de requisição retornado ao cliente.
- interface de provedor substituível em testes.

## 8. Falhas esperadas

| Falha | Comportamento esperado |
| --- | --- |
| Corpo inválido | `400` com código estável |
| Sessão ausente quando exigida | `401` |
| Sem permissão | `403` |
| Limite excedido | `429` e orientação de retry |
| Provedor indisponível | `502` ou `503`, sem resposta bruta |
| Timeout | encerramento do stream e erro rastreável |
| Browser desconectado | cancelamento do trabalho externo |
| Configuração inválida | serviço não fica pronto |

## 9. Questões deliberadamente abertas

- linguagem e framework do backend;
- provedor e modelo de IA inicial;
- mecanismo antiabuso antes de existir login;
- formato exato do streaming;
- necessidade real de autenticação GitHub no MVP;
- serviço de hospedagem do Relay;
- retenção de conversas em fases futuras.

Essas escolhas estão organizadas em [decisões pendentes](decisoes-pendentes.md).
