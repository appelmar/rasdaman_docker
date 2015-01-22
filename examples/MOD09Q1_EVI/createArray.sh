#!/bin/bash

# Pars:
# 1) ARRAY_NAME
# 2) TILING WIDTH
# 3) TILING HEIGHT
# 4) TILING TIME STEPS
# Example createArray MODIS 512 512 1


# MOD09Q1 array type definitions
rasdl --delmsettype "MOD09Q1_stack_set"
rasdl --delmsettype "MOD09Q1_image_set"
rasdl --delmddtype "MOD09Q1_stack"
rasdl --delmddtype "MOD09Q1_image"
rasdl --delbasetype "MOD09Q1_pixel"
rasdl -r MOD09Q1.dl -i # Add data types for MOD09Q1 data


rasql --user rasadmin --passwd rasadmin -q "drop collection ${1}" # delete if exists
rasql --user rasadmin --passwd rasadmin -q "create collection ${1} MOD09Q1_stack_set" 
rasql --user rasadmin --passwd rasadmin -q "insert into ${1} values marray it in [1:1,1:1,1:1] values struct {0s,0s,0us} tiling regular [1:${2},1:${3},1:${4}]" 

# Check whether array exists
#rasql --user rasadmin --passwd rasadmin -q "select r from RAS_COLLECTIONNAMES as r" --out string
#rasql --user rasadmin --passwd rasadmin -q "select sdom(s) from ${1} as s" --out string

