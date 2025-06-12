#!/bin/bash

# Default network if not specified
NETWORK=mainnet

FILE=env.json
WORKING_DIR=Temp
FRAMEWORK_ZIP_FILE_NAME=libminotari_wallet_ffi.ios-xcframework.zip
FRAMEWORK_DIRECTORY=libminotari_wallet_ffi-ios-xcframework
FRAMEWORK_FILE_NAME=libminotari_wallet_ffi_ios.xcframework
PROJECT_FRAMEWORK_DIRECTORY=./MobileWallet/Libraries/TariLib

if test ! -f "$FILE"; then
    echo "$FILE does not exist. Creating default."
    cp env-example.json env.json
    echo "Please adjust env.json as needed."
fi

echo "\n\n***Pulling latest Tari lib build for $NETWORK network***"
source dependencies.env

# Determine which FFI version to use based on the network
if [ "$NETWORK" = "mainnet" ]; then
    FFI_VERSION=$FFI_MAINNET_VERSION
else
    FFI_VERSION=$FFI_NEXTNET_VERSION
fi

# Export network for use in build
export NETWORK

# Set MAINNET preprocessor macro in Xcode project
PROJECT_FILE="./MobileWallet.xcodeproj/project.pbxproj"
if [ "$NETWORK" = "mainnet" ]; then
    # Add MAINNET to both Debug and Release configurations if it doesn't exist
    if ! grep -q "MAINNET" "$PROJECT_FILE"; then
        # Find the GCC_PREPROCESSOR_DEFINITIONS section and add MAINNET before the closing parenthesis
        sed -i '' '/GCC_PREPROCESSOR_DEFINITIONS = (/ {
            :a
            N
            /);/!ba
            s/);/\t\t\t\t\t"MAINNET",\n\t\t\t\t);/
        }' "$PROJECT_FILE"
    fi
else
    # Remove MAINNET from both configurations if it exists
    sed -i '' '/"MAINNET"/d' "$PROJECT_FILE"
    # Fix any resulting double commas
    sed -i '' 's/,,/,/g' "$PROJECT_FILE"
    # Fix any resulting empty parentheses
    sed -i '' 's/ = ();/ = ();/' "$PROJECT_FILE"
fi

# Also set SWIFT_ACTIVE_COMPILATION_CONDITIONS for Swift
if [ "$NETWORK" = "mainnet" ]; then
    # Add MAINNET to Swift compilation conditions
    sed -i '' 's/SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;/SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG MAINNET";/' "$PROJECT_FILE"
else
    # Remove MAINNET from Swift compilation conditions
    sed -i '' 's/SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG MAINNET";/SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;/' "$PROJECT_FILE"
fi

rm -rf $WORKING_DIR
mkdir $WORKING_DIR

# Show the full download URL
DOWNLOAD_URL="https://github.com/tari-project/tari/releases/download/v$FFI_VERSION/$FRAMEWORK_ZIP_FILE_NAME"
echo "Downloading FFI library from: $DOWNLOAD_URL"

curl -L "https://github.com/tari-project/tari/releases/download/v$FFI_VERSION/$FRAMEWORK_ZIP_FILE_NAME" -o "./$WORKING_DIR/$FRAMEWORK_ZIP_FILE_NAME"
unzip "./$WORKING_DIR/$FRAMEWORK_ZIP_FILE_NAME" -d "./$WORKING_DIR"
rm -f "./$WORKING_DIR/$FRAMEWORK_ZIP_FILE_NAME"

rm -rf $PROJECT_FRAMEWORK_DIRECTORY/$FRAMEWORK_FILE_NAME
mv $WORKING_DIR/$FRAMEWORK_DIRECTORY/$FRAMEWORK_FILE_NAME $PROJECT_FRAMEWORK_DIRECTORY
rm -rf $WORKING_DIR

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

echo "\n\n***Updating pods***"
pod install

echo "\n\n***Updating Property Lists***"

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

echo "\n\n***Updating Git Hooks***"

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
