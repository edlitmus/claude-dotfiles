---
name: review
description: Code review completo e estruturado com veredicto formal. Revisa correção, segurança, performance, legibilidade, testes e padrões.
argument-hint: "[arquivo ou diretório opcional]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Agent
model: sonnet
effort: high
context: fork
---

# Code Review

Faça uma revisão de código completa, estruturada e profissional.

## Escopo

### Se um argumento foi fornecido
Revise o arquivo ou diretório: `$ARGUMENTS`

### Se nenhum argumento foi fornecido
Revise os arquivos alterados no working tree:
```bash
git diff --name-only HEAD
git diff --cached --name-only
```

## Anti-racionalização do review
Antes de começar, internalize:
- "O código parece limpo" → NÃO é motivo para pular categorias. Revise TODAS.
- "É uma mudança pequena" → Mudanças pequenas causam a maioria dos bugs em produção.
- "O autor é experiente" → Experiência não impede bugs. Revise como se fosse código novo.
- "Já vi esse padrão" → ESTE contexto pode ter diferenças. Leia com atenção.

## Categorias de revisão (TODAS obrigatórias)

### 1. Correção
- A lógica está correta?
- Há edge cases não tratados? (null, vazio, limites, concorrência)
- Contratos de tipos estão corretos?
- Há off-by-one errors?

### 2. Segurança
- Inputs de usuário são validados/sanitizados?
- Queries são parametrizadas?
- Há secrets hardcoded?
- Headers de segurança estão presentes?
- Dependências têm vulnerabilidades conhecidas?

### 3. Performance
- Queries N+1?
- Loops desnecessários sobre coleções grandes?
- Alocações de memória excessivas?
- Chamadas de rede em loops?
- Índices de banco necessários existem?

### 4. Legibilidade
- Nomes descrevem intenção?
- Funções têm responsabilidade única?
- Complexidade ciclomática está controlada?
- Há dead code?
- Comentários explicam "porquê" (não "o quê")?

### 5. Testes
- Há testes para a mudança?
- Cobrem happy path E edge cases?
- Mocks são necessários ou poderia ser integração?
- Nomes dos testes descrevem comportamento?

### 6. Padrões do projeto
- Segue convenções do codebase existente?
- Imports organizados?
- Estrutura de diretórios respeitada?
- Consistente com arquivos vizinhos?

## Formato de saída OBRIGATÓRIO

```
## Resumo
[1-3 frases sobre o estado geral]

## Arquivos revisados
| Arquivo | Linhas | Categorias com issues |
|---|---|---|

## Findings

### 🔴 Crítico (bloqueia merge)
> Bugs, vulnerabilidades, perda de dados, breaking changes não documentados.

- **[arquivo:linha]** Descrição
  - Impacto: [o que acontece se não corrigir]
  - Fix: [sugestão concreta]

### 🟡 Importante (deve corrigir)
> Problemas de performance, patterns incorretos, testes faltando.

- **[arquivo:linha]** Descrição
  - Fix: [sugestão]

### 🔵 Sugestão (pode melhorar)
> Legibilidade, naming, simplificação.

- **[arquivo:linha]** Descrição

### ✅ Pontos positivos
- [O que está bem feito — reconheça boas práticas]

## Checklist
- [ ] Correção: edge cases tratados
- [ ] Segurança: inputs validados, sem secrets
- [ ] Performance: sem N+1, sem loops desnecessários
- [ ] Legibilidade: nomes claros, funções curtas
- [ ] Testes: happy path + edge cases cobertos
- [ ] Padrões: consistente com o projeto

## Veredicto

**PASS** | **FAIL** | **NEEDS DISCUSSION**

- PASS: sem findings críticos ou importantes, código pronto para merge.
- FAIL: há findings críticos que DEVEM ser corrigidos antes do merge.
- NEEDS DISCUSSION: há questões de arquitetura/design que precisam de alinhamento.

Justificativa: [1 frase explicando o veredicto]
```

## Regras
- NUNCA dê PASS com findings críticos ou importantes pendentes.
- Se não encontrar nenhum problema, suspeite — releia com mais atenção.
- Review vazio ("tudo ok") é PROIBIDO — sempre detalhe o que foi verificado.
