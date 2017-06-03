#!/bin/bash

 #SBATCH -J In-soc-frag1_geo 
 #SBATCH --mail-type=END 
 #SBATCH --mail-user=jessicarose@mail.usf.edu 
 #SBATCH -o runlog.log 
#SBATCH -p RM
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH --ntasks-per-node 28

module load nwchem/6.6

cp *.inp $LOCAL
cd $LOCAL

mpirun -np 28 nwchem *.inp
