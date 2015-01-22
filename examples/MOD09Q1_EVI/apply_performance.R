
sink("apply_performance.log")

RASDAMAN_ARRAYNAME = "MOD09Q1"

ITERATIONS = 1 #5
NSERVER = 12
NT = 1  
NM = c(100,1000,4800)
VERBOSE=T

## Pars for server test:
# ITERATIONS = 5
# NSERVER = 12
# NT = 1  # or more?
# NM = c(100,250,500,1000,1500,2000,2500,3000,4000,4800)
# VERBOSE=T



starttime = Sys.time()

#rasql --user rasadmin --passwd rasadmin -q "select (marray x in [1:5,1:5] values 1f)[1,1] from TestColl" --out string 

Sys.setenv(RASLOGIN = "rasadmin:d293a15562d3e70b6fdc5ee452eaed40") # rasadmin:rasadmin

cat("STARTING PERFORMANCE TEST INITIALIZATION\n")


# Kill running default servers # down srv -all -kill does not work sometimes






install_servers <- function() {
	for (i in 1:NSERVER) {
		# using tile cache leads to segfault errors -> set to 0 (default)
		# Beware of already open ports of other services (e.g Tomcat!)
		system(paste("rascontrol -q -x define srv TEST", i ," -host rasdaman-dev1 -type n -port ", 9001 + i , " -dbh rasdaman_host", sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE) # 64 MB default cache size
		system(paste("rascontrol -q -x change srv TEST", i ," -countdown 200 -autorestart on", sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE) # 64 MB default cache size
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}

remove_servers <- function() {
	for (i in 1:NSERVER) {
		system(paste("rascontrol -q -x remove srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}

start_servers <- function() {
	for (i in 1:NSERVER) {
		system(paste("rascontrol -q -x up srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}


stop_servers <- function() {
	for (i in 1:NSERVER) {
		system(paste("rascontrol -q -x down srv TEST", i , sep=""),ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE)
		Sys.sleep(0.5)
	}
	Sys.sleep(2)
}

restart_servers <- function() {
	stop_servers()
	start_servers()
}


cat("DONE.\n")
#system("rascontrol -q -x list srv -all")

install_servers()
start_servers()



	
	
cat("STARTING RASDAMAN PERFORMANCE TEST FOR EVI APPLY OPERATION \n")
# CONSTANT TOTAL WORKLOAD
result <- data.frame(NT=rep(NT,length(NM)), NSERVER=rep(NSERVER,length(NM)), NM=NM, RUNTIME=rep(NA,length(NM)))
for (i in 1:length(NM)]) {
	ct <- 0
	cat("USING IMAGE SIZE", NM[i], "x", NM, "- POINTS IN TIME", NM, , NSERVER , " RUNNING SERVERS ")
	for (z in 1:ITERATIONS) {
		targetdims = paste(0, ":" , NM[i] , ",", 0, ":" , NM[i] , ",",  NT ,sep="")
		cmd = paste("rasql -q 'select (marray evi2 in [", targetdims, "] values (float)(2.5f * (img[", targetdims ,"].nir - img[", targetdims ,"].red) / (1f+2.4f*img[", targetdims ,"].red +img[", targetdims ,"].nir)))[1,1,1]  from", RASDAMAN_ARRAYNAME ," as img' --out string  &> rasql.log" , sep="") 
		ct <- ct + system.time(cmd,ignore.stdout = !VERBOSE, ignore.stderr = !VERBOSE))[3]
		cat(".")
	}
	cat(" TOOK ", round(ct / ITERATIONS, digits=2), "s\n")
	result[i,"RUNTIME"] = ct / ITERATIONS
	restart_servers() # Otherwise, memory consumption of single rasserver process may become problematic
}
save(result, file=paste("result_",as.character(Sys.info()["nodename"]), "_", format(starttime,format="%Y-%m-%d-%H-%M-%S"),".rda" ,sep=""))





cat("Cleaning up...")

# Clean up


stop_servers()
remove_servers()

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







