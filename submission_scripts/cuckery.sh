#!/bin/bash

#SBATCH --mem-per-cpu=4G
 #SBATCH -N 2 
 #SBATCH -n 16 
 #SBATCH -J In-soc-frag1_geo 
 #SBATCH -t 48:00:00 
 #SBATCH --partition=circe 
 #SBATCH --qos=mri16 
 #SBATCH --mail-type=END 
 #SBATCH --mail-user=jessicarose@mail.usf.edu 
 #SBATCH -o runlog.log 

module purge
module load apps/nwchem/6.1.1

mpirun -np 16 nwchem *.inp


