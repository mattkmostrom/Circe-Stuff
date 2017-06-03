#!/bin/bash

######### THIS SCRIPT COMBINES THE TWO OLD SCRIPTS FOR CALCULATING AND GRAPHING RADIAL DISTRIBUTION BY DISTANCE IN ANGSTROMS.
## retrieves data from restart.pqr files, which means it's very current when run


# remove tmp files just in case
rm radial_diffs*
rm all_centers_tmp.dat
rm all_posits_tmp.dat 
rm basis_vec.tmp

# define atoms to analyze radial distribution
model="BSSP" # for filename purposes only
c_site="BBE" # compare this center site with
o_site="H2G" # this one (center of H2)

xmg_str=""

#for pres in 1.0 1.0_Cu_swap 1.0_Cu_eq; do  #0.05 0.2 0.4 1.0 5.0 10.0; do
for pres in 0.001 0.005 0.01 0.05 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.0; do 

	############ PART 1: Get positions, radial distances, and thus radial magnitudes
		
	echo "pressure: "$pres" atm"
	# grab site coordinates
	cat $pres/*.restart.pqr | grep "$c_site" > all_centers_tmp.dat
	cat $pres/*.traj.pqr | grep "$o_site" > all_posits_tmp.dat
	
	#cat all_posits_tmp.dat
	#cat all_centers_tmp.dat
	
	m=1
	num_atoms=$(cat all_centers_tmp.dat | wc -l)
	limit=$(($num_atoms + 1))

	echo "number of center sites: "$c_site": "$num_atoms
	
	# 90 degree basis lengths
	cat $pres/*.inp | grep "basis" > basis_vec.tmp
	x_basis=$(cat basis_vec.tmp | head -1 | awk {'print $2'})
	y_basis=$(cat basis_vec.tmp | head -2 | tail -1 | awk {'print $3'})
	z_basis=$(cat basis_vec.tmp | tail -1 | awk {'print $4'})
	echo "xyz basis lengths: "$x_basis,$y_basis,$z_basis

	# write all distance differences from CuC center site xyz to H2 xyz
	while [ "$m" -lt "$limit" ]; do
		cx=$(cat all_centers_tmp.dat | head -$m | tail -1 | awk {'print $7'})
		cy=$(cat all_centers_tmp.dat | head -$m | tail -1 | awk {'print $8'})
		cz=$(cat all_centers_tmp.dat | head -$m | tail -1 | awk {'print $9'})
		echo "center "$m": "$cx $cy $cz
		
		cat all_posits_tmp.dat | awk '{printf("%10lf %10lf %10lf\n",'$cx'-$7,'$cy'-$8,'$cz'-$9)}' >> radial_diffs_xyz_tmp.dat
		
		#echo $x
		let m=$m+1
	done

	#cat radial_diffs_xyz_tmp.dat
	echo "done catting XYZ differences -- radial_diffs_xyz_tmp.dat";
	
	hbx=$(echo $x_basis*0.5 | bc)
	hby=$(echo $y_basis*0.5 | bc)
	hbz=$(echo $z_basis*0.5 | bc)
	
	echo "basis:" $x_basis $y_basis $z_basis
	echo "half basis: " $hbx $hby $hbz

	# remove negatives (just magnitudes) of xyz distances
	cat radial_diffs_xyz_tmp.dat | sed 's/-//g' > radial_diffs_xyz_tmp_positives.dat
	
	# reduce distances to half of basis dim. as a max.
	cat radial_diffs_xyz_tmp_positives.dat | awk '{
		if ($1 > '$hbx') 
		{
			printf("%10lf ",'$x_basis'-$1);
		}
		else {
			printf("%10lf ",$1);
		}
		 

		if ($2 > '$hby') 
		{
			printf("%10lf ",'$y_basis'-$2);
		}
		else {
			printf("%10lf ",$2);
		
		}

		if ($3 > '$hbz') 
		{
			printf("%10lf\n",'$z_basis'-$3);
		}
		else {
			printf("%10lf\n",$3);
		}
	}' >> radial_diffs_tmp_wrapped_half.dat
	
	#cat radial_diffs_tmp_wrapped_half.dat
	echo 'done catting radial half XYZs';
	
	# get magnitudes from xyz distances... r = (x^2 + y^2 + z^2)^(1/2)
	rm $pres/final_radial_diffs*
	cat radial_diffs_tmp_wrapped_half.dat | awk {'printf("%10lf\n",($1*$1+$2*$2+$3*$3)**(0.5))'} >> $pres/final_radial_diffs_$pres.dat
	

	#cat final_radial_diffs.dat
	echo 'done catting radial mags';
	
	#remove temp files
	rm radial_diffs*
	rm all_centers_tmp.dat
	rm all_posits_tmp.dat 
	rm basis_vec.tmp

	############### PART 2: MAKE GRAPH from magnitudes (get radial bins)
	
	#sort the radial magnitudes
	sort -nk1 $pres/final_radial* > $pres/tmp_sorted_radials.dat
	
	# insert 0 0 point on the bins file
	echo '0 0' > $pres/radial_hist.dat
	
	# bin 'em
	binsize=0.1
	cat $pres/tmp_sorted_radials.dat | awk 'BEGIN {c=0;binsize='$binsize';bincount=binsize} {
							
									while ($1 >= bincount)
									{
										print bincount,c
										c=0
										bincount=bincount+binsize
									}
									if ($1 < bincount)
									{
										c=c+1
									}
								} END {print bincount,c}' >> $pres/radial_hist.dat
	
	
	# normalize: molecules (e.g. H2) in each slice per unit volume
	cat $pres/radial_hist.dat | awk {'printf("%lf %lf \n",$1,($2 / (((4.0/3.0)*3.14159265359*($1)**3) -((4.0/3.0)*3.14159265359*($1-'$binsize')**3))))'} > $pres/tmp.tmp
	mv $pres/tmp.tmp $pres/radial_hist.dat

	
	# normalize: scale bin sizes to 1 total								
	cat $pres/radial_hist.dat | awk 'BEGIN {sum=0;} { sum += $2; } END {print sum}' > sumd.tmp
	read sum < sumd.tmp; echo "sum: "$sum
	cat $pres/radial_hist.dat | awk {'printf("%lf %lf \n",$1,$2 / '$sum')'} > $pres/tmp.tmp
	mv $pres/tmp.tmp $pres/radial_hist.dat

	# normalize offset points to "mid-range"
	cat $pres/radial_hist.dat | awk {'printf("%lf %lf \n",($1 - ('$binsize' / 2.0)),$2)'} > $pres/tmp.tmp
	mv $pres/tmp.tmp $pres/radial_hist.dat

	#remove leftover tmp files
	rm sumd.tmp;
	rm $pres/tmp_sorted_radials.dat


	#echo "xmgrace "$pres"/radial_hist.dat"; #xmgrace $pres/radial_hist.dat
	xmg_str=$xmg_str" "$pres"/radial_hist.dat"

done

#cp rad_dist.par t.par
#date=$(date);
#filedate=$(date +%Y-%m-%d);
#sed -i -- 's/As of 7-21-2015/As of '"$date"'/g' t.par
#sed -i -- 's/CuC/'"$c_site"'/g' t.par

echo "xmgrace string: "$xmg_str

# save graph to a PNG
xmgrace -autoscale none -par t.par -hdevice PNG -hardcopy -printfile rad_dists_$model.$c_site.$filedate.png $xmg_str

# view graph
xmgrace -autoscale none $xmg_str
