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
11. [Desenvolvimento local](desenvolvimento-local.md) — execução e diagnóstico sem segredos.
12. [Operação](operacao.md) — ativação, incidentes, orçamento e rollback.
13. [Privacidade](privacidade.md) — tratamento mínimo de dados no MVP.
14. [Decisões pendentes](decisoes-pendentes.md) — escolhas que dependem do produto.
15. [Roadmap](roadmap.md) — evolução do MVP até uma versão estável.
16. [Estado atual](estado-atual.md) — funcionalidades implementadas e validadas.
16. [ADRs](adr/README.md) — decisões aceitas e suas justificativas.

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
| Operação | Como ativar, monitorar, responder e reverter? |
| Privacidade | Quais dados transitam e quais não são guardados? |
| Decisões pendentes | O que ainda não pode ser presumido? |
| ADR | Por que uma escolha importante foi feita? |

Mudanças em autenticação, contrato público, armazenamento de conversas ou
tratamento de segredos exigem atualização da documentação antes da integração.
