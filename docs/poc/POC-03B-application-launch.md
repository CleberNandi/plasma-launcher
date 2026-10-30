# PoC 03B — Abertura nativa de aplicativos pelo card

**Data:** 30/10/2026.
**Status:** implementação e verificações lógicas prontas; homologação KDE pendente.
**Branch:** feat/poc-03-native-grid.
**Base:** 1ebafd0, com apresentação plana e clique do Kate confirmados pelo usuário.

## Comportamento

O clique no conjunto ícone/nome passa a solicitar a abertura das aplicações
elegíveis do catálogo, em vez de ficar limitado ao Kate. Continua uma única chamada
`currentModel.trigger(row, "", null)` no modelo exibido.
Não se cria comando de shell, não se usa Exec manualmente e não se executa texto
de display/description. A infraestrutura KDE resolve a desktop entry e seu comando.

São candidatos os itens folha, não desabilitados/separadores, cujo favoriteId
corresponde a applications: seguido de um identificador que termina em .desktop,
sem query ou fragmento. Não há fallback por nome. Outros esquemas e ações ficam
fora deste incremento. O filtro valida o formato esperado para este fluxo,
não autentica o pacote, arquivo desktop ou executável; sobreposições XDG seguem
sendo resolvidas pelo KDE.

O clique valida catalogReady, modelo atual, índice inteiro e limites. Grupos
seguem a navegação e retornam imediatamente; não chegam à execução.
O nome é capturado antes da chamada nativa e usado no status de solicitação.
Nenhuma leitura do objeto de entrada ocorre após trigger ou navegação.

O aviso “abertura disponível apenas para Kate” sai da interface principal.
O texto de status positivo indica solicitação enviada; o retorno da API não é
evidência de janela aberta. Erros e recusas são apresentados.
Sem fechamento automático de popup neste incremento, pois a sessão no painel
ainda não foi homologada.

## Fundamentação e limites

Reutiliza as fontes KDE inspecionadas em 02G:
[appsmodel.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appsmodel.cpp)
e [appentry.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appentry.cpp).
O role aponta à entrada de aplicativo e o caminho de ação padrão usa a
infraestrutura de lançamento KDE. Não foi adicionado C++ ao projeto.

A API permanece privada. Um ID sintaticamente aceito não deve vir de input do
usuário: aqui ele é lido do role do modelo nativo exibido. Nenhuma API de abertura
genérica por URL foi acrescentada. Configurações de favorito, menu padrão e
atalho do KRunner permanecem fora desta entrega.
Laboratório experiments/poc-02a continua com a restrição ao Kate para reprodução.

## Verificações no Work

Funções reais extraídas do QML exercitadas com modelos/entradas sintéticos:

- Kate, Dolphin e um ID local válido aceitos.
- Grupo, pai sem filhos, separador, desabilitado, ID ausente, esquema diferente,
  nome Kate sem ID, query/fragmento e sufixo inválido recusados para execução.
- Índices negativos, fora da contagem, fracionários e NaN; view ausente e
  catalogReady falso não acionam trigger.
- A linha do submodelo e argumentos vazio/null foram preservados.
- Falso e exceção geram status; nome corresponde à aplicação solicitada.
- Entrada simulada que invalida leituras após navegação/trigger não foi acessada
  novamente. Há uma única chamada trigger e não há whitespace novo.

Não foi executado qmllint ou runtime KDE no Work. Testes não comprovam binding,
controle visual, tratamento assíncrono do KDE nem janela aberta.

## Teste local curto

Com árvore limpa e a branch correta:

```bash
git pull --ff-only origin feat/poc-03-native-grid
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
plasmawindowed "$PWD/package"
```

1. Abrir Kate e outro aplicativo simples já instalado, de outra categoria
   (por exemplo Dolphin ou KWrite). Confirmar a janela correta após cada clique.
2. Trocar de categoria e rolar antes de abrir o segundo, verificando que o índice
   ainda corresponde ao item clicado.
3. Abrir o launcher e somente navegar: nada deve iniciar sem clique em aplicativo.
4. Confirmar Educação com LibreOffice Math direto e sem duplicação.

Enviar nomes abertos e diagnósticos. Não é necessário testar todos os aplicativos,
instalar componentes ou criar fixtures. Escolher aplicativos sem ações destrutivas
ao abrir. Não fazer merge nem instalar o pacote no painel para esse teste.
