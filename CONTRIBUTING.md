# Como contribuir

O Relay está em planejamento. Antes de implementar algo, confirme que o item
faz parte da fase atual e possui critérios de aceite documentados.

## Processo

1. Consulte o plano e as issues existentes.
2. Abra uma issue para mudanças de contrato, autenticação ou arquitetura.
3. Registre uma ADR para decisões difíceis de reverter.
4. Mantenha cada pull request focado em um comportamento.
5. Inclua testes e atualize a documentação afetada.

Um pull request deve explicar problema, solução, validação, impacto de segurança
e trade-offs. Nunca inclua chaves, tokens, prompts reais ou dados pessoais em
commits, testes, logs ou exemplos.

## Qualidade esperada

- formatação e lint sem erros;
- testes proporcionais ao risco;
- limites explícitos para entrada, saída e duração;
- cancelamento propagado para chamadas externas;
- erros públicos sem detalhes sensíveis;
- logs estruturados com identificador de requisição;
- dependências justificadas e atualizadas.

Falhas de segurança devem seguir o processo privado descrito em
[SECURITY.md](SECURITY.md).
