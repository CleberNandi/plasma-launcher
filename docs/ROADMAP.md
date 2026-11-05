# Estado e próximos incrementos

**Atualizado:** 05/11/2026.
**Baseline integrada:** main em 365f83f, pacote experimental 0.1.1.

## Concluído no ambiente local

| Incremento | Resultado | Evidência |
| --- | --- | --- |
| PoC 02 | Catálogo KDE e diagnóstico dinâmico do laboratório | PR #2 |
| PoC 03A/03B | Grade nativa, categorias e abertura de aplicativos | PR #3 |
| PoC 03C/03D | Busca local, mapeamento de resultados, teclado e foco | PR #4 |
| PoC 03E/03F | Layout compacto C e favoritos próprios persistentes | PR #5 |
| PoC 03G | Popup no painel, atalho e persistência após login | PR #6 |
| PoC 03H | Coletor verificado, duas coletas agregadas e lint local | PR #6 |

Os PRs #2 → #3 → #4 → #5 → #6 foram integrados sequencialmente por merge commits.
A árvore final é idêntica à revisão fb6b2b0 validada antes da integração.
A homologação cobre o ambiente local documentado, não todas as versões Plasma.

## Próximo incremento — PoC 04A: perfil no rodapé

**Escopo preparado; implementação ainda não iniciada.**

Objetivo: substituir a identificação genérica do rodapé por uma apresentação
discreta do usuário da sessão, aproximando o produto do conceito visual escolhido.

- Nome e avatar obtidos de uma API KDE disponível no ambiente.
- Fallback para login e ícone de usuário quando nome/avatar estiverem ausentes.
- Nome longo truncado, mantendo o nome completo acessível por tooltip/acessibilidade.
- Manter dimensões do popup e acesso às mensagens de falha de abertura.
- Não acrescentar arquivo de preferências para dados já pertencentes à conta.
- Identificação visual, sem editar a conta ou introduzir autenticação.
- Validar a disponibilidade da API antes de implementar; registrar dependências.
- Preservar pesquisa, favoritos, foco e atalho homologados.
- Entrega em branch própria e PR para avaliação local.

Critério de aceite: perfil corresponde ao usuário da sessão, fallbacks
funcionam, rodapé cabe no popup e os fluxos básicos seguem operacionais.
Dados da sessão vistos em testes não devem ser publicados automaticamente.

## Em seguida — PoC 04B: ações de sessão

Escopo a avaliar após 04A: menu discreto para bloquear e, depois, suspender,
reiniciar ou desligar quando oferecidos pela infraestrutura nativa do KDE.

As capacidades e confirmações devem vir do KDE. Não construir comandos de shell,
não encerrar a sessão em testes automatizados e não implementar confirmação
própria que duplique ou suprima a política nativa. Avaliar integração sem C++
próprio antes de prometer a função. Login/avatar e ações de sessão são entregas
separadas para facilitar revisão e homologação.

## Qualidade e distribuição — MVP 0.2

- Tema claro/escuro, nomes longos, escala e acessibilidade por teclado/leitor.
- Verificação em outras posições de painel e monitores conforme disponíveis.
- Extrair componentes QML quando houver fronteiras claras; preservar a correção
  de ciclo de vida dos cards. Não refatorar junto de uma mudança funcional grande.
- Documentar versões suportadas, instalação/upgrade e reversão.
- Definir licença do repositório antes de uma distribuição pública: o campo MIT
  nos metadados não substitui um arquivo de licença.
- Automatizar verificações viáveis sem apresentar mocks como E2E KDE.

## Backlog posterior

- Relevância, aliases e busca aproximada, com critérios previsíveis.
- Densidade configurável e possíveis melhorias de apresentação dos resultados.
- Reordenação e coleções pessoais de favoritos.
- Avaliar integração com infraestrutura KRunner para funções universais.
- Atribuição de consumo por sessão isolada e latência até primeiro frame, apenas
  se necessárias para responder uma pergunta de desempenho concreta.

Não há compromisso de launcher independente para Hyprland/i3, indexador próprio,
sistema de plugins ou migração dos favoritos do Kickoff neste roadmap.
