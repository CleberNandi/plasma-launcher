# PoC 03H — Coleta agregada de plasmashell e revisão do checkpoint

**Data:** 05/11/2026.
**Base funcional:** 5fd072658fbf069daea33338b8b5f0a193ca5895.
**Branch:** feat/poc-03-panel-popup.
**Status:** duas coletas locais concluídas no mesmo processo; crescimento menor na segunda rodada. Sem merge.

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

## Primeira coleta local — 05/11/2026

JSON enviado pelo usuário com status complete, escopo whole-plasmashell,
SC_CLK_TCK=100 e todos os campos de memória presentes. Durações observadas:
5,022 s / 15,067 s / 5,022 s.

| Fase | CPU média (% de um núcleo) | RSS mediana (KiB) | PSS mediana (KiB) |
| --- | ---: | ---: | ---: |
| Fechado antes | 0,000 | 583592 | 316143 |
| Interação | 1,925 | 595772 | 328261 |
| Fechado depois | 0,199 | 597804 | 330280 |

Entre as medianas fechadas: RSS +14212 KiB (+13,88 MiB), PSS +14137 KiB
(+13,81 MiB). Memória final estável nas cinco amostras dessa fase; isso não
demonstra estabilidade ao longo de novos ciclos. Zero CPU na primeira janela
significa ausência de ticks de CPU observados nesse intervalo, não garantia
de CPU perpetuamente nula.

A média de CPU da interação é pequena em relação à capacidade de um núcleo;
não informa picos, frame pacing nem tempo de abertura. A CPU após fechamento
ficou em 0,199% de um núcleo. Não há relato específico de engasgos junto ao JSON.

O aumento de memória pode incluir inicialização/caches do Qt, ícones, catálogo
e outros widgets. Hipóteses, sem atribuição causal ao launcher. Não caracteriza
vazamento por si só. Não chamar os 583,79 MiB de RSS final de “RAM do launcher”.

Próxima verificação limitada: repetir a mesma coleta no mesmo processo/sessão,
sem reinstalar, reiniciar ou encerrar a sessão. Comparar o novo fechado antes
com o final desta rodada e o crescimento entre as duas fases fechadas novas.
Se a memória estabilizar, isso favorece a hipótese de aquecimento/cache;
se voltar a crescer, investigar tendência em mais ciclos antes de concluir.
Não reiniciar para produzir artificialmente uma nova baseline fria.

## Segunda coleta local — 05/11/2026

JSON com status complete, mesmo PID e start_ticks da primeira coleta,
SC_CLK_TCK=100 e todas as amostras de memória presentes. Durações observadas:
5,035 s / 15,114 s / 5,037 s. A execução do coletor é válida; não há registro
automático das ações do usuário durante a fase de interação.

| Fase | CPU média (% de um núcleo) | RSS mediana (KiB) | PSS mediana (KiB) |
| --- | ---: | ---: | ---: |
| Fechado antes | 0,199 | 597752 | 326873 |
| Interação | 2,382 | 600300 | 329384 |
| Fechado depois | 0,397 | 600372 | 329461 |

Comparação entre medianas fechadas de cada rodada:

| Rodada | Delta RSS (MiB) | Delta PSS (MiB) |
| --- | ---: | ---: |
| 1 | +13,88 | +13,81 |
| 2 | +2,56 | +2,53 |

O RSS inicial da segunda rodada está apenas 52 KiB abaixo do RSS final anterior.
Entre os dois finais: RSS +2,51 MiB, PSS -0,80 MiB. PSS pode variar também pela
distribuição de páginas compartilhadas; não interpretar a queda como prova
de liberação de alocações do launcher.

O crescimento menor é compatível com aquecimento/cache se aproximando de um
patamar, mas duas coletas curtas não comprovam estabilidade definitiva nem
ausência de vazamento. Não apareceu evidência de crescimento repetido da
mesma magnitude. Escopo continua sendo todo o plasmashell, sem atribuição isolada
ao widget e sem medida de latência. Nenhum relato de engasgos foi confirmado.

Não solicitar uma terceira rodada idêntica sem novo sintoma ou tendência que
justifique. Para o checkpoint experimental, registrar esta caracterização
limitada e seguir com a evidência de lint e revisão final de integração.
