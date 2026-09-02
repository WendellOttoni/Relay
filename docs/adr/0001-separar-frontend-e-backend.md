# 0001 — Separar o frontend estático do backend

- Status: Aceita
- Data: 2026-09-02

## Contexto

O frontend será hospedado no GitHub Pages, que entrega arquivos estáticos. O
chat precisa utilizar credenciais secretas, aplicar limites e conversar com APIs
externas. Código executado no navegador é público e controlado pelo usuário.

## Decisão

Manter o frontend no GitHub Pages e executar o Relay em um serviço de backend
separado, acessível por HTTPS. O frontend conhece somente a URL pública e o
contrato versionado do Relay.

## Consequências

O frontend preserva hospedagem simples e barata, enquanto o backend pode guardar
segredos e controlar uso. Passamos a operar dois deploys, configurar CORS e
monitorar disponibilidade e custo do serviço externo.

## Alternativas consideradas

- **Chamar a IA diretamente do navegador:** rejeitada porque expõe credenciais
  ou exige entregar ao cliente capacidade que não pode ser controlada.
- **Hospedar frontend e backend juntos:** possível em outra plataforma, mas
  abandona o objetivo de manter o site no GitHub Pages.
- **Usar GitHub Actions como backend:** rejeitada porque automações de build não
  substituem uma API interativa e continuamente disponível.
