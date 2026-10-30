#!/usr/bin/env bash
# PoC 02E.2: executar via bash; não executar como root.
set -euo pipefail
[[ ${EUID} -ne 0 ]] || { printf '%s\n' 'Execute como usuário comum.' >&2; exit 1; }
[[ -t 0 ]] || { printf '%s\n' 'Este teste requer terminal interativo.' >&2; exit 1; }
data_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}
[[ "$data_dir" = /* ]] || { printf '%s\n' 'XDG_DATA_HOME precisa ser absoluto.' >&2; exit 1; }
apps_dir="$data_dir/applications"
[[ -d "$apps_dir" ]] || { printf '%s\n' 'Diretório applications ausente; nenhuma alteração realizada.' >&2; exit 1; }
command -v sha256sum >/dev/null
fixture=$(mktemp "$apps_dir/dev.nandi.plasmalauncher.poc02e2.XXXXXX.desktop")
expected=$(sha256sum "$fixture")
expected=${expected%% *}
owned() {
    [[ -f "$fixture" && ! -L "$fixture" ]] || return 1
    local current
    current=$(sha256sum "$fixture")
    [[ "${current%% *}" = "$expected" ]]
}
cleanup() {
    if owned; then
        rm -- "$fixture"
        printf 'Fixture removida: %s\n' "$fixture"
    elif [[ -e "$fixture" || -L "$fixture" ]]; then
        printf 'Arquivo alterado externamente; preservado: %s\n' "$fixture" >&2
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
write_fixture() {
    owned || { printf '%s\n' 'Fixture mudou externamente; operação cancelada.' >&2; exit 1; }
    cat > "$fixture" <<EOF
[Desktop Entry]
Type=Application
Name=$1
Comment=Entrada temporária para homologação do Plasma Launcher
Icon=applications-development
Exec=/usr/bin/true
Terminal=false
Categories=$2;
X-PlasmaLauncher-PoC=02E2
EOF
    expected=$(sha256sum "$fixture")
    expected=${expected%% *}
}
observe() {
    local mode note started=$SECONDS
    printf '\n%s\n' "$1"
    printf '%s\n' 'Aguarde até 60 s sem atualizar catálogo/cache.'
    printf '%s\n' 'Após refresh, volte à categoria indicada e procure a entrada no FINAL da lista.'
    printf '%s\n' 'Não basta ver o contador mudar: confirme nome/categoria/ausência da entrada.'
    printf '%s\n' 'Capture a tela com o resultado e os contadores antes de avançar.'
    printf '%s\n' 'Se não concluir em 60 s, não clique refresh: registre inconclusivo.'
    read -r -p 'Digite auto se confirmou visualmente, ou inconclusivo para encerrar: ' mode
    read -r -p 'Detalhes (conteúdo observado e contadores): ' note
    printf 'OBSERVAÇÃO: modo=%s; intervalo até resposta=%ss; %s\n' "$mode" "$((SECONDS - started))" "$note"
    if [[ "$mode" != auto ]]; then
        printf '%s\n' 'Rodada interrompida. A limpeza pode gerar outro refresh; não atribua esse evento à fase interrompida.'
        exit 0
    fi
}
printf 'Arquivo temporário: %s\n' "$fixture"
printf '%s\n' 'Mantenha a PoC aberta. Não execute nem favorite a entrada.'
write_fixture 'ZZ Plasma Launcher PoC 02E2 A' Development
observe 'FASE A: procure ZZ Plasma Launcher PoC 02E2 A em Desenvolvimento.'
write_fixture 'ZZ Plasma Launcher PoC 02E2 B' Utility
observe 'FASE B: A deve sair de Desenvolvimento; B deve aparecer em Utilitários.'
owned || { printf '%s\n' 'Fixture alterada externamente; remoção cancelada.' >&2; exit 1; }
rm -- "$fixture"
observe 'FASE C: B deve desaparecer de Utilitários.'
printf '%s\n' 'Teste concluído. Envie as três observações e os erros do visualizador.'
