# 0002 — Manter segredos somente no backend

- Status: Aceita
- Data: 2026-09-02

## Contexto

Arquivos e variáveis incorporados ao build do frontend podem ser lidos no
navegador. Ofuscação, nomes diferentes ou um repositório privado não tornam uma
chave segura depois que ela é enviada ao usuário.

## Decisão

Chaves de IA, client secrets, tokens do GitHub e strings de conexão existirão
somente no ambiente do Relay. O frontend nunca enviará nem receberá esses
valores. O backend usará identidade e permissões mínimas para cada integração.

## Consequências

Toda operação privilegiada passa pelo Relay e pode receber validação, limites e
auditoria. O deploy precisa oferecer secret management e rotação. Vazamentos em
logs, exceções e telemetria também precisam ser prevenidos e testados.

## Alternativas consideradas

- **Variável de ambiente do build frontend:** rejeitada porque o valor termina
  no bundle público.
- **Chave ofuscada ou dividida:** rejeitada porque o navegador precisa
  reconstruí-la para uso.
- **Token fornecido pelo próprio usuário:** pode existir para casos avançados,
  mas não substitui autenticação e armazenamento seguro e não será o padrão.
