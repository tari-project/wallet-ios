#!/bin/bash

FILE=env.json
if test ! -f "$FILE"; then
    echo "$FILE does not exist. Creating default."
    cp env-example.json env.json
    echo "Please adjust env.json as needed."
fi

echo "\n\n***Pulling latest Tari lib build***"
source dependencies.env
FFI_FILE="libwallet-ios-$FFI_VERSION.tar.gz"
curl -s "https://tari-binaries.s3.amazonaws.com/libwallet/$FFI_FILE" | tar xz
mv "libwallet-ios-$FFI_VERSION/libtari_wallet_ffi.a" MobileWallet/TariLib/
mv "libwallet-ios-$FFI_VERSION/wallet.h" MobileWallet/TariLib/
rm -rf "libwallet-ios-$FFI_VERSION"

# Check for cocoapods and install if missing.
if hash pod 2>/dev/null; then
  echo "Cool, you have pods installed."
else
  echo "You need cocoapods. Would you like it installed?"
  read -e -p "y or n? " yn
  if [[ "y" = "$yn" || "Y" = "$yn" ]]; then
    sudo gem install cocoapods
  fi
fi
# Check for carthage and install if missing.
if hash carthage 2>/dev/null; then
  echo "Cool, you have carthage installed."
else
  echo "You need carthage. Would you like it installed?"
  read -e -p "y or n? " yn
  if [[ "y" = "$yn" || "Y" = "$yn" ]]; then
    brew install carthage
  fi
fi
echo "\n\n***Updating pods***"
pod install

echo "\n\n***Updating carthage***"
carthage update --platform iOS

echo "\n\n***Updating Property Lists***"

CONSTS_PLIST_PATH="./MobileWallet/Constants.plist"
FFI_VERSION_KEY="FFI Version"

plutil -replace "$FFI_VERSION_KEY" -string $FFI_VERSION $CONSTS_PLIST_PATH