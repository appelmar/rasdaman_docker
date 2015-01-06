#!/bin/bash

# TODO: Third MODIS TRMM band is automatically typed as float instead of byte / char while running gdal_merge.py
# This should be changed in the future including rasdaman type definitions 


rasdl --delmsettype "TRMM_stack_set"
rasdl --delmsettype "TRMM_image_set"
rasdl --delmddtype "TRMM_stack"
rasdl --delmddtype "TRMM_image"
rasdl --delbasetype "TRMM_pixel"
rasdl -r /home/rasdaman/examples/TRMM_3B43_ANOM/TRMM.dl -i # Add data types for TRMM data



# Create collection for 3 bands
rasql --user rasadmin --passwd rasadmin -q "drop collection TRMM" # delete if exists
rasql --user rasadmin --passwd rasadmin -q "create collection TRMM FloatSet3" 
rasql --user rasadmin --passwd rasadmin -q "insert into TRMM values marray it in [0:0,0:0,0:0] values struct {0f,0f,0f}" 


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
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030401.7A.HDF":0 temp_20030401_b01.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030401.7A.HDF":1 temp_20030401_b02.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030401.7A.HDF":2 temp_20030401_b03.tif
gdal_merge.py -separate temp_20030401_b01.tif temp_20030401_b02.tif temp_20030401_b03.tif -o temp_20030401.tif 

gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030501.7A.HDF":0 temp_20030501_b01.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030501.7A.HDF":1 temp_20030501_b02.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030501.7A.HDF":2 temp_20030501_b03.tif
gdal_merge.py -separate temp_20030501_b01.tif temp_20030501_b02.tif temp_20030501_b03.tif -o temp_20030501.tif

gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030601.7A.HDF":0 temp_20030601_b01.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030601.7A.HDF":1 temp_20030601_b02.tif
gdal_translate -of GTiff HDF4_SDS:UNKNOWN:"3B43.20030601.7A.HDF":2 temp_20030601_b03.tif
gdal_merge.py -separate temp_20030601_b01.tif temp_20030601_b02.tif temp_20030601_b03.tif -o temp_20030601.tif

# Import to Rasdaman

#rasimport  -f temp_20030401.tif --coll TRMM --coverage-name TRMM -t TRMM_stack:TRMM_stack_set --crs-uri 'http://www.opengis.net/def/crs/EPSG/0/5806':'%SECORE_URL%/crs/OGC/0/AnsiDate' --3D top --csz 1 --shift 0:0:1
# rasimport  -f temp_20030401.tif --coll TRMM --coverage-name TRMM -t FloatCube:FloatSet3 --crs-uri 'http://www.opengis.net/def/crs/EPSG/0/5806':'%SECORE_URL%/crs/OGC/0/AnsiDate' --3D top --csz 1 
# rasimport  -f temp_20030501.tif --coll TRMM --coverage-name TRMM -t FloatCube:FloatSet3 --crs-uri 'http://www.opengis.net/def/crs/EPSG/0/5806':'%SECORE_URL%/crs/OGC/0/AnsiDate' --3D top --csz 1 
# rasimport  -f temp_20030601.tif --coll TRMM --coverage-name TRMM -t FloatCube:FloatSet3 --crs-uri 'http://www.opengis.net/def/crs/EPSG/0/5806':'%SECORE_URL%/crs/OGC/0/AnsiDate' --3D top --csz 1 



rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,1] assign decode($1)' --file temp_20030401.tif # April
rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,2] assign decode($1)' --file temp_20030501.tif # May
rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,3] assign decode($1)' --file temp_20030601.tif # June
rasql --user rasadmin --passwd rasadmin -q 'commit'
rasql -q 'select sdom(s) from TRMM as s' --out string | grep Result

rasql -q 'select encode(img[*:*,*:*,1], "GTiff") from TRMM as img' --out file --outfile TRMM1 
sudo cp TRMM1.tif /opt/shared/



rasql -q 'select encode(marray prec in [sdom(TRMM)[0], sdom(TRMM)[1]] values condense + over x in sdom(TRMM)[2] using TRMM[prec[0], prec[1], x[0]].precipitation, "GTiff") from TRMM' --out file --outfile TRMM



