#!/bin/bash

# Constants

FILE=env.json
WORKING_DIR=Temp

WALLET_ZIP_FILE_NAME=libminotari_wallet_ffi.ios-xcframework.zip
WALLET_DIRECTORY=libminotari_wallet_ffi-ios-xcframework
WALLET_FILE_NAME=libminotari_wallet_ffi_ios.xcframework
PROJECT_WALLET_DIRECTORY=./MobileWallet/Libraries/TariLib

CHAR_ZIP_FILE_NAME=libminotari_chat_ffi.ios-xcframework.zip
CHAR_DIRECTORY=libminotari_chat_ffi-ios-xcframework
CHAT_FILE_NAME=libminotari_chat_ffi_ios.xcframework
PROJECT_CHAR_DIRECTORY=./MobileWallet/Libraries/Chat

if test ! -f "$FILE"; then
    echo "$FILE does not exist. Creating default."
    cp env-example.json env.json
    echo "Please adjust env.json as needed."
fi

source dependencies.env

# FFI Frameworks update

update() {
  printf "\n*** Downloading $1 Framework ***\n\n"
  curl -L https://github.com/tari-project/tari/releases/download/v$FFI_VERSION/$2 -o ./$WORKING_DIR/$2
  unzip ./$WORKING_DIR/$2 -d ./$WORKING_DIR
  rm -rf $5/$4
  mv $WORKING_DIR/$3/$4 $5
}

rm -rf $WORKING_DIR
mkdir $WORKING_DIR

update "FFI Wallet" $WALLET_ZIP_FILE_NAME $WALLET_DIRECTORY $WALLET_FILE_NAME $PROJECT_WALLET_DIRECTORY
update "FFI Chat" $CHAR_ZIP_FILE_NAME $CHAR_DIRECTORY $CHAT_FILE_NAME $PROJECT_CHAR_DIRECTORY

rm -rf $WORKING_DIR

# Check for cocoapods and install if missing.

if hash pod 2>/dev/null; then
  printf "\nCool, you have Cocoapods installed."
else
  printf "You need Cocoapods. Would you like it installed?"
  read -e -p "y or n? " yn
  if [[ "y" = "$yn" || "Y" = "$yn" ]]; then
    sudo gem install cocoapods
  fi
fi

printf "\n\n*** Updating Cocoapods dependencies ***\n\n"
pod install

printf "\n*** Updating Property Lists ***"

# Info.plist

INFO_PLIST_PATH="./MobileWallet/Info.plist"
DROPBOX_KEY="Dropbox"

API_KEY=$( jq -r '.dropboxApiKey' $FILE )
ELEMENTS_COUNT=$( plutil -extract CFBundleURLTypes raw $INFO_PLIST_PATH )

if [ $API_KEY != null ]; then
  for (( i=0; i<$ELEMENTS_COUNT; i++ ))
  do
    KEY=$( plutil -extract CFBundleURLTypes.$i.CFBundleURLName raw $INFO_PLIST_PATH )
    if [ $KEY == $DROPBOX_KEY ]; then
        plutil -replace CFBundleURLTypes.$i.CFBundleURLSchemes -json "[\"db-$API_KEY\"]" $INFO_PLIST_PATH
    fi
  done
fi

# Git Hooks

printf "\n\n*** Updating Git Hooks ***\n\n"

PER_COMMIT_HOOK_PATH=".git/hooks/pre-commit"
PRE_HOOK_SCRIPT_PATH="./pre_commit.sh"

chmod 500 $PRE_HOOK_SCRIPT_PATH

if ! [[ -f $PER_COMMIT_HOOK_PATH ]]; then
  touch $PER_COMMIT_HOOK_PATH
  chmod 700 $PER_COMMIT_HOOK_PATH
fi

if ! $( grep -Fxq $PRE_HOOK_SCRIPT_PATH $PER_COMMIT_HOOK_PATH ); then
  echo $PRE_HOOK_SCRIPT_PATH >> $PER_COMMIT_HOOK_PATH
fi
