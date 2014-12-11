#!/bin/bash
rasql -q "select r from RAS_COLLECTIONNAMES as r" --out string
rasdaman_insertdemo.sh localhost 7001 $RMANHOME/share/rasdaman/examples/images rasadmin rasadmin
rasql -q "select r from RAS_COLLECTIONNAMES as r" --out string
