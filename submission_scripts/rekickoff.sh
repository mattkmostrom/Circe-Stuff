#!/bin/sh

for pres in 0.001 0.005 0.01 0.05 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.0 5.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0; do

	cd $pres
	cp *restart.pqr New_COF1_input.pqr
	sbatch mri.sge
	cd ../

done
