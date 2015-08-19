# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]
### Added
- OS X 10.9+ compatibility
- OCTSubmanagerBootstrap that implements bootstrapping logic from STS [Tox-STS/#65](https://github.com/Tox/Tox-STS/pull/65/files).
- Predefined list of nodes to bootstrap from https://wiki.tox.chat/users/nodes.

### Changes
- `toxcore-ios` replaced with `toxcore` pod.
- OCTSubmanagerFriends: removed return `BOOL` value from `removeFriendRequest:` method.

### Fixed
- Crash when loading bad profile [#98](https://github.com/Antidote-for-Tox/objcTox/issues/98).

### Deprecated
- `[OCTManager initWithConfiguration:]`, use `[OCTManager initWithConfiguration:error:]` instead.
- `[OCTManager initWithConfiguration:loadToxSaveFilePath:]`, use `[OCTManager initWithConfiguration:loadToxSaveFilePath:error:]` instead.
- `[OCTManager bootstrapFromHost:port:publicKey:error:]`, use OCTSubmanagerBootstrap instead.
- `[OCTManager addTCPRelayWithHost:port:publicKey:error:]`, use OCTSubmanagerBootstrap instead.

## [0.1.0] - 2015-06-30
### Added
- OCTTox wrapper for tox.h file.
- OCTManager that provides high level API for Tox. Below are features for OCTManager.
- Changing user name, status, status message, nospam.
- Sending, receiving, removing and accepting friend requests.
- Removing friends.
- Auto updating and changeable nickname for friend.
- Chat objects with various information.
- Sending and receiving messages.

[unreleased]: https://github.com/Antidote-for-Tox/objcTox/compare/0.1.0...master
