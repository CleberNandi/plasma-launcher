# PoC 04A — Perfil de leitura no rodapé

**Data:** 05/11/2026.
**Base:** main em 365f83fbd438e5b735a2244bcd6069f8977b8984.
**Branch:** feat/poc-04a-profile-footer.
**Pacote:** 0.1.2.
**Status:** viewer homologado pelo usuário; atualização e avaliação na instância do painel pendentes.

## Mudança

O rodapé troca o texto genérico Plasma Launcher por avatar/nome da conta da
sessão. O componente components/ProfileBadge.qml usa KUser do módulo público
org.kde.coreaddons. Não há leitura própria de arquivos de contas, gravação de
perfil, subprocessos, autenticação, telemetria ou dados pessoais no repositório.

Nome: fullName não vazio, depois loginName, depois Usuário.
Avatar: faceIconUrl do KUser, mostrado como Image em 24 px quando Ready.
Enquanto vazio/carregando ou em Error, apresenta o ícone user-identity.
Imagem conserva a proporção. Nenhum avatar personalizado é embutido no pacote.

Nome longo tem elide à direita e tooltip com texto completo. Acessibilidade
identifica o componente como texto estático com o nome completo; imagem/texto
internos são ignorados para evitar anúncio duplicado. Não cria parada de Tab
nem botão de edição de conta. Nome é texto simples, sem interpretação de markup.

Perfil ocupa no máximo 45% da largura útil do rodapé. A mensagem de abertura
mantém o espaço restante com truncamento. Dimensões mínima/preferida do popup
preservadas; a altura interna do avatar passa de 20 para 24 px.
Busca, favoritos, ativação, fechamento, seleção e atalho não foram modificados.

## Dependência e limites

KUser QML: [documentação oficial](https://api.kde.org/qml-org-kde-coreaddons-kuser.html).
Import: org.kde.coreaddons. Propriedades lidas: fullName, loginName, faceIconUrl.
A disponibilidade do módulo no KDE do usuário ainda precisa ser confirmada pelo
lint/runtime. A dependência Kicker existente continua privada.

Um módulo QML ausente impede carregar o componente; o fallback de avatar/nome
cobre dados ausentes, não ausência do módulo. Não instalar pacotes por tentativa
nem mudar o perfil do sistema para contornar erros. Informar o diagnóstico.

## Verificação disponível

- Quatro casos executados da função real userDisplayName: nome completo com
  espaços; nome vazio com login; ambos em branco; valores null/undefined. PASS.
- Prefixo do main.qml antes do rodapé comparado à base, descontando apenas
  import do componente: idêntico.
- IDs QML únicos e whitespace final conferidos.
- Não há runtime local Qt/KDE disponível nesta rodada. Não foi executado
  qmllint, nem comprovados avatar, geometria, leitura da conta ou acessibilidade
  no ambiente nativo. O novo componente precisa da rodada abaixo.

## Testar primeiro no viewer

No repositório, com árvore limpa, executar cada linha separadamente:

```bash
git fetch origin
git switch --track origin/feat/poc-04a-profile-footer
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml package/contents/ui/main.qml package/contents/ui/components/ProfileBadge.qml
plasmawindowed "$HOME/Workspace/personal/plasma-launcher/package"
```

Se a branch local já existir, usar git switch feat/poc-04a-profile-footer.
Se o lint apontar módulo/tipo/propriedade inexistente, enviar a saída antes de
atualizar o pacote instalado no painel. O viewer usa o checkout da branch.

1. Conferir se nome e avatar correspondem à conta da sessão. Se não houver
   avatar configurado, conferir o ícone genérico. Não alterar conta para testar.
2. Passar o mouse no nome: tooltip completo, sem cortar nomes longos.
3. Buscar code/kate e abrir uma aplicação; a mensagem deve continuar no rodapé.
4. Conferir que setas/Enter/Escape mantêm o fluxo anterior.
5. Enviar avaliação/captura sem obrigação de publicar dados pessoais.

Fallbacks de nome foram exercitados em lógica; Image.Error e leitor de tela
continuam sem execução nativa. Não alegar homologação desses casos por inferência.

## Depois da conferência no viewer

Para testar na instância existente, sem removê-la:

```bash
kpackagetool6 --type Plasma/Applet --upgrade "$HOME/Workspace/personal/plasma-launcher/package"
```

O Plasma pode manter uma instância já carregada em memória. Se ainda mostrar
o rodapé antigo, não remover a instância para forçar atualização: isso pode
apagar favoritos/atalho. Conferir após próximo login natural. Nenhum logout,
reinício de Plasma ou substituição do launcher original é obrigatório agora.

## Reversão

O checkpoint anterior continua na main. Fechar o viewer experimental e retornar
à main. Se tiver feito upgrade, reinstalar o pacote da main mediante procedimento
de downgrade da ferramenta local, se permitido; não apagar a instância/configuração.
A reversão no painel não foi testada nesta rodada. Por isso, iniciar pelo viewer.

Perfil não inclui ações de sessão; estas seguem como próximo incremento separado.
PR de documentação #7 é independente; este incremento parte da main funcional.
Sem merge.

## Retorno local — 05/11/2026

Revisão funcional entregue: f41edbbe821b1ae59a1c6afbdd92fcbb82c8b8a4.
A captura mostra identificação no rodapé com ícone genérico, sem sobreposição
com a grade. Após solicitação específica para conferir tooltip, busca/abertura
de Code e Kate e lint, o usuário confirmou: “sim, todos passaram pode seguire”.

Registrar PASS relatado para esses itens no viewer. A confirmação do lint é
agregada; nenhuma saída de terminal ou código de saída específico foi anexado
nesta rodada. Não inferir avatar personalizado, nome completo longo,
Image.Error ou leitor de tela a partir dessa captura.

Próximo passo autorizado: upgrade do pacote existente para avaliar no painel,
sem remover a instância. Conferir perfil, favoritos, atalho Ctrl+Shift+Enter,
busca/abertura e fechamento. Caso o Plasma mantenha o QML anterior carregado,
conferir após o próximo login natural. Nenhum merge autorizado nesta rodada.
