# Política de segurança

O Relay ainda não possui versão estável e não deve ser utilizado em produção.

## Regras fundamentais

- Chaves de IA, segredos OAuth e tokens do GitHub existem apenas no backend.
- Segredos são fornecidos pelo ambiente da hospedagem, nunca pelo repositório.
- CORS restringe navegadores, mas não substitui autenticação ou controle de abuso.
- O socket valida origem e token curto antes de permitir entrada em um Channel.
- Prompts, respostas, tokens e credenciais não são registrados por padrão.
- Entrada, saída, duração, concorrência e consumo possuem limites configuráveis.
- Respostas de erro não expõem stack traces nem respostas brutas de provedores.
- A chave OpenRouter possui teto financeiro externo e pode ser desabilitada sem
  novo deploy.
- O endpoint de oportunidades exige sessão assinada, consentimento, limites de
  tamanho e rate limit. Monitore spam e custo no provedor.
- A URL de entrega é configuração do servidor e aceita somente formulários HTTPS
  no domínio `formspree.io`; o visitante não controla o destino.

Em suspeita de exposição, desabilite `CHAT_ENABLED`, revogue a chave no painel
da OpenRouter e faça a rotação pelo procedimento em `docs/openrouter.md`. Não
cole a chave em tickets, chats, logs ou commits.

## Dados do chat

O MVP não persiste conversas no Relay. O histórico permanece no navegador e é
reenviado com limites. Processos, dumps, telemetria e relatórios de erro também
não devem capturar o conteúdo. Qualquer persistência futura exige autenticação,
retenção, exclusão e revisão de privacidade antes da implementação.

## Relato de vulnerabilidades

Use o recurso de relato privado de vulnerabilidades do GitHub para este
repositório. Informe revisão afetada, reprodução, impacto e possível mitigação.
Não abra uma issue pública antes de existir correção ou plano de divulgação.
