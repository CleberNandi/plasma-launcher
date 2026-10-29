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



## Homologação PoC 01B — Integração Plasma

Ambiente:
- Arch Linux
- KDE Plasma 6.8.1
- Qt 6.12.0
- Wayland

### Testes funcionais

- [x] Widget aparece no painel.
- [x] Popup abre corretamente.
- [x] Segundo clique fecha o popup.
- [x] Categorias filtram os aplicativos.
- [x] Clique externo fecha o popup.
- [x] KRunner permanece funcional.
- [x] Launcher original permanece disponível.
- [x] Largura da barra lateral permanece estável.

### Geometria validada

- Popup: 700 × 500
- Layout interno: 668 × 468
- Barra lateral: 190
- Espaçamento: 16
- Área de aplicativos: 462

Valores obtidos com plasmawindowed em pixels lógicos.

### Resultado

PoC 01B aprovada.

A instalação local foi atualizada com kpackagetool6.
O Plasma precisou recarregar a instância QML para
refletir a versão atualizada.

### Limitações

- Catálogo ainda simulado.
- Aplicativos não executáveis.
- Favoritos ainda simulados.
- Interface visual provisória.
- Pesquisa local ainda não implementada.
