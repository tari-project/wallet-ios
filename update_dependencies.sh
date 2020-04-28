#!/bin/bash

echo "\n\n***Pulling latest Tari lib build***"
source dependencies.env
if [[ -z "$FFI_VERSION" ]]; then
        FFI_FILE="${1:-$(curl -s --compressed "https://www.tari.com/downloads/" | egrep -o  'libtari_wallet_ffi-ios-[0-9\.]+.tar.gz' | sort -V  | tail -1)}"
else
        FFI_FILE="libtari_wallet_ffi-ios-$FFI_VERSION.tar.gz"
fi

curl -s "https://www.tari.com/binaries/$FFI_FILE" | tar xz - -C MobileWallet/TariLib/ --exclude wallet.h

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
