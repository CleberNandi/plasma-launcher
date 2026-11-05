#!/usr/bin/env python3
"""Read-only, aggregate plasmashell sampling; Python standard library only."""

import json
import os
from pathlib import Path
import statistics
import sys
import time


def parse_stat(text):
    # comm (field 2) may contain spaces and parentheses.
    tail = text[text.rindex(")") + 1:].split()
    return int(tail[11]) + int(tail[12]), int(tail[19])


def parse_rollup(text):
    values = {}
    for line in text.splitlines():
        parts = line.split()
        if parts and parts[0] in {"Rss:", "Pss:"}:
            values[parts[0][:-1]] = int(parts[1])
    return values


def snapshot(process):
    ticks, identity = parse_stat((process / "stat").read_text())
    stamp = time.monotonic()
    try:
        memory = parse_rollup((process / "smaps_rollup").read_text())
    except PermissionError:
        memory = {}
    _, identity_after = parse_stat((process / "stat").read_text())
    if identity_after != identity:
        raise RuntimeError("O processo mudou durante a leitura; coleta cancelada.")
    return {
        "clock": stamp,
        "ticks": ticks,
        "start_ticks": identity,
        "rss_kib": memory.get("Rss"),
        "pss_kib": memory.get("Pss"),
    }


def find_plasma():
    candidates = []
    for process in Path("/proc").iterdir():
        if not process.name.isdigit():
            continue
        try:
            if process.stat().st_uid == os.getuid():
                if (process / "comm").read_text().strip() == "plasmashell":
                    candidates.append(process)
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
    if len(candidates) != 1:
        raise RuntimeError(
            "Esperado exatamente um plasmashell do usuário; encontrados: "
            + str(len(candidates)) + ". Nenhuma configuração foi alterada."
        )
    return candidates[0]


def summarize(samples, first, last, hz):
    summary = {
        "intervals": len(samples),
        "elapsed_s": round(last["clock"] - first["clock"], 3),
        # 100% represents one CPU core, not all cores combined.
        "cpu_mean_pct_one_core": round(
            100 * (last["ticks"] - first["ticks"])
            / hz / (last["clock"] - first["clock"]), 3
        ),
    }
    for field in ("rss_kib", "pss_kib"):
        values = [sample[field] for sample in samples if sample[field] is not None]
        summary[field] = (
            {"min": min(values), "median": statistics.median(values), "max": max(values)}
            if values else None
        )
        summary[field + "_available_samples"] = len(values)
    return summary


def sample_phase(process, identity, seconds, hz):
    first = previous = snapshot(process)
    if first["start_ticks"] != identity:
        raise RuntimeError("plasmashell reiniciou; não comparar processos diferentes.")
    samples = []
    for _ in range(seconds):
        time.sleep(1)
        current = snapshot(process)
        if current["start_ticks"] != identity or current["ticks"] < previous["ticks"]:
            raise RuntimeError("plasmashell reiniciou; coleta cancelada.")
        samples.append(current)
        previous = current
    return {
        "summary": summarize(samples, first, previous, hz),
    }


def prompt(message):
    print(message, file=sys.stderr, flush=True)
    input()


def main():
    if not sys.stdin.isatty():
        raise RuntimeError("Execute em um terminal interativo.")
    if os.getuid() == 0:
        raise RuntimeError("Execute como usuário comum, sem sudo.")
    process = find_plasma()
    identity = snapshot(process)["start_ticks"]
    hz = os.sysconf("SC_CLK_TCK")
    print(
        "Coleta do processo inteiro plasmashell; não isola o launcher. "
        "Sem escrita de arquivos, execução de aplicativos ou mudanças de configuração.",
        file=sys.stderr,
    )
    result = {
        "schema": 1, "pid": int(process.name), "start_ticks": identity,
        "scope": "whole-plasmashell", "clock_ticks_per_second": hz, "phases": {},
    }
    prompt("1/3: feche o popup e deixe o desktop quieto. Enter inicia 5 s de coleta.")
    result["phases"]["closed_before"] = sample_phase(process, identity, 5, hz)
    prompt(
        "2/3: Enter inicia 15 s. Nesse período use Ctrl+Shift+Enter para abrir, "
        "pesquisar code/kate, limpar e fechar repetidamente. Não abra aplicativos."
    )
    result["phases"]["interaction"] = sample_phase(process, identity, 15, hz)
    prompt("3/3: feche o popup. Enter inicia 5 s de repouso e 5 s de coleta final.")
    time.sleep(5)
    result["phases"]["closed_after"] = sample_phase(process, identity, 5, hz)
    result["status"] = "complete"
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, ValueError, IndexError, EOFError) as error:
        print("Coleta não concluída: " + str(error), file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nColeta interrompida; nenhuma configuração foi alterada.", file=sys.stderr)
        sys.exit(130)
