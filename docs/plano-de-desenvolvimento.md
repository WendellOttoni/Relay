# Plano de desenvolvimento

Status: **Planejado**  
Última revisão: **2026-09-02**

## 1. Objetivo

Desenvolver um message broker single-node em Rust para estudar e demonstrar,
de forma explícita, os fundamentos de sistemas de mensageria: filas, entrega,
confirmação, reentrega, backpressure, protocolo de rede e persistência.

O desenvolvimento deve produzir incrementos executáveis e testáveis. Cada fase
introduz apenas a complexidade necessária para validar o próximo comportamento.

## 2. Resultado esperado da primeira versão estável

A v1 deve permitir que processos independentes:

1. iniciem uma conexão TCP com o Relay;
2. criem filas e tópicos;
3. publiquem mensagens;
4. consumam mensagens individualmente ou em grupo;
5. confirmem ou rejeitem entregas;
6. recuperem mensagens duráveis após uma reinicialização;
7. encaminhem mensagens que excederam as tentativas para uma dead-letter queue;
8. observem a saúde e as métricas básicas do servidor.

A v1 é single-node. Clustering, replicação, exactly-once, painel web e transações
entre filas não fazem parte desse compromisso.

## 3. Estratégia de evolução

```text
fundação
   |
   v
domínio em memória
   |
   v
protocolo + TCP + CLI
   |
   v
ACK, retry, TTL e dead-letter
   |
   v
persistência + recuperação
   |
   v
tópicos + grupos de consumidores
   |
   v
operação + estabilização
```

Não se deve iniciar persistência antes de o modelo de entrega em memória estar
correto. Também não se deve criar SDKs antes de o protocolo ter uma primeira
especificação executável.

## 4. Fases de desenvolvimento

| Fase | Entrega principal | Dependência |
| --- | --- | --- |
| 1 — Fundação | Workspace, servidor mínimo, configuração, logs e CI | Nenhuma |
| 2 — Domínio | Filas em memória e máquina de estados de entrega | Fase 1 |
| 3 — Comunicação | Protocolo TCP, sessões e CLI | Fase 2 |
| 4 — Confiabilidade | ACK/NACK, timeout, retry, TTL e dead-letter | Fase 3 |
| 5 — Durabilidade | Log, recovery, snapshot e compactação | Fase 4 |
| 6 — Roteamento | Tópicos, bindings e grupos de consumidores | Fase 5 |
| 7 — Operação | Métricas, diagnóstico, benchmarks e hardening | Fase 6 |
| 8 — v1 | Compatibilidade, documentação e release estável | Fase 7 |

Cada fase deve terminar com uma demonstração reproduzível, testes automatizados
e documentação do comportamento entregue.

## 5. Estrutura planejada do workspace

```text
Relay/
├── Cargo.toml                 # workspace e configuração compartilhada
├── Cargo.lock                 # dependências reproduzíveis
├── crates/
│   ├── relay-core/            # domínio e máquina de estados
│   ├── relay-protocol/        # frames, comandos e codecs
│   ├── relay-storage/         # log, recovery, snapshot e compactação
│   ├── relay-server/          # processo, rede, configuração e ciclo de vida
│   ├── relay-cli/             # administração, publicação e consumo
│   └── relay-testkit/         # relógio controlável e fixtures de integração
├── docs/                      # especificações e decisões
├── examples/                  # cenários completos de uso
├── benchmarks/                # workloads reproduzíveis
└── sdk/                       # clientes externos futuros
```

Essa é uma estrutura-alvo, não uma ordem para criar crates vazios. Cada crate
deve nascer somente quando houver responsabilidade real e independente.

## 6. Responsabilidades e dependências

```text
relay-cli ---------> relay-protocol
                         ^
                         |
relay-server ------> relay-protocol
     |                   |
     +--------------> relay-core <------ relay-storage
                           ^
                           |
                     relay-testkit
```

Regras:

- `relay-core` não conhece TCP, arquivos, CLI nem runtime assíncrono.
- `relay-protocol` traduz bytes e comandos, mas não decide regras de negócio.
- `relay-storage` persiste eventos do domínio, sem conhecer conexões de clientes.
- `relay-server` compõe os módulos e controla o ciclo de vida do processo.
- `relay-cli` é um cliente do protocolo, nunca um atalho para acessar o core.
- `relay-testkit` deve existir apenas quando fixtures compartilhadas forem úteis.
- Dependências cíclicas entre crates não são permitidas.

## 7. Modelo inicial do domínio

Os nomes ainda podem mudar, mas o domínio deverá representar explicitamente:

| Conceito | Responsabilidade |
| --- | --- |
| `Message` | ID, payload imutável, headers e metadados de publicação |
| `Queue` | Mensagens disponíveis, em voo e agendadas |
| `Delivery` | Consumidor, tentativa e prazo de visibilidade |
| `Consumer` | Identidade da sessão e capacidade disponível |
| `RetryPolicy` | Limite, intervalo e destino após esgotamento |
| `BrokerCommand` | Operação solicitada ao domínio |
| `BrokerEvent` | Alteração válida que poderá ser persistida |

Estado mínimo de uma mensagem:

```text
publicada -> disponível -> em voo -> confirmada
                ^             |
                |             +-> retry agendado
                |                       |
                +-----------------------+
                                        |
                                        +-> dead-letter
```

Transições inválidas devem resultar em erro de domínio, e não ser ignoradas.

## 8. Decisões técnicas iniciais

Já definidas por ADR:

- Rust estável como linguagem de implementação;
- single-node até a v1;
- protocolo versionado desde o primeiro frame.

Decisões que devem ser tomadas durante as fases, com ADR própria quando
necessário:

- runtime assíncrono e estratégia de concorrência;
- formato do corpo dos frames;
- formato dos registros persistidos e checksum;
- garantia utilizada para `fsync` e confirmação de publicação;
- estratégia de snapshot e compactação;
- formato e endpoint das métricas;
- política de compatibilidade do protocolo e do armazenamento.

Não escolher uma tecnologia apenas por popularidade. A decisão deve registrar
restrições, alternativas e o custo operacional introduzido.

## 9. Estratégia de testes

| Nível | O que validar |
| --- | --- |
| Unitário | Regras, validação e transições do domínio |
| Máquina de estados | Sequências de publish, deliver, ACK, NACK e timeout |
| Propriedades | Parser, framing e recuperação diante de entradas arbitrárias |
| Integração | Servidor e clientes reais comunicando-se por TCP |
| Falhas | Queda de conexão, escrita parcial, restart e cliente lento |
| Carga | Memória limitada, throughput, latência e fairness |
| Compatibilidade | Cliente e servidor em versões suportadas |

O relógio usado por TTL, timeout e retry deve ser injetável. Os testes não devem
depender de `sleep` longo nem de condições de corrida para validar tempo.

## 10. Processo de desenvolvimento

Para cada item do backlog:

1. confirmar o comportamento e os critérios de aceite;
2. registrar uma ADR se a solução trouxer uma decisão difícil de reverter;
3. escrever ou ajustar o teste do comportamento;
4. implementar a menor alteração que satisfaça o contrato;
5. executar formatação, linter, testes e verificações de segurança;
6. atualizar documentação e exemplos afetados;
7. abrir um pull request pequeno e revisável.

Sugestão para branches: `feat/<tema>`, `fix/<tema>`, `docs/<tema>` e
`chore/<tema>`. A branch `main` deve permanecer compilável e testada.

## 11. Definition of Done

Uma tarefa só está concluída quando:

- os critérios de aceite foram atendidos;
- o comportamento possui teste proporcional ao risco;
- não existem warnings de compilação ou lint;
- erros possuem contexto e não são silenciosamente descartados;
- logs não expõem payloads ou credenciais por padrão;
- documentação pública e ADRs foram atualizadas quando necessário;
- o pull request explica problema, solução, validação e trade-offs;
- não há crescimento de escopo não registrado.

Uma fase só está concluída quando sua demonstração e seus critérios de saída
podem ser reproduzidos a partir de um clone limpo.

## 12. Práticas de qualidade

- Formatação automática obrigatória.
- Linter tratado como erro na CI.
- `unsafe` proibido por padrão e documentado quando inevitável.
- Dependências mínimas, com licença e finalidade conhecidas.
- Payload de mensagens nunca registrado por padrão.
- Buffers, canais, filas e tamanhos de frames sempre limitados.
- Benchmarks não substituem testes de correção.
- Otimizações devem apresentar medição antes e depois.

## 13. Riscos principais

| Risco | Controle |
| --- | --- |
| Escopo semelhante a brokers maduros | Manter limites explícitos da v1 |
| Concorrência difícil de reproduzir | Estado com proprietário único e testes determinísticos |
| Uso ilimitado de memória | Limites e backpressure desde a fase em memória |
| Corrupção após queda | Checksums, registros atômicos e testes de escrita parcial |
| Protocolo acidentalmente estável | Marcar v0.x como experimental e versionar frames |
| Otimização prematura | Criar baseline antes de alterar arquitetura por desempenho |
| Crates excessivamente fragmentados | Extrair módulos somente com responsabilidade comprovada |

## 14. Próximo passo

O desenvolvimento deve começar exclusivamente pela
[Fase 1: fundação](fase-01-fundacao.md). A máquina de estados de mensagens será
planejada em detalhe ao final dessa fase, usando o servidor mínimo e o ambiente
de testes já validados.
