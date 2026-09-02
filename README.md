# Relay

> Um message broker pequeno e confiável, construído do zero em Rust.

Relay é um projeto educacional de engenharia de sistemas focado nos mecanismos
internos de um message broker: protocolos, garantias de entrega, persistência,
backpressure e concorrência. O objetivo não é substituir brokers utilizados em
produção, mas construir uma implementação compacta cujo comportamento possa ser
compreendido de ponta a ponta.

> [!IMPORTANT]
> O Relay está atualmente na fase de projeto. O repositório contém a
> especificação e as decisões de arquitetura; ainda não existe uma versão
> utilizável do broker.

## Por que Relay?

A maioria dos tutoriais sobre mensageria termina em uma fila mantida em memória.
O Relay pretende ir além, tornando as partes difíceis visíveis e testáveis:

- filas e tópicos publish/subscribe;
- confirmações explícitas e reentrega de mensagens;
- tentativas limitadas e filas de mensagens não processadas;
- mensagens duráveis armazenadas em um log somente de acréscimo;
- grupos de consumidores e consumidores concorrentes;
- controle de fluxo para clientes lentos;
- protocolo de comunicação documentado e versionado;
- métricas e visibilidade operacional.

## Experiência planejada

```text
publicador                 Relay                    consumidores
    |                        |                           |
    |--- PUBLISH orders ---->|                           |
    |<-------- OK -----------|--- MESSAGE orders ------>|
    |                        |<--------- ACK ------------|
```

A interface inicial será composta por um servidor TCP e uma pequena CLI:

```console
$ relay-server --data ./relay-data
$ relay-cli queue create orders --durable
$ relay-cli publish orders '{"order_id": 42}'
$ relay-cli consume orders --group billing
```

Os nomes e a sintaxe dos comandos são provisórios até que a ADR do protocolo
seja aceita.

## Escopo

A primeira versão estável deverá oferecer:

| Área | Objetivo para a v1 |
| --- | --- |
| Mensageria | Filas, tópicos e grupos de consumidores |
| Entrega | No máximo uma vez e pelo menos uma vez |
| Confiabilidade | ACK/NACK, novas tentativas e filas de mensagens não processadas |
| Persistência | Log somente de acréscimo e recuperação |
| Rede | Protocolo versionado sobre TCP |
| Operação | Verificação de saúde, métricas e desligamento seguro |
| Ferramentas | CLI de administração e cliente Rust |

Entrega exatamente uma vez, clustering, painel web e replicação entre regiões
estão deliberadamente fora do escopo da v1.

## Arquitetura

```text
                         +------------------+
publicadores/consumidores|  transporte TCP  |
 ----------------------> +---------+--------+
                                   |
                         +---------v--------+
                         | protocolo + auth |
                         +---------+--------+
                                   |
                    +--------------v---------------+
                    | roteamento, filas e entregas |
                    +------+----------------+-------+
                           |                |
                    +------v------+  +------v------+
                    | agendador   |  | persistência|
                    | ACK / retry |  | append log  |
                    +-------------+  +-------------+
```

Consulte [o documento de arquitetura](docs/architecture.md) para conhecer os
limites dos componentes, as invariantes e a estrutura proposta para o
repositório.

## Roadmap

- **v0.1 — Fundação:** workspace, configuração, modelo de erros e CI.
- **v0.2 — Broker em memória:** filas, publicação, consumo e ACK/NACK.
- **v0.3 — Protocolo:** frames TCP, sessões de clientes e CLI.
- **v0.4 — Confiabilidade:** novas tentativas, tempo de visibilidade e mensagens não processadas.
- **v0.5 — Durabilidade:** log somente de acréscimo, recuperação e compactação.
- **v0.6 — Pub/sub:** tópicos, inscrições e grupos de consumidores.
- **v0.7 — Operação:** métricas, verificações de saúde e desligamento seguro.
- **v1.0 — Estável:** política de compatibilidade, benchmarks e documentação completa.

As definições e os critérios de conclusão de cada marco estão no
[roadmap completo](docs/roadmap.md).

## Princípios de projeto

1. **Correção antes de desempenho.** O estado de entrega deve permanecer compreensível.
2. **Uso limitado de recursos.** Filas e clientes devem aplicar backpressure.
3. **Recuperação de falhas é uma funcionalidade.** O estado durável deve sobreviver a encerramentos abruptos.
4. **Protocolo pequeno e explícito.** Todo frame deve ser versionado e documentado.
5. **Medir antes de otimizar.** Melhorias de desempenho exigem benchmarks reproduzíveis.

## Estrutura do repositório

```text
crates/       crates planejados para o workspace Rust
docs/         arquitetura, protocolo, roadmap e ADRs
examples/     exemplos completos planejados
benchmarks/   cenários reproduzíveis de desempenho
sdk/          bibliotecas cliente planejadas
```

Neste momento, os diretórios contêm apenas contratos e notas sobre suas
responsabilidades. O código-fonte será introduzido gradualmente conforme os
marcos do roadmap forem iniciados.

## Situação atual e contribuições

A API pública e o protocolo de comunicação ainda não são estáveis. Sugestões
sobre o projeto são bem-vindas por meio de issues e discussions. Antes de
contribuir, leia o [guia de contribuição](CONTRIBUTING.md) e as
[decisões de arquitetura](docs/adr/README.md) aceitas.

## Licença

Relay está disponível sob a [Licença MIT](LICENSE).
