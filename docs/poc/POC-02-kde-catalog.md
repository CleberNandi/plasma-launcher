
# PoC 02 — Catálogo real de aplicativos KDE

## Ambiente

- Arch Linux
- KDE Plasma 6.8.1
- Qt 6.12.0
- KService 6.31.0
- Wayland

## PoC 02A — Descoberta do catálogo

- [x] Módulo Kicker disponível.
- [x] RootModel instanciado por QML.
- [x] Dez categorias reais identificadas.
- [x] Sem C++ próprio.

## PoC 02B — Navegação por categorias

- [x] modelForRow() retorna os submodelos.
- [x] Aplicativos reais apresentados.
- [x] Navegação entre categorias funcional.
- [x] Catálogo simulado do launcher principal preservado.

## Decisão arquitetural provisória

Utilizar org.kde.plasma.private.kicker como candidato
para integração do catálogo real.

O módulo é uma API privada do Plasma.
Sua adoção definitiva depende de validação de
compatibilidade, execução e ciclo de vida dos modelos.

## Próximos testes

- [ ] PoC 02C — Ícones, metadados e execução.
- [ ] PoC 02D — Favoritos.
- [ ] PoC 02E — Atualização dinâmica do catálogo.

## Restrições

- Sem C++.
- KRunner permanece inalterado.
- Nenhuma modificação no launcher principal.
- Nenhuma execução de aplicativos realizada até aqui.
