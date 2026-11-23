cd "/c/Users/aljou/OneDrive/Desktop/full das"
DS=${1:-17}
for n in ${CASES:-base slope5 slope15 road100 road500 water25 water100 inside500}; do
  SENS_NAME=$n SENS_DSTAR=$DS matlab -batch "cd('C:/Users/aljou/OneDrive/Desktop/full das/scripts'); siting_sens_run" > results/tmp_sens_$n.log 2>&1
done
echo alldone > results/tmp_sens_done.txt
