To run the MODIS EVI example, perform the following steps:

1. Change to /home/rasdaman/examples/MOD09Q1_EVI/ directory: `cd /home/rasdaman/examples/MOD09Q1_EVI/`.
2. Before downloading MODIS images,  edit configuration parameters of the corresponding script `vi modis2rasdaman.R`. That allows you to select specific tiles and temporal ranges of images that will be downloaded.
3. Start the download and Rasdaman import process by `nohup Rscript modis2rasdaman.R &`. Depending on the number of images, this might take some time.
4. Adapt parameters of `aggregate_performance.R` and `apply_performance.R` files (e.g. #Iterations, #Servers, Array Size, etc.).
5. To start computations run Rscript decoupled from the terminal: `nohup Rscript aggregate_performance.R &` or `nohup Rscript apply_performance.R &` respectively.
6. The status can be monitored by running `tail -f aggregate_performance.log` or `tail -f apply_performance.log`.
7. Wait until the script is finished and copy result rda files to `/opt/shared/` which is mounted on the host machine: `sudo cp result* /opt/shared/`
8. Analyze results in R

