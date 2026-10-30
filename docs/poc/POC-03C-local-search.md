# PoC 03C — Pesquisa local de aplicativos

**Data:** 30/10/2026.
**Status:** preparada; import, lint Qt6 e homologação KDE pendentes.
**Branch:** feat/poc-03-local-search.
**Base:** de67c0960d707a2c7642bea8fe33000ea30ed610 (PoC 03B).

## Experiência

Campo “Pesquisar aplicativos…” no cabeçalho. A pesquisa cobre nome e descrição
de todos os aplicativos instalados presentes no catálogo, independentemente da
categoria selecionada. Termos separados por espaço devem aparecer no conjunto
nome/descrição, sem distinção de maiúsculas. São substrings literais: não há
regex fornecida pelo usuário, busca fuzzy, remoção de acentos ou ranking novo.

A entrada nativa Todos os aplicativos passa a integrar a barra lateral e a ser
a seleção inicial. Resultados usam a grade e os mesmos cards. O título mostra
a contagem. Nenhum resultado exibe mensagem específica.

Limpar ou Escape no campo remove a pesquisa e retorna à categoria selecionada.
Selecionar uma categoria também limpa o texto. Somente espaços não ativam busca.
Digitar/limpar não abre aplicativos; a ativação continua por clique explícito.
Enter para abrir o primeiro resultado e navegação direcional de resultados ficam
para o próximo incremento de teclado/foco, sem alegar suporte nesta entrega.

Ao reconstruir o catálogo, a view e a origem do proxy são desligadas enquanto
catalogReady é falso; a pesquisa é reaplicada à nova origem. Não se preservam
índices entre reconstruções nem se armazenam ponteiros de resultados em arrays.

## Implementação

Kicker.RootModel usa showAllApps true, showAllAppsCategorized false,
showFavoritesPlaceholder false e showRootSeparator false, com recentes e energia
desativados. Na fonte KDE consultada, o grupo de todos os apps é deduplicado,
ordenado e inserido na primeira linha quando essas opções estão configuradas.
Esse submodelo fornece a origem do filtro; ele também aparece como item nativo
na lateral. Não há leitura de arquivos desktop por código próprio.

Novo import público: `org.kde.kitemmodels`, KSortFilterProxyModel.
Não se adiciona processo, serviço, pacote de outro ecossistema ou código C++.
É necessário confirmar a presença desse módulo QML na instalação local;
não instalar automaticamente se faltar.

O proxy mantém os roles e a origem nativos. filterRoleName description resolve
o ID desse role; o callback usa esse ID e Qt.DisplayRole para ler dados.
O callback substitui o filtro padrão. invalidateFilter é chamado ao mudar a
consulta; os sinais do modelo mantêm a origem observável.
sortRoleName vazio preserva a ordem do submodelo já ordenado pelo Kicker.

Antes de trigger, a linha de resultado é mapeada por mapToSource(index(row, 0)).
A abertura usa o modelo de origem e sua linha, nunca o índice filtrado diretamente.
O guard de entrada de aplicação e os argumentos vazios/null são preservados.
A pesquisa não usa RunnerModel, runners, busca de arquivos ou comandos de shell.
KRunner e Super+Espaço permanecem independentes.

O título inicial da categoria usa labelForRow, evitando uma tradução própria
do rótulo fornecido pelo KDE.

## Fontes inspecionadas

- [RootModel — KDE plasma-workspace, 63e20ff9d15b](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/rootmodel.cpp):
  construção/deduplicação e posição do grupo Todos os aplicativos.
- [AbstractModel](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/abstractmodel.h):
  labelForRow e acesso aos submodelos.
- [KSortFilterProxyModel — KItemModels, e9867153a8ec](https://github.com/KDE/kitemmodels/blob/e9867153a8ec96d541e0c21d4cf2fda78e7cb8ee/src/qml/ksortfilterproxymodel.h)
  e [implementação](https://github.com/KDE/kitemmodels/blob/e9867153a8ec96d541e0c21d4cf2fda78e7cb8ee/src/qml/ksortfilterproxymodel.cpp):
  resolução de roles por nome, callback, invalidação e mapeamento.

O contrato posicional do grupo Todos e o próprio Kicker são privados e devem ser
conferidos no ambiente homologado. Fontes upstream fundamentam a implementação,
não substituem teste da versão instalada.

## Verificações realizadas

Funções reais extraídas do QML foram exercitadas em JavaScript com mocks:
nome, descrição com múltiplos termos/maiúsculas, vazio e sem correspondência,
caracteres de regex tratados literalmente, linha 2 do proxy mapeada para linha 6
da origem, caminho direto sem proxy, mapeamento inválido e reset bloqueados,
troca de categoria limpando consulta e rótulo inicial vindo do modelo.
Conferidas única chamada trigger, ausência de RunnerModel e whitespace.

Não se executou engine QML, qmllint ou KDE no Work. Não foi verificado
comportamento nativo do callback/import, QModelIndex ou foco da janela.
Esses são itens do teste local.

## Homologação local curta

Com árvore limpa, primeira entrada na branch:

```bash
git status --short --branch
git fetch origin
git switch --track origin/feat/poc-03-local-search
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
plasmawindowed "$PWD/package"
```

1. Selecionar uma categoria sem Kate e pesquisar kate: deve encontrá-lo mesmo
   fora da categoria. Clicar no resultado e confirmar que Kate abre.
2. Pesquisar outro aplicativo conhecido, com várias correspondências se possível,
   e abrir um resultado que não seja o primeiro. Confirmar a janela correta.
3. Pesquisar editor ou trecho de uma descrição visível no tooltip; o resultado
   deve corresponder ao texto instalado. Testar maiúsculas e dois termos.
4. Pesquisar texto inexistente, limpar e usar Escape; verificar saída do modo
   de busca, seleção e grade coerentes. Selecionar categoria enquanto pesquisa.
5. Somente digitar e navegar não deve iniciar aplicativos.

Enviar diagnósticos e resultados. Se o import KItemModels falhar, relatar a saída;
não instalar ou substituir por RunnerModel para contornar. Não alterar painel.
Sem merge.

## Layout e continuidade

O usuário fará pesquisas de referências visuais. Reservado refinamento de layout
com mockups comparáveis antes de nova reorganização: hierarquia de perfil,
pesquisa, favoritos, categorias e grade; tema/escala e navegação por teclado.
Esta entrega apenas encaixa o campo de pesquisa no cabeçalho existente.
Não tratar o layout atual como direção visual definitiva.

O PR de pesquisa tem base na branch da grade, dependente do PR #3, que por sua
vez depende do #2. Rever base e diff antes de retarget após qualquer squash.
