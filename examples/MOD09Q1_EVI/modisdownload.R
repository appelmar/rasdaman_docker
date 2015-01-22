

# PARAMETERS
VERBOSE = T
H = 12
V = 9
STARTDATE = "2006.06.01"
ENDDATE = "2006.06.30"
IMAGESIZE = c(4800,4800)
RASDAMAN_ARRAYNAME = "MOD09Q1"
RASDAMAN_ARRAYDIMS = IMAGESIZE * c(max(H)-min(H)+1,max(V)-min(V)+1)
RASDAMAN_CHUNKSIZE = c(512,512,1)


Sys.setenv(RASLOGIN = "rasadmin:d293a15562d3e70b6fdc5ee452eaed40") # rasadmin:rasadmin


HDF_SUBDATASETS = c("MOD_Grid_250m_Surface_Reflectance:sur_refl_b01",
                "MOD_Grid_250m_Surface_Reflectance:sur_refl_b02",
                "MOD_Grid_250m_Surface_Reflectance:sur_refl_qc_250m")




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













# DOWNLOAD MODIS FILES, this might take some time...
hdffiles = getHdf("MOD09Q1",begin=STARTDATE, end=ENDDATE, tileH=H, tileV=V )



# Create Rasdaman Array
cmd = paste("./createArray", RASDAMAN_ARRAYNAME,RASDAMAN_CHUNKSIZE[1],RASDAMAN_CHUNKSIZE[2],RASDAMAN_CHUNKSIZE[3])
system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)



# MOD09Q1 array type definitions
system('rasdl --delmsettype "MOD09Q1_stack_set"'
rasdl --delmsettype "MOD09Q1_image_set"
rasdl --delmddtype "MOD09Q1_stack"
rasdl --delmddtype "MOD09Q1_image"
rasdl --delbasetype "MOD09Q1_pixel"
rasdl -r /home/rasdaman/examples/MOD09Q1_EVI/MOD09Q1.dl -i # Add data types for MOD09Q1 data



# Create collection for 3 bands
rasql --user rasadmin --passwd rasadmin -q "drop collection MOD09Q1" # delete if exists
rasql --user rasadmin --passwd rasadmin -q "create collection MOD09Q1 MOD09Q1_image_set" 
rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1 values marray it in [0:0,0:0] values struct {0s,0s,0us} tiling regular [0:511,0:511] index rpt_index" 






# Process HDF files before loading into rasdaman
filenames = basename(hdffiles$MOD09Q1.005) 
for (i in 1:length(hdffiles$MOD09Q1.005)) {
  
  # Extract tile IDs, year and day of year out of MODIS filename
  htile = as.integer(regmatches(filenames[i], regexec(pattern = ".h([[:digit:]]{2})", text = filenames[i]))[[1]][2])
  vtile = as.integer(regmatches(filenames[i], regexec(pattern = "v([[:digit:]]{2}).", text = filenames[i]))[[1]][2])
  
 
  year = as.integer(regmatches(filenames[i], regexec(pattern = ".A([[:digit:]]{4})", text = filenames[i]))[[1]][2])
  day = as.integer(regmatches(filenames[i], regexec(pattern = ".A[[:digit:]]{4}([[:digit:]]{3}).h", text = filenames[i]))[[1]][2])
  
  ## GDAL AND GDAL MERGE REQUIRED! BINARIES MUST BE IN PATH
  
  for (k in 1:length(HDF_SUBDATASETS)) {
    system(paste('gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"', filenames[i] , '":', HDF_SUBDATASETS[k] , ' temp_', k, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
  }
  
  cmd = paste('gdal_merge.py -separate ', cat(paste0("temp_", 1:length(HDF_SUBDATASETS), ".tif")), ' -o temp.tif', sep="")
  system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)
  
  
  
  # Load to Rasdaman
  
  # automatically compute shift parameter
  shift = c((htile-min(H))*IMAGESIZE[1],(vtile-min(V))*IMAGESIZE[2], i) # WARNING: Assumes that files wil be process in temporal order
  
  targetdims = paste(0+shift[1], ":" , IMAGESIZE[1]+shift[1]-1 , ",", 0+shift[2], ":" , IMAGESIZE[1]+shift[2]-1 , ",",  shift[3] ,sep="")
  #rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,i] assign inv_tiff($1)' --file temp.tif 
  cmd = paste("rasql -q 'update ", RASDAMAN_ARRAYNAME, "  as c set c[" , targetdims, "] assign inv_tiff($1)' --file temp.tif", sep="")
  system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)
  

  
}

