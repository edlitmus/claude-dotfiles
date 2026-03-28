---
name: review
description: Code review completo do código alterado ou de um arquivo/diretório específico.
argument-hint: "[arquivo ou diretório opcional]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Agent
model: sonnet
effort: high
context: fork
---

# Code Review

Faça uma revisão de código completa e profissional.

## Se um argumento foi fornecido
Revise o arquivo ou diretório: `$ARGUMENTS`

## Se nenhum argumento foi fornecido
Revise os arquivos alterados no working tree:
```bash
git diff --name-only HEAD
git diff --cached --name-only
```

## Critérios de revisão
Para cada arquivo, avalie:

1. **Correção**: A lógica está correta? Há edge cases não tratados?
2. **Segurança**: Há vulnerabilidades? Inputs validados? Secrets expostos?
3. **Performance**: Queries N+1? Loops desnecessários? Memória?
4. **Legibilidade**: Nomes claros? Funções pequenas? Complexidade controlada?
5. **Testes**: Há testes? Cobrem o happy path e edge cases?
6. **Padrões do projeto**: Segue as convenções existentes?

## Formato de saída
```
## Resumo
[1-3 frases sobre o estado geral]

## Problemas encontrados
### 🔴 Crítico
- [arquivo:linha] Descrição + sugestão de fix

### 🟡 Importante
- [arquivo:linha] Descrição + sugestão

### 🔵 Sugestão
- [arquivo:linha] Descrição

## Pontos positivos
- O que está bem feito

## Veredicto
[✅ Aprovado | ⚠️ Aprovado com ressalvas | ❌ Mudanças necessárias]
```
