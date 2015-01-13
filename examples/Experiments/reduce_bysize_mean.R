
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
res_im_avg <- data.frame(it=rep(NA,length(im)), im=rep(NA,length(im)), time=(rep(NA,length(im))))
for (i in 1:length(im)) {

	ct <- 0
	cat("USING IMAGE SIZE", im[i], "x", im[i], "AND", it, "POINTS IN TIME...")
	
	for (z in 1:ITERATIONS) {
		ct <- ct + system.time(system(paste("rasql -q 'select (marray prec in [ 1:", im[i] ,", 1:", im[i] ,"] values avg_cells(TestColl[prec[0], prec[1], 1:", it ,"].precipitation) )[1,1] from TestColl' --out string", sep=""),ignore.stdout = TRUE, ignore.stderr = TRUE))[3]
	}
	cat("... TOOK ", round(ct / ITERATIONS, digits=2), "s\n")
	res_im_avg[i,] = c(it,im[i], ct / ITERATIONS)
}

save(res_im_avg, file="results_bysize_mean.rda")
cat("DONE.\n\n\n")



