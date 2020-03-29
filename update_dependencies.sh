#!/bin/bash

echo "\n\n***Pulling latest Tari lib build***"
curl -O https://www.tari.com/binaries/libtari_wallet_ffi-ios-0.3.4.tar.gz
tar -xvf libtari_wallet_ffi-ios-*.tar.gz && mv libtari_wallet_ffi.a MobileWallet/TariLib/

echo "\n\n***Cleaning up***"
rm libtari_wallet_ffi-ios-*.tar.gz
rm wallet.h

echo "\n\n***Updating pods***"
pod install

echo "\n\n***Updating carthage***"
carthage update --platform iOS
