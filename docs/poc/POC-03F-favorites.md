# PoC 03F — Favoritos próprios na lateral

**Data:** 04/11/2026.
**Base:** 6747482f9e773d81461f96f6b0efc3f883097553.
**Branch:** feat/poc-03-compact-layout.
**Status:** implementação preparada; lint, interação e persistência KDE pendentes.

## Comportamento

Favoritos aparece acima de Todos os aplicativos, separado da lista de categorias.
Começa vazio. Clique com o botão direito em um aplicativo e escolha Adicionar aos
favoritos; o mesmo menu permite Remover dos favoritos. Também pode ser aberto por
Shift+F10 com um card selecionado na grade. Clique esquerdo/Enter continuam abrindo
o aplicativo pela mesma função existente.

Ao escolher Favoritos, consulta e caminho são limpos e a grade mostra a lista
salva. Uma pesquisa posterior continua abrangendo todo o catálogo. Cima em Todos
os aplicativos leva a Favoritos; Baixo em Favoritos volta a Todos. Direita entra
na grade; Esquerda na primeira coluna volta à seção lateral correspondente.

## Persistência e modelo

package/contents/config/main.xml define favoriteApplicationIds como StringList,
inicialmente vazia, no grupo General. A configuração pertence à instância deste
plasmoid, salva pelo Plasma/KConfig via Plasmoid.configuration. Não se usa o
contexto KAStats fixo do laboratório, não se lê nem escreve favoritos do Kickoff.

A lista guarda IDs applications:*.desktop, sem query/fragmento, deduplicados.
Inclusão/remoção grava uma nova lista; não há shell, Exec, arquivo JSON próprio
ou indexador. IDs inválidos são ignorados. A configuração guarda somente IDs,
não nomes, ícones ou posições do catálogo.

Kicker.SimpleFavoritesModel resolve IDs para nome, ícone, descrição e ativação.
Ele é instanciado como propriedade filha do RootModel de aplicativos, fornecendo
ao AppEntry o contexto nativo de formatação que ele espera. Não se substitui o
KAStatsFavoritesModel interno do RootModel nem se inicializa contexto externo.
A lista do modelo é revinculada ao estado do catálogo; durante reset fica vazia
e reaplica os IDs configurados ao concluir. IDs de apps indisponíveis podem
permanecer salvos e voltar ao catálogo; não são apagados silenciosamente.

O menu pertence à representação principal, copia apenas ID/nome, e usa a grade
estável como referência de posição. A gravação que pode destruir o delegate é
a última operação relevante, evitando leitura posterior de um objeto removido.
Um modelo vazio recebe uma mensagem com instruções para adicionar favoritos.

## Fontes inspecionadas

- KDE plasma-workspace, revisão 63e20ff9d15bbb709d8fb59952088e536ae8d523:
  applets/kicker/simplefavoritesmodel.h/.cpp, rootmodel.h/.cpp, abstractmodel.h.
  Modelo exportado com QML_ELEMENT; favorites, count, trigger, refresh e roles.
- [Configuração de plasmoids](https://develop.kde.org/docs/plasma/widget/configuration/).
- [Qt Quick Controls Menu](https://doc.qt.io/qt-6/qml-qtquick-controls-menu.html).

Kicker é API privada; disponibilidade e comportamento precisam de validação no
Plasma local. A ausência de C++ próprio não elimina essa dependência.

## Verificações no Work

Funções reais extraídas do QML foram exercitadas com mocks: normalização,
deduplicação, inclusão/remoção, persistência por lista nova, recusa de esquema
inválido e catálogo indisponível, recarga simulada de configuração e seleção
da seção. Funções de ativação e atualização da busca são idênticas à base.
IDs únicos e whitespace conferidos. qmllint não está instalado neste ambiente.

A simulação não valida exportação QML nativa, parentesco QObject, renderização,
interação do menu nem gravação KConfig em disco. Nenhum PASS nativo é inferido.

## Teste no KDE

Executar uma linha por vez:

```bash
git pull --ff-only origin feat/poc-03-compact-layout
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
plasmawindowed "$PWD/package"
```

1. Conferir Favoritos acima de Todos os aplicativos e estado vazio.
2. Buscar kate; botão direito no card → Adicionar aos favoritos. A operação não
   deve abrir Kate.
3. Selecionar Favoritos e conferir nome/ícone; abrir Kate por clique/Enter.
4. Adicionar VS Code e conferir ambos. Verificar Shift+F10 e navegação lateral.
5. Fechar normalmente o viewer, reabrir o mesmo pacote e conferir persistência.
   A identidade da instância de plasmawindowed pode diferir da futura instância
   instalada no painel; não prometer compartilhamento automático entre elas.
6. Remover um favorito pelo menu, conferir a lista e reabrir para verificar.
7. Repetir busca code/kate após alternar Favoritos/categorias.

Relatar terminal, revisão e sequência em caso de falha. Não reconstruir cache,
editar configuração do painel ou instalar dependências para contornar erros.
Não há reordenação/drag-and-drop, importação, sincronização entre instâncias ou
ações de sessão neste incremento. Laboratório PoC 02 inalterado. Sem merge.
