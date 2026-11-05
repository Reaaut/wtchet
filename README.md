# wtchet

Rootless WeChat tweak for iOS 15+.

## Current feature: chat composer

- Frosted composer pill with three corner-radius presets.
- Native bottom tray cleanup with a separate system Thin Material layer.
- Independent input-method toolbar controls (master switch, native background visibility, blur, rounded corners).
- Button tint/fill styling, SMS compact mode, placeholder text, fade layer, animated edge glow and vertical offset.
- Global enable switch refreshes the active chat UI immediately.
- Original host, editor and button appearance is snapshotted and restored when styling is disabled.
- Layout scans are throttled to avoid repeatedly walking the WeChat view tree during every layout pass.

The hook uses conservative view-tree and geometry checks because WeChat's private view classes can vary by version. Some keyboard-owned accessory views may live outside the app's view hierarchy and cannot be styled by this hook.

## Build

`make clean package THEOS_PACKAGE_SCHEME=rootless`

No WCGlass binary code or server verification is used; this is an independent implementation.
