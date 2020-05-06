Tari iOS wallet
===========================
[![Build Status](https://travis-ci.com/tari-project/wallet-ios.svg?branch=development)](https://travis-ci.com/tari-project/wallet-ios)

Mobile-based UI client that connects to a full node in the Tari network.

### Swift Style Guide

Code follows [Github's](https://github.com/github/swift-style-guide) style guide and the [SwiftLint](https://github.com/realm/SwiftLint) is run on each build using. Code is linted on each build.

### Getting started

```bash
git clone git@github.com:tari-project/wallet-ios.git
sh update_dependencies.sh
```

This will also create a default `env.json` file for sensitive vars. Adjust these settings as needed.

### Dependencies

Third party frameworks and Library are managed using a pre-compiled [Tari](https://github.com/tari-project/tari) binary from https://www.tari.com/downloads/ as well as packages from Cocoapods and Carthage.

### Pods used 

```ruby
- pod 'SwiftLint'
- pod 'FloatingPanel'
- pod 'lottie-ios'
- pod 'SwiftEntryKit', '1.2.3'
- pod 'ReachabilitySwift'
```

### Carthage packages used used 

    - binary "https://icepa.github.io/Tor.framework/Tor.json" == 400.6.3


### Version Management

* Build Number willl increased for each iTunes submission and are increased automatically with fastlane
* App version will only increase on app submiting to App Store

### Folder Structure and Architecture

Coming soon.

### Git

- `development` will be the semi-stable branch with `tag` on each stable merge. This is the branch from where IPA should be published to iTunes Test Flight.
- `master` will have code that are fully stable with `release` on each merge. App store publishing should be done from this branch only.

### UI testing

Right now we don't have UI tests using asserts but running `generate_screenshots.sh` will automatically generate a report containing screenshots of each view on multiple simulators. This report can be used to visually inspect each PR for any possible UI or layout bugs that might have been introduced.