
sink("scalability.log")

VERBOSE=T
ITERATIONS = 3
NINSTANCEMAX = 6


## Pars for server test:
#ITERATIONS = 5 #
#NINSTANCEMAX = 32

NT=100
NM = 4800

TILING = c(100,100,10)


starttime = Sys.time()

Sys.setenv(RASLOGIN = "rasadmin:d293a15562d3e70b6fdc5ee452eaed40") # rasadmin:rasadmin

cat("STARTING PERFORMANCE TEST INITIALIZATION\n")


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





install_servers <- function() {
	for (i in 1:NINSTANCEMAX) {
		# using tile cache leads to segfault errors -> set to 0 (default)
		# Beware of already open ports of other services (e.g Tomcat!)
		system(paste("rascontrol -q -x define srv TEST", i ," -host rasdaman-dev1 -type n -port ", 9001 + i , " -dbh rasdaman_host", sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE) # 64 MB default cache size
		system(paste("rascontrol -q -x change srv TEST", i ," -countdown 200 -autorestart on", sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE) # 64 MB default cache size
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}

remove_servers <- function() {
	for (i in 1:NINSTANCEMAX) {
		system(paste("rascontrol -q -x remove srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}

start_servers <- function(n) {
	if (missing(n)) n <- NINSTANCEMAX
	for (i in 1:n) {
		system(paste("rascontrol -q -x up srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}


stop_servers <- function() {
	for (i in 1:NINSTANCEMAX) {
		system(paste("rascontrol -q -x down srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}

restart_servers <- function(n) {
	stop_servers()
	start_servers(n)
}



install_servers()
start_servers()
#system("rascontrol -q -x list srv -all")









cat("DONE.\n")

cat("ADDING DATA\n")
# Add data
system("rasql --user rasadmin --passwd rasadmin -q 'drop collection TestColl'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rasql --user rasadmin --passwd rasadmin -q 'create collection TestColl FloatSet3'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
system("rasql --user rasadmin --passwd rasadmin -q 'insert into TestColl values marray it in [0:0,0:0,0:0] values 0f'",ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
cmd =  paste("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[1:", NM ,",1:", NM, ",1:", NT, "] assign marray v in [1:", NM ,",1:", NM, ",1:", NT, "] values 1f'",sep="")
system(cmd,ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)

cat("DONE.\n")
cat("STARTING SCALABILITY TEST\n")

result <- data.frame(NT=rep(NT,NINSTANCEMAX), NM=rep(NM,NINSTANCEMAX), NINSTANCE=1:NINSTANCEMAX, RUNTIME_AGGREG2D=rep(NA,NINSTANCEMAX),RUNTIME_APPLY=rep(NA,NINSTANCEMAX),RUNTIME_AGGREG3D=rep(NA,NINSTANCEMAX))
for (i in 1:NINSTANCEMAX) {
	ct_aggreg3d <- 0
	ct_aggreg2d <- 0
	ct_apply <- 0
	cat("USING IMAGE SIZE", NM, "x", NM, "- POINTS IN TIME ", NT, "- NINSTANCES", i)
	
	## ADD SERVER
	restart_servers(i)
	Sys.sleep(2)
	
	
	for (z in 1:ITERATIONS) {
		cmd = paste("rasql -q 'select (marray prec in [ 1:", NM ,",1:", NM ,"] values avg_cells(TestColl[prec[0], prec[1], 1:", NT ,"])) from TestColl' --out none", sep="")
		ct_aggreg2d <- ct_aggreg2d + system.time(system(cmd,ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE))[3]
		
		cmd = paste("rasql -q 'select max_cells(TestColl[prec[0], prec[1], 1:", NT ,"]) from TestColl' --out none" , sep="" )
		ct_aggreg3d <- ct_aggreg3d + system.time(system(cmd,ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE))[3]
		
		cmd = paste("rasql -q 'select (2.5f * TestColl[ 1:", NM ,",1:", NM ,",1:", NT, "]) from TestColl' --out none" , sep="" )
		ct_apply <- ct_apply + system.time(system(cmd,ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE))[3]
		
		Sys.sleep(0.5)
		cat(".")
	}
	cat(" TOOK ", round(ct_aggreg2d / ITERATIONS, digits=2), "s - ", round(ct_aggreg3d / ITERATIONS, digits=2), "s - ", round(ct_apply / ITERATIONS, digits=2), "s\n")
	result[i,"RUNTIME_AGGREG2D"] = ct_aggreg2d / ITERATIONS
	result[i,"RUNTIME_AGGREG3D"] = ct_aggreg3d / ITERATIONS
	result[i,"RUNTIME_APPLY"] = ct_apply / ITERATIONS
}
save(result, file=paste("result_",as.character(Sys.info()["nodename"]), "_", format(starttime,format="%Y-%m-%d-%H-%M-%S"),".rda" ,sep=""))




stop_servers()
remove_servers()
# RESTORE DEFAULT CONF


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








