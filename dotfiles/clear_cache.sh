#!/usr/bin/bash

echo "Clearing cache..." 
echo "This can take time to complete ...." 
echo 3 > /proc/sys/vm/drop_caches
echo "Done" 

