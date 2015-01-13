



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
it = 10 
im = c(10,25,50,75,100,150,200,350,500, 750, 1000, 1250, 1500, 1750, 2000) # varying image size 
res_im_var <- data.frame(it=rep(NA,length(im)), im=rep(NA,length(im)), time=(rep(NA,length(im))))
for (i in 1:length(im)) {

	ct <- 0
	cat("USING IMAGE SIZE", im[i], "x", im[i], "AND", it, "POINTS IN TIME...")
	
	for (z in 1:ITERATIONS) {
		ct <- ct + system.time(system(paste("rasql --user rasadmin --passwd rasadmin -q 'select (marray variance in [0:", im[i], ",0:", im[i], "] values condense + over y in [1:", it ,"] using (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", it, "])) * (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", it, "])) / ", it-1 ,"f)[1,1] from TestColl' --out string", sep=""),ignore.stdout = TRUE, ignore.stderr = TRUE))[3]
	}
	cat("... TOOK ", round(ct / ITERATIONS, digits=2), "s\n")
	res_im_var[i,] = c(it,im[i], ct / ITERATIONS)
}

save(res_im_var, file="results_bysize_variance.rda")
cat("DONE.\n\n\n")



