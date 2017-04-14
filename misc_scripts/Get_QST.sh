#!/bin/sh
for model in "buch" "bss" "bssp"; do
cd $model
rm QST_$model.dat
rm tmp*
for pres in 0.001 0.005 0.01 0.05 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.0 5.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0; do

    cat ./$pres/runlog.log | grep "wt % (ME) =" >> tmp1
    cat tmp1 | awk 'END{print ($6*10)/2.016}' >> tmp1.dat
    echo $pres
done

for pres in 0.001 0.005 0.01 0.05 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.0 5.0 10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0; do

    cat ./$pres/runlog.log | grep "qst =" >> tmp2
    cat tmp2 | awk 'END{print $4}' >> tmp2.dat
    echo $pres
done

paste -d " " tmp1.dat tmp2.dat >> QST_$model.dat
cp QST_$model.dat ..
cd ..
done



rm tmp1
rm tmp2
rm tmp1.dat 
rm tmp2.dat
module load apps/grace/5.1.22

for n in "QST_buch.dat" "QST_bss.dat" "QST_bssp.dat"; do
xmgrace $n
done
