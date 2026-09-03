# Registros de decisões de arquitetura

ADRs registram decisões difíceis de reverter. Um documento aceito não é
reescrito para mudar a decisão; uma nova ADR o substitui e preserva o histórico.

| ADR | Decisão | Status |
| --- | --- | --- |
| [0001](0001-separar-frontend-e-backend.md) | Separar o Pages do backend | Aceita |
| [0002](0002-manter-segredos-no-backend.md) | Manter segredos somente no Relay | Aceita |
| [0003](0003-usar-elixir-e-phoenix.md) | Usar Elixir e Phoenix | Aceita |
| [0004](0004-usar-phoenix-channels.md) | Usar Channels/WebSocket para o chat | Aceita |
| [0005](0005-hospedar-no-render.md) | Hospedar o experimento no Render | Aceita para experimento |
| [0006](0006-integrar-openrouter-no-backend.md) | Integrar OpenRouter pelo backend | Aceita |
| [0007](0007-adiar-postgresql-e-ecto.md) | Adiar PostgreSQL e Ecto | Aceita |
| [0008](0008-proteger-sessoes-anonimas.md) | Proteger sessões anônimas | Aceita |

## Próximas ADRs necessárias

- modelo e política de roteamento da OpenRouter;
- persistência, retenção e propriedade dos dados;
- hospedagem definitiva após o experimento;
- autenticação GitHub, quando houver caso de uso.

Copie [o modelo](template.md), use o próximo número e inicie com status
`Proposta`.
