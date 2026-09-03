# Desenvolvimento local

Este repositório contém somente o backend Phoenix. O frontend e o widget
Turnstile pertencem ao repositório do GitHub Pages e não recebem segredos do
Relay.

## Pré-requisitos

- Erlang/OTP 29.0.6 e Elixir 1.20.4-otp-29, conforme `.tool-versions`;
- dependências obtidas com `mix deps.get`;
- uma origem explícita para o frontend local, por exemplo
  `http://localhost:5173`.

## Comandos usuais

```text
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix check
```

`mix check` executa formatação, compilação sem warnings e testes. A suíte
normal é offline e usa o provedor e o Turnstile falsos; ela não deve receber uma
chave OpenRouter.

## Configuração local segura

Os valores padrão de desenvolvimento permitem apenas
`http://localhost:5173`. Para apontar outro frontend local, defina
`ALLOWED_ORIGINS` e `PUBLIC_SITE_URL` com a URL exata desse frontend antes de
iniciar o Relay. Nunca inclua `OPENROUTER_API_KEY`, `TURNSTILE_SECRET_KEY` ou
segredos do GitHub em arquivos versionados, no bundle do frontend ou em testes.

Em produção, o chat permanece desabilitado até que `CHAT_ENABLED=true` e todas
as configurações obrigatórias sejam fornecidas pelo ambiente da plataforma.

## Diagnóstico

- `GET /health/live` confirma que o processo está vivo.
- `GET /health/ready` informa se a configuração de runtime permite receber
  tráfego; a resposta não expõe valores secretos.
- Falhas de CORS normalmente indicam que a origem não está presente em
  `ALLOWED_ORIGINS`; HTTP e WebSocket usam a mesma lista validada.
- Não use uma chave enviada em chat ou commitada. Revogue-a e cadastre uma nova
  diretamente no cofre de segredos da plataforma de deploy.
