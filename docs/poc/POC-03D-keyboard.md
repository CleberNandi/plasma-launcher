# PoC 03D — Teclado, foco e ativação

**Data:** 30/10/2026.
**Status:** implementação e testes lógicos preparados; eventos/foco no KDE pendentes.
**Branch:** feat/poc-03-local-search.
**Base:** 3ec6a0eb753dbf39f8e602cf94f3ac58f0e1cc3d (busca por clique homologada).

## Interação

| Local | Tecla | Comportamento |
| --- | --- | --- |
| Pesquisa | Baixo | Seleciona primeiro resultado e transfere foco à grade |
| Pesquisa | Enter/Enter numérico | Seleciona e solicita abertura do primeiro resultado, se houver |
| Grade | Setas | Move seleção, sem abrir |
| Grade, primeira linha | Cima | Volta o foco à pesquisa |
| Grade, primeira coluna | Esquerda | Transfere foco às categorias |
| Grade | Enter/Enter numérico | Ativa o item selecionado |
| Categorias | Cima/Baixo | Seleciona categoria e atualiza conteúdo |
| Categorias | Direita ou Enter | Entra na grade, sem abrir aplicativo |
| Grade/categorias | Escape | Limpa pesquisa e foca o campo |
| Pesquisa | Escape | Limpa o texto |
| Fluxo geral | Tab/Shift+Tab | Usa a sequência de foco dos controles nativos |

Enter mantido pressionado não repete solicitações: os handlers de ativação
recusam eventos isAutoRepeat. Setas podem repetir para navegação.
Resultado vazio, catálogo em reset ou ausência de seleção não executam nada.
Uma nova consulta ou mudança estrutural do modelo invalida a seleção antiga.
Para ativar após essa invalidação na grade, selecionar novamente com uma seta;
Enter no campo escolhe explicitamente o primeiro resultado da consulta atual.

Movimento horizontal segue a ordem dos itens e fica limitado ao primeiro/último.
Movimento vertical usa a contagem atual de colunas, limitada à lista.
Este incremento tem como alvo a disposição esquerda→direita do ambiente local;
não declara suporte homologado a RTL ou todos os cenários de acessibilidade.

## Implementação e ciclo de vida

A grade mantém currentIndex e o foco; cards não criam uma parada Tab para cada
aplicativo. O card selecionado é destacado pelo controle nativo, com texto da
cor de destaque do tema. Um clique também atualiza seleção e foca a grade antes
de chamar activateEntry, sem consultar o delegate após a chamada.

A grade emite activationRequested(row); o delegate que representa essa linha
entrega seu modelo à mesma função de ativação usada pelo mouse.
Não se tenta ler propriedades customizadas de currentItem (tipado como QQuickItem)
nem se salva seu ponteiro para uso futuro. forceLayout antecede a emissão para
aplicar alterações pendentes da view; criação/foco reais ainda precisam de teste.

O fluxo continua passando pelo mapeamento do proxy à origem e pelos guards
existentes. Não há segundo caminho de trigger exclusivo do teclado.

selectionInvalidated é emitido ao mudar consulta, categoria/caminho ou reconstruir
o catálogo. A grade observa também alterações estruturais do modelo exibido:
reset, inserção, remoção, movimentação e layout. Sua seleção volta a -1.
Nenhuma dessas notificações solicita execução.

Referência: [Qt — GridView](https://doc.qt.io/qt-6/qml-qtquick-gridview.html),
currentIndex, foco/teclado, ciclo de vida de delegates e positionViewAtIndex.
A lógica de movimento é explícita; keyNavigationEnabled fica false para evitar
processar a mesma seta também pelo comportamento automático da view.
Enter na lista de categorias transfere foco e não abre o primeiro aplicativo.

## Verificações no Work

Funções reais extraídas do QML e o handler de activationRequested foram
exercitados com mocks. Casos: primeiro resultado, seleção por setas, último item
em linha incompleta, limites, lista vazia, invalidação e reset, transferência de
foco simulada e linha 2 filtrada mapeada para linha 7 na origem.
Setas não chamaram trigger; cada emissão selecionada gerou uma única ativação.
Conferidos guards de repetição, única chamada trigger e whitespace.

Esses testes não simulam a entrega real de KeyEvent, ordem de foco do Qt,
instanciação da view, event propagation ou atalhos do KWin/Wayland.
Não se executou runtime KDE/qmllint no Work. Não é homologação nativa de teclado.

## Teste local

Com árvore limpa na branch de pesquisa:

```bash
git pull --ff-only origin feat/poc-03-local-search
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
plasmawindowed "$PWD/package"
```

1. Digitar kate e pressionar Enter: confirmar abertura do Kate.
2. Pesquisar termo com vários resultados (por exemplo qt, se houver). Baixo
   seleciona o primeiro; Direita/Baixo mudam o destaque. Enter deve abrir
   exatamente o selecionado, não o primeiro nem outro item da origem.
3. Repetir sem resultados: Enter não faz nada. Limpar com Escape.
4. Após selecionar resultado, voltar ao campo com Cima na primeira linha e mudar
   a consulta; a seleção anterior não deve permanecer ativa.
5. Esquerda na primeira coluna entra nas categorias. Cima/Baixo trocam categoria;
   Direita/Enter entram na grade sem abrir aplicativo.
6. Conferir mouse, Tab/Shift+Tab, rolagem até um item fora da área inicial e
   redimensionamento. Uma tecla Enter mantida não deve gerar aberturas repetidas.

Relatar falha com a sequência exata, item destacado, aplicativo aberto e terminal.
Não instalar ferramentas nem alterar atalhos globais/painel para concluir o teste.
Sem fechamento de popup, novas dependências ou alterações de favoritos.
Sem merge.

O layout maior segue provisório; teclado não determina a futura direção visual
nem dispensa avaliação dos mockups/referências que o usuário irá reunir.

## Retorno do lint local — 04/11/2026

O usuário reportou dois avisos missing-property no caminho de ativação da busca:
QModelIndex.row e QAbstractItemModel.count. Não foi relatado resultado do teste
nativo de teclado nesta rodada. A colagem do comando também continha o marcador
[200~, causando bad pattern no zsh; isso é separado dos avisos QML.

A ativação agora recupera a origem por root.allApplicationsModel, a referência
dinâmica ao modelo Kicker também usada em sourceModel do proxy. Essa referência
preserva count e trigger, ausentes da interface estática QAbstractItemModel.
O mapeamento continua sendo mapToSource, sem tratar linha filtrada como origem.

QModelIndex.row é uma propriedade da API QML documentada pelo Qt:
[QModelIndex em QML](https://doc.qt.io/qt-6/qmodelindex-and-related-classes-in-qml.html).
Foi mantida uma supressão missing-property somente nessa linha, com comentário
explicativo; os demais diagnósticos continuam habilitados. Não se troca row por
row(), pois a interface QML expõe uma propriedade.

A função real de ativação foi exercitada com mocks: linha filtrada 2 mapeada
para origem 7 com uma chamada trigger; índice inválido e origem ausente não
ativam. Isso não substitui qmllint e execução no KDE, ainda pendentes.

## Retorno manual de teclado — 04/11/2026

O usuário confirmou que setas e Enter funcionam. Nesta mesma rodada apareceu
uma divergência de nome/ícone nos resultados filtrados; a busca Code abriu VS Code,
mas exibiu outro aplicativo no card. O SHA local não foi informado. Não se infere
aprovação individual de Escape, Tab, repetição ou reset de catálogo.
A correção candidata e seu reteste estão registrados em POC-03C-local-search.md.
