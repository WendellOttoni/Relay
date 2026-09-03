# Documentação

Esta documentação registra as decisões aceitas e define um caminho executável
para o Relay.

## Ordem de leitura

1. [Arquitetura](arquitetura.md) — componentes, fluxo e limites de confiança.
2. [Plano de desenvolvimento](plano-de-desenvolvimento.md) — fases e processo.
3. [Fase 1: fundação](fase-01-fundacao.md) — primeiro backlog executável.
4. [Fase 2: chat simulado](fase-02-chat-simulado.md) — Channel sem custo externo.
5. [Fase 3: OpenRouter](fase-03-openrouter.md) — integração real protegida.
6. [Contrato HTTP](api.md) — endpoints fora do Channel.
7. [Protocolo dos Channels](protocolo-channels.md) — contrato do chat em tempo real.
8. [Integração OpenRouter](openrouter.md) — fronteira do primeiro provedor.
9. [Configuração](configuracao.md) — ambientes, secrets e limites.
10. [Deploy](deploy.md) — GitHub Pages e Render Free.
11. [Decisões pendentes](decisoes-pendentes.md) — escolhas que dependem do produto.
12. [Roadmap](roadmap.md) — evolução do MVP até uma versão estável.
13. [ADRs](adr/README.md) — decisões aceitas e suas justificativas.

## Responsabilidade dos documentos

| Documento | Pergunta |
| --- | --- |
| Arquitetura | Como as partes se relacionam? |
| Plano | Em qual ordem construir? |
| Fase atual | O que fazer agora e como validar? |
| API HTTP | Como criar sessão e verificar saúde? |
| Channels | Quais eventos o frontend pode usar? |
| OpenRouter | Como o provedor fica isolado? |
| Configuração | Quais variáveis e limites existem? |
| Deploy | Onde cada parte executa? |
| Decisões pendentes | O que ainda não pode ser presumido? |
| ADR | Por que uma escolha importante foi feita? |

Mudanças em autenticação, contrato público, armazenamento de conversas ou
tratamento de segredos exigem atualização da documentação antes da integração.
