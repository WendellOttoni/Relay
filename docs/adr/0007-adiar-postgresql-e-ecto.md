# 0007 — Adiar PostgreSQL e Ecto

- Status: Aceita
- Data: 2026-09-03

## Contexto

PostgreSQL e Ecto foram considerados para histórico, contas e autenticação. O
primeiro chatbot pode manter o histórico no navegador e o estado transitório em
processos da BEAM durante a conexão.

## Decisão

Gerar o primeiro projeto Phoenix sem Ecto e sem banco. Não persistir mensagens,
respostas, sessões ou tokens. Reavaliar PostgreSQL quando existir um caso de uso
que exija propriedade, retenção e recuperação de dados.

Se a persistência entrar no experimento, a primeira prova usará Ecto com um
PostgreSQL externo gratuito; Supabase é a opção inicial, sujeita a nova validação
de limites na data da implementação.

## Consequências

- o primeiro deploy possui menos dependências e segredos;
- reinícios e desconexões encerram o estado da conversa no servidor;
- o navegador deve reenviar um histórico limitado a cada geração;
- autenticação, retenção, exportação e exclusão serão decididas antes do banco;
- adicionar Ecto posteriormente continuará sendo uma evolução suportada pelo
  ecossistema Phoenix.

## Referências

- [Ecto.Repo](https://hexdocs.pm/ecto/Ecto.Repo.html)
- [Plano gratuito do Supabase](https://supabase.com/pricing)
