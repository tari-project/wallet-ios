Tari iOS wallet
===========================
[![Build Status](https://travis-ci.com/tari-project/wallet-ios.svg?branch=development)](https://travis-ci.com/tari-project/wallet-ios)

Mobile-based UI client that connects to a full node in the Tari network.

### Swift Style Guide

Code follows [Github's](https://github.com/github/swift-style-guide) style guide and the [SwiftLint](https://github.com/realm/SwiftLint) is run on each build using. Code is linted on each build.

### Dependencies

Third party frameworks and Library are managed using Cocoapods.

### Pods used 

    - pod 'SwiftLint'
    - pod 'FloatingPanel'
    - pod 'lottie-ios'
    - pod 'SwiftEntryKit', '1.2.3'
    - pod 'ReachabilitySwift'

### Carthage packages used used 

    - binary "https://icepa.github.io/Tor.framework/Tor.json" == 400.6.3


### Version Management

* Build Number willl increased for each iTunes submission
* App version will only increase on app submiting to App Store

### Folder Structure and Architecture

Coming soon.

### Git

- `development` will be the semi-stable branch with `tag` on each stable merge. This is the branch from where IPA should be published to iTunes Test Flight.
- `master` will have code that are fully stable with `release` on each merge. App store publishing should be done from this branch only.
