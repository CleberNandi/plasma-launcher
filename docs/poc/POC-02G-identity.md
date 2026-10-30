# PoC 02G.1 — Identidade do aplicativo

**Data:** 30/10/2026.
**Status:** homologação funcional positiva em b878a9a: ID aceito, Kicker retornou true e usuário confirmou abertura do Kate.
**Baseline:** c263a32, com retorno funcional agregado positivo para Bound.

## Comportamento

O botão Abrir Kate deixa de depender do nome exibido e passa a exigir o role
`favoriteId` exatamente igual a `applications:org.kde.kate.desktop`.
A condição é aplicada na visibilidade e novamente no clique. Grupos, separadores
e entradas desabilitadas são recusados. ID ausente ou diferente não libera abertura.

Não há fallback por display, busca parcial, remoção de query ou normalização
permissiva. O nome serve apenas à apresentação. Uma entrada renomeada com o ID
correto continua elegível; outra chamada Kate com ID diferente fica bloqueada.

A abertura continua em `currentModel.trigger(index, "", null)`, no submodelo
exibido, após clique explícito e validação de limites. Não são criados processos
por shell nem ações customizadas. A view é obtida via propriedade anexada
`ListView.view` antes da solicitação. A correção de ciclo de vida é preservada.

Para diagnóstico da PoC, a linha elegível ou com display Kate mostra seu ID
(elidido se faltar espaço). O status após a solicitação mostra o ID esperado e
o retorno de trigger. A igualdade já foi conferida antes dessa chamada.
O retorno não comprova abertura de janela.

## Fundamentação

Código KDE consultado na revisão
[63e20ff9d15b](https://github.com/KDE/plasma-workspace/commit/63e20ff9d15bbb709d8fb59952088e536ae8d523):

- [appsmodel.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appsmodel.cpp):
  entrega `entry->id()` para o role FavoriteIdRole nas entradas de aplicação.
- [appentry.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appentry.cpp):
  forma o ID com esquema applications e storageId do KService; ações podem
  acrescentar query.
- O repositório oficial [KDE/kate](https://github.com/KDE/kate/blob/master/apps/kate/data/org.kde.kate.desktop)
  contém a desktop entry org.kde.kate.desktop.

O valor esperado é fundamentado nessas fontes; o role real instalado ainda
precisa ser confirmado no ambiente local. O Kicker continua uma API privada.
O nome favoriteId não implica edição de favoritos: nenhuma API de escrita ou
inicialização de favoritos é chamada para ler esse role.

## Limites

Essa é uma identidade de catálogo, não prova criptográfica de origem, assinatura
ou caminho confiável do executável. Uma desktop entry local pode sobrepor uma do
sistema segundo as regras XDG. O launcher delega a resolução ao KDE; este
incremento não implementa validação de pacote, de conteúdo ou de origem.

Não libera execução para todos os aplicativos, não muda o pacote principal,
não integra favoritos ao produto nem altera KRunner. Empacotamentos com IDs
diferentes ficarão bloqueados até uma decisão explícita baseada em evidência.

## Verificações

No Work, a função real extraída do QML foi exercitada com entradas sintéticas:
ID exato aceito com nome original ou renomeado; ID ausente/diferente, sufixo,
query de ação, grupo, separador e entrada desabilitada recusados.
Foi conferida a presença da mesma condição no botão e no clique, a manutenção
da única chamada trigger com ação vazia/argumento null e ausência de whitespace.

Esses testes não exercitam o engine QML, Kicker nem lançamento de aplicativos.
Não há novo resultado de qmllint/runtime neste ambiente.

## Homologação local

```bash
git pull --ff-only origin feat/poc-02-kde-app-catalog
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml experiments/poc-02a/package/contents/ui/main.qml
plasmawindowed "$PWD/experiments/poc-02a/package"
```

Em Desenvolvimento, confirmar o botão no Kate, clicar e confirmar sua abertura.
Enviar o status completo: deve conter applications:org.kde.kate.desktop e o
retorno do Kicker. Outros aplicativos e grupos não devem apresentar Abrir Kate;
navegar ou atualizar não deve abrir nada.

Se o botão desaparecer no Kate, não flexibilizar a condição pelo nome:
registrar o ID mostrado e o terminal para avaliar a diferença.
Não criar desktop entries falsas nem modificar o menu para este teste.
Sem novas fixtures e sem merge.

## Evidência recebida — 30/10/2026

O terminal confirma atualização por fast-forward de c263a32 para
`b878a9a337f4b5abe11fabee4b48e81d0c71b5bd`. A captura identifica a PoC 02G.1
e mostra, em Desenvolvimento:

- Kate com o botão Abrir Kate e rótulo de ID parcialmente elidido.
- Status completo `applications:org.kde.kate.desktop | Retorno de Kicker.trigger: true`.
- Dez categorias, refreshed 1 e resets 1.
- Outras linhas visíveis sem o botão Abrir Kate.

Na implementação dessa revisão, a chamada trigger exige novamente o ID exato
antes de executar. O status observado é, portanto, evidência de aceitação da
identidade esperada pelo guard e do retorno true do Kicker.
Não é um dump independente do role: o status exibe a constante conferida,
e o rótulo do role está parcialmente elidido na captura.

O trecho do terminal contém apenas `qml: 0` e `qml: undefined`, sem
ReferenceError ou outro diagnóstico explícito. Não há saída individual de lint
nem código de saída nessa mensagem; não se registra EXIT=0 medido.
A origem das duas linhas genéricas permanece indeterminada.

A mensagem não confirma textualmente que a janela do Kate abriu e a captura
mostra apenas o launcher. Confirmação visual de abertura após o clique permanece
pendente; o retorno true não substitui essa evidência.
Os casos negativos de IDs ausentes/diferentes continuam cobertos apenas por
testes lógicos sintéticos, sem criar desktop entries artificiais na workstation.

## Confirmação da abertura — 30/10/2026

Em complemento à captura e ao terminal da rodada b878a9a, o usuário confirmou:
“sim kate abriu com sucesso”. Encerrada a pendência de confirmação visual dessa
solicitação explícita. Homologado o caminho positivo da PoC 02G.1 no ambiente
local informado, sem ampliar a validação para outros empacotamentos ou versões.
Casos negativos permanecem verificados apenas por testes lógicos sintéticos.
A confirmação não modifica o registro de lint: código de saída não capturado.
