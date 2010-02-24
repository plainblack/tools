#!/bin/bash

echo "Making root folder package"
wgd package root
tar zxf root.wgpkg
rm -f root.wgpkg
mv `perl -lne 'print "$ARGV\n" if /assetId. : .PBasset000000000000001/;' -- *.json` ../root.pkg
rm -f -- *.json *.storage

echo "Compiling composite JSON files"
#for file in `find ../packages-7.8.0 -name '*wgpkg' -print`; do \
for file in `find ../packages-7.8.{0,1,2,3,4,5,6,8,10,11,12,13} -name '*wgpkg' -print`; do \
    tar zxf $file; \
    for json in *.json; do \
        mv -- $json `perl -ne 'print $1 if /assetId. : .(\S{22})/;' -- $json`.pkg;
    done
done

mv ../root.pkg .

echo "Reverting from assetId names to lineage names"
for file in *.pkg; do \
    #echo -- $file `perl -ne 'print $1 if /lineage. : .(\d+)/;' -- $file`.json;
    mv -- $file `perl -ne 'print $1 if /lineage. : .(\d+)/;' -- $file`.json;
done

echo "Build wgpkg and cleanup"
tar czf merged.wgpkg *.json
rm -f -- *.json
