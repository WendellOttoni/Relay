# Integração com a OpenRouter

Status: **Definida para a Fase 3**

## 1. Fronteira

Somente `Relay.Integrations.OpenRouter` conhece endpoints, autenticação e formato
da OpenRouter. O restante da aplicação depende de uma porta interna de geração
de chat.

Interface conceitual:

```elixir
@callback stream_chat(request(), event_receiver(), keyword()) ::
            :ok | {:error, reason()}
```

O adaptador falso implementa a mesma porta e produz uma sequência determinística
sem internet.

## 2. Requisição externa

```text
POST https://openrouter.ai/api/v1/chat/completions
Authorization: Bearer <OPENROUTER_API_KEY>
Content-Type: application/json
Accept: text/event-stream
HTTP-Referer: <PUBLIC_SITE_URL>
X-Title: Relay
```

Corpo conceitual:

```json
{
  "model": "configurado no servidor",
  "messages": [
    {"role": "system", "content": "configurado no servidor"},
    {"role": "user", "content": "mensagem validada"}
  ],
  "stream": true,
  "max_tokens": 1000
}
```

O Relay não repassa propriedades arbitrárias do cliente. Modelo, prompt de
sistema, limite de saída, temperatura e roteamento são definidos pelo servidor.

## 3. Consumo do stream

O cliente HTTP inicial será `Req` em versão estável. O adaptador processa o corpo
incrementalmente, interpreta somente eventos `data`, trata o marcador de fim e
converte os chunks para eventos internos.

Regras:

- não acumular a resposta inteira no backend;
- preservar cancelamento da tarefa até a conexão HTTP;
- limitar tempo de conexão, tempo total e inatividade entre chunks;
- tolerar divisão de uma linha SSE entre chunks de transporte;
- ignorar comentários/keepalives válidos;
- normalizar razão de término e usage quando disponíveis;
- classificar respostas `401`, `402`, `429` e `5xx` sem expor o corpo bruto;
- nunca registrar headers, mensagens ou texto gerado.

## 4. Tentativas e falhas

- falhas de conexão anteriores ao aceite do provedor podem ter uma tentativa
  curta e limitada;
- não repetir automaticamente depois do primeiro delta;
- respeitar `Retry-After` quando o provedor fornecer;
- cancelamento do usuário não é registrado como erro operacional;
- autenticação inválida e saldo insuficiente geram estado operacional e erro
  seguro no Channel; health checks não chamam a OpenRouter.

## 5. Modelo e orçamento

`OPENROUTER_MODEL` contém um identificador explícito. Não usar alias que troque
silenciosamente de modelo no primeiro experimento. O modelo será escolhido por
uma avaliação curta com perguntas representativas, comparando qualidade,
latência e custo.

Antes de habilitar a chave real:

- definir limite financeiro da chave na OpenRouter;
- definir máximo de tokens de saída no Relay;
- limitar concorrência e requisições por sessão;
- disponibilizar uma chave de emergência para desativar o chat;
- confirmar política de retenção do modelo/provedor selecionado.

## 6. Testes

A suíte padrão não chama a OpenRouter. Ela usa:

- adaptador falso para testes de Channel e aplicação;
- servidor HTTP local controlado para testar framing SSE;
- fixtures sintéticas sem prompts ou dados reais;
- casos de chunk parcial, timeout, cancelamento, `429`, `5xx` e stream truncado.

Um smoke test real será separado, manual e desabilitado por padrão.

## 7. Operação segura da credencial

`OPENROUTER_API_KEY` é um segredo exclusivo do ambiente de hospedagem. Nunca a
coloque em `.env` versionado, frontend, log, issue, conversa ou comando salvo.
Antes de habilitar chat público, configure no painel da OpenRouter um limite
financeiro baixo e alertas de consumo; os limites locais não substituem esse
teto.

### Rotação planejada

1. Crie uma chave substituta no painel, com o mesmo teto baixo.
2. Atualize somente o segredo `OPENROUTER_API_KEY` no provedor de hospedagem e
   faça novo deploy/restart controlado.
3. Execute o smoke manual autorizado e acompanhe os contadores agregados e os
   logs sem conteúdo.
4. Revogue a chave anterior no painel assim que a nova estiver confirmada.
5. Registre internamente a data, responsável e motivo, sem registrar o valor da
   chave.

### Suspeita de exposição

Desabilite imediatamente `CHAT_ENABLED`, revogue a chave no painel da
OpenRouter, investigue consumo e logs sem copiar a credencial, e crie uma nova
chave somente depois da análise. Uma chave enviada em chat, issue ou commit deve
ser tratada como exposta e rotacionada, mesmo que seja apagada em seguida.
