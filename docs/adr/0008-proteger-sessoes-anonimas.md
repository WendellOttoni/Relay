# 0008 — Proteger sessões anônimas antes do chat real

- Status: Aceita
- Data: 2026-09-03

## Contexto

O site será público e a chave OpenRouter pertencerá ao projeto. CORS e validação
de origem reduzem uso acidental pelo navegador, mas não impedem chamadas diretas
por scripts.

## Decisão

Antes de criar uma sessão, o navegador obterá um token Cloudflare Turnstile. O
Relay validará o token no servidor e emitirá um token de sessão anônima, assinado,
curto e vinculado a um identificador aleatório.

O MVP combinará:

- validação Turnstile na criação da sessão;
- `check_origin` no socket e CORS explícito na API HTTP;
- uma geração simultânea por sessão;
- limites por sessão e por sinal de rede disponível;
- limites de entrada, saída e duração;
- teto financeiro na chave OpenRouter e limite global de emergência.

O limitador da instância experimental poderá usar ETS. Antes de escalar para mais
de uma instância, será necessário um armazenamento distribuído ou uma proteção na
borda.

## Consequências

- não será necessário criar contas no MVP;
- o Turnstile não será tratado como autenticação de identidade;
- reiniciar a instância pode limpar contadores locais, por isso o limite da chave
  OpenRouter permanece a última barreira financeira;
- a validação do Turnstile será simulada nos testes comuns.

## Referências

- [Cloudflare Turnstile](https://developers.cloudflare.com/turnstile/get-started/)
- [Validação server-side](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/)
