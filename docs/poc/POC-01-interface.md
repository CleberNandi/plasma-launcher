# PoC 01 — Interface QML

## Ambiente
- Arch Linux, kernel 7.2.11
- KDE Plasma 6.8.1
- Qt 6.12.0
- Wayland

## Objetivo
Validar a execução de um Plasmoid nativo com interface
QML e catálogo simulado de aplicativos.

## Evidências
- metadata.json validado com jq.
- main.qml formatado com qmlformat.
- qmllint sem diagnósticos.
- plasmawindowed executado.
- Interface renderizada corretamente.
- Processo encerrado com código 0.

## Pendente
- Confirmar troca de categorias.
- Validar representação compacta no painel.
- Integrar catálogo real de aplicações (PoC 02).

## Restrições
- Sem C++.
- Sem instalação no painel durante esta PoC.
- KRunner permanece inalterado.
