#!/bin/bash

# MOD09Q1 array type definitions, not yet used
rasdl --delmsettype "TRMM_stack_set"
rasdl --delmsettype "TRMM_image_set"
rasdl --delmddtype "TRMM_stack"
rasdl --delmddtype "TRMM_image"
rasdl --delbasetype "TRMM_pixel"
rasdl -r /home/rasdaman/examples/TRMM_NDVI/TRMM.dl -i # Add data types for TRMM data



# Create collection for 3 bands
rasql --user rasadmin --passwd rasadmin -q "drop collection TRMM" # delete if exists
rasql --user rasadmin --passwd rasadmin -q "create collection TRMM TRMM_stack_set" 
rasql --user rasadmin --passwd rasadmin -q "insert into TRMM values marray it in [0:0,0:0,0:0] values struct {0s,0s,0us} tiling regular [0:511,0:511] index rpt_index" 


# Download data 
# parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/182 ::: {1998..2006}
# parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/183 ::: {1998..2006}
# parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/213 ::: {1998..2006}
# parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/214 ::: {1998..2006}
# parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/244 ::: {1998..2006}
# parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/245 ::: {1998..2006}
wget --retry-connrefused --wait=4 --tries=10 -r -np -nd -nc -p /opt/shared ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/2003/091/3B43.20030401.7A.HDF
wget --retry-connrefused --wait=4 --tries=10 -r -np -nd -nc -p /opt/shared ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/2003/121/3B43.20030501.7A.HDF
wget --retry-connrefused --wait=4 --tries=10 -r -np -nd -nc -p /opt/shared ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/2003/152/3B43.20030601.7A.HDF


# Transform subdatasets of HDF4 files to multiband tiff images
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030401.7A.HDF":0 temp_b01.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030401.7A.HDF":1 temp_b02.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030401.7A.HDF":2 temp_b03.tif
gdal_merge.py -separate temp_20030401_b01.tif temp_20030401_b02.tif temp_20030401_b03.tif -o temp_20030401.tif

gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030501.7A.HDF":0 temp_b01.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030501.7A.HDF":1 temp_b02.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030501.7A.HDF":2 temp_b03.tif
gdal_merge.py -separate temp_20030501_b01.tif temp_20030501_b02.tif temp_20030501_b03.tif -o temp_20030501.tif

gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030601.7A.HDF":0 temp_b01.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030601.7A.HDF":1 temp_b02.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030601.7A.HDF":2 temp_b03.tif
gdal_merge.py -separate temp_20030601_b01.tif temp_20030601_b02.tif temp_20030601_b03.tif -o temp_20030601.tif

# Import to Rasdaman
rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c assign shift(inv_tiff($1),[0,0,3])' --file temp_20030401.tif # April
rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c assign shift(inv_tiff($1),[0,0,4])' --file temp_20030501.tif # May
rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c assign shift(inv_tiff($1),[0,0,5])' --file temp_20030601.tif # June

rasql -q 'select encode(marray prec in [sdom(TRMM)[0], sdom(TRMM)[1]] values condense + over x in sdom(TRMM)[2] using TRMM[prec[0], prec[1], x[0]].precipitation, "GTiff") from TRMM' --out file --outfile TRMM



