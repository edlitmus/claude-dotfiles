# Convenções Globais

## Idioma
- Responda sempre em **português brasileiro** salvo instrução contrária.
- Commits, nomes de variáveis e código devem permanecer em **inglês**.

## Estilo de código
- Priorize legibilidade sobre concisão.
- Prefira funções pequenas e com responsabilidade única.
- Nomeie variáveis e funções de forma descritiva — evite abreviações obscuras.
- Não adicione comentários óbvios; comente apenas o "porquê", nunca o "o quê".
- Não crie abstrações prematuras — 3 linhas repetidas são melhores que 1 abstração desnecessária.

## Segurança
- Nunca exponha secrets, tokens ou senhas em código ou commits.
- Valide inputs em fronteiras do sistema (APIs, formulários), não internamente.
- Siga OWASP Top 10 como baseline.

## Git
- Mensagens de commit em inglês, imperativo, curtas (<72 chars na primeira linha).
- Prefixos: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`.
- Um commit por mudança lógica — não misture refactor com feature.

## Testes
- Toda feature nova deve ter pelo menos um teste.
- Prefira testes de integração sobre mocks quando o custo for baixo.
- Nomeie testes descrevendo o comportamento esperado, não o método.

## Arquitetura
- Separe responsabilidades: controller/service/repository ou equivalente.
- Evite dependências circulares.
- Use injeção de dependência quando fizer sentido para testabilidade.

## Ao receber uma tarefa
1. Leia o código existente antes de propor mudanças.
2. Pergunte se a instrução for ambígua — não assuma.
3. Proponha a solução mais simples que resolve o problema.
4. Se a mudança for grande, apresente um plano antes de implementar.
