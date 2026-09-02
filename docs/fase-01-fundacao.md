# Fase 1 — Fundação do projeto

Status: **Pronta para iniciar**  
Marco relacionado: **v0.1**

## 1. Objetivo

Criar uma base compilável, testável e observável para receber o domínio do
broker na fase seguinte. Esta fase não implementa filas, publicação, consumo,
protocolo de mensagens nem persistência.

## 2. Resultado demonstrável

Ao final da fase deve ser possível:

```console
$ relay-server --config relay.toml
INFO relay_server: servidor iniciado
INFO relay_server: configuração carregada
INFO relay_server: aguardando encerramento
```

O processo deve:

- iniciar com configuração padrão ou arquivo informado;
- rejeitar configuração inválida com mensagem clara;
- produzir logs estruturados;
- responder a uma verificação simples de saúde;
- receber um sinal de encerramento;
- finalizar recursos dentro de um prazo configurado.

O exemplo representa comportamento planejado; comandos e mensagens finais serão
definidos durante a implementação.

## 3. O que está dentro do escopo

- workspace Rust;
- crate executável `relay-server`;
- módulo de configuração;
- modelo comum de erros na fronteira da aplicação;
- inicialização de logging/tracing;
- ciclo de vida e desligamento seguro;
- verificação de saúde mínima;
- testes unitários e de processo;
- CI e automações de qualidade;
- documentação para desenvolvimento local.

## 4. O que está fora do escopo

- filas e tópicos;
- comandos `PUBLISH`, `CONSUME`, `ACK` ou `NACK`;
- protocolo público definitivo;
- autenticação e TLS;
- armazenamento de mensagens;
- retry, TTL e dead-letter queues;
- SDKs e benchmarks de throughput;
- otimizações de desempenho.

Se uma tarefa exigir algum desses itens, ela deve ser adiada para a fase
correspondente, e não incorporada silenciosamente à Fase 1.

## 5. Sequência de implementação

### F1.1 — Inicializar o workspace

Entregáveis:

- `Cargo.toml` na raiz;
- crate binária `crates/relay-server`;
- toolchain e edição Rust documentadas;
- comandos locais de build, lint e teste.

Critérios de aceite:

- `cargo build --workspace` conclui sem warnings;
- `cargo test --workspace` conclui com sucesso;
- o binário imprime sua versão;
- um clone limpo consegue reproduzir os comandos documentados.

### F1.2 — Definir configuração

Configurações iniciais propostas:

| Chave | Finalidade | Comportamento inicial |
| --- | --- | --- |
| `server.bind` | Endereço local de escuta | Valor seguro para desenvolvimento |
| `server.shutdown_timeout` | Prazo de encerramento | Limitado e maior que zero |
| `limits.max_connections` | Proteção contra conexões ilimitadas | Obrigatoriamente limitado |
| `limits.max_frame_size` | Proteção antes da alocação | Obrigatoriamente limitado |
| `observability.log_level` | Nível de logs | Validado na inicialização |
| `data.directory` | Futuro diretório de dados | Caminho explícito e validado |

Precedência proposta:

```text
argumentos CLI > variáveis de ambiente > arquivo > valores padrão
```

Critérios de aceite:

- configuração padrão é válida;
- arquivo inexistente ou inválido produz erro com contexto;
- valores fora de limite são recusados antes de iniciar o servidor;
- precedência possui testes;
- segredos não aparecem em logs ou mensagens de erro.

### F1.3 — Padronizar erros e diagnóstico

Entregáveis:

- erros tipados dentro dos módulos;
- contexto legível na fronteira do executável;
- código de saída diferente de zero em falha de inicialização;
- convenção de campos para logs estruturados.

Critérios de aceite:

- nenhuma falha esperada depende de `panic`;
- mensagens indicam operação e causa;
- detalhes internos não são enviados a futuros clientes;
- payloads e segredos não são registrados.

### F1.4 — Implementar ciclo de vida

Estados propostos:

```text
starting -> ready -> draining -> stopped
    |                     |
    +--------> failed <---+
```

Critérios de aceite:

- o servidor sinaliza quando está pronto;
- um encerramento solicitado deixa de aceitar novo trabalho;
- recursos recebem prazo para finalizar;
- uma segunda solicitação pode forçar o encerramento;
- testes não dependem do processo ficar aguardando indefinidamente.

### F1.5 — Adicionar verificação de saúde

A Fase 1 precisa apenas de uma prova simples de que o processo está vivo e
pronto. Ela não deve definir prematuramente a API administrativa final.

Critérios de aceite:

- diferencia estado vivo de estado pronto;
- possui timeout e tamanho de resposta limitados;
- deixa de indicar prontidão durante o encerramento;
- pode ser validada por teste de integração.

Uma ADR deve decidir se essa verificação será HTTP, comando administrativo TCP
ou outro mecanismo antes de a tarefa ser implementada.

### F1.6 — Configurar qualidade contínua

A CI deve executar, no mínimo:

```console
cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cargo doc --workspace --no-deps
```

Também deve existir uma verificação de dependências e vulnerabilidades. A
ferramenta e sua política serão escolhidas durante esta tarefa e documentadas.

Critérios de aceite:

- a CI executa em pull requests e no `main`;
- falha de formatação, lint ou teste bloqueia a integração;
- builds e testes não dependem de serviços externos;
- cache melhora tempo, mas não é necessário para correção.

### F1.7 — Documentar execução local

Entregáveis:

- pré-requisitos;
- build e execução;
- configuração de exemplo sem segredos;
- execução de testes e lints;
- solução de erros locais frequentes.

Critérios de aceite:

- instruções funcionam a partir de um clone limpo;
- comandos são compatíveis com a CI;
- nenhum arquivo local ou segredo precisa ser versionado.

## 6. Backlog inicial sugerido

| Ordem | Issue sugerida | Resultado |
| --- | --- | --- |
| 1 | `chore: initialize Rust workspace` | Workspace e binário mínimo |
| 2 | `chore: add formatting, lint and test CI` | Proteções do `main` |
| 3 | `feat(server): load and validate configuration` | Configuração determinística |
| 4 | `feat(server): initialize structured tracing` | Diagnóstico padronizado |
| 5 | `feat(server): model application lifecycle` | Estados explícitos |
| 6 | `docs: decide health check transport` | ADR aceita |
| 7 | `feat(server): expose liveness and readiness` | Saúde testável |
| 8 | `feat(server): implement graceful shutdown` | Encerramento controlado |
| 9 | `test: verify server process lifecycle` | Teste de ponta a ponta da fase |
| 10 | `docs: add local development guide` | Fase reproduzível |

Cada issue deve copiar os critérios relevantes deste documento e permanecer
pequena o suficiente para um pull request focado.

## 7. Testes mínimos da fase

- inicialização com valores padrão;
- inicialização com arquivo válido;
- rejeição de configuração inválida;
- precedência das fontes de configuração;
- disponibilidade da verificação de saúde após prontidão;
- remoção da prontidão durante encerramento;
- encerramento normal dentro do prazo;
- código de saída correto após falha de inicialização;
- ausência de segredo conhecido nos logs capturados.

## 8. Decisões que bloqueiam tarefas

Antes da respectiva implementação, devem ser resolvidas:

1. runtime assíncrono e modelo inicial de concorrência;
2. transporte da verificação de saúde;
3. formato do arquivo e prefixo das variáveis de ambiente;
4. política de versão mínima do Rust;
5. ferramentas de auditoria e política de atualização de dependências.

Cada decisão deve ser pequena. Runtime e transporte de saúde provavelmente
merecem ADR; convenções reversíveis podem ser registradas no próprio pull
request e na documentação de desenvolvimento.

## 9. Critério de saída da Fase 1

A Fase 1 termina somente quando:

- todos os itens F1.1 a F1.7 atendem aos critérios de aceite;
- a CI está verde no `main`;
- o binário inicia, fica pronto e encerra de forma controlada;
- a configuração inválida falha antes de abrir recursos;
- a verificação de saúde é coberta por teste de integração;
- os comandos de desenvolvimento funcionam em clone limpo;
- limitações e decisões tomadas estão documentadas;
- nenhuma funcionalidade de mensageria foi implementada antecipadamente.

## 10. Preparação da Fase 2

Após concluir esta fase, criar a especificação da máquina de estados do domínio
com cenários de publish, entrega, ACK, NACK e timeout. Somente então devem nascer
`relay-core` e as primeiras filas em memória.
