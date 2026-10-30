# PoC 03A — Catálogo nativo na grade principal

**Data:** 30/10/2026.
**Status:** primeira grade renderizada em capturas; layout inicial rejeitado na revisão visual. Ajuste compacto preparado; novo lint/homologação pendentes.
**Branch:** feat/poc-03-native-grid.
**Base:** 73899697e76f8ce1a6152c7232455fc19f6b6b80, checkpoint da PoC 02.

## Entrega

Ao abrir `package/`, a interface principal passa a apresentar categorias reais
na barra lateral e nomes, ícones e descrições reais em uma GridView com rolagem.
A seleção visual destaca a categoria principal. Grupos exibem Entrar e o
caminho permite Voltar. Aplicativos comuns são apresentados sem ação de execução;
Kate mantém um botão explícito condicionado ao ID já homologado na PoC 02G.1.

O catálogo simulado da PoC 01 é removido desta branch. As seções simuladas
Favoritos/Todos não são preservadas como se fossem nativas. A leitura de
favoritos continua no laboratório 02D; nenhum client fixo é levado ao principal.
Pesquisa local, perfil real, favoritos e execução geral serão entregas separadas.

O nome/ícone e ID do pacote principal permanecem os mesmos. Este teste deve usar
somente plasmawindowed, sem instalar/atualizar widgets nem substituir o menu do
painel. A validação do popup no painel continuará pendente após o smoke em janela.

## Escolhas de implementação

- Reaproveitada a lógica validada no laboratório: RootModel hierárquico,
  modelForRow por nível, revisão observável e invalidação do caminho no reset.
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
2. Educação → Ciências → Voltar → Matemática. Confirmar caminho e conteúdo;
   trocar para Desenvolvimento deve limpar o caminho.
3. Com um grupo aberto, Atualizar catálogo: retorno ao nível inicial, conteúdo
   válido e nenhum ReferenceError.
4. Abrir Kate pelo botão; confirmar retorno e abertura visual. Nenhum outro
   card deve oferecer abertura, e navegar/atualizar não deve iniciar aplicativos.
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
