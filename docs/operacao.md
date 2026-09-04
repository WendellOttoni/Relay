# Operação do Relay

O Relay é um backend sem interface própria. Sua operação normal é permanecer
publicado, porém com `CHAT_ENABLED=false`, até que o GitHub Pages integrado
precise oferecer a funcionalidade. Não há processo de *keep alive* nem motivo
para manter gerações ativas sem usuários.

## Estados e responsáveis

| Situação | Ação esperada |
| --- | --- |
| Serviço desligado para chat | manter `CHAT_ENABLED=false`; health pode continuar disponível para diagnóstico |
| Ativação planejada | seguir o checklist abaixo e habilitar somente após aprovação do orçamento |
| Falha do provedor, custo ou suspeita de segredo exposto | desabilitar chat primeiro; investigar depois |
| Mudança de código/configuração | deploy controlado, verificação e rollback se necessário |

O responsável pelo deploy deve registrar internamente data, revisão, ambiente,
responsável e motivo de ativações, rotações, incidentes e rollbacks. Esse
registro não inclui mensagens, tokens de socket nem valores de segredos.

## Checklist de ativação

1. Confirme que o consumidor é a origem exata em `ALLOWED_ORIGINS` e que
   `PUBLIC_SITE_URL` e `PHX_HOST` correspondem
   ao ambiente publicado.
2. Cadastre no cofre do host `SECRET_KEY_BASE`, `OPENROUTER_API_KEY`,
   modelo e prompt. Nunca os coloque no repositório,
   build do Pages, console do navegador ou ticket.
3. Defina limites locais e um teto financeiro/alertas no painel da OpenRouter.
   O teto externo é obrigatório porque métricas locais reiniciam com a instância
   e não são uma fonte de cobrança.
4. Revise a política de dados do provedor/modelo antes de ativar; o identificador
   configurado atualmente é `minimax/minimax-m3:free`, mas o uso real depende
   de disponibilidade e política vigentes no provedor.
5. Publique ou reinicie controladamente com `CHAT_ENABLED=false`, confirme
   `/health/live` e `/health/ready`, CORS e origem do WebSocket.
6. Após aprovar o orçamento, habilite `CHAT_ENABLED=true`, reimplante e execute
   um smoke manual explicitamente autorizado. Ele não faz parte da CI.
7. Valide pelo navegador integrado: criação de sessão, conexão,
   delta, cancelamento, expiração e comportamento após cold start. Não copie
   conteúdo de conversa em evidências públicas.

Se qualquer etapa falhar, volte `CHAT_ENABLED` para `false` e não tente
contornar validações de origem ou limites.

## Monitoramento e alertas

Verifique periodicamente:

- disponibilidade de `/health/live` e `/health/ready`;
- respostas `503`, `429`, erros de sessão e falhas de conexão pelo host;
- ocorrências de `service_overloaded`, que indicam que o limite de gerações
  simultâneas da instância foi atingido antes de uma chamada ao provedor;
- contadores agregados de geração (resultado, duração e usage quando houver);
- avisos estruturados para falhas repetidas do provedor;
- consumo e alertas/teto configurados diretamente na OpenRouter;
- comportamento de cold start, reconexão e WebSocket no ambiente publicado.

Os alertas devem alcançar a pessoa responsável pelo orçamento. Limites ou
incidentes sem responsável definido bloqueiam a ativação pública. Não se
prometem métricas históricas: o MVP não possui persistência e seus contadores
locais são efêmeros.

## Incidentes

### Indisponibilidade, timeout ou aumento de falhas

1. Desabilite o chat se a falha for contínua, atingir custo ou prejudicar o
   consumidor; preserve health para diagnóstico quando seguro.
2. Consulte status do host e os logs/contadores seguros por categoria e horário.
   Não solicite prompts, respostas, headers ou corpo bruto do provedor.
3. Verifique configuração, orçamento e disponibilidade do provedor; aplique uma
   correção ou rollback da revisão conhecida.
4. Reative somente após uma validação controlada e registre o desfecho.

### Suspeita ou confirmação de segredo exposto

1. Defina `CHAT_ENABLED=false` imediatamente e reimplante/reinicie.
2. Revogue a credencial afetada no respectivo provedor. Uma chave enviada em
   chat, commit, log, issue ou captura é considerada exposta.
3. Investigue escopo e consumo sem reproduzir o valor do segredo em registros.
4. Crie segredo novo no provedor, atualize apenas o cofre da hospedagem e faça
   deploy controlado.
5. Teste de forma autorizada, revogue qualquer chave anterior remanescente e
   documente apenas metadados do incidente.

### Excesso de custo ou abuso

1. Desabilite o chat; não espere a conclusão da investigação.
2. Confirme o teto e consumo no provedor, e mantenha a chave revogada se houver
   dúvida de comprometimento.
3. Revise origem, limites e padrões agregados. Não atribua identidade
   a usuários anônimos além do que os dados disponíveis permitem.
4. Antes de reativar, ajuste controles e defina claramente o orçamento restante.

### Capacidade temporariamente esgotada

O Channel responde `service_overloaded` quando todas as vagas de geração locais
estão ocupadas. O cliente deve exibir indisponibilidade temporária e aplicar
tentativa limitada com backoff; não deve abrir sessões ou sockets adicionais.
Se o sinal for recorrente, mantenha o chat desabilitado durante a análise ou
ajuste `CHAT_MAX_CONCURRENT_GENERATIONS` somente após verificar orçamento,
memória, limite do provedor e o impacto de uma única instância. Esse semáforo é
local; ele não coordena múltiplas instâncias.

## Rollback

Um rollback restaura uma revisão de aplicação/configuração conhecida; não
recupera sessões, conexões ou gerações interrompidas. No host:

1. Desabilite chat se houver risco de custo, privacidade ou credencial.
2. Selecione a última revisão validada e execute o rollback conforme a
   plataforma de hospedagem.
3. Confirme health, origem HTTP/WebSocket e que o modo de chat esperado foi
   aplicado.
4. Com o Pages, teste uma sessão nova; clientes não retomam streams anteriores.
5. Registre a revisão de origem/destino, motivo e resultado; então corrija a
   causa em uma alteração separada.

## Rotação programada

Use o procedimento detalhado em [OpenRouter](openrouter.md). A rotação inclui
criar chave substituta, atualizar somente o cofre de deploy, validar de modo
controlado e revogar a anterior.
`SECRET_KEY_BASE` segundo as capacidades e impacto de cada provedor; mudar
`SECRET_KEY_BASE` invalida tokens/sessões assinados existentes.

## Limites do MVP

O Relay não tem SLA, banco, histórico persistente, painel administrativo,
métrica de cobrança própria ou autenticação de usuário. Caso o uso deixe de ser
eventual ou o Pages ganhe tráfego relevante, reavalie limites distribuídos,
observabilidade persistente, hospedagem e autenticação antes de ampliar o
acesso público.
