#!/bin/bash
# This script automatically starts all relevant services on the container
echo -e "\n\nStarting required services..."
/usr/sbin/sshd -D >/dev/null &
echo -e "... sshd started"
/etc/init.d/postgresql start >/dev/null
echo -e "... postgresql started"
echo -e "DONE.\n\n"

