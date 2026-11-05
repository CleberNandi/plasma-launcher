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

## Homologação local reportada — 30/10/2026

Fonte: relatório do Codex local fornecido pelo usuário nesta conversa.
Revisão testada: 1774f8c192ccbbe37e2040428dcf5e76eb070190.
Branch: feat/poc-02-kde-app-catalog; árvore limpa antes/depois.
Viewer: plasmawindowed 1.0. Relatório original: /tmp/plasma-launcher-report.wnPnDD.
Os arquivos brutos permanecem na workstation; não foram acessados pelo Work.

| Fase | Resultado | a | b | refreshed |
| --- | --- | --- | --- | --- |
| baseline | PASS | [] | [] | 2 |
| inclusion | PASS | ["Desenvolvimento"] | [] | 3 |
| migration | PASS | [] | ["Utilitários"] | 4 |
| removal | PASS | [] | [] | 5 |

Todas as fases atingiram três snapshots completos consecutivos; EXIT=0.
Contadores inserted/removed/changed permaneceram zero em todas as fases.
Sem refresh manual, rebuild externo de cache ou correção de código na rodada.
O executor reportou ausência de erros/warnings QML/Qt; viewer.log continha
qml: 0 e 21 linhas de telemetria.
Limpeza confirmada pelo executor: fixture e arquivos de staging ausentes,
processo do probe encerrado. Nenhum favorito alterado pelo teste.

Conclusão: inclusão, mudança de nome/categoria por publicação atômica e remoção
automáticas homologadas no probe independente, no ambiente testado.
Não constitui homologação integral da interface principal, navegação
hierárquica, estabilidade entre versões ou reescrita direta do arquivo.
A razão dos contadores dos submodelos zerados é hipótese compatível com
reconstrução/reconexão; não foi provada apenas pelos snapshots.
Não concluir que o teste manual anterior falhou por causa da escrita direta.

O histórico enviado menciona uma execução inicial com exit code 1, sem seu
relatório ou causa. O PASS acima corresponde à rodada wnPnDD; não atribuir
sucesso à tentativa inicial nem inventar diagnóstico para ela.

Próximo passo: revisão consolidada da PoC 02 e preparação de PR de checkpoint,
com limitações explícitas e sem merge automático. Integração ao launcher
principal será um incremento separado.
