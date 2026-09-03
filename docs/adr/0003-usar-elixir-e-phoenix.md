# 0003 — Usar Elixir e Phoenix no backend

- Status: Aceita
- Data: 2026-09-03

## Contexto

O Relay é um projeto experimental para conectar um frontend estático a um
provedor de IA. Além de proteger a credencial, o backend precisa manter conexões
de curta duração, transmitir deltas, cancelar trabalho quando o cliente sair e
isolar falhas entre conversas. O projeto também deve permitir experimentar um
modelo de concorrência diferente das stacks tradicionais já conhecidas pelo
mantenedor.

## Decisão

Implementar o Relay com Elixir 1.20, Erlang/OTP 29 e Phoenix 1.8. O projeto será
gerado sem HTML, assets, LiveView, mailer ou Ecto. Phoenix fornecerá a API HTTP,
o endpoint WebSocket e os Channels. Processos supervisionados executarão cada
geração da IA.

As versões patch serão fixadas no repositório quando o projeto for criado e
atualizadas de forma explícita. Não serão usadas versões release candidate.

## Consequências

- concorrência, cancelamento e isolamento poderão usar primitivas da BEAM;
- a equipe precisará aprender padrões OTP, supervisão e passagem de mensagens;
- o backend continuará implantável como um release ou container convencional;
- o frontend permanecerá independente e não utilizará LiveView;
- banco e Ecto não serão dependências obrigatórias do primeiro deploy.

## Alternativas consideradas

- **ASP.NET Core:** tecnicamente robusto e familiar, mas oferece menos valor para
  o objetivo experimental deste projeto.
- **Node.js/TypeScript:** reduz a quantidade de linguagens, mas não explora o
  modelo de concorrência e supervisão escolhido para o Relay.
- **Rust:** eficiente e seguro, porém aumenta o custo de implementação sem uma
  necessidade de desempenho demonstrada.

## Referências

- [Elixir 1.20](https://elixir-lang.org/blog/2026/06/03/elixir-v1-20-0-released/)
- [Phoenix 1.8](https://phoenixframework.org/blog/phoenix-1-8-released)
- [Deploy de Phoenix com releases](https://hexdocs.pm/phoenix/releases.html)
