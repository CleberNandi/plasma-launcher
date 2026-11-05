# Plasma Launcher

Launcher experimental nativo para KDE Plasma 6, feito com QML, Qt Quick e
JavaScript integrado ao QML. Direção visual: catálogo compacto C, com Favoritos
no topo da lateral e categorias do KDE.

## Estado atual

O checkpoint funcional foi integrado à main em 05/11/2026
(`365f83f`, PRs #2 a #6). Versão do pacote: **0.1.1**, ainda experimental.

- Catálogo e categorias reais via Kicker; subcategorias reunidas na grade.
- Busca literal por nome e descrição em todo o catálogo.
- Abertura por clique ou Enter, seleção por setas e Escape em duas etapas.
- Favoritos próprios por instância, editados pelo botão direito ou Shift+F10.
- Popup no painel, foco inicial na pesquisa e fechamento após abertura aceita.
- Atalho configurável pelo Plasma; Ctrl+Shift+Enter testado pelo usuário.
- Persistência de widget, favoritos e atalho após novo login confirmada.

Homologação local em Arch Linux, Plasma 6.8.2 e Wayland. O qmllint Qt6 passou
sem diagnósticos e com saída 0. Cinco testes do coletor passaram no Work.
Duas coletas agregadas de plasmashell estão registradas; não são uma medida
isolada do consumo do launcher nem um benchmark de latência.

## Testar a janela do laboratório

No diretório do repositório, executar cada linha separadamente:

```bash
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
plasmawindowed "$PWD/package"
```

## Instalar no painel

Como usuário comum, sem sudo:

```bash
kpackagetool6 --type Plasma/Applet --install "$PWD/package"
```

Se o pacote já estiver instalado, usar upgrade:

```bash
kpackagetool6 --type Plasma/Applet --upgrade "$PWD/package"
```

No modo de edição do painel, adicionar o widget **Plasma Launcher Lab**.
A instalação copia o pacote; mudanças posteriores no checkout precisam de upgrade.
Favoritos do viewer e de cada instância no painel são separados.
Instruções de teste, atualização e reversão estão na
[PoC 03G](docs/poc/POC-03G-panel-popup.md).

## Limites

- Kicker é API privada do Plasma; compatibilidade precisa ser revalidada.
  A versão mínima 6.0 declarada nos metadados não é uma matriz homologada.
- Busca aproximada, perfil do usuário, ações de sessão e reordenação de favoritos
  ainda não estão implementados.
- KRunner continua separado da busca local; não há indexação própria de arquivos.
- Não há runtime C++, Electron, Python ou Node no widget. Python e Node foram
  usados apenas em ferramentas de desenvolvimento/verificação fora do pacote.
- X11, outros ambientes, painel vertical e múltiplas escalas/monitores não têm
  homologação específica registrada.

## Documentação

- [Plano de estudos](docs/studies/01-plano-de-estudos.md)
- [Estado e próximos incrementos](docs/ROADMAP.md)
- [Catálogo e grade](docs/poc/POC-03A-native-grid.md)
- [Busca local](docs/poc/POC-03C-local-search.md)
- [Teclado](docs/poc/POC-03D-keyboard.md)
- [Favoritos](docs/poc/POC-03F-favorites.md)
- [Painel e persistência](docs/poc/POC-03G-panel-popup.md)
- [Coletas e limites de desempenho](docs/poc/POC-03H-performance.md)
