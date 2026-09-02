# Política de segurança

O Relay ainda não possui versão estável e não deve ser utilizado em produção.

## Regras fundamentais

- Chaves de IA, segredos OAuth e tokens do GitHub existem apenas no backend.
- Segredos são fornecidos pelo ambiente da hospedagem, nunca pelo repositório.
- CORS restringe navegadores, mas não substitui autenticação ou controle de abuso.
- Prompts, respostas, tokens e credenciais não são registrados por padrão.
- Entrada, saída, duração, concorrência e consumo possuem limites configuráveis.
- Respostas de erro não expõem stack traces nem respostas brutas de provedores.

## Relato de vulnerabilidades

Use o recurso de relato privado de vulnerabilidades do GitHub para este
repositório. Informe revisão afetada, reprodução, impacto e possível mitigação.
Não abra uma issue pública antes de existir correção ou plano de divulgação.
