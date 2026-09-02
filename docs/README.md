# Documentação do Relay

Este diretório concentra a especificação técnica e o planejamento do projeto.
Antes de implementar uma funcionalidade, confirme em qual fase ela se encaixa,
quais módulos serão afetados e quais critérios precisam ser atendidos.

## Comece por aqui

1. [Plano de desenvolvimento](plano-de-desenvolvimento.md) — escopo, ordem de
   implementação, estrutura do workspace e processo de trabalho.
2. [Fase 1: fundação](fase-01-fundacao.md) — primeiro ciclo de desenvolvimento,
   dividido em tarefas pequenas e verificáveis.
3. [Arquitetura](architecture.md) — componentes, limites e invariantes do broker.
4. [Roadmap](roadmap.md) — evolução planejada da v0.1 até a v1.0.
5. [Protocolo](protocol.md) — restrições e questões abertas do protocolo TCP.
6. [ADRs](adr/README.md) — decisões de arquitetura e suas justificativas.

## Função de cada documento

| Documento | Pergunta respondida |
| --- | --- |
| Plano de desenvolvimento | Como o projeto deve ser construído? |
| Especificação da fase | O que deve ser feito agora? |
| Arquitetura | Quais são os componentes e seus limites? |
| Roadmap | O que será entregue e em qual ordem? |
| Protocolo | Como clientes e servidor se comunicarão? |
| ADR | Por que uma decisão importante foi tomada? |

## Regra de atualização

- Uma mudança de escopo deve atualizar o plano ou o roadmap.
- Uma decisão difícil de reverter deve gerar uma ADR.
- Uma mudança observável no comportamento deve atualizar sua especificação.
- Uma fase concluída deve registrar evidências para todos os critérios de saída.

Os documentos de arquitetura, roadmap, protocolo e ADRs foram inicialmente
escritos em inglês. A documentação operacional e o planejamento inicial estão
em português; a tradução dos documentos restantes pode ocorrer sem alterar as
decisões registradas.
