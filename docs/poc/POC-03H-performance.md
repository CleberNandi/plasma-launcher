# PoC 03H — Coleta agregada de plasmashell e revisão do checkpoint

**Data:** 05/11/2026.
**Base funcional:** 5fd072658fbf069daea33338b8b5f0a193ca5895.
**Branch:** feat/poc-03-panel-popup.
**Status:** coletor verificado; medições no KDE aguardadas. Sem merge.

## Revisão do checkpoint

Leitura do pacote principal: QML, configuração XML e metadados. Não foi
identificado novo bloqueio estático nos fluxos de catálogo, pesquisa, favoritos,
ativação ou popup já homologados. A revisão não prova ausência de defeitos.

- Ativação usa trigger do modelo nativo, com validação de linha, tipo de entrada
  e ID de aplicativo. A pesquisa mapeia a linha do proxy para a origem.
- A recriação dos cards após filtrar foi preservada: corrige a divergência de
  nome/ícone confirmada no KDE. Não otimizar sem medir e repetir a regressão.
- Configuração persiste IDs por instância; nenhum armazenamento paralelo ou
  execução de shell foi introduzido no widget.
- Foco adiado verifica visibilidade/expanded. Fechamento explícito só ocorre
  após solicitação aceita e somente em painel.
- A API Kicker é privada. Minimum-version 6.0 dos metadados não comprova
  compatibilidade com todas as versões Plasma 6.
- O pacote principal ainda concentra a UI em um QML grande. Isso é um custo de
  manutenção; não exige refatoração antes de consolidar a base funcional.
- Scripts do laboratório foram conferidos com bash -n; isso não é reexecução
  do probe nem E2E do widget. Não foram executados contra a sessão do usuário.
- Simulação anterior de popup/ativação reexecutada: PASS. Nenhum novo lint ou
  runtime nativo Qt/KDE disponível no Work; evidência de lint ainda deve ser
  obtida antes da integração definitiva.

## Coletor

scripts/measure-plasma.py usa somente a biblioteca padrão Python e leituras de
/proc. Não grava arquivos, não modifica o painel, não lança aplicativos nem
envia dados. O JSON é impresso no terminal. Recusa root e entrada não interativa.
Requer exatamente um plasmashell do usuário atual; não escolhe entre processos
ambíguos. Não coleta cmdline, ambiente, nomes de arquivos ou consultas digitadas.

CPU: delta de utime + stime dividido pelo intervalo monotônico real e
SC_CLK_TCK. 100% corresponde a um núcleo. RSS/PSS: smaps_rollup em KiB;
mínimo, mediana e máximo por fase. Se houver falta de permissão de memória,
campos ficam null; não usar sudo para contornar. Identidade por starttime é
conferida para não misturar amostras após reinício/reutilização do PID.

As fases são: 5 s fechado, 15 s de interação manual, 5 s de repouso + 5 s de
coleta final fechado. Tempo total de coleta/repouso: cerca de 30 s, mais as pausas
entre fases. Nenhuma tecla é enviada automaticamente.

## Executar

No terminal, dentro do repositório e na branch feat/poc-03-panel-popup:

```bash
git pull --ff-only origin feat/poc-03-panel-popup
python3 scripts/measure-plasma.py
```

Execute uma linha por vez. Não precisa reinstalar o widget: pacote principal
inalterado nesta entrega. Siga as três mensagens no terminal:

1. Popup fechado e desktop quieto; Enter inicia a primeira fase.
2. Enter inicia 15 s para abrir, pesquisar code/kate, limpar e fechar pelo atalho.
   Repita os ciclos sem iniciar aplicativos. Isso evita medir a carga de abertura
   de um aplicativo junto com a busca.
3. Feche o popup e pressione Enter; aguarde repouso e coleta final.

Evite mexer em outros widgets durante a rodada. Ao concluir, enviar o JSON e
informar se percebeu engasgos. Um relato visual não é uma medida em milissegundos.
A execução não automatiza interações; é responsabilidade do operador executar
o roteiro no período indicado. Para repetir, executar o mesmo comando novamente.

## Interpretação e limites

O resultado é do processo plasmashell inteiro: NÃO é “RAM do nosso launcher”.
Outros widgets, notificações, animações, cache e atividades do desktop podem
mudar as métricas. Não há baseline sem o widget nem atribuição causal isolada.

Comparar as fases fechadas e a CPU no repouso ajuda a identificar sinais para
investigação. Uma única diferença positiva não comprova vazamento. Se houver
crescimento, repetir ciclos e verificar tendência/estabilização antes de agir.
Não definir um limite arbitrário de memória ou declarar leveza sem evidência.

Para atribuição incremental rigorosa, usar sessão de teste isolada sem/com
o widget. Medir latência de abertura exigiria correlacionar entrada e primeiro
frame visível. Esta coleta não mede latência, GPU, VRAM ou alocações por widget.

## Verificação do coletor

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```

5 testes PASS no Work: parsing de comm com espaços/parênteses, nomes exatos de
RSS/PSS, CPU por intervalo real e dados de memória ausentes, recusa de reinício
do processo e leitura real de /proc/self. Isso valida o coletor, não o desempenho
do launcher. Rodada interativa em KDE não executada no Work.

## Integração

Dependências #2 → #3 → #4 → #5 → #6 já conferidas. Os fluxos básicos, atalho
Ctrl+Shift+Enter e persistência após novo login foram homologados pelo usuário.
Coleta local e evidência de lint ficam pendentes para fechar o checkpoint.
Nenhum merge, troca do launcher original ou alteração da configuração do painel.

## Referências

- https://docs.kernel.org/filesystems/proc.html
- https://man7.org/linux/man-pages/man5/proc_pid_stat.5.html
