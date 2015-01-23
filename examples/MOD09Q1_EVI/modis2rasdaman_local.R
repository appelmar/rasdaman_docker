

# PARAMETERS
VERBOSE = T
LOCAL_ARCHIVE = "/home/marius/rasdamanSciDB/modisdata/"
IMAGESIZE = c(4800,4800)
RASDAMAN_ARRAYNAME = "MOD09Q1"
RASDAMAN_CHUNKSIZE = c(512,512,1)

HDF_SUBDATASETS = c("MOD_Grid_250m_Surface_Reflectance:sur_refl_b01",
                "MOD_Grid_250m_Surface_Reflectance:sur_refl_b02",
                "MOD_Grid_250m_Surface_Reflectance:sur_refl_qc_250m")


Sys.setenv(RASLOGIN = "rasadmin:d293a15562d3e70b6fdc5ee452eaed40") # rasadmin:rasadmin



# Look what files exist

hdffiles <- paste(LOCAL_ARCHIVE, list.files(path = LOCAL_ARCHIVE, pattern=".hdf$"), sep="")
filenames = basename(hdffiles) 

# Extract information out of tile's filnames
HH = as.integer(sapply(regmatches(filenames, regexec(pattern = ".h([[:digit:]]{2})", text = filenames)), function(v) {return (v[2])}))
VV = as.integer(sapply(regmatches(filenames, regexec(pattern = "v([[:digit:]]{2}).", text = filenames)), function(v) {return (v[2])}))
YYYY = as.integer(sapply(regmatches(filenames, regexec(pattern = ".A([[:digit:]]{4})", text = filenames)), function(v) {return (v[2])}))
DD = as.integer(sapply(regmatches(filenames, regexec(pattern = ".A[[:digit:]]{4}([[:digit:]]{3}).h", text = filenames)), function(v) {return (v[2])}))

modisdata = data.frame(hdffiles, HH, VV, YYYY, DD)
modisdata = modisdata[ order(YYYY, DD), ]# Order by time



RASDAMAN_ARRAYDIMS = IMAGESIZE * c(max(HH)-min(HH)+1,max(VV)-min(VV)+1)






# Create Rasdaman Array
cmd = paste("./createArray.sh", RASDAMAN_ARRAYNAME,RASDAMAN_CHUNKSIZE[1]-1,RASDAMAN_CHUNKSIZE[2]-1,RASDAMAN_CHUNKSIZE[3]-1)
system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)



cat("LOADING FILES INTO RASDAMAN \n")


# Process HDF files before loading into rasdaman
for (i in 1:nrow(modisdata)) {
  

  ## GDAL AND GDAL MERGE REQUIRED! BINARIES MUST BE IN PATH
  
  # TODO: Paralellization, unique filenames,temporary file deletion

  system(paste('gdal_translate -of GTiff -ot Int16 HDF4_EOS:EOS_GRID:\"', modisdata$hdffiles[i] , '\":', HDF_SUBDATASETS[1] , ' temp_', 1, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
  system(paste('gdal_translate -of GTiff -ot Int16 HDF4_EOS:EOS_GRID:\"', modisdata$hdffiles[i] , '\":', HDF_SUBDATASETS[2] , ' temp_', 2, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
  system(paste('gdal_translate -of GTiff -ot UInt16 HDF4_EOS:EOS_GRID:\"', modisdata$hdffiles[i] , '\":', HDF_SUBDATASETS[3] , ' temp_', 3, '.tif' ,  sep=""),ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)  
  

  cmd = paste('gdal_merge.py -separate ', paste0("temp_", 1:length(HDF_SUBDATASETS), ".tif", collapse=" "), ' -o temp.tif', sep="")
  system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)
  
 

  # Load to Rasdaman
  
  # automatically compute shift parameter
  shift = c((modisdata$HH[i]-min(modisdata$HH))*IMAGESIZE[1],(modisdata$VV[i]-min(modisdata$VV))*IMAGESIZE[2], i) # Assumes that files will be process in temporal order
  
  targetdims = paste(0+shift[1], ":" , IMAGESIZE[1]+shift[1]-1 , ",", 0+shift[2], ":" , IMAGESIZE[1]+shift[2]-1 , ",",  shift[3] ,sep="")
  #rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,i] assign inv_tiff($1)' --file temp.tif 
  cmd = paste("rasql --user rasadmin --passwd rasadmin -q 'update ", RASDAMAN_ARRAYNAME, " as c set c[" , targetdims, "] assign inv_tiff($1,\"sampletype=short\")' --file temp.tif", sep="")
  
  system(cmd,ignore.stdout = !VERBOSE,ignore.stderr = !VERBOSE)
  
  cat(".")
  
}

cat("FINISHED.")