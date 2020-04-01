#!/bin/bash

echo "\n\n***Pulling latest Tari lib build***"
curl -s "https://www.tari.com/binaries/$(curl -s --compressed "https://www.tari.com/downloads/" | egrep -o  'libtari_wallet_ffi-ios-[0-9\.]+.tar.gz' | sort -V  | tail -1)" | tar xz - -C MobileWallet/TariLib/ --exclude wallet.h

echo "\n\n***Updating pods***"
pod install

echo "\n\n***Updating carthage***"
carthage update --platform iOS
