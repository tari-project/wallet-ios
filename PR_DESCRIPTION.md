# Add Bridge Feature Implementation

## Description
This PR adds bridge functionality to wrap XTM tokens from Tari to Ethereum (wXTM) and unwrap wXTM back to Tari. The implementation includes:

- Bridge models and data structures for transaction management
- API service layer for communicating with the bridge backend
- Bridge service for handling wrap/unwrap operations
- Complete UI screens for bridge operations and transaction history
- Integration with the Home screen navigation
- Configuration support for bridge API URL

## Motivation and Context
This change implements the bridge feature that allows users to bridge their XTM tokens between the Tari network and Ethereum. This enables users to:
- Wrap XTM tokens to wXTM on Ethereum for use in DeFi applications
- Unwrap wXTM back to XTM on Tari network
- View their bridge transaction history
- Track transaction status and fees

The bridge feature is essential for interoperability between Tari and Ethereum ecosystems, allowing users to leverage their XTM tokens in Ethereum-based applications.

## How Has This Been Tested?
- ✅ Code structure and compilation verified
- ✅ Models and services follow existing code patterns
- ✅ UI components integrated with existing navigation system
- ⚠️ Backend API integration requires testing with actual bridge API
- ⚠️ End-to-end transaction flow requires testing with testnet/mainnet
- ⚠️ Ethereum wallet integration for unwrap functionality needs to be completed

**Note**: Full testing requires:
- Bridge API backend to be available
- Testnet environment setup
- Ethereum wallet integration for unwrap operations

## Screenshots and/or video clip
<!--- Screenshots will be added after UI testing is complete -->

## Types of changes
* [ ] UI fix (non-breaking change which fixes a UI issue)
* [ ] Functionality bug fix (non-breaking change which fixes an issue)
* [x] New feature (non-breaking change which adds functionality)
* [ ] Breaking change (fix or feature that would cause existing functionality to change)
* [ ] Feature refactor (No new feature or functional changes, but performance or technical debt improvements)
* [ ] New Tests
* [ ] Documentation

## Checklist:
* [ ] I have tested this on multiple simulator devices with different screensizes.
* [ ] I'm merging against the `development` branch.
* [x] Commits have been squashed into one commit with a descriptive commit message
* [ ] I ran all tests before pushing.
* [x] My change requires a change to the documentation.
* [x] I have updated the documentation accordingly (env-example.json updated with bridgeAPIURL).
* [ ] I have added/changed tests to cover my changes if not UI changes.

## Additional Notes
- Unwrap functionality structure is in place but requires Ethereum wallet integration (Web3/WalletConnect)
- Bridge API endpoints should match the backend API specification from `@tari-project/wxtm-bridge-backend-api`
- Fee calculation uses basis points (BPS) from backend configuration
- Configuration requires adding `bridgeAPIURL` to `env.json` file

## Files Changed
### New Files
- `MobileWallet/Common/Models/BridgeModels.swift` - Bridge transaction models and store
- `MobileWallet/Common/Services/BridgeAPIService.swift` - API client for bridge backend
- `MobileWallet/Common/Services/BridgeService.swift` - Bridge operations manager
- `MobileWallet/Screens/Bridge/Bridge.swift` - Main bridge UI
- `MobileWallet/Screens/Bridge/BridgeHistory.swift` - Transaction history view

### Modified Files
- `MobileWallet/Screens/Home/Home/Scenes/Home.swift` - Added Bridge button
- `MobileWallet/Screens/Home/Home/Scenes/HomeRouter.swift` - Added bridge navigation support
- `MobileWallet/Libraries/TariLib/Wrappers/Utils/Settings/TariSettings.swift` - Added bridge API URL config
- `env-example.json` - Added bridgeAPIURL configuration
