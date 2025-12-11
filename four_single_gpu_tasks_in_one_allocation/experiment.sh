#!/usr/bin/env bash

########################
# Global experiment config
########################

# Optional: suggested time limit *per batch* (one allocation),
# used if no CLI --time/-t is provided.
EXP_TIME_PER_BATCH="0:20:00"

# Per-run setup: executed inside each srun shell
experiment_setup() {
    # Activate your environment, set variables, etc.
    source "$SCRATCH/.venv/bin/activate"
    wandb disabled
}

# Shared arguments
baseArgs=(
    # --volume_grid "./resources/vdb/bunny_cloud.npy"
    # --output "./test_script_output/bunny/"
    --opt_spp 1
    --grad_spp 1
    --ref_spp 32
    --cam_count 32
    --cam_res_x 512
    --cam_res_y 512
    --init_opacity 1e-3
    --init_scale 2e-2
    --sigmat_scale 10.0
    --iterations_gaussian 256
    --iterations_gabor 200
    --gauss_count 100
    --gabor_count 100
    --start_pruning_from 99999
    --densify_every 100
    --densify_until -1
    --densify_count 100
    --importance_sample_means
    --sample_single_hemisphere
    --global_lr_gabor 4.0
    --global_lr_gaussian 1.0
    --centers_lr 0.003
    --scales_lr 0.0002
    --quats_lr 0.0003
    --opacity_lr 0.00002
    --omega_lr 0.001
    --regen_pyramid
)

########################
# Run definitions
########################

RUN_CMDS=()

RUN_CMDS+=("python scripts/gabor_volume_regression.py ${baseArgs[*]} --volume_grid ./resources/vdb/bunny_cloud.npy --output ./test_script_output/bunny1/")
RUN_CMDS+=("python scripts/gabor_volume_regression.py ${baseArgs[*]} --volume_grid ./resources/vdb/bunny_cloud.npy --output ./test_script_output/bunny2/")
RUN_CMDS+=("python scripts/gabor_volume_regression.py ${baseArgs[*]} --volume_grid ./resources/smoke.npy --output ./test_script_output/smoke1/")
RUN_CMDS+=("python scripts/gabor_volume_regression.py ${baseArgs[*]} --volume_grid ./resources/smoke.npy --output ./test_script_output/smoke2/")
