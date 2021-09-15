#!/bin/bash

if brew ls --versions imagemagick > /dev/null; then
  echo "imagemagick already installed"
else
  brew install imagemagick
fi

fastlane snapshot

fastlane run frameit
sed -i -e "s/.png/_framed.png/g" ./fastlane/screenshots/screenshots.html