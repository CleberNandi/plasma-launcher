
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

- [x] PoC 02C.1 — Roles display, decoration e description homologadas.
- [ ] PoC 02C.2 — Execução controlada preparada; homologação desta revisão pendente.
- [ ] PoC 02D — Favoritos.
- [ ] PoC 02E — Atualização dinâmica do catálogo.

## Restrições

- Sem C++.
- KRunner permanece inalterado.
- Nenhuma modificação no launcher principal.
- Execução experimental limitada ao botão Abrir Kate, após interação explícita.
- Nenhum comando de shell construído pelo plasmoid.

## PoC 02C.2 — Revisão para homologação

Estado remoto inspecionado em 29/10/2026: main em b499d50 e branch
feat/poc-02-kde-app-catalog em ea5d524, posterior ao checkpoint db0d567.
A atribuição duplicada de text já estava corrigida no código remoto.
O relato anterior “abriu Kate” é uma evidência manual histórica, sem vinculação
inequívoca a esta revisão; repetir a homologação abaixo.

O botão é visível somente quando display é exatamente Kate. O clique verifica
novamente esse nome, a disponibilidade de trigger e os limites do índice.
Essa comparação é uma restrição de interface da PoC, não uma verificação de
identidade confiável: nomes de desktop entries podem ser alterados ou repetidos.
Validar um identificador estável antes de generalizar a execução.

O índice do delegate pertence ao submodelo exibido por applicationList.
Nunca passar selectedCategoryIndex para trigger: ele identifica a categoria
no RootModel, não o aplicativo. A chamada continua trigger(index, "", null),
sem ação customizada nem argumento de comando.

A interface exibe o retorno bruto de trigger ou a exceção. O retorno não
comprova que uma janela abriu. Sua semântica exata na versão instalada
permanece por verificar no código-fonte correspondente do KDE.

### Roteiro reproduzível no Arch

Não sincronizar com alterações locais pendentes. Inspecionar git status e
git diff primeiro; preservar essas alterações em commit próprio antes do pull.
Em uma árvore limpa, atualizar apenas por fast-forward e testar o pacote isolado:

```bash
cd ~/Workspace/personal/plasma-launcher
git status --short --branch
git diff
git fetch origin
git switch feat/poc-02-kde-app-catalog
git pull --ff-only origin feat/poc-02-kde-app-catalog
git log -1 --oneline
plasmoidviewer -a "$PWD/experiments/poc-02a/package"
```

Usar o visualizador já disponível; não instalar componentes nem reiniciar o Plasma.

- [ ] O pacote carrega sem Property value set multiple times ou TypeError.
- [ ] Trocar entre pelo menos duas categorias e conferir nomes/ícones/descrições.
- [ ] Abrir Kate aparece somente na entrada Kate; nenhum app abre ao navegar.
- [ ] Localizar Kate novamente após trocar de categoria; clicar uma vez.
- [ ] Registrar o retorno exibido e confirmar a abertura/ativação da janela Kate.
- [ ] Conferir ausência de erro QML no terminal do visualizador.
- [ ] KRunner continua disponível por Super + Espaço.

Registrar SHA testado, versões, categoria usada, retorno literal e resultado visual.
Não marcar a PoC como homologada apenas com revisão estática.
Favoritos (02D), atualização dinâmica/ciclo de vida (02E) e integração ao launcher
principal permanecem etapas separadas. A reação a resets do catálogo ainda não
está garantida; não conservar referências a submodelos para uso futuro.

## Evidência de homologação funcional — 29/10/2026

Revisão testada: baseline ea5d524 com patch poc-02c2-review aplicado
e correção de whitespace no plano de estudos.

- Execução pelo plasmawindowed usando o caminho do pacote experimental.
- Dez entradas no modelo raiz.
- Navegação entre categorias demonstrada em capturas.
- Nomes, ícones e descrições renderizados.
- Botão Abrir Kate exibido somente no Kate nas entradas observadas.
- Kicker.trigger retornou true.
- Usuário confirmou que Kate abriu corretamente após o clique.
- Nenhuma abertura automática do Kate.
- Ausência de erros no terminal: não confirmada.

PoC 02C.2 homologada funcionalmente neste ambiente.
Isso não homologa atualização dinâmica, estabilidade da API privada,
navegação em subcategorias ou integração ao painel do launcher principal.

Observação: Educação contém Ciências e Matemática como subcategorias;
a navegação hierárquica precisa ser avaliada antes da integração.
