# PoC 03C — Pesquisa local de aplicativos

**Data:** 30/10/2026.
**Status:** busca por nome e abertura pelo resultado homologadas manualmente na rodada local; demais casos e lint detalhados abaixo.
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
O incremento [POC-03D-keyboard.md](POC-03D-keyboard.md) prepara ativação com Enter
e navegação por setas, ainda pendentes de homologação nativa.

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

## Evidência funcional recebida — 30/10/2026

O usuário confirmou: “Funcionando a busca e abrindo app tb”.
A captura mostra a consulta code, título Resultados (1) e o card Visual Studio Code.
A barra lateral inclui Todos os aplicativos e categorias reais; Limpar está visível.

Registrado como homologação manual positiva de busca por nome e abertura a partir
do resultado. O HEAD local não foi reenviado; a rodada foi solicitada para 47e0f76
e é compatível com essa implementação. A captura comprova o resultado apresentado;
a abertura vem do relato explícito do usuário, não da imagem do launcher.

A apresentação/filtragem em execução indica que o módulo necessário foi carregado
nessa rodada, mas não substitui um relatório de lint. Não foram fornecidos saída
do qmllint, código de saída ou logs do viewer nesta mensagem.

Busca por descrição, múltiplos termos/maiúsculas, texto inexistente, Limpar/Escape,
ativação de resultado que não é o primeiro e reconstrução do catálogo durante
pesquisa não foram confirmados individualmente. Permanecem casos de regressão,
sem desconsiderar o caminho positivo já comprovado. Não é necessário repetir
a busca code sem nova mudança que justifique regressão.

Próxima entrega de usabilidade: seleção/foco nos resultados e ativação por
teclado. O refinamento visual maior permanece reservado para referências do
usuário e avaliação de mockups. Nenhum merge autorizado ou realizado.

## Continuidade de teclado

A implementação 03D usa a mesma pesquisa/ativação do clique, com seleção na grade,
Enter e foco entre campo, grade e categorias. O teste por clique de 03C permanece
histórico; não prova entrega de eventos ou foco dessa nova implementação.
Roteiro e limites em [POC-03D-keyboard.md](POC-03D-keyboard.md).

## Divergência visual na busca — 04/11/2026

O usuário confirmou setas e Enter funcionando. Também relatou que buscar Code
abre o VS Code, mas o card não mostra o ícone correto; a captura mostra ainda
nome incorreto (Visualizador de processos com fal…), enquanto o status indica
solicitação de Visual Studio Code. Outros resultados também foram afetados.
Isso é uma falha de correspondência visual, não homologação completa da busca.
Não foi fornecido o SHA local desta rodada.

Hipótese de trabalho: bindings de apresentação via model.display/decoration não
acompanham os dados atuais da linha filtrada. Não há reprodução no runtime deste
ambiente que permita atribuir a causa ao Qt, ao KItemModels ou ao tema.

O delegate agora declara explicitamente os roles requeridos display, decoration,
description, favoriteId e flags. Um Item recebe os roles; o ItemDelegate interno
mantém o botão nativo. Essa separação evita colisão entre o role display e a
propriedade display de AbstractButton. Texto, ícone e tooltip leem esses roles;
mouse e teclado recebem um entryData construído deles, preservando mapToSource
e os guards. Nenhum rebuild de cache, fallback de ícone ou troca de filtro.
Referência: [Qt — Models and Views](https://doc.qt.io/qt-6/qtquick-modelviewsdata-modelview.html).

Verificação lógica com funções e snapshot extraídos do QML: Code mapeado à linha
20 e Kate à linha 7; status com o nome correspondente; disabled e esquema diferente
de applications recusados; whitespace conferido. Esse teste não reproduz bindings
nem renderização Qt. O ajuste precisa de qmllint e validação visual no KDE.

Reteste curto: buscar Code, conferir nome E ícone de Visual Studio Code e abrir;
trocar por kate sem fechar a janela e conferir nome/ícone/Enter; limpar a consulta
e voltar a uma categoria para confirmar cards e navegação. Se a divergência
persistir, registrar sequência e terminal; não dar o problema como resolvido.

## Reteste visual: divergência permanece — 04/11/2026

Após a proposta 97f69be, o usuário enviou capturas: code ainda mostra o nome/ícone
do Visualizador de processos com falha; kate mostra Kate com o ícone esperado.
O usuário não forneceu SHA local ou saída do pull nesta resposta. Portanto,
não se assume a revisão exata do processo aberto nem se declara a causa provada.

Foi adicionada instrumentação temporária SEARCH_DIAG, somente leitura. Um timer
de 500 ms após alteração da consulta/roles/índice compara os primeiros cinco cards:
query, proxyRow, sourceRow, cardName/Icon/Id, proxyName/Icon e sourceName/Icon.
O diagnóstico não solicita ativação, altera filtros, cache, favoritos ou arquivos.
Acesso a QModelIndex.row tem a mesma exceção local de lint já documentada.

Coleta local: fechar instâncias anteriores, atualizar a branch, informar
git rev-parse --short HEAD e iniciar plasmawindowed com caminho absoluto.
Pesquisar code, aguardar um segundo, trocar por kate e aguardar. Enviar as linhas
SEARCH_DIAG do terminal e qualquer warning. Não atribuir ainda o defeito a cache,
tema, Qt, KItemModels ou Kicker. Os dados distinguem divergência na origem/proxy de
bindings do card. Remover esta instrumentação ao concluir a investigação.

Verificação no Work: função real de diagnóstico extraída com mocks preservou
nomes diferentes entre card/proxy/origem, identificou a linha mapeada e respeitou
guards de limite/consulta vazia. Não há reprodução nativa aqui.

## Diagnóstico nativo e ajuste de ciclo de vida — 04/11/2026

O usuário forneceu SEARCH_DIAG de uma execução local:

| Consulta | Linha proxy → origem | Card | Proxy e origem |
| --- | --- | --- | --- |
| code | 0 → 52 | Visualizador de processos com falhas; tools-report-bug; applications:org.kde.drkonqi.coredump.gui.desktop | Visual Studio Code; <instalação local do VS Code>/resources/app/resources/linux/code.png |
| KATE | 0 → 18 | Kate; kate; applications:org.kde.kate.desktop | Kate; kate |
| Ark | 0 → 2 | Ark; ark; applications:org.kde.ark.desktop | Ark; ark |

O desvio inclui identidade do card, não apenas renderização do ícone. Leitura
direta do proxy e da origem concordam. Isso localiza a divergência na passagem
dos roles para o delegate durante filtragem incremental; não prova um defeito
upstream específico nem alteração/cache inválido do arquivo desktop.
O SHA local não foi enviado, mas a presença de SEARCH_DIAG confirma o diagnóstico.

O ajuste usa searchResultsReady como barreira: mudança de consulta ou modelo de
origem desvincula a grade de resultados (model null) e limpa a seleção.
Qt.callLater executa uma função estável que invalida o filtro com a consulta
atual e só então volta a vincular o proxy. Assim a grade recria seus delegates,
em vez de manter o card observado com roles anteriores. Chamadas pendentes à
mesma função são coalescidas pelo Qt. O catálogo e o proxy não são copiados;
não há cache rebuild nem novo serviço. O custo é recriar os cards a cada consulta.

A ativação pela busca recusa chamadas durante essa atualização e compara o nome
do card com labelForRow da origem mapeada. Divergência é recusada com mensagem,
evitando abrir silenciosamente outra apresentação. Essa comparação de nomes
é um guard de consistência adicional; não é autenticação de IDs nem prova que
nomes sejam únicos. Guards de tipo/ID e mapToSource continuam existentes.
SEARCH_DIAG permanece temporariamente para confirmar card/proxy/origem juntos.

Testes lógicos extraíram as funções reais: atualização em duas etapas, chamadas
coalescidas, recusa durante atualização, recusa do card DrKonqi para origem
VS Code, abertura correta da linha 52 uma vez e bloqueio durante reset.
Nenhuma validação de destruição/recriação nativa dos delegates é inferida.
Reteste: code → KATE → Ark → code, aguardando um segundo por consulta.
Confirmar nomes, ícones, abertura por clique/Enter e logs correspondentes.

## Confirmação nativa após a correção — 04/11/2026

Após a publicação de a1e84de, o usuário confirmou: “agora deu certo o code, kate
e outros”. A captura mostra Visual Studio Code com nome e ícone correspondentes.
O log fornecido confirma igualdade de nome/ícone entre card, proxy e origem:

| Consulta | Linha proxy → origem | Resultado |
| --- | --- | --- |
| Ark | 0 → 2 | Ark |
| kate | 0 → 18 | Kate |
| code | 0 → 53 | Visual Studio Code |
| anti | 0 → 1 | Antigravity IDE |
| qt | 0 → 16 | Haruna |
| qt | 1 → 40 | Qt Assistant |
| qt | 2 → 41 | Qt D-Bus Viewer |
| qt | 3 → 42 | Qt Linguist |
| qt | 4 → 43 | Qt V4L2 video capture utility |

O ID do card também corresponde aos aplicativos nomeados. Os caminhos pessoais
dos ícones não são reproduzidos neste documento. A linha de VS Code mudou de 52
para 53 entre rodadas, reforçando que posição não é identidade persistente.
Haruna na busca qt não é, isoladamente, uma falha: o filtro consulta nome e
descrição; o trecho de log não contém a descrição para afirmar a correspondência
textual específica.

Não foi enviado SHA local ou resultado explícito do qmllint; o retorno é uma
validação funcional manual da correção visual nos casos observados, não de todos
os cenários da matriz. O trecho fornecido não contém erros QML; contém apenas
telemetria e mensagens qml: 0/undefined.

Encerrada a coleta, foram removidos exclusivamente a função SEARCH_DIAG, seu
timer e os handlers de coleta. Permanecem a barreira searchResultsReady, a
atualização do filtro antes de revincular a grade e o guard de nome desatualizado.
A limpeza foi conferida por inspeção do código e ausência de referências ao
diagnóstico; não exige repetir a homologação completa. Sem merge.
