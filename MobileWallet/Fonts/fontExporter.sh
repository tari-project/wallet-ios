#!/bin/bash
for f in *.otf
do
  echo "Processing $f file..."
  # take action on each file. $f store current file name

  #Uncomment to export all to editable xml files
  #/System/Volumes/Data/Library/Apple/usr/bin/ftxdumperfuser -t hhea -A d $f
  
  #Uncomment to comvert xml files into otf files
  #/System/Volumes/Data/Library/Apple/usr/bin/ftxdumperfuser -t hhea -A f $f
done