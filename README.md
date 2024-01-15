<p align="center">
	<img width="300" src="./readme-files/tari-logo.svg">
</p>

![Build Status](https://app.bitrise.io/app/b525265e43df3333/status.svg?token=4FoLfg9CpiFswB2syqYexA&branch=master)

## What is Aurora?
Aurora is a reference-design mobile wallet app for the forthcoming [Tari](https://www.tari.com/) digital currency. The goal is for creators and developers to be able to use the open-source Aurora libraries and codebase as a starting point for developing their own Tari wallets and applications. Aurora also sets the bar for applications that use the Tari protocol. In its production-ready state, it will be a beautiful, easy-to-use Tari wallet focused on Tari as a default-private digital currency.

Want to contribute to Aurora? Get started here in this repository.

<a href="https://apps.apple.com/us/app/tari-aurora/id1503654828" target="_blank"><img width="100" src="https://aurora.tari.com/img/AppStoreButton_large.svg"></a>

## Build Instructions

### Swift Style Guide

Code follows [Github's](https://github.com/github/swift-style-guide) style guide and the [SwiftLint](https://github.com/realm/SwiftLint) is run on each build using. Code is linted on each build.

### Getting started

```bash
git clone git@github.com:tari-project/wallet-ios.git
sh update_dependencies.sh
```

This will also create a default `env.json` file for sensitive vars. Adjust these settings as needed.

### Dependencies

Third-party frameworks and libraries are managed using a pre-compiled [Tari](https://github.com/tari-project/tari) binary from https://www.tari.com/downloads/ as well as packages from Cocoapods.

### Pods used 

```ruby
- pod 'Tor'
- pod 'FloatingPanel'
- pod 'lottie-ios'
- pod 'SwiftEntryKit'
- pod 'ReachabilitySwift'
- pod 'Sentry'
- pod 'SwiftKeychainWrapper'
- pod 'Giphy'
- pod 'IPtProxy'
- pod 'Zip'
- pod 'SwiftyDropbox'
- pod 'YatLib'
- pod 'TariCommon'
```

### Version Management

* Build Number will be increased with every merge to the `develop` and `release` branches. The action is handled by the external CI.
* The app version will be increased when the App will be submitted to AppStore. 
    * The major revision will be increased only after significant and breaking changes.
    * The minor revision will be increased when new features or improvements are introduced.
    * The patch revision will be increased when the new version contains only hotfixes 

### Git Branches

- `develop/<version>` are development branches. They contain new features, improvements, and bug fixes that will be published with the specified version. At the end of the development cycle `develop/<version>` will become a root for the `release/<version>` branch.
- `feautre/<name>` are working branches. They contain a single feature, improvement of other code alternation. When the new feature is ready it needs to pass the core review before it will be merged with `develop/<version>`.
- `release/<version>` the release branch is created at the end of the development cycle from the `develop<version>` branch. All builds made from this branch become potential release candidates. After the official release, this branch will be merged with the `master` branch.
- `master` this branch is a collection of releases snapshots. Every merge with this branch should be tagged with the App and libwallet versions (format: `<app_version>-libwallet-<libwallet_version>`).
