
# PoC 02 — Catálogo real de aplicativos KDE


## Estado consolidado do checkpoint — 30/10/2026

Esta seção resume o estado atual; as seções seguintes preservam o histórico
de preparação e testes, inclusive resultados parciais depois esclarecidos.

| Escopo | Evidência e estado |
| --- | --- |
| Catálogo/categorias reais e roles | Homologação manual local |
| Execução explícita do Kate | Homologação manual local via Kicker |
| Favoritos nativos | Leitura/apresentação confirmadas; client instance-4 fixo |
| Layout experimental | Capturas validaram faixa de favoritos e rolagem |
| Refresh explícito | Fluxo manual observado e sinais registrados |
| Mudanças automáticas | Probe independente PASS: inclusão, rename/categoria e remoção por publicação atômica |
| Subcategorias (02F.1) | Entrada/retorno e correção de ciclo de vida homologados em 8a050ce; regressões restantes pendentes |
| Escopo dos componentes | Bound preparado em 41d9424; novo lint e regressão nativa pendentes |

Evidência automatizada e limites: [POC-02E-automated.md](POC-02E-automated.md).
O PASS local foi reportado pelo executor na revisão 1774f8c; Work não executou KDE.
Scripts Bash tiveram validação de sintaxe. Qt6 qmllint 6.12.0 foi executado
localmente em 3f016fc: imports/sintaxe sem erros reportados, com warnings de
escopo e de propriedades no probe. Isso não equivale a lint limpo.
O ajuste Bound altera apenas a interface experimental; resultado posterior ainda
não medido. Ver [POC-02F-navigation.md](POC-02F-navigation.md).

Pendências antes da integração ao launcher principal:
- Concluir regressões da navegação hierárquica e medir o lint após Bound: [POC-02F-navigation.md](POC-02F-navigation.md).
- Identidade estável dos aplicativos, em vez de restringir execução por display.
- Definição do client de favoritos, ordenação e atividades; sem migrar dados.
- Revisão/compatibilidade da API privada e ciclos de vida em outras versões.
- Explicar divergência de reescrita direta versus publicação atômica se necessário.
- Testar interface principal, teclado, busca local e painel em incremento próprio.

A declaração X-Plasma-API-Minimum-Version 6.0 é metadado do pacote, não matriz
de compatibilidade homologada. O experimento não deve ser apresentado como
launcher pronto ou como suporte validado a todas as versões Plasma 6.

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

## PoC 02E.1 — Refresh explícito e ciclo de vida

Preparado sobre 72ffca9. Implementação ainda não homologada no KDE.

API apoiada nas evidências locais de kickerplugin.qmltypes: refresh() em
AbstractModel e sinal refreshed em RootModel. Os sinais modelAboutToBeReset
e modelReset são herdados do modelo Qt; verificar sua exposição no runtime.

- Atualizar catálogo chama appsModel.refresh() somente por clique.
- Contadores distinguem refreshed de modelReset; não presumir relação 1:1.
  Podem começar acima de zero devido à população inicial.
- Em modelAboutToBeReset, a view de aplicativos perde o submodelo (model null).
- Em modelReset/refreshed, Qt.callLater agenda a reconexão para a próxima volta
  do event loop. Isso evita solicitar modelForRow no meio do handler de reset;
  não constitui garantia universal para toda sequência de sinais de API privada.
- A seleção volta à linha zero: um índice antigo não identifica uma categoria.
- A revisão refreshed participa do binding para reavaliar modelForRow mesmo
  se a quantidade de categorias e selectedCategoryIndex não mudarem.
- Cliques no catálogo/execução ficam bloqueados enquanto catalogReady é false.
- Não há polling, Timer, comando externo, alteração de favoritos ou novo serviço.
- O finally lógico do botão (callLater após try/catch) reabilita a view caso
  refresh não emita sinais. O contador/status permite observar esse caso.

### Homologação 02E.1 — sem alterar o catálogo instalado

1. Sincronizar a branch limpa e abrir o pacote com plasmawindowed.
2. Anotar os contadores iniciais (não exigir zero).
3. Selecionar Desenvolvimento; localizar Kate sem abrir.
4. Clicar Atualizar catálogo uma vez; registrar status e novos contadores.
5. Conferir retorno à primeira categoria e aplicativos correspondentes.
6. Voltar a Desenvolvimento e confirmar nomes, ícones e botão do Kate.
7. Repetir três vezes, incluindo uma rodada após Ler contexto instance-4.
8. Conferir que os quatro favoritos continuam apresentados.
9. Abrir Kate uma vez pelo botão exclusivo; registrar resultado e erros QML.
10. Fechar e reabrir para verificar uma nova sessão funcional.

Não instalar nem remover apps para este teste; não reiniciar Plasma.
Sem runtime Qt/KDE neste Work: revisão de código e whitespace não substituem
essa homologação. Se o botão não produzir refreshed/reset, registrar os valores
e investigar; não interpretar a ausência de sinal como atualização comprovada.

### PoC 02E.2 — teste futuro de mudança real

Após 02E.1: preparar fixture .desktop temporária com nome exclusivo, criação
sem sobrescrever arquivos, remoção reversível e atualização do cache KDE.
Medir inclusão, mudança de nome/categoria e remoção com a PoC aberta.
Separar comportamento automático de atualização explícita; não clicar refresh
antes de registrar se houve atualização espontânea. Nenhuma fixture é criada
por este commit. Atualização dinâmica permanece não homologada.

### Referências de aprendizagem

- https://doc.qt.io/qt-6/qml-qtqml-connections.html
- https://doc.qt.io/qt-6/qml-qtqml-qt.html#callLater-method
- https://doc.qt.io/qt-6/qabstractitemmodel.html#modelAboutToBeReset

## Evidência funcional 02E.1 — 30/10/2026

Revisão disponibilizada para homologação: 3c3d7c9.
Capturas e confirmação manual fornecidas pelo usuário:

- Dez categorias mantidas nas três capturas.
- Contadores refreshed/resets observados em 1/1, 2/2 e 3/3.
  Essa sequência não comprova relação universal de um reset por refresh.
- Status Sinal refreshed recebido; seleção reiniciada apresentado.
- Primeira categoria (Ajuda) e seus aplicativos apresentados após refresh.
- Navegação posterior para Desenvolvimento demonstrada.
- Quatro favoritos renderizados junto ao catálogo na captura final.
- Usuário confirmou que Kate abriu no teste desta rodada.

Homologação funcional do fluxo observado de refresh e navegação pós-refresh.
A captura final mostra os favoritos carregados, mas não determina sozinha a
ordem entre o carregamento deles e o último refresh. Persistência dos favoritos
através de refresh após sua inicialização permanece sem confirmação explícita.
Ausência de erros QML no terminal, execução completa das repetições do roteiro
e reabertura da sessão não foram confirmadas.

A atualização automática por inclusão, alteração ou remoção de uma entrada
.desktop ainda não foi testada. Próximo passo: PoC 02E.2 com fixture temporária
reversível, sem instalação de aplicativos nem alteração de favoritos.

## PoC 02E.2 — Harness interativo publicado

Script: experiments/poc-02a/scripts/poc-02e2-catalog.sh.
Executar com bash como usuário comum, em terminal interativo, com a PoC aberta.

O script cria um arquivo exclusivo com mktemp em XDG_DATA_HOME/applications
(fallback ~/.local/share/applications), sem criar o diretório se ausente.
Fase A: nome ZZ Plasma Launcher PoC 02E2 A, categoria Development.
Fase B: mesmo arquivo, nome terminado em B, categoria Utility.
Fase C: remoção. Não executa a entrada (Exec=/usr/bin/true), não altera favoritos,
não instala software, não chama cache builder e não reinicia Plasma.

Em cada fase, aguardar aproximadamente 10 segundos, observar antes de clicar
Atualizar catálogo e registrar contadores/resultado espontâneo. Se precisar
do botão, registrar esse resultado separadamente. Ausência de atualização
na janela observada é um resultado, não comprova falha definitiva do watcher.
Cada refresh pode voltar à primeira categoria; navegar à categoria indicada.

O script pausa para observações e as imprime no terminal; não cria relatório.
Ctrl+C ou saída normal removem a fixture se seu hash corresponder ao esperado.
Se detectar conteúdo externo, preserva o arquivo e informa seu caminho.
A proteção por hash evita exclusão acidental no uso normal, mas não é defesa
contra processo concorrente malicioso. SIGKILL/queda de energia impedem trap;
nesse caso inspecionar o caminho impresso antes de remover a fixture manualmente.
Não executar duas cópias simultâneas (os nomes visuais se repetem).

Validação no Work: bash -n PASS; recusa de execução como root observada.
Fluxo interativo de escrita/limpeza e integração KDE: NOT RUN neste ambiente.
Homologação na workstation pendente; não afirmar teste dinâmico concluído.

Comandos em terminais separados, a partir da raiz do repositório:
```bash
plasmawindowed "$PWD/experiments/poc-02a/package"
```
```bash
bash experiments/poc-02a/scripts/poc-02e2-catalog.sh
```

Referência de formato: https://specifications.freedesktop.org/desktop-entry/latest/recognized-keys.html

## Rodada parcial 02E.2 — 30/10/2026

Usuário relatou refresh automático na inclusão (A) e atualização tardia,
superior a 10 s, atribuída à fase B. A observação da fase B foi corrigida
durante a fase C; os eventos de mudança e remoção podem ter se sobreposto.
Capturas mostram refreshed/resets em 1/1, 2/2 e 4/4, mas não mostram a
fixture A ou B; a captura de Desenvolvimento não exibe o fim da lista.
Os quatro favoritos aparecem na captura final.

Resultado parcial: refresh espontâneo relatado; inclusão, migração e
remoção corretas do conteúdo não homologadas separadamente. Não atribuir
os quatro sinais individualmente às fases. Limpeza foi alcançada pelo fluxo
normal do script, mas ausência do arquivo deve ser confirmada na workstation.

Roteiro revisado substitui a orientação de 10 s e fallback manual anterior:
observar até 60 s sem clicar Atualizar catálogo, navegar novamente à categoria
após reset e localizar a entrada no fim da lista. Confirmar conteúdo por fase,
capturar antes de avançar e digitar auto apenas quando confirmado.
Qualquer outra resposta encerra a rodada com limpeza, sem iniciar a fase seguinte.
O intervalo registrado mede tempo até resposta humana, não latência do KDE.
60 s é janela de observação, não SLA nem timeout implementado no script.
Validação da revisão: bash -n PASS; execução KDE pendente.

## Esclarecimento e evidências de inclusão/remoção — 30/10/2026

Nova rodada encerrada na fase A como inconclusiva pelo usuário, com relato
de mudança dos contadores. O critério do roteiro foi interpretado como
espera pelo desaparecimento da entrada durante a fase A.

Correção do critério: durante a pausa A, o arquivo existe e a entrada A deve
permanecer em Desenvolvimento, inclusive depois de refresh manual.
O desaparecimento só é esperado após remoção do arquivo (fase C ou limpeza).

Captura antes da saída: entrada A visível em Desenvolvimento, refreshed/reset 2/2.
Script informou Fixture removida ao encerrar.
Usuário relatou que ZZ desapareceu somente após encerrar o script.
Captura seguinte: refreshed/reset 3/3, lista ao final sem a entrada A.

Evidência funcional de inclusão no catálogo e remoção após a limpeza.
O relato não indica novo clique manual entre limpeza e desaparecimento;
registrar como atualização compatível com detecção automática, sem alegar
latência medida nem comprovação instrumentada da origem de cada sinal.
Não há evidência de falha por a entrada permanecer enquanto o arquivo existia.
O intervalo de 98 s é tempo até resposta humana, não tempo de refresh.

A fase B (alteração do nome e migração de Development para Utility) não foi
executada nesta rodada; permanece pendente. Não repetir inclusão/remoção
apenas porque o usuário registrou a fase A como inconclusiva: separar o rótulo
digitado dos fatos visuais e do ciclo de vida esperado do arquivo.

## Correção do critério de sinais — 30/10/2026

Usuário reiterou ausência de novo refreshed durante a pausa A; a captura
mostra A em Desenvolvimento com contadores 2/2. Após encerramento/limpeza,
captura mostra 3/3 e ausência de A. Não tratar a permanência do arquivo A
como falha nem exigir sinal refreshed para aceitar a presença do conteúdo.

A instrumentação atual conta somente refreshed e resets, não rowsInserted,
rowsRemoved ou dataChanged dos submodelos. Atualização incremental sem reset
é uma hipótese; não foi instrumentada nem comprovada nesta rodada.
O aparecimento da fixture e a emissão de refreshed são observações distintas.

O prompt passa a pedir sim/nao para conteúdo confirmado, aceitando auto por
compatibilidade. Sem exigir mudança dos contadores. As instruções anteriores
que condicionavam avanço ao sinal ficam substituídas por este critério.
Nenhuma nova repetição de inclusão/remoção é exigida agora.
Fase B permanece pendente. Execução e lint QML não realizados nesta alteração
de roteiro; código do plasmoid não alterado.

## PoC 02F.1 — Incremento preparado em 30/10/2026

Navegação de grupos via `hasChildren` e `modelForRow`, com botão Entrar, retorno
por nível e descarte do caminho ao trocar categoria ou reconstruir o RootModel.
A execução continua restrita ao Kate e não é acionada pela navegação.
Testes da lógica JavaScript passaram com modelos sintéticos no Work; nenhum
resultado nativo novo foi inferido. Roteiro e limites em
[POC-02F-navigation.md](POC-02F-navigation.md).
