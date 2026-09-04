# Estado atual do Relay

Atualizado em 4 de setembro de 2026.

## Em produção e validado

- Relay publicado no Render em `https://relay-sa0e.onrender.com`;
- frontend publicado no GitHub Pages com widget flutuante, carregado somente ao
  abrir o assistente;
- criação de sessão curta, conexão Phoenix Channel e respostas em streaming pela
  OpenRouter;
- CORS e origem do WebSocket limitados ao site configurado;
- prompt de sistema comercial: o assistente usa o contexto do portfólio, não
  inventa preço, prazo ou fatos e pode estruturar uma proposta inicial;
- ações no resultado para copiar, baixar e transformar a conversa em uma
  oportunidade;
- formulário revisável de oportunidade com consentimento explícito;
- entrega autenticada no endpoint `/api/v1/leads` para o Formspree;
- entrega real de e-mail validada pelo destinatário;
- limites locais para criação de sessão, mensagens, gerações e oportunidades;
- o Relay não persiste conversas nem dados de oportunidade e não registra PII
  nos logs.

## Configuração ativa

No Render, o chat requer `CHAT_ENABLED=true`, a chave/modelo da OpenRouter e as
origens públicas corretas. A entrega de oportunidades requer
`LEAD_DELIVERY_ENABLED=true` e `FORMSPREE_FORM_ENDPOINT` com URL HTTPS de um
formulário Formspree. No frontend, `leadDeliveryEnabled` está ativado em
`relay-config.js`.

Nenhum segredo deve ser incluído no repositório ou no bundle do GitHub Pages.

## Fora do escopo atual

- integração com GitHub API/App;
- banco de dados, login, histórico ou painel administrativo;
- geração de PDF ou assinatura de proposta;
- limites distribuídos para múltiplas instâncias;
- registro formal do teto financeiro e smoke manual isolado da OpenRouter.

Esses itens permanecem como evolução opcional no [roadmap](roadmap.md).
