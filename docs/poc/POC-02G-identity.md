# PoC 02G.1 — Identidade do aplicativo

**Data:** 30/10/2026.
**Status:** implementação e testes lógicos preparados; homologação KDE pendente.
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
