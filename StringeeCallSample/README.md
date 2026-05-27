# StringeeCallSample

`StringeeCallSample` is the primary sample for integrating the Stringee iOS SDK through Swift Package Manager.

The sample is designed to behave like a third-party app consuming the public SPM package, not like an internal SDK workspace. It keeps the app code small, testable, and free of CocoaPods, Storyboard-based UI, or extra app dependencies.

## SDK Dependency

Add Stringee with Swift Package Manager:

```swift
.package(
    url: "https://github.com/stringeecom/Stringee-iOS-SDK-SPM.git",
    exact: "2.0.3"
)
```

The Xcode project already pins this dependency in `Package.resolved`.

## What This Sample Shows

- Installing Stringee through SPM.
- Connecting to Stringee with a runtime access token.
- Starting a voice call with `StringeeCall`.
- Starting a video call with `StringeeCall2`.
- Receiving foreground incoming calls.
- Using `initAnswer()` before answering incoming calls.
- Registering a VoIP push token with Stringee.
- Reporting incoming calls with CallKit.
- Reconnecting with a demo Keychain token after VoIP push wakes the app.

## App Architecture

- UIKit with programmatic Auto Layout.
- No `Main.storyboard` or XIB for app UI.
- MVVM for screen state.
- Service protocols around Stringee, CallKit, PushKit, and token storage.
- `StringeeSDKAdapter` is the only app layer that talks directly to Stringee SDK types.

## Token Setup

Enter a Stringee access token in the app at runtime.

For convenience, the sample stores the last entered token in Keychain so it can reconnect after a VoIP push. This is only demo behavior. Production apps should request short-lived tokens from a backend and must never embed Stringee API secrets in the iOS app.

## Run

Open:

```sh
StringeeCallSample/StringeeCallSample.xcodeproj
```

Select the `StringeeCallSample` scheme, then run on a simulator or device.

Command-line verification:

```sh
xcodebuild \
  -project StringeeCallSample/StringeeCallSample.xcodeproj \
  -scheme StringeeCallSample \
  -destination 'platform=iOS Simulator,name=<available iPhone simulator>' \
  test \
  CODE_SIGNING_ALLOWED=NO
```

## PushKit and CallKit Notes

Simulator tests use fake services for CallKit and PushKit flows. Real VoIP push delivery and killed-state incoming calls require a physical iPhone, a valid Apple Developer account, Push Notifications capability, Background Modes with Voice over IP, and matching APNs configuration in the Stringee dashboard.

Debug builds register VoIP tokens with `isProduction = false`. Release builds use `isProduction = true`.
