#!/usr/bin/env bash

########################
# Global defaults
########################

# Runs per allocation (typically == GPUs per node)
BATCH_SIZE_DEFAULT=4

########################
# Script
########################

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [-t TIME] [--batch-size N] <experiment_file.sh>" >&2
    exit 1
fi

CLI_TIME=""          # time passed via CLI (highest precedence)
BATCH_SIZE="$BATCH_SIZE_DEFAULT"
EXP_FILE=""

# Simple arg parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t)
            if [[ $# -lt 2 ]]; then
                echo "Error: -t requires an argument of format d-hh:mm:ss or h:mm:ss" >&2
                exit 1
            fi
            CLI_TIME="$2"
            shift 2
            ;;
        --batch-size)
            if [[ $# -lt 2 ]]; then
                echo "Error: --batch-size requires an argument" >&2
                exit 1
            fi
            BATCH_SIZE="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            EXP_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$EXP_FILE" ]]; then
    echo "Missing experiment file." >&2
    exit 1
fi

if [[ ! -f "$EXP_FILE" ]]; then
    echo "Experiment file '$EXP_FILE' not found!" >&2
    exit 1
fi

# Read number of runs and experiment-specified time (if any)
readarray -t CMD_INFO < <(bash -lc "
    source '$EXP_FILE'
    echo \${#RUN_CMDS[@]}
    echo \${EXP_TIME_PER_BATCH-}
")

NUM_RUNS="${CMD_INFO[0]}"
EXP_TIME_PER_BATCH="${CMD_INFO[1]}"

echo "Found $NUM_RUNS runs in $EXP_FILE"
echo "Experiment time (if any): '${EXP_TIME_PER_BATCH}'"
echo "CLI time override: '${CLI_TIME}'"
echo "Batch size: $BATCH_SIZE"

# Determine time limit with precedence
TIME_LIMIT=""
if [[ -n "$CLI_TIME" ]]; then
    TIME_LIMIT="$CLI_TIME"
elif [[ -n "$EXP_TIME_PER_BATCH" ]]; then
    TIME_LIMIT="$EXP_TIME_PER_BATCH"
fi

start=0

while (( start < NUM_RUNS )); do
    echo "Submitting batch starting at index $start"

    if [[ -n "$TIME_LIMIT" ]]; then
        sbatch -t "$TIME_LIMIT" batch.sh "$EXP_FILE" "$start" "$BATCH_SIZE"
    else
        sbatch batch.sh "$EXP_FILE" "$start" "$BATCH_SIZE"
    fi

    start=$(( start + BATCH_SIZE ))
done
