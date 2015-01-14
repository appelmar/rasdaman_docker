#!/bin/bash

# Pars: NM NT NQ 


# Pars: NM NT INDEX
query() {
	VAL=1
	i=0
	while (( VAL != 0 && i < 20000)) # approx. wait at most one hour
	do
	 #rasql --user rasadmin --passwd rasadmin -q "select (marray x in [1:$1,1:$1] values 1f)[1,1] from TestColl" --out string  &> q${3}.log
	 rasql --user rasadmin --passwd rasadmin -q "select (marray variance in [1:$1,1:$1] values condense + over y in [1:$2] using (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:$2])) * (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:$2])) / $2 f)[1,1] from TestColl" --out string  &> q${3}.log
	 VAL=$?
	 (( i+=1 ))
	 if ((VAL != 0))
	 then
		sleep 0.2
	 fi
	done  
	echo -e "Query ${3} terminated"
	exit
}

for i in `seq 1 $3`; do
   query $1 $2 $i &
done
wait
echo -e "FINISHED"



#"select (marray variance in [1:$1,1:$1] values condense + over y in [1:$2] using (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:$2])) * (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:$2])) / $2 f)[1,1] from TestColl"



