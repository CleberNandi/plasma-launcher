# Plano de estudos — Plasma Launcher

**Versão:** 0.2
**Stack:** KDE Plasma 6, Qt Quick 6, QML, JavaScript integrado ao QML  
**Ambiente-alvo:** Arch Linux, KDE Plasma 6, sessão Wayland  
**Status:** Checkpoint PoC 02: catálogo, Kate, favoritos e probe dinâmico validados no ambiente local; integração pendente

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

- [x] **PoC 00 — Baseline:** verificar versões existentes e APIs, sem instalar pacotes.
- [x] **PoC 01 — Interface:** Plasmoid com popup e categorias simuladas.
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

Revisar o checkpoint PoC 02 antes de integração. Homologar a navegação por subcategorias preparada na PoC 02F.1 (`docs/poc/POC-02F-navigation.md`); depois validar identidade estável dos aplicativos e definição do client/ordem dos favoritos. O probe de mudanças automáticas passou na rodada local de 30/10/2026; consultar `docs/poc/POC-02E-automated.md` para evidências e limites.

## Aprendizagem aplicada — PoC 02C

- **Modelo e roles:** RootModel fornece categorias; modelForRow fornece o
  submodelo. display, decoration e description são dados de apresentação.
- **Delegate e índice:** cada delegate representa uma linha do modelo da view.
  Seu index não é um identificador persistente e pode mudar com o catálogo.
- **Sinais:** onClicked delimita a solicitação explícita; bindings e criação de
  delegates não devem iniciar aplicativos.
- **Bindings:** selectedCategoryIndex altera o submodelo apresentado pela view.
  launchStatus atualiza o Label sem atribuir text duas vezes no mesmo objeto.
- **Ciclo de vida:** delegates são criados e destruídos pela view; submodelos
  pertencem à infraestrutura KDE. Não armazenar seus índices como identidade.
  Resets e o sinal de atualização do RootModel serão investigados na PoC 02E.
- **Diagnóstico:** o retorno de uma API e a evidência visual de abertura são
  observações distintas. Registrar ambos, sem deduzir sucesso de uma janela
  apenas pelo valor retornado.

Exercício imediato: localizar Kate, anotar a categoria e entender por que o
índice passado a trigger é o do aplicativo. Repetir após trocar de categoria.
Limite: não há runtime KDE/Qt neste ambiente Work; lint e execução devem ser
verificados na workstation. A API privada segue provisória.

## Aprendizagem aplicada — PoC 02D.1

- A assinatura em qmltypes descreve a interface; não prova ausência de efeitos
  colaterais de uma chamada nativa.
- ID de applet e client de persistência são conceitos distintos. O applet 66
  observado não autoriza deduzir que o contexto antigo instance-4 foi migrado.
- A view fica sem modelo até o clique. Após initForClient, o binding conecta a
  ListView diretamente ao modelo Qt; notificações do modelo atualizam a view.
- Uma chamada de inicialização pode retornar antes da consulta terminar.
  Contagem zero é um estado a observar, não um diagnóstico definitivo.
- A propriedade favorites não é usada como uma lista a sobrescrever.
  A PoC apresenta dados; migração e edição ficam fora deste incremento.

## Aprendizagem aplicada — PoC 02E.1

- Connections observa sinais do RootModel sem misturar a infraestrutura com
  delegates. Handlers usam function onNomeDoSinal().
- modelAboutToBeReset marca referências posicionais como inválidas. A view
  remove temporariamente seu submodelo antes de voltar a pedir modelForRow.
- Qt.callLater adia a reconexão até o controle retornar ao event loop; não é
  uma espera por tempo arbitrário nem um serviço de polling.
- Uma revisão observável força o binding a consultar novamente o submodelo,
  mesmo quando a contagem de categorias permanece igual.
- Reconstrução de modelo não preserva identidade por índice: a PoC volta à
  primeira categoria deliberadamente. Preservação por identidade estável é
  outra decisão, ainda não implementada.
- Contadores são evidência de sinais recebidos. Refresh manual bem-sucedido
  não comprova detecção automática de mudanças nos arquivos .desktop.

## Aprendizagem aplicada — PoC 02F.1 (entrada/retorno homologados; regressões pendentes)

- Uma linha com `hasChildren` representa um grupo navegável; seus filhos vêm de
  `modelForRow(index)` no modelo desse nível.
- O caminho é uma sequência de índices locais, não uma lista de IDs persistentes.
  Nomes entram apenas no rótulo visual.
- Atribuir um novo array à propriedade QML torna a mudança de caminho observável
  pelo binding do modelo exibido.
- Ao voltar, retira-se o último passo; ao trocar categoria ou reconstruir o
  catálogo, descarta-se o caminho inteiro.
- IDs dentro de um componente têm escopo próprio: handlers da representação
  passam o modelo à função externa, em vez de depender de IDs internos.
- Teste JavaScript com modelo sintético não comprova renderização nem sinalização
  do modelo Qt. A homologação local está descrita na PoC 02F.1.

### Escopo e vida útil — correções aplicadas em 02F.1

- Trocar o modelo pode destruir o delegate que disparou o clique. Não consultar
  seu contexto após a troca; reposicionamento pertence ao `onModelChanged` da
  view que continua viva. Correção homologada manualmente em 8a050ce.
- `pragma ComponentBehavior: Bound` explicita o contexto dos componentes internos
  e permite resolver IDs externos do mesmo arquivo. Não prolonga a vida de
  delegates nem substitui a correção anterior.
- Com Bound, dados de modelo devem entrar por propriedades `required`.
  Os três delegates experimentais já declaram esses dados explicitamente.
- O pragma foi preparado para validação Qt6 local. Redução de warnings e
  ausência de regressão visual precisam ser medidas, não inferidas.

## Aprendizagem aplicada — PoC 02G.1 (homologação pendente)

- `display` é um nome de apresentação, não uma identidade. Um mesmo nome pode
  pertencer a desktop entries diferentes.
- O role `favoriteId` do Kicker identifica a entrada no catálogo e pode ser lido
  sem inicializar ou escrever no modelo de favoritos.
- A restrição experimental usa igualdade exata com
  `applications:org.kde.kate.desktop`, tanto na visibilidade quanto no clique.
  Não se aceitam sufixos, ações, caminhos alternativos ou fallback pelo nome.
- Um ID de catálogo não autentica o executável: sobreposições XDG e o conteúdo
  de desktop entries continuam sendo responsabilidade da infraestrutura KDE.
- O teste sintético verifica a decisão de permitir/bloquear; somente a execução
  local valida o role real entregue pelo Kicker e a abertura da aplicação.
