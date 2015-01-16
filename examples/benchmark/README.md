To run the performance test script perform the following steps:

1. Change to /home/rasdaman/examples/benchmark/ directory: `cd /home/rasdaman/examples/benchmark/`
2. Adapt parameters of reduce_scalability_v2.R file (e.g. #Iterations, #Servers, Array Size, etc.)
3. To start computations run Rscript decoupled from the terminal: `nohup Rscript reduce_scalability_v2.R &`
4. The status can be monitored by running `tail -f reduce_scalability_v2.log`
5. Wait until the script is finished and copy result_*.rda files to /opt/shared/ which is mounted on the host machine: `sudo cp result_* /opt/shared/`
6. Analyze results in R

