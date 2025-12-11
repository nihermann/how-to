#!/usr/bin/env bash

########################
# Global experiment config
########################

# Optional: suggested time limit per batch (one allocation),
# used if no CLI -t is provided. Use format "d-hh:mm:ss" or "h:mm:ss"
EXP_TIME_PER_BATCH="0:20:00"

# Per-run setup: executed inside each srun shell
experiment_setup() {
    # Activate your environment, set variables, etc.
    source "$SCRATCH/.venv/bin/activate"
    wandb disabled
}

# Shared arguments
baseArgs=(
    --opt_spp 1
    --grad_spp 1
    --ref_spp 32
    --cam_count 32
    --cam_res_x 512
    --cam_res_y 512
    --init_opacity 1e-3
    --init_scale 2e-2
    --centers_lr 0.003
    --scales_lr 0.0002
    --quats_lr 0.0003
    --opacity_lr 0.00002
    --omega_lr 0.001
)

########################
# Run definitions
########################

RUN_CMDS=()

RUN_CMDS+=("python scripts/volume_regression.py ${baseArgs[*]} --volume_grid ./resources/vdb/bunny_cloud.npy --output ./test_script_output/bunny1/")
RUN_CMDS+=("python scripts/volume_regression.py ${baseArgs[*]} --volume_grid ./resources/vdb/bunny_cloud.npy --output ./test_script_output/bunny2/")
RUN_CMDS+=("python scripts/volume_regression.py ${baseArgs[*]} --volume_grid ./resources/smoke.npy --output ./test_script_output/smoke1/")
RUN_CMDS+=("python scripts/volume_regression.py ${baseArgs[*]} --volume_grid ./resources/smoke.npy --output ./test_script_output/smoke2/")
