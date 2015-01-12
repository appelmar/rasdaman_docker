#plot(data.frame(nt=c(3,5,10,20,50), runtime=c(3.552,6.96,18.93,65.5,8*60+35)), type="o")


system("rasql --user rasadmin --passwd rasadmin -q 'drop collection TestColl'")
system("rasql --user rasadmin --passwd rasadmin -q 'create collection TestColl FloatSet3'")
system("rasql --user rasadmin --passwd rasadmin -q 'insert into TestColl values marray it in [0:0,0:0,0:0] values 0f'")

system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 1] assign marray v in [0:999, 0:999] values 1f'")
system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 2] assign marray v in [0:999, 0:999] values 2f'")
system("rasql --user rasadmin --passwd rasadmin -q  'update TestColl as c set c[0:999, 0:999, 3] assign marray v in [0:999, 0:999] values 3f'")
# TODO: More?




ITERATIONS = 3



it = c(3,5,8,10, 15, 25,50,75,100) # number of points in time
im = 250

res_it <- data.frame(it=rep(NA,length(it)), im=rep(NA,length(it)), time=(rep(NA,length(it))))
for (i in 1:length(it)) {

	ct <- 0
	for (z in 1:ITERATIONS) {
		ct <- ct + system.time(system(paste("rasql --user rasadmin --passwd rasadmin -q 'select (marray variance in [0:", im, ",0:", im, "] values condense + over y in [1:", it[i] ,"] using (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:3])) * (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", it[i], "])) / ", it[i]-1 ,"f)[1,1] from TestColl' --out string", sep=""))[3]
	}
	
	res_it[i,] = c(it[i],im, ct / ITERATIONS)
}

save(res_it, file="results_ntimes.rda")




it = 10 
im = c(10,25,50,75,100,150,200,250,400,500,650, 800, 1000, 1250, 1500, 1750, 2000, 2500, 3000) # varying image size number of points in time
res_it <- data.frame(it=rep(NA,length(im)), im=rep(NA,length(im)), time=(rep(NA,length(im))))
for (i in 1:length(im)) {

	ct <- 0
	for (z in 1:ITERATIONS) {
		ct <- ct + system.time(system(paste("rasql --user rasadmin --passwd rasadmin -q 'select (marray variance in [0:", im[i], ",0:", im[i], "] values condense + over y in [1:", it ,"] using (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:3])) * (TestColl[variance[0], variance[1], y[0]] - avg_cells(TestColl[variance[0], variance[1], 1:", it, "])) / ", it-1 ,"f)[1,1] from TestColl' --out string", sep=""))[3]
	}
	
	res_it[i,] = c(it,im[i], ct / ITERATIONS)
}

save(res_im, file="results_nimagesize.rda")




