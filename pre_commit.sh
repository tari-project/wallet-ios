#!/bin/bash

PLIST_PATH="./MobileWallet/Info.plist"
DROPBOX_KEY="Dropbox"
ELEMENTS_COUNT=$( plutil -extract CFBundleURLTypes raw $PLIST_PATH )

for (( i=0; i<$ELEMENTS_COUNT; i++ ))
do
    KEY=$( plutil -extract CFBundleURLTypes.$i.CFBundleURLName raw $PLIST_PATH )
    if [ $KEY == $DROPBOX_KEY ]; then
        plutil -replace CFBundleURLTypes.$i.CFBundleURLSchemes -json "{}" $PLIST_PATH
    fi
done