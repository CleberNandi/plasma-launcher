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
    local note
    printf '\n%s\n' "$1"
    printf '%s\n' 'Observe por cerca de 10 s SEM atualizar catálogo/cache.'
    printf '%s\n' 'Anote: apareceu/mudou/sumiu, refreshed e resets.'
    printf '%s\n' 'Se falhar: clique Atualizar catálogo e registre separadamente.'
    printf '%s\n' 'Se ainda falhar, não reconstrua cache agora: relate o resultado.'
    read -r -p 'Digite sua observação e Enter para avançar: ' note
    printf 'OBSERVAÇÃO: %s\n' "$note"
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
