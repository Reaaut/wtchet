# wtchet

Rootless WeChat tweak for iOS 15+.

## Chat composer controls

- Clear native composer and bottom tray backgrounds so the chat wallpaper remains visible.
- Optional independent thin-material frosted layer for the outer tray and composer pill.
- Rounded composer styles, compact SMS mode, button tint, text and cursor colors, placeholder text, vertical offset.
- Optional fade overlay and animated edge glow with speed/color controls.
- Independent input-method area controls: master switch, native background visibility, frosted material and corner radius.
- Settings controls persist locally and notify the active chat UI to refresh.
- Original native background colors and blur effects are restored when disabled.

## Build

`make clean package THEOS_PACKAGE_SCHEME=rootless`

This is an independent implementation and does not include WCGlass binary code or server verification.
