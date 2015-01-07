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
rasql --user rasadmin --passwd rasadmin -q "create collection TRMM TRMM_stack_set" 
rasql --user rasadmin --passwd rasadmin -q "insert into TRMM values marray it in [0:0,0:0,0:0] values struct {0f,0f,0f}" 



YEARS=( 1998 1999 2000 2001 2002 2003 2004 2005 2006 )
MONTHS=( 4 5 6 7 )

NYEARS=${#YEARS[@]}
NMONTHS=${#MONTHS[@]}

echo $NYEARS
echo $NMONTHS





# leapyear(){ 
# if [ $[$1 % 400] -eq "0" ]; then
  # return 1
# elif [ $[$1 % 4] -eq 0 ]; then
		# if [ $[$1 % 100] -ne 0 ]; then
		  # return 1
		# else
		  # return 0
		# fi
# else
  # return 0
# fi
# }
# leapyear 2000
# leapyear 2005
 
# Download data 
# parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 --accept="*.hdf* ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/182 ::: {1998..2006}
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



rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,1] assign inv_tiff($1, "sampletype=float")' --file temp_20030401.tif # April
rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,2] assign inv_tiff($1, "sampletype=float")' --file temp_20030501.tif # May
rasql --user rasadmin --passwd rasadmin -q  'update TRMM as c set c[*:*,*:*,3] assign inv_tiff($1, "sampletype=float")' --file temp_20030601.tif # June
rasql --user rasadmin --passwd rasadmin -q 'commit'
rasql -q 'select sdom(s) from TRMM as s' --out string | grep Result

rasql -q 'select encode(img[*:*,*:*,1].precipitation, "GTiff") from TRMM as img' --out file --outfile TRMM1 
rasql -q 'select encode(img[*:*,*:*,1].gaugeRelativeWeighting, "GTiff") from TRMM as img' --out file --outfile TRMM3 
sudo cp TRMM3.tif /opt/shared/

# This seems to be working:
# Average
rasql -q 'select encode(marray prec in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] values condense + over x in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using TRMM[prec[0], prec[1], x[0]].precipitation / 3f , "GTiff") from TRMM' --out file --outfile TRMM_avg

# CHECK, the following queries should return equal results
rasql -q 'select (marray prec in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] values condense + over x in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using TRMM[prec[0], prec[1], x[0]].precipitation)[1,1] from TRMM' --out string
rasql -q 'select TRMM[1,1,1].precipitation + TRMM[1,1,2].precipitation + TRMM[1,1,3].precipitation from TRMM' --out string





# Create new array for average prec # does not work yet... is that kind of queries (insert into B select x from A) supported?
#rasql --user rasadmin --passwd rasadmin -q "create collection TRMM_PREC_AVG FloatSet" 
#rasql --user rasadmin --passwd rasadmin -q "insert into TRMM_PREC_AVG values marray it in [0:0,0:0] values 0f" 
#rasql --user rasadmin --passwd rasadmin -q  'update TRMM_PREC_AVG as c set c assign marray prec in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] values condense + over x in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using TRMM[prec[0], prec[1], x[0]].precipitation / 3f from ' 

#rasql --user rasadmin --passwd rasadmin -q "insert into TRMM_PREC_AVG values marray prec in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] values condense + over x in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using TRMM[prec[0], prec[1], x[0]].precipitation / 3f" 


# Stddev # this becomes ugly without storing avg as intermediate result array...
# First try: mean absolute error
# WARNING: Running the following command will cause a long-running rasserver process with increasing memory consumption until it finally crashes
rasql -q 'select encode(
	marray prec_stdev in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] 
	values
		condense + over y in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi]
		using (TRMM[prec_stdev[0], prec_stdev[1], y[0]].precipitation - 
		((marray prec_avg in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] 
		values condense + over x in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using TRMM[prec_avg[0], prec_avg[1], x[0]].precipitation / 3f )[prec_stdev[0], prec_stdev[1]])) / 3f, "GTiff") from TRMM' --out file --outfile TRMM_avg
		
rasql -q 'select encode(marray prec_stdev in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] values condense + over y in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using (TRMM[prec_stdev[0], prec_stdev[1], y[0]].precipitation - ((marray prec_avg in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] values condense + over x in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using TRMM[prec_avg[0], prec_avg[1], x[0]].precipitation / 3f )[prec_stdev[0], prec_stdev[1]])) / 3f, "GTiff") from TRMM' --out file --outfile TRMM_avg
			
		
		
	






rasql -q 'select max_cells(marray prec in [ sdom(TRMM)[0].lo:sdom(TRMM)[0].hi, sdom(TRMM)[1].lo:sdom(TRMM)[1].hi ] values condense + over x in [sdom(TRMM)[2].lo:sdom(TRMM)[2].hi] using TRMM[prec[0], prec[1], x[0]].precipitation) from TRMM' --out file --outfile TRMM





rasql -q 'select max_cells(TRMM) from TRMM' --out string
rasql -q 'select max_cells(TRMM.precipitation) from TRMM' --out string

