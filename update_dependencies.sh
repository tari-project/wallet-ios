#!/bin/bash

echo "\n\n***Pulling latest Tari lib build***"
source dependencies.env
if [[ -z "$FFI_VERSION" ]]; then
	FFI_FILE="${1:-$(curl -s --compressed "https://www.tari.com/downloads/" | egrep -o  'libtari_wallet_ffi-ios-[0-9\.]+.tar.gz' | sort -V  | tail -1)}"
else
	FFI_FILE="libtari_wallet_ffi-ios-$FFI_VERSION.tar.gz"
fi

curl -s "https://www.tari.com/binaries/$FFI_FILE" | tar xz - -C MobileWallet/TariLib/ --exclude wallet.h

echo "\n\n***Updating pods***"
pod install

echo "\n\n***Updating carthage***"
carthage update --platform iOS
