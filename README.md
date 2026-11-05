# wtchet

Rootless WeChat tweak. Current work: compact frosted settings UI and first chat composer glass pass.

- Settings cards reduced to fit smaller screens; root page has a visible return/close button.
- Input composer hook is scoped to `BaseMsgContentViewController`; it searches for a bottom-anchored `UITextView` host and adds a non-interactive native blur layer only.
- Existing input settings persist style and enable values.
- No server verification or copied WCGlass binary code.

Build: `make clean package THEOS_PACKAGE_SCHEME=rootless`.
