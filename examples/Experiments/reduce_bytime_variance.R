



cat("STARTING PERFORMANCE TEST INITIALIZATION\n")
system("rasql --user rasadmin --passwd rasadmin -q 'drop collection TestColl'",ignore.stdout = TRUE, ignore.stderr = TRUE)
system("rasql --user rasadmin --passwd rasadmin -q 'create collection TestColl FloatSet3'",ignore.stdout = TRUE, ignore.stderr = TRUE)
system("rasql --user rasadmin --passwd rasadmin -q 'insert into TestColl values marray it in [0:0,0:0,0:0] values 0f'",ignore.stdout = TRUE, ignore.stderr = TRUE)

system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 1] assign marray v in [0:999, 0:999] values 1f'",ignore.stdout = TRUE, ignore.stderr = TRUE)
system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 2] assign marray v in [0:999, 0:999] values 2f'",ignore.stdout = TRUE, ignore.stderr = TRUE)
system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 3] assign marray v in [0:999, 0:999] values 3f'",ignore.stdout = TRUE, ignore.stderr = TRUE)
# TODO: More?
cat("DONE.\n")


ITERATIONS = 3

cat("STARTING PERFORMANCE TEST WITH INCREASING NUMBER OF POINTS IN TIME\n")
it = c(3,5,8,10, 15, 25,50,75,100) # number of points in time
im = 250
res_it_var <- data.frame(it=rep(NA,length(it)), im=rep(NA,length(it)), time=rep(NA,length(it)))
for (i in 1:length(it)) {

	ct <- 0
	cat("USING IMAGE SIZE", im, "x", im, "AND", it[i], "POINTS IN TIME...")
	for (z in 1:ITERATIONS) {
		ct <- ct + system.time(system(paste("rasql --user rasadmin --passwd rasadmin -q 'select (marray variance in [0:", im, ",0:", im, "] values condense + over y in [1:", it[i] ,"] using (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", it[i], "])) * (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", it[i], "])) / ", it[i]-1 ,"f)[1,1] from TestColl' --out string", sep=""),ignore.stdout = TRUE, ignore.stderr = TRUE))[3]
	}
	cat("... TOOK ", round(ct / ITERATIONS, digits=2), "s\n")
	res_it_var[i,] = c(it[i],im, ct / ITERATIONS)
}

save(res_it_var, file="results_bytime_variance.rda")
cat("DONE.\n\n\n")




