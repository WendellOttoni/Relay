# Privacidade mínima do MVP

Este documento descreve o comportamento pretendido do backend Relay no MVP. É
uma nota operacional, não substitui aviso legal aplicável ao site do GitHub
Pages nem a política do provedor de IA escolhido.

## Dados que transitam

Para gerar uma resposta, o navegador envia ao Relay o histórico limitado de
mensagens. O Relay encaminha ao provedor de IA somente os
dados necessários para a solicitação, acrescidos do prompt de sistema controlado
pelo servidor. O provedor e o modelo possuem políticas próprias que devem ser
revisadas antes da ativação.

O navegador pode manter seu histórico localmente. Isso está fora do controle do
Relay e deve ser explicado pela interface que o consome.

Quando o visitante solicita contato, nome, e-mail, empresa opcional, resumo do
projeto e proposta revisada são enviados ao Formspree somente após consentimento
explícito. O Relay não persiste esses campos, mas o serviço de entrega e a caixa
postal destinatária podem retê-los segundo suas próprias políticas. A finalidade
é exclusivamente responder à oportunidade comercial enviada pelo visitante.

## Dados que o Relay não deve guardar

No MVP, o Relay não possui banco nem histórico persistente. Não deve registrar:

- mensagens, respostas, histórico ou prompt de sistema;
- chave OpenRouter, `SECRET_KEY_BASE`, headers de
  autorização, token de socket ou cookies;
- respostas brutas de erro do provedor.

Os dados de uma oportunidade transitam em memória durante a entrega, sem serem
incluídos nos logs do Relay.

Logs e telemetria usam somente categorias de resultado, duração e contagens de
uso quando disponibilizadas. Eles podem existir temporariamente no host de
deploy e devem receber a mesma proteção operacional que outros dados de serviço.

## Uso responsável pelo consumidor

O GitHub Pages (ou outro consumidor aprovado) deve:

- avisar que mensagens são encaminhadas a um serviço de IA antes do envio;
- orientar usuários a não enviar segredos, credenciais ou dados pessoais
  desnecessários;
- não incorporar segredos no bundle público;
- apontar para as políticas aplicáveis do site, da hospedagem e do
  provedor/modelo de IA;
- oferecer um caminho de contato para questões de privacidade compatível com o
  responsável pelo projeto.

## Alterações futuras

Persistir conversas, adicionar login, analytics detalhado, contexto de
repositórios ou novas integrações altera materialmente este documento. Antes de
implementar qualquer um deles, defina finalidade, base aplicável, acesso,
retenção, exclusão, exportação, medidas de segurança e atualização do aviso ao
usuário.
