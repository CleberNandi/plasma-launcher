# PoC 02E — diagnóstico automático no KDE local

## Objetivo e limites

Executar `bash experiments/poc-02a/scripts/poc-02e2-auto.sh` na sessão gráfica
KDE do usuário, sem sudo, em terminal ou Codex CLI local. Não requer stdin.

O runner abre e encerra sua própria janela plasmawindowed com um pacote de
diagnóstico separado. Não fecha janelas preexistentes. Não instala componentes,
não reinicia Plasma, não altera favoritos e não executa a fixture.
Não clicar Atualizar catálogo nem reconstruir cache durante a rodada automática.

Dependências já instaladas: bash, plasmawindowed, jq, flock, sha256sum, mktemp,
sed, tail e ferramentas coreutils. Pré-condições ausentes geram erro; não instalar
dependências automaticamente. Diretório applications precisa existir.

## Operação

O probe QML usa RootModel com categorias reais e Repeater eager para observar
todos os aplicativos dos submodelos de primeiro nível, sem depender de viewport.
A fixture usa Development e Utility, já observadas no ambiente alvo.
Não percorre subcategorias recursivamente. Um timeout não prova defeito no KDE:
pode indicar categorias diferentes ou falha no probe; inspecionar viewer.log.

Fases: baseline sem fixture; A em Development; mesmo arquivo passa a B em Utility;
remoção. A migração exige nome A ausente, B presente em uma única categoria e
categoria diferente da observada em A. Não depende de nomes traduzidos fixos.
Cada fase exige três snapshots consecutivos completos; janela de até 90s.
O snapshot completo verifica contagens/delegates, mas não é uma transação do
modelo nativo. Três observações reduzem aceitação de estados transitórios.
O teste não valida geometria da interface principal nem execução de aplicativos.

O probe emite snapshots a cada segundo. Essa amostragem é somente instrumentação
de teste; não é polling adicionado ao launcher. Contadores de refreshed,
rowsInserted, rowsRemoved e dataChanged são auxiliares: condições de sucesso
dependem do conteúdo. Não inferir latência exata a partir de resposta humana.

A fixture é exclusiva (mktemp) e alterações são publicadas por rename atômico,
para evitar exposição de conteúdo parcial. Isso difere do harness interativo
anterior, que reescrevia o arquivo diretamente: comparar as estratégias em uma
investigação futura se os resultados divergirem; não atribuir causa sem prova.

## Relatório e limpeza

O caminho RELATÓRIO é impresso no início e no fim. Resultados ficam em diretório
privado temporário: result.txt, viewer.log, baseline.json, inclusion.json,
migration.json, removal.json, commit.txt, version.txt e fixture-path.txt.
Exit 0 = etapas confirmadas; 1 = timeout/falha; 2 = pré-condição.
Logs Qt podem conter caminhos e informações da sessão; revisar antes de publicar.
Não adicionar automaticamente relatórios ao Git. O diretório /tmp não é durável:
guardar evidência selecionada no repositório apenas após análise e revisão.

Trap EXIT/INT/TERM remove a fixture se o hash corresponder ao conteúdo gerado,
e encerra apenas o PID do viewer iniciado pelo runner. Um arquivo alterado
externamente é preservado e reportado. Não é defesa contra corrida maliciosa.
SIGKILL/queda de energia podem impedir limpeza; inspecionar fixture-path.txt.
Há lock por sessão para impedir duas rodadas automáticas simultâneas. Não rodar
o harness interativo paralelo nem alterar o catálogo durante o diagnóstico.

## Tarefa para o Codex local

1. Confirmar branch, HEAD e árvore; preservar alterações do usuário.
2. Ler este documento e o runner/probe. Executar o runner na sessão do usuário
   com limite de execução de pelo menos 8 minutos, sem instalar nada.
3. Ler result.txt, snapshots e viewer.log. Informar PASS/FAIL por fase, sinais,
   erros QML, versão e confirmação da limpeza.
4. Se falhar, distinguir falha do próprio probe de comportamento do catálogo.
   Não mascarar uma falha automática chamando refresh/cache builder.
   Investigar assinatura/API instalada; propor ou implementar correção pequena
   em branch de desenvolvimento com evidências. Não editar launchers do sistema,
   favoritos ou arquivos pessoais e não realizar merge.
5. Entregar resumo técnico; não exigir capturas manuais para avaliar conteúdo.

## Validação no Work

Bash syntax: PASS. Runner testado com viewer simulado, filesystem temporário,
mudança de categoria e limpeza; não corresponde à homologação do KDE.
Runtime QML/Kicker e qmllint: NOT RUN, indisponíveis neste ambiente.
A execução local é necessária e pode revelar incompatibilidade da API privada.

Referências:
- https://doc.qt.io/qt-6/qml-qtquick-repeater.html
- https://doc.qt.io/qt-6/qml-qtqml-connections.html
- https://specifications.freedesktop.org/desktop-entry/latest/recognized-keys.html
