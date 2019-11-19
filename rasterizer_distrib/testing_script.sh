#!/bin/bash
# to run this script
# chmod +x testing_script.sh
# ./testing_script.sh

declare -a imgs=(
        "vec_271_01_sv.dat"
				"vec_271_01_sv_short.dat" 
				"vec_271_02_sv.dat" 
				"vec_271_02_sv_short.dat"
				"vec_271_03_sv_short.dat"
				"vec_271_04_sv.dat"
				"vec_271_04_sv_short.dat")

declare -a refs=(
        "vec_271_01_sv_ref.ppm"
				"vec_271_01_sv_short_ref.ppm" 
				"vec_271_02_sv_ref.ppm" 
				"vec_271_02_sv_short_ref.ppm"
				"vec_271_03_sv_short_ref.ppm"
				"vec_271_04_sv_ref.ppm"
				"vec_271_04_sv_short_ref.ppm")

file=~/ee271/EE-271-Rasterizer/rasterizer_distrib/output_test.txt
counter=0
for i in "${imgs[@]}"
do
  dt=$(date '+%d/%m/%Y %H:%M:%S');
  echo "$dt" >> "$file"
  echo "testing $i" >> "$file"
  start=$SECONDS
  make clean > /dev/null 2>&1
  make run RUN="+testname=$EE271_VECT/$i" > /dev/null 2>&1
  duration=$(( SECONDS - start ))
  echo "make took $duration seconds -> $( bc -l <<< $duration/60 ) minutes" >> "$file"
  if [[ $(diff verif_out.ppm $EE271_VECT/${refs[$counter]}) ]]; then
  	echo "FAIL" >> "$file"
  else
  	echo "SUCCESS" >> "$file"
  fi
  ((counter=counter+1))
done