# PoC 02F.1 — Navegação por subcategorias

**Status:** implementação preparada; homologação QML/KDE pendente.
**Data:** 30/10/2026.

## Incremento

A interface experimental em `experiments/poc-02a/package` passa a oferecer:

- Botão **Entrar** nas linhas cujo role `hasChildren` é verdadeiro.
- Botão **Voltar** para remover um nível do caminho.
- Caminho textual dos grupos abertos, sem usar nomes como identidade.
- Limpeza do caminho ao trocar a categoria principal ou reconstruir o RootModel.
- Abertura ainda restrita ao Kate, por clique explícito; grupos não recebem esse botão.

O pacote principal `package/` e o probe automático 02E permanecem no checkpoint anterior.
Este incremento não integra o catálogo à interface principal.

## Modelo e ciclo de vida

Cada passo guarda apenas a posição da linha e o rótulo de apresentação.
O modelo exibido é obtido percorrendo `modelForRow()` desde a categoria principal.
Não se guardam ponteiros de submodelos em uma pilha JavaScript.
O percurso valida limites e interrompe com modelo nulo quando o caminho não existe.

Os índices são locais a cada nível e não persistentes. `modelAboutToBeReset` e
`refreshed` do RootModel invalidam o caminho antes da reconexão adiada.
Não se tenta restaurar seleção por nomes nem preservar caminho entre reconstruções.
A homologação deve observar também alterações do catálogo enquanto há um grupo aberto;
o PASS anterior do probe separado não cobre esta nova navegação.

As funções no objeto raiz recebem o modelo da view como argumento ao entrar.
IDs definidos dentro de `fullRepresentation` são usados pelos handlers desse
componente; a lógica externa não depende de alcançá-los por escopo.

## Fonte consultada

Foi inspecionado o código upstream KDE em
[`63e20ff9d15b`](https://github.com/KDE/plasma-workspace/commit/63e20ff9d15bbb709d8fb59952088e536ae8d523):

- [abstractmodel.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/abstractmodel.cpp):
  mapeia o role `hasChildren`.
- [appsmodel.cpp](https://github.com/KDE/plasma-workspace/blob/63e20ff9d15bbb709d8fb59952088e536ae8d523/applets/kicker/appsmodel.cpp):
  fornece esse role e retorna o modelo filho em `modelForRow(row)`.

Esta inspeção explica a escolha da API privada; não comprova que o código upstream
seja idêntico ao binário instalado nem amplia a matriz de compatibilidade.

## Verificações realizadas no Work

As funções JavaScript extraídas do QML foram exercitadas com modelos sintéticos:
entrada em dois níveis, retorno, recusa de folha sem modelo filho, bloqueio durante
reset, limpeza do caminho e índices inválidos. Também foi verificada a ausência
de referência ao ID interno da view nessas funções e de whitespace novo.

Isso verifica lógica e limites; não substitui parser QML, bindings, renderização,
sinais nativos ou teste do pacote no KDE. `qmllint` e runtime KDE não disponíveis
neste ambiente. Nenhum PASS nativo novo foi registrado.

## Homologação na workstation

Sincronizar a branch de desenvolvimento, com árvore local limpa:

```bash
git pull --ff-only origin feat/poc-02-kde-app-catalog
git diff --check
plasmawindowed "$PWD/experiments/poc-02a/package"
```

Roteiro curto para o usuário ou executor local:

1. Em Educação, clicar **Entrar** em Ciências ou Matemática. Confirmar que aparecem
   as entradas do grupo e que o caminho mostra seu nome.
2. Clicar **Voltar**. Confirmar o retorno à lista de grupos. Repetir a entrada e
   trocar para Desenvolvimento: o caminho deve ser limpo.
3. Voltar a um grupo e clicar **Atualizar catálogo**. Confirmar retorno ao nível
   inicial sem erro QML, referência inválida ou abertura de aplicativo.
4. Em Desenvolvimento, clicar **Abrir Kate** e confirmar a abertura explícita.
   Nenhum aplicativo deve abrir ao navegar, voltar ou atualizar.
5. Redimensionar a janela e verificar acesso aos botões e às barras de rolagem.

Se o ambiente não possuir subcategorias, registrar como não exercitado. Não instalar
aplicativos nem alterar o menu para satisfazer este roteiro.

Para o Codex local: verificar branch/HEAD e árvore antes e após; executar
`qmllint` somente se já disponível, informando sua versão, comando e diagnósticos;
não tratar erros de resolução de imports como ausência de erros QML. Observar
`plasmawindowed` na sessão gráfica apenas se houver capacidade de interação;
caso contrário, deixar os cliques explicitamente pendentes. Não afirmar execução
visual com base somente na análise do código. Não fazer merge.

O runner 02E continua útil para regressão do catálogo, mas não aciona os novos
botões. Não é necessário repetir fixtures para validar somente entrada/retorno.
