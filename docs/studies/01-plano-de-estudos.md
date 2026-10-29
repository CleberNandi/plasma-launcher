# Plano de estudos — Plasma Launcher

**Versão:** 0.1  
**Stack:** KDE Plasma 6, Qt Quick 6, QML, JavaScript integrado ao QML  
**Ambiente-alvo:** Arch Linux, KDE Plasma 6, sessão Wayland  
**Status:** Planejamento — sem instalação ou desenvolvimento iniciado

## Objetivo

Aprender o necessário para desenvolver, testar e distribuir um launcher nativo como Plasmoid. O aprendizado ocorrerá **em paralelo às provas de conceito**, sem exigir estudo integral de Qt antes do início do desenvolvimento.

## Decisões e limites

- Usar QML/Qt Quick para a interface e JavaScript integrado ao QML para lógica simples de interação.
- Reutilizar as APIs públicas do KDE Plasma quando possível.
- Manter KRunner para busca global (`Super + Espaço`), sem recriar indexação de arquivos.
- Não utilizar C++, Electron, Python/PySide6 ou Node.js no MVP.
- Rust permanece hipótese futura, mediante necessidade demonstrada e decisão registrada.
- Preservar o Kickoff/Andromeda e permitir testes reversíveis.
- Não acoplar o projeto ao Arch Linux, embora seja o primeiro ambiente de homologação.

## Trilha prioritária

### Módulo 1 — Fundamentos de QML e Qt Quick (P0)

**Estudar**
- Estrutura de arquivos `.qml`, imports, tipos e árvore de objetos.
- `Item`, `Rectangle`, `Text`, `Image`, `MouseArea` e controles Qt Quick.
- `id`, propriedades, bindings, sinais e handlers (`onClicked`).
- Diferença entre declaração QML e expressões JavaScript dentro de QML.

**Exercício:** construir uma tela demonstrativa com cabeçalho e dois painéis.

**Critério de conclusão:** explicar o fluxo de uma mudança de propriedade até a atualização visual; criar uma interação sem código imperativo desnecessário.

### Módulo 2 — Layouts, modelos e delegates (P0)

**Estudar**
- `RowLayout`, `ColumnLayout`, âncoras e dimensionamento.
- `ListModel`, `Repeater`, `ListView`, `GridView` e delegates.
- Estados e seleção de categoria; filtragem sobre dados simulados.
- Diferenças entre dados de apresentação e identidade de aplicativo.

**Exercício:** barra lateral de categorias e grade que muda com a seleção.

**Critério de conclusão:** trocar categorias sem reconstruções desnecessárias e sem erros de binding.

### Módulo 3 — Estrutura de um Plasmoid no Plasma 6 (P0)

**Estudar**
- `metadata.json`, identificador único do pacote e estrutura `package/`.
- `PlasmoidItem`, `compactRepresentation` e `fullRepresentation`.
- Popup, dimensões, contexto do painel e ciclo de vida.
- Teste isolado antes de adicionar ao painel real.

**Exercício:** PoC 01, ícone compacto que abre um popup com conteúdo simulado.

**Critério de conclusão:** o widget carrega e abre sem alterar o launcher atual.

### Módulo 4 — Componentes e convenções do KDE (P1)

**Estudar**
- `org.kde.plasma.components`, componentes de tema e ícones.
- Convenções visuais do Plasma, acessibilidade e escala.
- Separação de componentes reutilizáveis QML.

**Exercício:** extrair `ProfileHeader`, `CategorySidebar` e `ApplicationGrid`.

**Critério de conclusão:** a interface responde adequadamente ao tema e à escala do Plasma.

### Módulo 5 — Catálogo real de aplicativos e execução (P0, risco técnico)

**Investigar**
- Desktop Entry Specification e categorias XDG.
- APIs públicas de descoberta e execução oferecidas pelo KDE.
- Modelos internos do Kickoff: disponibilidade, estabilidade e restrições de uso.
- Ícones, favoritos, arquivos `.desktop`, identificadores e parâmetros de execução.
- Diferença entre integração pública suportada e dependência de API privada.

**Exercício:** PoC 02, listar categorias e executar aplicativos reais sem montar comandos de shell com texto de pesquisa.

**Critério de conclusão:** catálogo correto, visibilidade compatível com KDE e execução segura; registrar a API selecionada e riscos de manutenção.

### Módulo 6 — Busca local, teclado e foco (P1)

**Estudar**
- Busca textual incremental no catálogo de aplicativos.
- `FocusScope`, navegação por teclado, `Enter`, `Escape` e seleção.
- Comportamento de popup e foco sob Wayland/KWin.
- Acessibilidade e feedback visual.

**Exercício:** filtrar e abrir aplicativo por teclado dentro do menu, sem substituir o KRunner.

**Critério de conclusão:** fluxo completo utilizável por teclado e mouse.

### Módulo 7 — Testes, diagnósticos e distribuição (P1)

**Estudar**
- Ferramentas de visualização/teste de Plasmoids disponíveis na versão instalada.
- Logs e diagnóstico de erros QML, verificações estáticas e testes manuais.
- Empacotamento com ferramentas KDE compatíveis com Plasma 6.
- Instalação e remoção reversíveis, sem privilégios de administrador quando possível.
- Compatibilidade entre versões Plasma/Frameworks.

**Exercício:** homologar o Plasmoid em um ambiente de teste e preparar instruções de distribuição.

**Critério de conclusão:** instalação e remoção documentadas, sem alterações destrutivas de configurações do usuário.

## Sequência de entregas

- [ ] **PoC 00 — Baseline:** verificar versões existentes e APIs, sem instalar pacotes.
- [ ] **PoC 01 — Interface:** Plasmoid com popup e categorias simuladas.
- [ ] **PoC 02 — Catálogo:** aplicativos e categorias reais por API validada.
- [ ] **MVP 0.1 — Usabilidade:** favoritos, busca local, mouse/teclado.
- [ ] **MVP 0.2 — Qualidade:** tema, acessibilidade, testes e distribuição.

## Registro de aprendizagem

Para cada módulo, registrar em `docs/studies/`:

1. Conteúdo estudado e fonte.
2. Exemplo executado e comportamento observado.
3. Dúvidas e limitações identificadas.
4. Decisões técnicas decorrentes.
5. Evidência de conclusão (teste, imagem ou commit).

Evitar escrever anotações extensas que apenas repetem a documentação oficial; priorizar conhecimento prático e decisões aplicáveis ao projeto.

## Referências oficiais

- [Qt QML — documentação](https://doc.qt.io/qt-6/qtqml-index.html)
- [Qt Quick — documentação](https://doc.qt.io/qt-6/qtquick-index.html)
- [KDE — Plasma Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [KDE — Setup de um Plasmoid](https://develop.kde.org/docs/plasma/widget/setup/)
- [Freedesktop — Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry/latest-single/)

## Próxima ação

Criar o repositório local, adicionar este documento ao Git e realizar a **PoC 00** (levantamento do ambiente e APIs) antes de instalar qualquer dependência.
