
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
- [x] PoC 02C.2 — Homologação funcional registrada em 29/10/2026.
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
plasmawindowed "$PWD/experiments/poc-02a/package"
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

## PoC 02D.1 — Leitura experimental de favoritos

Baseline de preparação: 3d605ba. Leitura/apresentação homologada no checkpoint
15eb75b; ver evidência funcional abaixo.

Evidências fornecidas pela workstation:
- kickerplugin.qmltypes exporta KAStatsFavoritesModel e initForClient(QString).
- O Kickoff atual está no applet 66.
- kactivitymanagerd-statsrc contém grupos Favorites para o client
  org.kde.plasma.kickoff.favorites.instance-4, global e por atividade.
- Não foi demonstrado que o contexto persistido 4 pertence ao Kickoff atual 66.
  O client é explícito na tela; não inferir equivalência nem migrar dados.

O botão Ler contexto instance-4 chama initForClient uma única vez por abertura.
A view observa count e as roles display e decoration, sem polling ou cópia para
ListModel. A atualização inicial pode ser assíncrona: count zero não comprova
ausência de favoritos, nem inicialização bem-sucedida.

Não há chamadas de adição, remoção, reordenação, migração ou execução no painel
de favoritos. A execução controlada do Kate permanece apenas no catálogo.
Não são atribuídos favorites, maxFavorites ou configurações do Kickoff.

Limite de garantia: o qmltypes comprova a assinatura, não os efeitos internos
de initForClient. A PoC não solicita alterações de favoritos, mas não oferece
garantia de ausência de escrita interna pelo backend KDE (por exemplo,
metadados de ordenação). Não qualificá-la como acesso estritamente read-only
ao armazenamento. A implementação upstream correspondente ainda deve ser auditada.

### Homologação 02D.1

1. Com a árvore limpa, sincronizar a branch por git pull --ff-only.
2. Abrir plasmawindowed "$PWD/experiments/poc-02a/package".
3. Confirmar Modelo não inicializado; nenhum aplicativo deve abrir.
4. Clicar Ler contexto instance-4 uma vez; aguardar o carregamento.
5. Registrar quantidade, nomes, ícones e eventuais erros do terminal.
6. Comparar visualmente com os favoritos do launcher atual, sem editar nenhum.
7. Fechar e reabrir a PoC; conferir que exige novo clique.
8. Revalidar navegação por categorias e execução explícita do Kate.

Divergência de conteúdo ou ordem deve ser registrada, não corrigida escrevendo
no contexto 4 ou 66. Nenhum favorito deve ser editado para preparar o teste.
A listagem inicial não homologa troca de atividade nem sincronização dinâmica.

## Evidência funcional 02D.1 — 29/10/2026

- Leitura iniciada por clique explícito, usando instance-4.
- Modelo retornou quatro entradas.
- Nomes e ícones renderizados.
- Usuário confirmou correspondência com os favoritos do menu atual.
- Menu atual: Discover, Dolphin, Configurações do sistema e Firefox.
- Ordem observada na PoC difere da apresentada pelo Kickoff.
- Homologada leitura/apresentação; ordenação e vínculo com applet 66 pendentes.
- Ausência de erros no terminal não confirmada.
- Ajustes de layout pendentes: área de favoritos e categorias cortadas.

## Ajuste de layout após 02D.1

Implementado na branch de desenvolvimento; homologação visual pendente.

- Favoritos em faixa horizontal de altura limitada, oculta antes da inicialização.
- Cards com ícone e nome; barra horizontal quando o conteúdo exceder a largura.
- Barras verticais para categorias e aplicativos, com espaço reservado nos delegates.
- Listas mantêm recorte e rolagem: não é necessário exibir dez categorias ao mesmo
  tempo, mas todas precisam ser alcançáveis.
- Nenhuma mudança nos modelos, client de favoritos ou chamada de execução do Kate.

Sincronizar a branch e abrir o pacote com plasmawindowed.
Validar na janela inicial e após redimensionar: quatro favoritos acessíveis,
rolagem até Utilitários e até o último aplicativo de uma categoria longa,
ausência de sobreposição com as barras, leitura explícita e abertura do Kate
somente pelo botão. Registrar eventuais erros QML.

Referência: https://doc.qt.io/qt-6/qml-qtquick-controls-scrollbar.html
ScrollBar pode ser anexada diretamente a ListView, que fornece a geometria
de rolagem. A interface observa o modelo Qt sem copiar ou reordenar seus dados.

## Evidência visual do ajuste de layout — 29/10/2026

Revisão disponibilizada para o teste: 7ecc5e1.
Capturas fornecidas pelo usuário após a sincronização solicitada:

- Antes da leitura, faixa de favoritos oculta e modelo não inicializado.
- Após o clique, quatro favoritos simultaneamente visíveis: Firefox,
  Configurações do sistema, Dolphin e Discover.
- Nome longo elidido no card de Configurações do sistema.
- Barra vertical de categorias visível; rolagem até Utilitários demonstrada.
- Navegação para Desenvolvimento e Utilitários demonstrada.
- Barra vertical de aplicativos visível em listas maiores.
- Botão Abrir Kate continua restrito às entradas Kate mostradas.

Aceita a apresentação visual nas dimensões das capturas. Não há evidência
nesta rodada de ausência de erros no terminal, rolagem horizontal em janela
estreita, acesso ao último aplicativo ou nova execução do Kate.
Esses pontos não foram marcados como homologados.

Próximo incremento: planejar PoC 02E de atualização do catálogo e ciclo de vida
dos submodelos. Antes de implementar, consultar a API instalada e definir um
teste reproduzível com desktop entry temporária, sem instalar aplicativos,
reiniciar Plasma ou alterar favoritos. Não executar esse teste nesta etapa.
