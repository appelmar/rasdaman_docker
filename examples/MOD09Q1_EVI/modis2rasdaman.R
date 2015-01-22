

# PARAMETERS
VERBOSE = T
H = 12
V = 9
STARTDATE = "2006.06.01"
ENDDATE = "2006.06.10"
IMAGESIZE = c(4800,4800)
RASDAMAN_ARRAYNAME = "MOD09Q1"
RASDAMAN_ARRAYDIMS = IMAGESIZE * c(max(H)-min(H)+1,max(V)-min(V)+1)
RASDAMAN_CHUNKSIZE = c(512,512,1)


Sys.setenv(RASLOGIN = "rasadmin:d293a15562d3e70b6fdc5ee452eaed40") # rasadmin:rasadmin


HDF_SUBDATASETS = c("MOD_Grid_250m_Surface_Reflectance:sur_refl_b01",
                "MOD_Grid_250m_Surface_Reflectance:sur_refl_b02",
                "MOD_Grid_250m_Surface_Reflectance:sur_refl_qc_250m")



				
# Set default CRAN mirror
local({
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.rstudio.com/"
  options(repos = r)
})

# LOAD AND (IF NEEDED) INSTALL REQUIRED PACKAGES
if (!require(sp)) {
  install.packages("sp")
  library(sp)
}

if (!require(raster)) {
  install.packages("raster")
  library(raster)
}

if (!require(MODIS)) {
  install.packages("MODIS", repos="http://R-Forge.R-project.org")
  library(MODIS)
}


if (!require(rgdal)) {
  install.packages("rgdal")
  library(rgdal)
}

if (!require(rgeos)) {
  install.packages("rgeos")
  library(rgeos)
}

if (!require(RCurl)) {
  install.packages("RCurl")
  library(RCurl)
}


if (!require(XML)) {
  install.packages("XML")
  library(XML)
}










# DOWNLOAD MODIS FILES, this might take some time...
hdffiles = getHdf("MOD09Q1",begin=STARTDATE, end=ENDDATE, tileH=H, tileV=V )



# Create Rasdaman Array
cmd = paste("./createArray.sh", RASDAMAN_ARRAYNAME,RASDAMAN_CHUNKSIZE[1],RASDAMAN_CHUNKSIZE[2],RASDAMAN_CHUNKSIZE[3])
system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)



filenames = basename(hdffiles$MOD09Q1.005) 

# Process HDF files before loading into rasdaman
for (i in 1:length(hdffiles$MOD09Q1.005)) {
  
  # Extract tile IDs, year and day of year out of MODIS filename
  htile = as.integer(regmatches(filenames[i], regexec(pattern = ".h([[:digit:]]{2})", text = filenames[i]))[[1]][2])
  vtile = as.integer(regmatches(filenames[i], regexec(pattern = "v([[:digit:]]{2}).", text = filenames[i]))[[1]][2])
  
 
  year = as.integer(regmatches(filenames[i], regexec(pattern = ".A([[:digit:]]{4})", text = filenames[i]))[[1]][2])
  day = as.integer(regmatches(filenames[i], regexec(pattern = ".A[[:digit:]]{4}([[:digit:]]{3}).h", text = filenames[i]))[[1]][2])
  
  ## GDAL AND GDAL MERGE REQUIRED! BINARIES MUST BE IN PATH
  
  # TODO: Paralellization, unique filenames,temporary file deletion
  #-ot {Byte/Int16/UInt16/UInt32/Int32/Float32
  
       
  system(paste('gdal_translate -of GTiff -ot Int16 HDF4_EOS:EOS_GRID:\"', hdffiles$MOD09Q1.005[i] , '\":', HDF_SUBDATASETS[1] , ' temp_', 1, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
  system(paste('gdal_translate -of GTiff -ot Int16 HDF4_EOS:EOS_GRID:\"', hdffiles$MOD09Q1.005[i] , '\":', HDF_SUBDATASETS[2] , ' temp_', 2, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
  system(paste('gdal_translate -of GTiff -ot UInt16 HDF4_EOS:EOS_GRID:\"', hdffiles$MOD09Q1.005[i] , '\":', HDF_SUBDATASETS[3] , ' temp_', 3, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
  
       
       
#   for (k in 1:length(HDF_SUBDATASETS)) {
#     system(paste('gdal_translate -of GTiff HDF4_EOS:EOS_GRID:\"', hdffiles$MOD09Q1.005[i] , '\":', HDF_SUBDATASETS[k] , ' temp_', k, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
#   }
  
  
  
  
  cmd = paste('gdal_merge.py -separate ', paste0("temp_", 1:length(HDF_SUBDATASETS), ".tif", collapse=" "), ' -o temp.tif', sep="")
  system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)
  
  
  
  # Load to Rasdaman
  
  # automatically compute shift parameter
  shift = c((htile-min(H))*IMAGESIZE[1],(vtile-min(V))*IMAGESIZE[2], i) # WARNING: Assumes that files will be process in temporal order
  
  targetdims = paste(0+shift[1], ":" , IMAGESIZE[1]+shift[1]-1 , ",", 0+shift[2], ":" , IMAGESIZE[1]+shift[2]-1 , ",",  shift[3] ,sep="")
  #rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,i] assign inv_tiff($1)' --file temp.tif 
  cmd = paste("rasql --user rasadmin --passwd rasadmin -q 'update ", RASDAMAN_ARRAYNAME, " as c set c[" , targetdims, "] assign inv_tiff($1,\"sampletype=short\")' --file temp.tif", sep="")
  
cmd = paste("rasql --user rasadmin --passwd rasadmin -q 'update ", RASDAMAN_ARRAYNAME, " as c set c[" , targetdims, "] assign inv_tiff($1,\'sampletype=short\')' --file temp.tif", sep="")

system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)
  

  
}

