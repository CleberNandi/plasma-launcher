# PoC 03A — Catálogo nativo na grade principal

**Data:** 30/10/2026.
**Status:** grade compacta renderizada; clique no card do Kate confirmado em bfee9a4. Apresentação plana por categoria preparada; homologação KDE pendente.
**Branch:** feat/poc-03-native-grid.
**Base:** 73899697e76f8ce1a6152c7232455fc19f6b6b80, checkpoint da PoC 02.

## Entrega

Ao abrir `package/`, a interface principal passa a apresentar categorias reais
na barra lateral e nomes, ícones e descrições reais em uma GridView com rolagem.
A seleção visual destaca a categoria principal. Grupos abrem por clique no ícone/nome e o
caminho permite Voltar. Aplicativos comuns são apresentados sem ação de execução;
Kate abre pelo mesmo tipo de clique, condicionado ao ID já homologado na PoC 02G.1.

O catálogo simulado da PoC 01 é removido desta branch. As seções simuladas
Favoritos/Todos não são preservadas como se fossem nativas. A leitura de
favoritos continua no laboratório 02D; nenhum client fixo é levado ao principal.
Pesquisa local, perfil real, favoritos e execução geral serão entregas separadas.

O nome/ícone e ID do pacote principal permanecem os mesmos. Este teste deve usar
somente plasmawindowed, sem instalar/atualizar widgets nem substituir o menu do
painel. A validação do popup no painel continuará pendente após o smoke em janela.

## Escolhas de implementação

- Reaproveitada a lógica validada no laboratório: RootModel com categorias
  principais e submodelos planos (flat: true), revisão observável e invalidação
  do caminho no reset. Navegação hierárquica preservada como fallback.
- ComponentBehavior: Bound e propriedades required explícitas nos delegates.
- GridView substitui GridLayout/Repeater para oferecer rolagem e instanciação
  limitada dos cards visíveis. Quantidade de colunas calculada pela largura útil,
  reservando espaço à barra de rolagem.
- O delegate obtém sua view por GridView.view antes de navegar ou solicitar
  execução. Nenhuma consulta ao delegate após alterar o modelo.
- A própria view reposiciona em onModelChanged. Não reutilizar o handler com
  acesso ao contexto destruído que foi corrigido em 02F.1.
- Kate exige favoriteId exato applications:org.kde.kate.desktop, entrada folha,
  não desabilitada e índice válido; trigger(row, "", null) permanece no submodelo.
- A primeira categoria é selecionada novamente após reconstrução. Não se
  preserva caminho por índice entre versões do catálogo.
- Header inicial “Aplicativos” é genérico; após selecionar uma categoria, mostra
  seu nome e o caminho dos grupos. O ícone de perfil ainda é um placeholder.

A lógica está no mesmo main.qml neste primeiro incremento. O laboratório é
preservado como referência independente. Evita-se dependência em caminhos de
experimentos ou nova camada de abstração antes da homologação da grade.
Se a manutenção exigir compartilhamento, extrair componente em incremento próprio.

Dimensões: mínimo original 700×460 preservado; preferência 760×560 para a grade.
Não há alteração de configuração do painel. Minimum-version 6.0 continua metadado,
sem ampliar a matriz testada da dependência privada do Kicker.

## Verificações no Work

Funções reais extraídas do QML foram exercitadas com modelos sintéticos:
categoria, subcategoria, retorno, troca de categoria com limpeza do caminho,
reset/bloqueio, ID do Kate e rejeição de outro ID com mesmo nome.
Cálculo de colunas conferido em quatro larguras. Conferidos required nos dois
delegates, única chamada trigger e ausência de dados simulados/favoritos escritos.
Sem whitespace novo.

Não houve execução de qmllint, parser QML ou KDE no Work. Esses testes não
atestam geometria renderizada, lifecycle real de GridView, sinais nativos ou
abertura de aplicativo. Evidência da PoC 02 não é automaticamente homologação
da nova representação principal.

## Sincronização e homologação

Primeiro, preservar alterações locais existentes. Com árvore limpa:

```bash
git status --short --branch
git fetch origin
git switch --track origin/feat/poc-03-native-grid
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
plasmawindowed "$PWD/package"
```

O switch --track acima é para a primeira entrada nessa branch. Se ela já existir
localmente, usar git switch feat/poc-03-native-grid e git pull --ff-only.
Registrar separadamente saída/código de saída do lint e diagnósticos do viewer.
Não instalar ferramentas se algum comando estiver ausente; relatar.

Roteiro curto:

1. Confirmar categorias e grade com nomes/ícones reais; rolar Desenvolvimento
   até o final e a barra lateral até Utilitários.
2. Selecionar Educação: esperar aplicativos diretamente, sem exigir entrada em
   Ciências/Matemática. LibreOffice Math deve aparecer uma única vez nessa categoria.
   Trocar para Desenvolvimento deve manter conteúdo e título coerentes.
3. O catálogo reage aos sinais nativos de mudança; não há refresh manual nesta
   interface. O ensaio controlado de refresh permanece em experiments/poc-02a.
4. Clicar no ícone/nome do Kate; confirmar a solicitação e a abertura visual.
   Outros aplicativos continuam sem execução nesta prévia; navegar não inicia apps.
5. Redimensionar entre o mínimo e uma janela maior, verificando colunas,
   nomes longos, rolagem e acesso aos botões.

Enviar resultado e erros. Sem fixtures temporárias nem alteração de favoritos.

## Revisão e isolamento

O PR deste incremento tem base na branch da PoC 02 para mostrar apenas o delta
da integração, enquanto o PR #2 permanece separado contra main. São PRs
dependentes; nenhum merge foi autorizado. Se o checkpoint base avançar ou sofrer
squash, revisar a base e o diff antes de retarget/merge.

Não executar merge automático nem tratar smoke em janela como validação do
painel Wayland. Para voltar ao laboratório, com árvore limpa:

```bash
git switch feat/poc-02-kde-app-catalog
plasmawindowed "$PWD/experiments/poc-02a/package"
```

## Revisão visual e ajuste de densidade — 30/10/2026

As capturas enviadas pelo usuário mostram a grade nativa em Desenvolvimento,
os grupos Ciências/Matemática em Educação e LibreOffice Math dentro de Ciências.
Isso comprova renderização e percurso observados nessas capturas, sem comprovar
todas as etapas do roteiro (Kate, reset, redimensionamento e lint não reenviados
nessa mensagem). O usuário avaliou o layout como insatisfatório.

Diagnóstico: poucas colunas, células altas, descrições truncadas e ações isoladas
criavam espaço excessivo e hierarquia fraca. A correção trata a composição,
não apenas o tamanho dos ícones.

| Elemento | Primeira grade | Ajuste preparado |
| --- | --- | --- |
| Ícone de aplicativo/grupo | 48 px | 32 px |
| Largura alvo da célula | 160 px | 112 px |
| Altura da célula | 164 px | 124 px |
| Barra lateral | 190 px, botões elevados | 164 px, ItemDelegate com seleção e ícone de 16 px |
| Descrição | Linha sempre visível, frequentemente cortada | Tooltip com nome e descrição |
| Cabeçalho | Marca + rótulo técnico + botão elevado | Ícone de 28 px, subtítulo Aplicativos, atualização flat |
| Rodapé inicial | Dois textos de diagnóstico | Uma indicação curta da restrição de abertura |

A grade calcula colunas pela largura disponível; a previsão é de aproximadamente
quatro colunas na janela das capturas, dependente da largura real da view,
scrollbar e escala. Não se afirma renderização de quatro colunas sem nova captura.
Os tokens são dimensões lógicas QML; nenhuma escala física foi forçada.

Os nomes mantêm a fonte configurada no ambiente e até duas linhas. Descrições
completas aparecem após hover de 600 ms. Status de abertura só fica visível
após solicitação; falha de atualização continua sendo apresentada.
Cores de texto e destaque vêm do tema. Sem paleta hardcoded, CSS ou assets novos.
Entrar e Abrir Kate permanecem controles explícitos, agora flat e próximos ao
conteúdo. A área de um card inteiro não foi convertida em ação de execução.

Foram preservados os corpos dos cliques, as funções de catálogo, a checagem de ID,
a única chamada trigger e a reconexão da view. Verificações locais compararam
essas partes ao baseline e conferiram aritmética de colunas e whitespace.
O novo uso de ItemDelegate/HoverHandler/ToolTip ainda requer lint e runtime Qt6.

### Próxima validação

Na branch feat/poc-03-native-grid, atualizar por fast-forward e abrir o pacote
principal. Testar Desenvolvimento e Educação/Ciências, hover nos nomes longos,
rolagem, seleção de categorias e uma janela redimensionada. Confirmar legibilidade,
densidade, contraste do item selecionado e ausência de itens sobrepostos.
Regressões de Kate e reset continuam úteis, sem ampliar a permissão de execução.

Não há skill específica de design KDE entre as skills disponíveis nesta sessão.
Não foi instalada skill externa, dependência visual nem ferramenta na workstation.
A revisão usa os componentes nativos existentes; uma futura skill deverá ser
avaliada quanto à adequação a QML/Plasma, sem presumir que regras para web se
apliquem diretamente ao launcher.

## Separar laboratório de interação do launcher — 30/10/2026

As capturas do ajuste 4cd6a40 mostram quatro colunas, ícones menores,
categorias em lista e tooltip com nome/descrição. O usuário identificou dois
controles inadequados à interação esperada de um launcher: Atualizar no topo e
Abrir Kate separado do ícone. Eles vieram dos ensaios de diagnóstico da PoC.

Incremento preparado:

- Remover Atualizar da representação principal, mantendo a observação dos sinais
  do catálogo e a invalidação/reconexão de modelos. O laboratório preserva refresh
  explícito; não foi adicionado polling ou reconstrução externa de cache.
- Usar ItemDelegate como alvo de clique do conjunto ícone/nome. Hover e foco vêm
  do controle nativo; tooltips e ícones de 32 px são preservados.
- Abrir subcategorias pelo clique no grupo, sem botão Entrar.
- Abrir Kate pelo clique no seu card, sem botão textual separado; ID exato e
  validação de modelo/índice continuam obrigatórios.
- Outros aplicativos ficam apenas apresentados nesta prévia. O rodapé continua
  informando a restrição, e não se amplia a execução silenciosamente.
- Exibir Voltar apenas dentro de subcategorias.
- Barra lateral ampliada de 164 para 190 px para acomodar Desenvolvimento;
  verificar novamente os nomes no ambiente real.
- Altura da célula cai de 124 para 104 px, aproveitando a remoção das ações
  separadas. O card ocupa a célula menos 8 px para espaçamento.
- Status da solicitação usa texto curto em vez de ID/retorno bruto de diagnóstico.
  Solicitação aceita não comprova janela aberta.

A função activateEntry recebe view, índice e dados antes de qualquer mutação.
Ela valida estado/limites, trata grupos e retorna imediatamente após navegar.
Somente depois da checagem de identidade pode chamar trigger, com os mesmos
argumentos vazio/null. Não consulta o delegate após a troca do modelo.

Testes da função extraída passaram com entradas sintéticas: Kate exato, bloqueio
de ID diferente/ausente, disabled/separador, índices inválidos, estado indisponível,
grupo sem acesso após mutação e exceção do trigger. A única chamada de execução
permanece guardada. Conferida ausência do botão de refresh e das ações separadas.

Ainda pendentes lint Qt6 e teste no KDE deste incremento. Conferir hover, clique
no Kate, grupo Ciências → Voltar e nomes da barra lateral. A restrição de execução
a Kate deve continuar válida; não considerar todo card de aplicativo executável.
Não repetir fixtures para validar somente essa alteração de interação.

## Clique confirmado e apresentação plana — 30/10/2026

O usuário confirmou que Kate abriu com sucesso após a mudança para clique no
card. As capturas mostram a representação sem Atualizar/Abrir Kate separados,
com nomes das categorias legíveis e aplicativos reais na grade.
Esta é evidência funcional do caminho positivo do card em bfee9a4; não foi enviada
nova saída de lint nessa mensagem.

O usuário questionou a utilidade de Educação → Ciências/Matemática quando ambos
contêm o mesmo aplicativo. Decisão: preservar a taxonomia do KDE na origem, mas
apresentar diretamente os aplicativos de cada categoria principal.
Subcategorias continuam úteis no laboratório para explorar a API; não precisam
ser expostas como etapas extras no fluxo principal.

### Opção nativa escolhida

`flat: true` no RootModel principal. Não foi introduzido filtro por nome da
categoria, cópia de aplicativos para array JavaScript ou deduplicação própria.

O código KDE consultado em
[63e20ff9d15b — appsmodel.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appsmodel.cpp)
mostra:

- refreshInternal preserva grupos principais quando o modelo está na raiz.
- AppGroupEntry recebe o valor de flat para construir o submodelo da categoria.
- processServiceGroup percorre subgrupos recursivamente quando flat está ativo.
- containsSameStorageId evita inserir novamente a mesma aplicação no submodelo.

[appentry.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appentry.cpp)
mostra a propagação da opção para o modelo filho.

Essa inspeção fundamenta a mudança, mas não substitui observar a versão instalada.
A deduplicação é por categoria; um aplicativo continua podendo pertencer
legitimamente a categorias principais diferentes. Não deduplicar globalmente nem
comparar pelo display: aplicativos distintos podem ter o mesmo nome.

### Alcance e validação pendente

Única alteração de comportamento no QML: flat false → true, com comentário.
A lógica de seleção, clique, identidade do Kate, sinais e layout permanece igual.
Laboratório, menu padrão e arquivos de classificação KDE não foram modificados.
A navegação por grupos/Voltar fica preservada como fallback, normalmente sem uso
quando o modelo entrega somente aplicativos por categoria.

No Work foi conferida a diferença mínima e a implementação upstream; não se
executou runtime KDE, lint ou teste nativo de deduplicação. Não há um PASS novo
inferido a partir do código-fonte.

Na próxima rodada, selecionar Educação e confirmar LibreOffice Math diretamente
e sem duplicação, mantendo as categorias principais na lateral. Verificar uma
categoria mais cheia para observar se outras duplicações internas foram removidas.
O clique do Kate já confirmado não precisa de repetição extensa; checagem curta
continua útil pois índices podem mudar com a opção flat.
