#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Execute como usuário comum.' >&2; exit 2; }
for tool in plasmawindowed jq flock sha256sum mktemp; do
    command -v "$tool" >/dev/null || { echo "Ausente: $tool (não instalado automaticamente)" >&2; exit 2; }
done
: "${XDG_RUNTIME_DIR:?Execute dentro da sessão KDE do usuário}"
[[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]] || { echo 'Sessão gráfica ausente.' >&2; exit 2; }
exec 9>"$XDG_RUNTIME_DIR/plasma-launcher-catalog-test.lock"
flock -n 9 || { echo 'Outro diagnóstico está em execução.' >&2; exit 2; }
base=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
[[ "$apps" = /* && -d "$apps" ]] || { echo 'applications ausente ou não absoluto.' >&2; exit 2; }
report=$(mktemp -d "${TMPDIR:-/tmp}/plasma-launcher-report.XXXXXX")
chmod 700 "$report"
echo "RELATÓRIO: $report"
fixture=''
expected=''
viewer=''
cleanup() {
    local rc=$?
    trap - EXIT
    if [[ -n "$fixture" && -f "$fixture" && ! -L "$fixture" ]]; then
        local hash
        hash=$(sha256sum "$fixture"); hash=${hash%% *}
        if [[ "$hash" = "$expected" ]]; then
            rm -- "$fixture"
        else
            echo "Fixture externa preservada: $fixture" >> "$report/result.txt"
        fi
    fi
    if [[ -n "$viewer" ]]; then
        kill "$viewer" 2>/dev/null || true
        wait "$viewer" 2>/dev/null || true
    fi
    echo "EXIT=$rc" >> "$report/result.txt"
    echo "Relatório preservado: $report"
    exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
git -C "$base" rev-parse HEAD > "$report/commit.txt" 2>/dev/null || true
plasmawindowed --version > "$report/version.txt" 2>&1 || true
plasmawindowed "$base/../catalog-probe/package" > "$report/viewer.log" 2>&1 &
viewer=$!
latest() {
    sed -n 's/^.*CATALOG_PROBE //p' "$report/viewer.log" | tail -n 1
}
wait_state() {
    local phase=$1 predicate=$2 deadline=$((SECONDS + 90)) consecutive=0 last='' state=''
    echo "FASE $phase" | tee -a "$report/result.txt"
    while (( SECONDS < deadline )); do
        kill -0 "$viewer" 2>/dev/null || { echo 'Viewer encerrou.' >> "$report/result.txt"; return 1; }
        state=$(latest)
        if [[ -n "$state" && "$state" != "$last" ]]; then
            last=$state
            if jq -e "$predicate" <<< "$state" >/dev/null 2>&1; then
                consecutive=$((consecutive + 1))
            else
                consecutive=0
            fi
            if (( consecutive >= 3 )); then
                echo "$state" > "$report/$phase.json"
                echo "PASS $phase" | tee -a "$report/result.txt"
                return 0
            fi
        fi
        sleep 1
    done
    echo "TIMEOUT $phase: conteúdo esperado não observado em 90s" | tee -a "$report/result.txt"
    return 1
}
wait_state baseline '.complete and (.a|length)==0 and (.b|length)==0'
fixture=$(mktemp "$apps/dev.nandi.plasmalauncher.auto.XXXXXX.desktop")
expected=$(sha256sum "$fixture"); expected=${expected%% *}
echo "$fixture" > "$report/fixture-path.txt"
write_entry() {
    local hash stage
    hash=$(sha256sum "$fixture"); hash=${hash%% *}
    [[ ! -L "$fixture" && "$hash" = "$expected" ]] || { echo 'Fixture alterada externamente.' >&2; return 1; }
    stage=$(mktemp "$report/entry.XXXXXX")
    printf '[Desktop Entry]\nType=Application\nName=ZZ Plasma Launcher Auto %s\nIcon=applications-development\nExec=/usr/bin/true\nTerminal=false\nCategories=%s;\n' "$1" "$2" > "$stage"
    # Publicação atômica no mesmo filesystem; arquivo intermediário oculto.
    local adjacent
    adjacent=$(mktemp "$apps/.plasma-launcher-stage.XXXXXX")
    if ! cp -- "$stage" "$adjacent" || ! mv -- "$adjacent" "$fixture"; then
        rm -f -- "$adjacent"
        return 1
    fi
    expected=$(sha256sum "$fixture"); expected=${expected%% *}
}
write_entry A Development
wait_state inclusion '.complete and (.a|length)==1 and (.b|length)==0'
category_a=$(jq -r '.a[0]' "$report/inclusion.json")
write_entry B Utility
wait_state migration ".complete and (.a|length)==0 and (.b|length)==1 and .b[0] != $(jq -Rn --arg c "$category_a" '$c')"
hash=$(sha256sum "$fixture"); hash=${hash%% *}
[[ ! -L "$fixture" && "$hash" = "$expected" ]] || exit 1
rm -- "$fixture"
fixture=''
wait_state removal '.complete and (.a|length)==0 and (.b|length)==0'
echo 'PASS: inclusão, mudança de nome/categoria e remoção no modelo nativo.' | tee -a "$report/result.txt"
