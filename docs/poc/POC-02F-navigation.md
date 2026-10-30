# PoC 02F.1 — Navegação por subcategorias

**Status:** entrada/retorno homologados em 8a050ce; ajuste Bound e roteiro de regressão confirmados de forma agregada pelo usuário em c263a32. Resultado detalhado abaixo.
**Data:** 30/10/2026.

## Incremento

A interface experimental em `experiments/poc-02a/package` passa a oferecer:

- Botão **Entrar** nas linhas cujo role `hasChildren` é verdadeiro.
- Botão **Voltar** para remover um nível do caminho.
- Caminho textual dos grupos abertos, sem usar nomes como identidade.
- Limpeza do caminho ao trocar a categoria principal ou reconstruir o RootModel.
- Abertura ainda restrita ao Kate, por clique explícito; grupos não recebem esse botão.

O pacote principal `package/` e o probe automático 02E permanecem no checkpoint anterior.
Este incremento não integra o catálogo à interface principal.

## Modelo e ciclo de vida

Cada passo guarda apenas a posição da linha e o rótulo de apresentação.
O modelo exibido é obtido percorrendo `modelForRow()` desde a categoria principal.
Não se guardam ponteiros de submodelos em uma pilha JavaScript.
O percurso valida limites e interrompe com modelo nulo quando o caminho não existe.

Os índices são locais a cada nível e não persistentes. `modelAboutToBeReset` e
`refreshed` do RootModel invalidam o caminho antes da reconexão adiada.
Não se tenta restaurar seleção por nomes nem preservar caminho entre reconstruções.
A homologação deve observar também alterações do catálogo enquanto há um grupo aberto;
o PASS anterior do probe separado não cobre esta nova navegação.

As funções no objeto raiz recebem o modelo da view como argumento ao entrar.
IDs definidos dentro de `fullRepresentation` são usados pelos handlers desse
componente; a lógica externa não depende de alcançá-los por escopo.

## Fonte consultada

Foi inspecionado o código upstream KDE em
[`63e20ff9d15b`](https://github.com/KDE/plasma-workspace/commit/63e20ff9d15bbb709d8fb59952088e536ae8d523):

- [abstractmodel.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/abstractmodel.cpp):
  mapeia o role `hasChildren`.
- [appsmodel.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appsmodel.cpp):
  fornece esse role e retorna o modelo filho em `modelForRow(row)`.

Esta inspeção explica a escolha da API privada; não comprova que o código upstream
seja idêntico ao binário instalado nem amplia a matriz de compatibilidade.

## Verificações realizadas no Work

As funções JavaScript extraídas do QML foram exercitadas com modelos sintéticos:
entrada em dois níveis, retorno, recusa de folha sem modelo filho, bloqueio durante
reset, limpeza do caminho e índices inválidos. Também foi verificada a ausência
de referência ao ID interno da view nessas funções e de whitespace novo.

Isso verifica lógica e limites; não substitui parser QML, bindings, renderização,
sinais nativos ou teste do pacote no KDE. `qmllint` e runtime KDE não disponíveis
neste ambiente. Nenhum PASS nativo novo foi registrado.

## Homologação na workstation

Sincronizar a branch de desenvolvimento, com árvore local limpa:

```bash
git pull --ff-only origin feat/poc-02-kde-app-catalog
git diff --check
plasmawindowed "$PWD/experiments/poc-02a/package"
```

Roteiro curto para o usuário ou executor local:

1. Em Educação, clicar **Entrar** em Ciências ou Matemática. Confirmar que aparecem
   as entradas do grupo e que o caminho mostra seu nome.
2. Clicar **Voltar**. Confirmar o retorno à lista de grupos. Repetir a entrada e
   trocar para Desenvolvimento: o caminho deve ser limpo.
3. Voltar a um grupo e clicar **Atualizar catálogo**. Confirmar retorno ao nível
   inicial sem erro QML, referência inválida ou abertura de aplicativo.
4. Em Desenvolvimento, clicar **Abrir Kate** e confirmar a abertura explícita.
   Nenhum aplicativo deve abrir ao navegar, voltar ou atualizar.
5. Redimensionar a janela e verificar acesso aos botões e às barras de rolagem.

Se o ambiente não possuir subcategorias, registrar como não exercitado. Não instalar
aplicativos nem alterar o menu para satisfazer este roteiro.

Para o Codex local: verificar branch/HEAD e árvore antes e após; executar
`qmllint` somente se já disponível, informando sua versão, comando e diagnósticos;
não tratar erros de resolução de imports como ausência de erros QML. Observar
`plasmawindowed` na sessão gráfica apenas se houver capacidade de interação;
caso contrário, deixar os cliques explicitamente pendentes. Não afirmar execução
visual com base somente na análise do código. Não fazer merge.

O runner 02E continua útil para regressão do catálogo, mas não aciona os novos
botões. Não é necessário repetir fixtures para validar somente entrada/retorno.

## Evidência local recebida — 30/10/2026

Revisão informada pelo executor local: `3f016fc739825478eb2e35adbb15db683d018df1`,
branch `feat/poc-02-kde-app-catalog`. Árvore limpa antes e depois, sem erros de
`git diff --check` e sem merge, conforme relatório recebido. Work não executou
essas verificações na workstation nem acessou os logs brutos.

### Verificação estática reportada

O executor identificou `/usr/bin/qmllint` 1.0 (Qt5) e utilizou o binário Qt6:

```bash
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml \
  experiments/poc-02a/package/contents/ui/main.qml \
  package/contents/ui/main.qml \
  experiments/poc-02a/catalog-probe/package/contents/ui/main.qml
```

Versão reportada: 6.12.0. Imports resolvidos, sem diagnósticos de import,
tipo não resolvido ou sintaxe no resumo fornecido.

| Arquivo | Warnings reportados |
| --- | --- |
| Interface experimental | 51 `unqualified` |
| Pacote principal | 5 `unqualified` |
| Probe de catálogo | 4 `unqualified` e 7 `missing-property` |

O relatório informa código de saída 0 na execução resumida e `success: false`
no JSON por warnings; também menciona uma execução anterior com saída 1.
Os resultados referem-se a invocações distintas. Não classificar o conjunto como
lint limpo nem descartar warnings com base somente no código de saída.

Os acessos entre componentes precisam de revisão de escopo. Avaliar
`pragma ComponentBehavior: Bound` em incremento próprio, com verificação de
delegates e teste nativo; não adicionar apenas para ocultar diagnósticos.
No probe, o retorno estaticamente tipado como QQuickItem de `itemAt()` não
expõe ao linter as propriedades específicas do delegate. Isso não comprova
falha de execução nem dispensa revisão de tipos.

### Evidência visual enviada pelo usuário

Três capturas mostram a interface 02F.1:

- Educação com os grupos Ciências e Matemática e seus botões Entrar.
- Caminho Ciências e entrada LibreOffice Math com ícone e descrição.
- Caminho Matemática e entrada LibreOffice Math com ícone e descrição.
- Nas três capturas: dez categorias, `refreshed: 1`, `resets: 1` e
  “Nenhuma execução solicitada”.

Essas imagens comprovam apresentação dos grupos e entrada nos dois submodelos.
A presença de LibreOffice Math em ambos não constitui erro por si só:
a PoC apresenta o conteúdo recebido do catálogo, sem deduplicar entre grupos.
Não foi comparada a classificação desse aplicativo com o menu nativo.

O executor CLI deixou interação visual pendente; as capturas do usuário
acrescentam evidência independente. Não comprovam isoladamente clique em Voltar,
limpeza ao trocar categoria, reset enquanto dentro do grupo, redimensionamento,
ausência de erros no terminal ou abertura do Kate nesta revisão.
A validação anterior do Kate continua histórica, sem substituir a regressão 02F.1.

### Pendências para encerrar 02F.1

- Confirmar retorno via Voltar e limpeza ao trocar de categoria.
- Confirmar atualização com grupo aberto, sem erro QML ou referência inválida.
- Confirmar regressão do clique explícito no Kate e navegação sem aberturas.
- Verificar redimensionamento e acesso aos controles.
- Revisar os warnings estáticos sem alterar o pacote principal neste incremento.

## Retorno funcional e correção de ciclo de vida — 30/10/2026

O usuário confirmou entrada em Educação → Ciências, retorno e entrada em
Matemática. O terminal registrou três ocorrências de:

```text
main.qml:361: ReferenceError: applicationList is not defined
```

Também foi enviada a linha `qml: undefined`, cuja origem não foi determinada.
O resultado é funcional parcial com erro, não homologação sem diagnósticos.
O HEAD da rodada não foi reenviado; a linha corresponde ao handler introduzido
em 3f016fc, cujo código não mudou no commit documental be68d3c.

A linha problemática reposicionava a lista **depois** de
`enterSubcategory()` mudar o binding do modelo. A navegação já tinha ocorrido.
A troca do modelo pode destruir o delegate e invalidar seu contexto de execução;
essa é a explicação adotada para o acesso falhar depois da transição, embora
não tenha sido reproduzida com instrumentação nativa no Work.

Correção mínima:

- Obter a view associada por `applicationDelegate.ListView.view` antes da troca
  e passar seu modelo à função.
- Encerrar o handler após navegar, sem consultar IDs do delegate novamente.
- Reposicionar em `onModelChanged` do próprio ListView, inclusive no retorno.
- Não alterar os roles, favoritos, trigger do Kate ou pacote principal.

Referência: [Qt — ListView](https://doc.qt.io/qt-6/qml-qtquick-listview.html),
seções sobre delegates e a propriedade anexada `view`. A documentação alerta
que delegates podem ser destruídos e descreve o acesso à view no objeto raiz
do delegate.

No Work, um teste do handler com delegate simulado que rejeita acessos após a
mutação passou; também foi verificado que o único reposicionamento restante está
no handler da view e que o arquivo não contém whitespace novo.
Esse teste verifica a ordem dos acessos, não reproduz o engine QML.
Não foi executado qmllint nem runtime KDE nesta correção.
Os warnings de escopo registrados anteriormente continuam pendentes; não foi
adicionado `ComponentBehavior: Bound` nem feita limpeza geral de lint.

Regressão curta: reabrir o pacote atualizado e repetir
Educação → Ciências → Voltar → Matemática → Voltar, observando o terminal.
Confirmar conteúdo/caminho, retorno e ausência do ReferenceError. Permanecem
pendentes também reset com grupo aberto, troca de categoria, Kate e redimensionamento.

## Regressão da correção confirmada — 30/10/2026

O usuário sincronizou por fast-forward de 3f016fc para
`8a050ce7aca4fa61627204b8906f6cc1f18a995d` e abriu o pacote experimental com:

```bash
plasmawindowed "$PWD/experiments/poc-02a/package"
```

Após o roteiro solicitado Educação → Ciências → Voltar → Matemática → Voltar,
confirmou: “Deu certo. sem erros”. O trecho de terminal enviado mostra apenas
`qml: 0` e `qml: undefined`, sem a ocorrência anterior de ReferenceError.

Registrada como homologação manual do fluxo de entrada/retorno e da correção
do acesso após a troca de modelo, no ambiente local informado. Não se atribui
significado de falha ou sucesso às duas linhas genéricas de log; sua origem
continua não determinada.

Esta rodada não incluiu novo resultado de qmllint, nem confirmação específica
de reset com grupo aberto, troca de categoria, Kate ou redimensionamento.
Essas pendências permanecem abertas. Não é necessário repetir o fluxo corrigido
sem nova alteração que justifique regressão. Nenhum merge autorizado ou realizado.

## Escopo explícito dos componentes — preparação em 30/10/2026

Após a correção de ciclo de vida homologada em 8a050ce, foi preparado
`pragma ComponentBehavior: Bound` no início do arquivo da interface experimental.
Esta é uma alteração de semântica de contexto, não uma supressão de warnings:
componentes internos ficam vinculados ao contexto de declaração e os IDs dos
componentes externos do mesmo arquivo tornam-se resolvíveis pelo tooling.

Referência: [Qt — ComponentBehavior](https://doc.qt.io/qt-6/qtqml-documents-structure.html#componentbehavior).

Revisão dos delegates existentes:

| Delegate | Dados recebidos explicitamente |
| --- | --- |
| Favorito | `required property var model` |
| Categoria | `required property var model`, `required property int index` |
| Aplicativo/grupo | `required property var model`, `required property int index` |

Não há dependência intencional de dados de modelo injetados implicitamente no
contexto desses delegates. O pragma exige propriedades required para esses dados.
Ele não mantém objetos destruídos vivos e não autoriza acessar o delegate depois
de trocar o modelo: a correção anterior foi preservada integralmente.

Não houve mudança em funções, handlers, favoritos ou execução. O pacote
principal e o probe separado não receberam o pragma; seus warnings permanecem
fora deste incremento. A compatibilidade deste ajuste ainda deve ser confirmada
no ambiente homologado; não se declara suporte adicional a versões do Plasma.

### Validação pendente e tarefa curta para o Codex local

No Work, foi revisada a declaração explícita dos dados dos três delegates e
verificado que a única diferença no QML é o pragma com sua linha separadora.
Não há binário Qt6/KDE neste ambiente; não foi estimada contagem nova de warnings.

Após sincronizar a branch, com árvore limpa, executar:

```bash
/usr/lib/qt6/bin/qmllint --version
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml experiments/poc-02a/package/contents/ui/main.qml
```

Registrar o código de saída e todos os diagnósticos dessa invocação. Não misturar
o resultado com o binário Qt5 ou com os warnings históricos dos outros pacotes.
Se surgirem novos erros de import, tipo, propriedade requerida ou contexto,
relatar antes de dar o ajuste como homologado. Não instalar componentes.

Como o pragma altera o contexto de todos os componentes internos, é necessária
uma regressão nativa curta na revisão nova. O executor CLI pode fazer o lint;
os cliques só podem ser atestados por quem interagir com a janela:

1. Ler os favoritos e confirmar as quatro entradas já conhecidas.
2. Entrar em Ciências, voltar, entrar em Matemática e mudar para Desenvolvimento:
   caminho limpo, nomes/ícones presentes e nenhum ReferenceError.
3. Entrar novamente em um grupo e atualizar catálogo: voltar ao nível inicial,
   sem abertura de aplicativo nem erro de referência. Redimensionar e conferir
   acesso aos controles e rolagem.
4. Em Desenvolvimento, abrir Kate somente pelo botão explícito.

Não repetir o teste dinâmico com fixtures para este ajuste. Não modificar dados
de favoritos nem dar como concluídas interações que o executor não consiga fazer.
O merge permanece fora do escopo autorizado.

## Retorno do ajuste Bound — 30/10/2026

O terminal enviado confirma atualização até `c263a32820335358fb88a961bccc379a30f078be`,
execução do qmllint Qt6 sobre a interface experimental e abertura em plasmawindowed.
O usuário confirmou “tudo ok” após o roteiro solicitado de favoritos, navegação,
atualização dentro de grupo e abertura explícita do Kate.

Nenhum diagnóstico do linter aparece no trecho enviado. Não foi capturado o código
de saída separado, portanto o registro é de invocação sem diagnósticos visíveis,
não de um EXIT=0 medido. A saída do visualizador contém `qml: 0` e `qml: undefined`,
sem os ReferenceErrors anteriores no trecho fornecido.
A confirmação funcional é agregada, sem evidência individual nova para cada clique
ou para redimensionamento. Os warnings históricos do pacote principal/probe não
foram reavaliados e não estão cobertos por esse comando.

Checkpoint 02F.1 aceito no ambiente local segundo o relato do usuário.
A próxima mudança de comportamento, identificação do Kate pelo role favoriteId,
é tratada separadamente em [POC-02G-identity.md](POC-02G-identity.md).
