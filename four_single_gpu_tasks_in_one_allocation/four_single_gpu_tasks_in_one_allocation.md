# Deploy Four Single GPU Tasks on Single Allocation on CSCS.Daint
> Information taken from [here](https://docs.cscs.ch/running/slurm/#running-more-than-one-job-step-per-node).

The goal of this manual is to make the best use out of a nodes resources. A single node on CSCS.Daint has four gh200 GPUs. If we only need one we would essentially waist resources. Unfortunately, currently it's not supported to share the node with other jobs, so even if you only allocate a single GPU it will still block the node entirely. However, to save quota we can run four single GPU jobs in a single allocation.

> batch.sh
```{bash}
#!/usr/bin/env bash
#SBATCH --exclusive --mem=0
#SBATCH -N1
#SBATCH -t 0:30:00
#SBATCH -A u6
#SBATCH --uenv=pytorch/v2.6.0:v1 --view=default

ONE="echo Job1"
TWO="echo Job2"
THREE="echo Job3"
FOUR="echo Job4"

srun -N1 --ntasks-per-node=1 --exclusive --gpus-per-task=1 --cpus-per-gpu=5 --mem=50G --output "logs/out-%J.log"  bash -c "${ONE}" &
srun -N1 --ntasks-per-node=1 --exclusive --gpus-per-task=1 --cpus-per-gpu=5 --mem=50G --output "logs/out-%J.log"  bash -c "${TWO}" &
srun -N1 --ntasks-per-node=1 --exclusive --gpus-per-task=1 --cpus-per-gpu=5 --mem=50G --output "logs/out-%J.log"  bash -c "${THREE}" &
srun -N1 --ntasks-per-node=1 --exclusive --gpus-per-task=1 --cpus-per-gpu=5 --mem=50G --output "logs/out-%J.log"  bash -c "${FOUR}" &

wait
```
> `--mem=0` can generally be used to allocate all memory on the node but the Slurm configuration on clariden doesn’t allow this.

> `&` at the end of `srun` is deferring the the call to the background so the shell is not blocked (e.g., waiting until `srun` finishes before starting the next). The `wait` at the end will wait until all subruns finish.

The important bits here are to use `--exclusive` in the header of the file. Further, when running `srun` we need to make sure to pass `--exclusive` again otherwise the first call will reserve all available resources instead of just the ones specified, leaving the remaining calls without resources. In the example we use a pytorch uenv via `#SBATCH --uenv=pytorch/v2.6.0:v1 --view=default`. It's interesting, that this uenv will stay active in the subsequent sub calls, but activating venvs will not carry over. Venvs need to be activated within all subcalls.

We submit this script via `sbatch batch.sh`

## Helpers
We can make our lifes easier with the following helper scripts. The idea is that we define our run configurations in a single file and then automatically dispatch them all in groups of four for optimal GPU usage. We want to avoid allocating once and runing all configurations in sequential batches as this forces us to pick a high time limit which slows down queuing time. More optimally we would queue each batch of four runs as a separate `sbatch` with smaller time limits for faster queuing. The following files implement this behaviour:
- `experiment.sh` where we define our individual run definitions.
    - `experiment_setup()` is used to activate environments, create folders, etc., whatever has to be done to prepare for the subsequent run command.
    - `RUN_CMDS` is the list of all run commands (usually the python call).
    - (optional) `EXP_TIME_PER_WAVE` define the time limit that each batch will have. This can alternatively be done later too.
- `batch.sh` to automatically batch them in groups of four to allocate each batch individually for faster queuing.
- `submit_batches.sh` to allocate all experiments outlined in `experiments.sh`.

### Setup
Copy all three files where you want to schedule your experiment from and run the following command once to make the bash file executable:
```{bash}
chmod +x submit_batches.sh
```

### Usage
#### 1. Define your experiment:
```{bash}
$EDITOR experiment.sh
# set EXP_TIME_PER_WAVE="0:20:00" if you want
```
#### 2. Submit with CLI time override (highest priority):
```{bash}
./submit_batches.sh --time 0:15:00 experiment.sh
```
This ignores `EXP_TIME_PER_WAVE` and the `#SBATCH -t`.
#### 3. Or just use the experiment’s time:
```{bash}
./submit_batches.sh experiment.sh
```

#### 4. Optionally adjust wave size:
```{bash}
./submit_batches.sh --wave-size 2 experiments_bunny.sh
```