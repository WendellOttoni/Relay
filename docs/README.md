# Documentação

Esta documentação define o Relay antes da implementação. Ela deve impedir que
decisões de infraestrutura sejam confundidas com requisitos do produto.

## Ordem de leitura

1. [Arquitetura](arquitetura.md) — componentes, fluxo e limites de confiança.
2. [Plano de desenvolvimento](plano-de-desenvolvimento.md) — fases e processo.
3. [Fase 1: fundação](fase-01-fundacao.md) — primeiro backlog executável.
4. [Contrato da API](api.md) — proposta inicial para frontend e backend.
5. [Deploy](deploy.md) — relação entre GitHub Pages e hospedagem da API.
6. [Decisões pendentes](decisoes-pendentes.md) — escolhas necessárias antes do código.
7. [Roadmap](roadmap.md) — evolução do MVP até uma versão estável.
8. [ADRs](adr/README.md) — decisões aceitas e suas justificativas.

## Responsabilidade dos documentos

| Documento | Pergunta |
| --- | --- |
| Arquitetura | Como as partes se relacionam? |
| Plano | Em qual ordem construir? |
| Fase atual | O que fazer agora e como validar? |
| API | Qual contrato o frontend pode usar? |
| Deploy | Onde cada parte executa? |
| Decisões pendentes | O que ainda não pode ser presumido? |
| ADR | Por que uma escolha importante foi feita? |

Mudanças em autenticação, contrato público, armazenamento de conversas ou
tratamento de segredos exigem atualização da documentação antes da integração.
