#!/bin/bash


# This example scripts, downloads two MODIS MOD09Q1 HDF files, imports the data in Rasdaman, and computes an NDVI array that is output as an image file. 
# INFORMATION: Particular files are still fixed, command line arguments for variable MODIS tiles and variable dates will be added later (partially included as commented code)



#TILEWIDTH=4800
#TILEHEIGHT=4800

#Define spatial extent (MODIS tile numbers that will be downloaded)
# HTILES=$(seq -w 9 1 12 )
# VTILES=$(seq -w 9 1 12 )
#TODO: Add time dimension

# MOD09Q1 array type definitions, not yet used
rasdl --delmsettype "MOD09Q1_stack_set"
rasdl --delmsettype "MOD09Q1_image_set"
rasdl --delmddtype "MOD09Q1_stack"
rasdl --delmddtype "MOD09Q1_image"
rasdl --delbasetype "MOD09Q1_pixel"
rasdl -r /home/rasdaman/examples/MOD09Q1_NDVI/MOD09Q1.dl -i # Add data types for MOD09Q1 data



# Create collection for 3 bands
rasql --user rasadmin --passwd rasadmin -q "drop collection MOD09Q1" # delete if exists
rasql --user rasadmin --passwd rasadmin -q "create collection MOD09Q1 MOD09Q1_image_set" 
rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1 values marray it in [0:0,0:0] values struct {0s,0s,0us} tiling regular [0:511,0:511] index rpt_index" 


# Create separate collections for 3 bands
# rasql --user rasadmin --passwd rasadmin -q "drop collection MOD09Q1_nir" # delete if exists
# rasql --user rasadmin --passwd rasadmin -q "create collection MOD09Q1_nir ShortSet" # change later
# rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1_nir values marray it in [0:0,0:0] values 0s" 

# rasql --user rasadmin --passwd rasadmin -q "drop collection MOD09Q1_red" # delete if exists
# rasql --user rasadmin --passwd rasadmin -q "create collection MOD09Q1_red ShortSet" # change later
# rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1_red values marray it in [0:0,0:0] values 0s" 

# rasql --user rasadmin --passwd rasadmin -q "drop collection MOD09Q1_qual" # delete if exists
# rasql --user rasadmin --passwd rasadmin -q "create collection MOD09Q1_qual UShortSet" 
# rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1_qual values marray it in [0:0,0:0] values 0us" 


# Download two neighbouring MODIS files # TODO: Run this automatically based on given tiles
wget --retry-connrefused --wait=4 --tries=10 -r -np -nd -nc -p /opt/shared http://e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/2006.08.05/MOD09Q1.A2006217.h10v09.005.2008104035415.hdf
wget --retry-connrefused --wait=4 --tries=10 -r -np -nd -nc -p /opt/shared http://e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/2006.08.05/MOD09Q1.A2006217.h10v10.005.2008104102009.hdf



# convert to tiff, separate file for HDF subdatasets  #TODO: sudo?
gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"MOD09Q1.A2006217.h10v09.005.2008104035415.hdf":MOD_Grid_250m_Surface_Reflectance:sur_refl_b01 temp_h10v09_b01.tif
gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"MOD09Q1.A2006217.h10v09.005.2008104035415.hdf":MOD_Grid_250m_Surface_Reflectance:sur_refl_b02 temp_h10v09_b02.tif
gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"MOD09Q1.A2006217.h10v09.005.2008104035415.hdf":MOD_Grid_250m_Surface_Reflectance:sur_refl_qc_250m temp_h10v09_b03.tif
gdal_merge.py -separate temp_h10v09_b01.tif temp_h10v09_b02.tif temp_h10v09_b03.tif -o temp_h10v09.tif



gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"MOD09Q1.A2006217.h10v10.005.2008104102009.hdf":MOD_Grid_250m_Surface_Reflectance:sur_refl_b01 temp_h10v10_b01.tif
gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"MOD09Q1.A2006217.h10v10.005.2008104102009.hdf":MOD_Grid_250m_Surface_Reflectance:sur_refl_b02 temp_h10v10_b02.tif
gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"MOD09Q1.A2006217.h10v10.005.2008104102009.hdf":MOD_Grid_250m_Surface_Reflectance:sur_refl_qc_250m temp_h10v10_b03.tif
gdal_merge.py -separate temp_h10v10_b01.tif temp_h10v10_b02.tif temp_h10v10_b03.tif -o temp_h10v10.tif




# import to rasdaman # TODO: Compute shift automatically based on MODIS tile numbers
# rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1_red as c set c assign shift(inv_tiff($1),[0,0])' --file temp_h10v09_b01.tif
# rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1_nir as c set c assign shift(inv_tiff($1),[0,0])' --file temp_h10v09_b02.tif
# rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1_qual as c set c assign shift(inv_tiff($1),[0,0])' --file temp_h10v09_b03.tif

# rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1_red as c set c assign shift(inv_tiff($1),[0,4800])' --file temp_h10v10_b01.tif
# rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1_nir as c set c assign shift(inv_tiff($1),[0,4800])' --file temp_h10v10_b02.tif
# rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1_qual as c set c assign shift(inv_tiff($1),[0,4800])' --file temp_h10v10_b03.tif




# import to rasdaman as multiband image
rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1 as c set c assign shift(inv_tiff($1),[0,0])' --file temp_h10v09.tif
rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1 as c set c assign shift(inv_tiff($1),[0,4800])' --file temp_h10v10.tif
#rasql -q 'select encode(img[0:4000,0:4000].red, "GTiff") from MOD09Q1 as img' --out file --outfile MOD09Q1
rasql -q 'select encode(img[0:*,0:*].red, "GTiff") from MOD09Q1 as img' --out file --outfile MOD09Q1 # BUG, does not work for large arrays (only up to approx. 1000x1000)


#rasql -q 'select encode((float)((img[0:4000,3000:5000].nir - img[0:4000,3000:5000].red)/(img[0:4000,3000:5000].red+img[0:4000,3000:5000].nir)), "GTiff") from MOD09Q1 as img' --out file --outfile MOD09Q1_NDVI
rasql -q 'select encode((float)((img[0:1000,0:1000].nir - img[0:1000,0:1000].red)/(img[0:1000,0:1000].red+img[0:1000,0:1000].nir)), "GTiff") from MOD09Q1 as img' --out file --outfile MOD09Q1_NDVI
# TODO: NaN treatment: NIR and RED in -100–16000, fill value -28672 
sudo cp MOD09Q1_NDVI.tif /opt/shared/







#rasql -q 'select encode(MOD09Q1_red[0:2000,0:2000], "GTiff") from MOD09Q1_red' --out file --outfile MOD09Q1_red
#rasql -q "select tiff(MOD09Q1_red[*:*,*:*]) from MOD09Q1_red" --out file --outfile MOD09Q1_red
#sudo cp MOD09Q1_red.tif /opt/shared/MOD09Q1_red.tif

#rasql -q "select csv(MOD09Q1_red[0:4799,0:9599]) from MOD09Q1_red" --out file --outfile MOD09Q1_red
#sudo cp MOD09Q1_red.csv /opt/shared/MOD09Q1_red.csv

#rasql -q "select hdf(MOD09Q1_red[0:200,0:200]) from MOD09Q1_red" --out file --outfile MOD09Q1_red


#rasql -q "select sdom(m) from MOD09Q1_red as m" --out string | grep Result


#rasql -q "select tiff((nir[0:1000,4000:5000] - red[0:1000,4000:5000]) / (nir[0:1000,4000:5000] + red[0:1000,4000:5000])) from MOD09Q1_red as red, MOD09Q1_nir as nir" --out file --outfile MOD09Q1_NDVI
#sudo cp MOD09Q1_NDVI.tif /opt/shared/MOD09Q1_NDVI.tif






# Create NDVI array
# rasql --user rasadmin --passwd rasadmin -q "drop collection MOD09Q1_NDVI" # delete if exists
# rasql --user rasadmin --passwd rasadmin -q "create collection MOD09Q1_NDVI FloatSet" # change later
# #rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1_NDVI values marray it in [0:0,0:0] values 0f"
# rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1_NDVI values marray it in [0:0,0:0] values select (nir[0:500,0:500] - red[0:500,0:500]) / (nir[0:500,0:500] + red[0:500,0:500]) from MOD09Q1_red as red, MOD09Q1_nir as nir"








# For all (VTILE, HTILE) file combinations: # TODO: include time dimension
# 1) download corresponding MODIS hdf4 file
# 2) run gdal_translate to create temporary single band tiffs out of subdatasets
# 3) import tiffs in corresponding rasdaman collections including shift information using partial updates
# 4) delete temporary tiffs and hdf4 file

# for htile in $HTILES 
# do
 # for vtile in $VTILES 
 # do
  # echo "STARTING DOWNLOAD OF TILE $htile , $vtile "
  # # wget
  # # gdal_translate -of GTiff HDF4_EOS:EOS_GRID:"/opt/shared/MOD09Q1.A2000185.h11v10.005.2006291111613.hdf":MOD_Grid_250m_Surface_Reflectance:sur_refl_b02 temp_h${htile}v${vtile}

  # #rasql --user rasadmin --passwd rasadmin -q  'update MOD09Q1_nir as c set c assign shift(inv_tiff($1),[$(( $HTILE * TILEWIDTH )),$(( $VTILE * TILEHEIGHT ))])' --file /opt/shared/est.tiff1
  # # Add other bands
   
 
 # done
# done




# filename=MOD09Q1.A2000185.h11v09.005.2006291111244.hdf
# TILEWIDTH=4800
# TILEHEIGHT=4800
# # extract relevant numbers and remove leading zeros
# YEAR="$(echo ${filename:9:4} | sed 's/^0//')"       # year
# DAYOFYEAR="$(echo ${filename:13:3}| sed 's/^0//')"  #day of year
# HTILE="$(echo ${filename:18:2} | sed 's/^0//')"     # h tile no
# VTILE="$(echo ${filename:21:2} | sed 's/^0//')"     # v tile no

# echo $YEAR
# echo $DAYOFYEAR
# echo $HTILE *  # h tile no
# echo $VTILE # v tile no

# echo $(( $HTILE * TILEWIDTH ))
# echo $(( $VTILE * TILEHEIGHT ))


