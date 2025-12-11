#!/usr/bin/env bash
#SBATCH --exclusive --mem=0
#SBATCH -N1
#SBATCH -A u6
#SBATCH --uenv=pytorch/v2.6.0:v1 --view=default
#SBATCH -t 0:30:00    # default if submit_batches.sh doesn't pass -t

########################
# Global settings
########################

LOGDIR="logs"

########################
# Script
########################

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <experiment_file.sh> <start_index> <max_runs>" >&2
    exit 1
fi

EXP_FILE="$1"
START_INDEX="$2"
MAX_RUNS="$3"

if [[ ! -f "$EXP_FILE" ]]; then
    echo "Experiment file '$EXP_FILE' not found!" >&2
    exit 1
fi

# Load RUN_CMDS (and optionally EXP_TIME_PER_WAVE, experiment_setup, etc.)
source "$EXP_FILE"

if [[ -z "${RUN_CMDS+x}" ]]; then
    echo "Experiment file did not define RUN_CMDS." >&2
    exit 1
fi

# Detect number of GPUs on the node
NUM_GPUS="${SLURM_GPUS_ON_NODE:-}"
if [[ -z "$NUM_GPUS" ]]; then
    if command -v nvidia-smi &>/dev/null; then
        NUM_GPUS=$(nvidia-smi -L | wc -l)
    else
        NUM_GPUS=4
    fi
fi

total=${#RUN_CMDS[@]}
end=$(( START_INDEX + MAX_RUNS ))
(( end > total )) && end=$total

echo "Running batch: indices [$START_INDEX, $end) on node $(hostname) with $NUM_GPUS GPUs"

# How many runs would this batch contain?
slots=$(( end - START_INDEX ))
# But we can only launch at most NUM_GPUS in parallel
if (( slots > NUM_GPUS )); then
    slots=$NUM_GPUS
fi

# Debug print (optional)
echo "Planned runs in this batch: $slots"

# Launch up to `slots` runs
for (( offset=0; offset<slots; offset++ )); do
    idx=$(( START_INDEX + offset ))
    cmd="${RUN_CMDS[$idx]}"
    echo "Launching run $idx: $cmd"

    # If you want to test *without* srun, comment the whole block
    # and leave just the echo.
    # For actual runs, use this:
    srun -N1 \
         --ntasks-per-node=1 \
         --gpus-per-task=1 \
         --cpus-per-gpu=5 \
         --mem=50G \
         --exclusive \
         --output "${LOGDIR}/out-%J-run${idx}.log" \
         bash -lc "source '$EXP_FILE'; \
                   if declare -F experiment_setup >/dev/null; then experiment_setup; fi; \
                   $cmd" &
done

# Wait for all background sruns in this batch
echo "Waiting for jobs to finish"
wait
echo "Batches [$START_INDEX, $end) finished."
