# PoC 03E — Catálogo compacto, direção visual C

**Data:** 04/11/2026.
**Status:** primeira etapa visual implementada; lint e inspeção nativa pendentes.
**Base:** c05a472caa708e05070512337167c815e5d2a220.
**Branch:** feat/poc-03-compact-layout.

## Decisão e escopo

O usuário escolheu o mockup C, “Favoritos na lateral”, após comparar catálogo
compacto, favoritos acima da grade e categorias recolhíveis. A direção mantém
busca superior, navegação lateral, grade de aplicativos e rodapé discreto.

Este primeiro incremento organiza a estrutura visual do catálogo já funcional.
Favoritos reais, perfil e ações de sessão serão incrementos funcionais seguintes;
não há controles sem ação, favoritos fictícios ou identificação pessoal fixa.
O rodapé identifica o launcher e preserva as mensagens reais de abertura/erro.

## Mudanças

- Pesquisa ocupa o topo, com ícone edit-find e botão Limpar contextual.
- Removido o cabeçalho grande que disputava espaço com a busca.
- Lateral de 208 unidades lógicas, fundo derivado do tema e divisor sutil.
- Área da grade com margem 16 e títulos de categoria preservados.
- Ícones continuam com 32 unidades; altura da célula passa de 104 para 92.
- Dimensões preferidas 760×520; mínimas 660×460. Colunas continuam responsivas.
- Rodapé separado com mensagem concisa; texto longo pode ser truncado.
- Cores derivam de Kirigami.Theme; nenhum bitmap de mockup entra no runtime.

Não se adicionou busca fuzzy, runner, indexador, atalhos globais ou dependência.
A arquitetura continua sendo um plasmoid KDE, sem executável próprio.
O mecanismo de busca preserva a desvinculação da grade durante refiltragem e
seus guards de ativação. O laboratório PoC 02 não foi modificado.

## Verificação

Conferidos no Work: trecho de lógica anterior a fullRepresentation integralmente
igual; handlers de teclado iguais após normalizar indentação; IDs únicos;
preservação do mapeamento/guards da busca e ausência de whitespace final.
Essa inspeção não substitui parser QML, qmllint ou renderização nativa.

No KDE, executar uma linha por vez, sem sudo:

```bash
git fetch origin
git switch --track origin/feat/poc-03-compact-layout
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
plasmawindowed "$PWD/package"
```

Se a branch já existir localmente, usar git switch feat/poc-03-compact-layout,
seguido de git pull --ff-only origin feat/poc-03-compact-layout.

Validar proporções, nomes de categorias, scrollbar, nomes em duas linhas e tema
claro/escuro. Buscar code e kate e conferir apresentação/abertura; navegar por
setas/Enter e redimensionar até o mínimo. A janela de plasmawindowed é um
visualizador; o popup no painel ainda precisa de sua própria homologação.

## Próximos incrementos

1. Favoritos reais na lateral, com definição explícita da persistência e escopo;
   não vincular automaticamente ao contexto fixo do laboratório.
2. Perfil e menu nativo de sessão com ações identificadas.
3. Integração ao painel e medição de abertura, busca e consumo adicional.
4. Melhorias graduais de relevância e PoC separada de integração com KRunner.

A grade C é a referência aprovada; densidade e medidas finais dependem do uso
real no KDE. Sem merge autorizado.

## Retorno visual e densidade — 04/11/2026

O usuário enviou três capturas da estrutura compacta: Todos os aplicativos,
busca kate e busca code. As buscas mostram nomes e ícones correspondentes.
Não foram fornecidos nesta resposta SHA local, saída de lint ou confirmação
explícita de abertura/teclado; não se infere esses resultados das capturas.

A janela mostrada tem aproximadamente 700 unidades de largura. A grade anterior,
com alvo mínimo de célula 112, passou para três colunas; a lateral também deixou
Utilitários abaixo da área inicial. Ajuste de densidade: alvo da célula 104,
categorias de 32 com espaçamento zero e cabeçalho lateral de 24.
Ícones permanecem em 32 e altura das células da grade em 92. Scrollbars continuam
disponíveis para fontes maiores e janelas menores.

A expectativa é quatro colunas na largura observada; perto da largura mínima
o layout ainda reduz para três. O alvo de densidade não fixa quatro colunas nem
garante ausência de rolagem em qualquer escala de fonte/tela.
As alterações de QML se limitam a quatro valores geométricos; busca, ativação,
roles e teclado permanecem iguais. Lint/renderização deste ajuste ainda pendentes.
