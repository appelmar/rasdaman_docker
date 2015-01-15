
ITERATIONS = 3 #5
NQUERYMAX = 10 #10 <= NSERVER
NT = 100   # 30
NM = 100 # 500
NSERVER= 10
VERBOSE=T


#rasql --user rasadmin --passwd rasadmin -q "select (marray x in [1:5,1:5] values 1f)[1,1] from TestColl" --out string 

Sys.setenv(RASLOGIN = "rasadmin:d293a15562d3e70b6fdc5ee452eaed40") # rasadmin:rasadmin

cat("STARTING PERFORMANCE TEST INITIALIZATION\n")
system("rasql --user rasadmin --passwd rasadmin -q 'drop collection TestColl'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rasql --user rasadmin --passwd rasadmin -q 'create collection TestColl FloatSet3'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rasql --user rasadmin --passwd rasadmin -q 'insert into TestColl values marray it in [0:0,0:0,0:0] values 0f'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)

system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 1] assign marray v in [0:999, 0:999] values 1f'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 2] assign marray v in [0:999, 0:999] values 2f'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 3] assign marray v in [0:999, 0:999] values 3f'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)


# Kill running default servers # down srv -all -kill does not work sometimes
system("rascontrol -q -x down srv N1 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N2 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N3 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N4 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N5 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N6 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N7 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N8 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x down srv N9 -kill",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
Sys.sleep(3)


for (i in 1:NSERVER) {
	# using tile cache leads to segfault errors -> set to 0 (default)
	# Beware of already open ports of other services (e.g Tomcat!)
	system(paste("rascontrol -q -x define srv TEST", i ," -host rasdaman-dev1 -type n -port ", 9001 + i , " -dbh rasdaman_host", sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE) # 64 MB default cache size
	system(paste("rascontrol -q -x change srv TEST", i ," -countdown 200 -autorestart on", sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE) # 64 MB default cache size
	Sys.sleep(0.5)
}
Sys.sleep(2)
cat("DONE.\n")
#system("rascontrol -q -x list srv -all")


for (i in 1:NSERVER) {
	system(paste("rascontrol -q -x up srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE) 
	Sys.sleep(0.5)
}



	
	
cat("STARTING SCALABILITY TEST \n")

result <- data.frame(NT=rep(NA,NQUERYMAX), NM=rep(NM,NQUERYMAX), NSERVER=rep(NSERVER,NQUERYMAX), NQUERIES=1:NQUERYMAX, RUNTIME=rep(NA,NQUERYMAX))
for (i in 1:NQUERYMAX) {
	nt <- ceiling(NT / i)
	ct <- 0
	cat("USING IMAGE SIZE", NM, "x", NM, "- POINTS IN TIME", nt, "- NQUERIES", i, "- RUNNING SERVERS", NSERVER)
	for (z in 1:ITERATIONS) {
		#ct <- ct + system.time(system(paste("parallel rasql --user rasadmin --passwd rasadmin -q 'select (marray variance in [1:", NM, ",1:", NM, "] values condense + over y in [1:", NT ,"] using (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", NT, "])) * (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", NT, "])) / ", NT-1 ,"f)[1,1] from TestColl' --out string ::: {1..", NQUERIES, "}", sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE))[3]
		ct <- ct + system.time(system(paste("./run_v2.sh", NM, nt, i),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE))[3]
		Sys.sleep(0.5)
		cat(".")
	}
	cat(" TOOK ", round(ct / ITERATIONS, digits=2), "s\n")
	result[i,"RUNTIME"] = ct / ITERATIONS
	result[i,"NT"] = nt
}

save(result, file="result.rda")









cat("Cleaning up...")

# Clean up


for (i in 1:NSERVER) {
    system(paste("rascontrol -q -x down srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
	Sys.sleep(0.5)
	system(paste("rascontrol -q -x remove srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
}


# Start default servers
system("rascontrol -q -x up srv N1",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N2",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N3",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N4",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N5",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N6",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N7",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N8",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rascontrol -q -x up srv N9",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)




cat("\nDONE.\n\n\n")







