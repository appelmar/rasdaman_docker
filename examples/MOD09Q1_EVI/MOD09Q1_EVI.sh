#!/bin/bash


# This example scripts, downloads two MODIS MOD09Q1 HDF files, imports the data in Rasdaman, and computes an NDVI array that is output as an image file. 
# INFORMATION: Particular files are still fixed, command line arguments for variable MODIS tiles and variable dates will be added later (partially included as commented code)



#TILEWIDTH=4800
#TILEHEIGHT=4800



# MOD09Q1 array type definitions, not yet used
rasdl --delmsettype "MOD09Q1_stack_set"
rasdl --delmsettype "MOD09Q1_image_set"
rasdl --delmddtype "MOD09Q1_stack"
rasdl --delmddtype "MOD09Q1_image"
rasdl --delbasetype "MOD09Q1_pixel"
rasdl -r /home/rasdaman/examples/MOD09Q1_EVI/MOD09Q1.dl -i # Add data types for MOD09Q1 data



# Create collection for 3 bands
rasql --user rasadmin --passwd rasadmin -q "drop collection MOD09Q1" # delete if exists
rasql --user rasadmin --passwd rasadmin -q "create collection MOD09Q1 MOD09Q1_image_set" 
rasql --user rasadmin --passwd rasadmin -q "insert into MOD09Q1 values marray it in [0:0,0:0] values struct {0s,0s,0us} tiling regular [0:511,0:511] index rpt_index" 



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




rasql -q 'select encode((float)(2.5f * (img[0:1000,0:1000].nir - img[0:1000,0:1000].red)/(2.4f * img[0:1000,0:1000].red+img[0:1000,0:1000].nir + 1)), "GTiff") from MOD09Q1 as img' --out file --outfile MOD09Q1_EVI
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
















