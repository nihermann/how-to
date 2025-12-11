# Deploy on CSCS.Daint
> Information taken from [here](https://docs.cscs.ch/running/slurm/#running-more-than-one-job-step-per-node).

The goal of this manual is to make the best use out of a nodes resources. A single node on CSCS.Daint has four gh200 GPUs. If we only need one we would essentially waist resources. Unfortunately, currently it's not supported to share the node with other jobs, so even if you only allocate a single GPU it will still block the node entirely. However, to save quota we can run four single GPU jobs in a single allocation.

> batch.sh
```{shell}
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