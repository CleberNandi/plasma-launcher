# PoC 03G — Popup nativo no painel

**Data:** 05/11/2026.
**Base:** 0499d986e07752316607c73eb1fa434180c71776 (PoC 03E/03F).
**Branch:** feat/poc-03-panel-popup.
**Status:** preparado para teste local, sem homologação do painel.

## Comportamento

Em form factors Horizontal e Vertical, o launcher usa representação compacta
com botão de ícone. O Plasma hospeda e posiciona a representação completa como
popup, mantendo as dimensões existentes. Fora do painel, o viewer continua
mostrando a representação completa.

Clique no botão alterna expanded; registra-se o estado ao pressionar para
evitar reabrir após a perda de foco causada pelo próprio clique. A ativação por
atalho usa activationTogglesExpanded do Plasma. Nenhuma tecla global é definida
pelo código e não se alteram Super, Alt+Espaço ou KRunner.

A cada abertura, a pesquisa e a seleção são limpas e o campo recebe foco, por
callback adiado. O callback verifica visibilidade e expanded antes de tocar no
foco, inclusive se o popup for fechado antes de sua execução. A seção lateral
selecionada é preservada. Escape limpa texto/seleção e retorna à pesquisa;
com texto vazio, fecha o popup. Autorepeat de Escape não fecha em cascata.
Escape dentro do menu de contexto continua sob o controle do menu Qt.

Após trigger retornar sucesso, fecha somente o popup no painel. Recusa ou
exceção mantém o status de falha; sucesso significa solicitação aceita pelo
Kicker, não confirmação de que a janela do aplicativo foi criada. A janela do
viewer permanece aberta. Clique fora usa hideOnWindowDeactivate do Plasma.
Ao recolher o popup, fecha-se o menu de favoritos e invalida-se a seleção.

Pesquisa/proxy, reconstrução dos cards e armazenamento de favoritos preservados.
O pacote é atualizado para versão 0.1.1. Sem C++ próprio, shell de execução,
indexador ou mudança de favoritos do Kickoff.

## Fontes

- [Porting Plasmoids to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/):
  divisão entre PlasmoidItem e Plasmoid, propriedades de representação.
- [PlasmoidItem QML Type](https://api.kde.org/qml-org-kde-plasma-plasmoid-plasmoiditem.html):
  compact/fullRepresentation e hideOnWindowDeactivate.
- [Testing widgets](https://develop.kde.org/docs/plasma/widget/testing/):
  viewer e teste como widget instalado no painel.

## Verificação no Work

Funções reais extraídas do QML foram executadas com mocks em Node:
Escape em duas etapas, autorepeat, callback após fechamento/representação
invisível, abertura aceita, recusa, exceção, índice inválido, entrada desabilitada,
catálogo indisponível e preservação da janela fora do painel. PASS.
Funções de busca, favoritos e navegação de índices comparadas com a base: iguais.
IDs QML únicos e ausência de whitespace final conferidos.

Não há Qt/KDE/qmllint neste ambiente. Mocks não validam parsing QML, imports,
eventos reais, integração de atalho, geometria, memória ou desempenho.
Nenhum resultado nativo é inferido.

## Atualizar e conferir lint

Executar cada linha separadamente, no repositório e com árvore limpa:

```bash
git fetch origin
git switch --track origin/feat/poc-03-panel-popup
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml
```

Se a branch local já existir, usar git switch feat/poc-03-panel-popup.
Se houver erro novo de lint, registrar a saída antes da instalação.

## Instalar para o usuário

```bash
kpackagetool6 --type Plasma/Applet --install "$HOME/Workspace/personal/plasma-launcher/package"
```

Se informar que dev.nandi.plasmalauncher já está instalado, usar:

```bash
kpackagetool6 --type Plasma/Applet --upgrade "$HOME/Workspace/personal/plasma-launcher/package"
```

Sem sudo. A instalação registra o pacote do laboratório, não substitui o Kickoff.
No painel: entrar no modo de edição → Adicionar widgets → procurar
Plasma Launcher Lab → arrastar para o painel → sair do modo de edição.
Manter o launcher atual para comparação. Não editar plasma-org.kde.plasma.desktop-appletsrc
nem reiniciar plasmashell como primeiro passo.

Instalação copia o pacote; alterações futuras no checkout exigem novo upgrade.
Se houver uma instância antiga já carregada, registrar a versão/comportamento
antes de removê-la, pois remover a instância pode apagar sua configuração.
Remover somente uma instância recém-criada e vazia se for preciso repetir o teste.
Os favoritos do viewer não são importados automaticamente para a instância do
painel. Isso é esperado: configuração própria por instância.

## Roteiro no KDE

1. Abrir pelo ícone; digitar code imediatamente, sem clicar no campo.
2. Fechar clicando no mesmo ícone e reabrir: campo vazio e foco na pesquisa.
3. Digitar kate → Escape limpa → outro Escape fecha. Segurar Escape após digitar
   deve limpar sem fechar por autorepeat.
4. Buscar code e kate; setas/Enter abrem o aplicativo correspondente e fecham o
   popup. Repetir abertura por clique e na seção Favoritos.
5. Botão direito → adicionar/remover favorito não abre app nem fecha o launcher.
   Escape no menu deve primeiro fechar o menu; retestar abertura pelo painel.
6. Clicar fora fecha. Reabrir não preserva seleção de resultado antigo.
7. Adicionar favoritos nesta instância, recolher/reabrir e conferir. Persistência
   após novo login fica pendente até uma oportunidade natural, sem forçar logout.
8. Escolher um atalho livre em Configurar Plasma Launcher Lab → Atalho de teclado. Se houver conflito,
   cancelar. Testar abrir/fechar e foco, preservando atalhos existentes.
9. Conferir popup contido na tela e associado ao painel; testar outro monitor
   e painel vertical somente se disponíveis. Não mover o painel principal para
   obter esse resultado. Escala/DPI, bordas e Wayland precisam de inspeção real.

Registrar revisão, monitor/escala, passos e terminal em falhas. Tempo de abertura
e consumo ainda não medidos. Rodapé/perfil/energia continuam fora deste incremento.

## Reversão

Para parar o teste, remover do painel somente o widget experimental (essa ação
remove a configuração da instância). Manter o launcher original. Se quiser
desinstalar também o pacote, depois de remover a instância:

```bash
kpackagetool6 --type Plasma/Applet --remove dev.nandi.plasmalauncher
```

PR dependente da branch compact-layout; sem merge na main.
