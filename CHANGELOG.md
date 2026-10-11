# CARBON CHANGELOG
## [0.1.16] - 2026-10-11
---
## [0.1.15] - 2026-10-11
---
## [0.1.14] - 2026-10-11
---
## [0.1.13] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))
- ✦ **[VIDEO]** fast-path 60fps video blitting, resource format loader, and windows msvc fixes ([`6c09f78`](https://github.com/sol-vin/emerald/commit/6c09f78))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))
- ✓ **[VLC]** link against vlc on Unix and libvlc on Windows with dual symlink fallback ([`5b8fa27`](https://github.com/sol-vin/emerald/commit/5b8fa27))
- ✓ **[CI]** ensure /usr/local/lib and /opt/homebrew/lib exist on macOS runners ([`f071609`](https://github.com/sol-vin/emerald/commit/f071609))
- ✓ **[CI]** embed rpath and export dyld library path in test-engine-macos ([`1279bec`](https://github.com/sol-vin/emerald/commit/1279bec))
- ✓ **[GODOT]** resolve EmeraldPlugin base class parse error, bundle VLC DLLs, and align with Lapis 0.0.290 ([`de9e4e4`](https://github.com/sol-vin/emerald/commit/de9e4e4))

### 🛠️ Chores & Tooling
- • **[DEPS]** update lapis shard to 4.8-dev7 commit 8595d2d ([`16cbe26`](https://github.com/sol-vin/emerald/commit/16cbe26))
- • add retry loop and winget fallback for vlc installation on windows runners ([`932287b`](https://github.com/sol-vin/emerald/commit/932287b))

---
## [0.1.12] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))
- ✦ **[VIDEO]** fast-path 60fps video blitting, resource format loader, and windows msvc fixes ([`6c09f78`](https://github.com/sol-vin/emerald/commit/6c09f78))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))
- ✓ **[VLC]** link against vlc on Unix and libvlc on Windows with dual symlink fallback ([`5b8fa27`](https://github.com/sol-vin/emerald/commit/5b8fa27))
- ✓ **[CI]** ensure /usr/local/lib and /opt/homebrew/lib exist on macOS runners ([`f071609`](https://github.com/sol-vin/emerald/commit/f071609))
- ✓ **[CI]** embed rpath and export dyld library path in test-engine-macos ([`1279bec`](https://github.com/sol-vin/emerald/commit/1279bec))
- ✓ **[GODOT]** resolve EmeraldPlugin base class parse error, bundle VLC DLLs, and align with Lapis 0.0.290 ([`de9e4e4`](https://github.com/sol-vin/emerald/commit/de9e4e4))

### 🛠️ Chores & Tooling
- • **[DEPS]** update lapis shard to 4.8-dev7 commit 8595d2d ([`16cbe26`](https://github.com/sol-vin/emerald/commit/16cbe26))

---
## [0.1.11] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))
- ✦ **[VIDEO]** fast-path 60fps video blitting, resource format loader, and windows msvc fixes ([`6c09f78`](https://github.com/sol-vin/emerald/commit/6c09f78))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))
- ✓ **[VLC]** link against vlc on Unix and libvlc on Windows with dual symlink fallback ([`5b8fa27`](https://github.com/sol-vin/emerald/commit/5b8fa27))
- ✓ **[CI]** ensure /usr/local/lib and /opt/homebrew/lib exist on macOS runners ([`f071609`](https://github.com/sol-vin/emerald/commit/f071609))
- ✓ **[CI]** embed rpath and export dyld library path in test-engine-macos ([`1279bec`](https://github.com/sol-vin/emerald/commit/1279bec))
- ✓ **[GODOT]** resolve EmeraldPlugin base class parse error, bundle VLC DLLs, and align with Lapis 0.0.290 ([`de9e4e4`](https://github.com/sol-vin/emerald/commit/de9e4e4))

---
## [0.1.10] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))
- ✓ **[VLC]** link against vlc on Unix and libvlc on Windows with dual symlink fallback ([`5b8fa27`](https://github.com/sol-vin/emerald/commit/5b8fa27))
- ✓ **[CI]** ensure /usr/local/lib and /opt/homebrew/lib exist on macOS runners ([`f071609`](https://github.com/sol-vin/emerald/commit/f071609))
- ✓ **[CI]** embed rpath and export dyld library path in test-engine-macos ([`1279bec`](https://github.com/sol-vin/emerald/commit/1279bec))
- ✓ **[GODOT]** resolve EmeraldPlugin base class parse error, bundle VLC DLLs, and align with Lapis 0.0.290 ([`de9e4e4`](https://github.com/sol-vin/emerald/commit/de9e4e4))

---
## [0.1.9] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))
- ✓ **[VLC]** link against vlc on Unix and libvlc on Windows with dual symlink fallback ([`5b8fa27`](https://github.com/sol-vin/emerald/commit/5b8fa27))
- ✓ **[CI]** ensure /usr/local/lib and /opt/homebrew/lib exist on macOS runners ([`f071609`](https://github.com/sol-vin/emerald/commit/f071609))
- ✓ **[CI]** embed rpath and export dyld library path in test-engine-macos ([`1279bec`](https://github.com/sol-vin/emerald/commit/1279bec))

---
## [0.1.8] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))
- ✓ **[VLC]** link against vlc on Unix and libvlc on Windows with dual symlink fallback ([`5b8fa27`](https://github.com/sol-vin/emerald/commit/5b8fa27))
- ✓ **[CI]** ensure /usr/local/lib and /opt/homebrew/lib exist on macOS runners ([`f071609`](https://github.com/sol-vin/emerald/commit/f071609))

---
## [0.1.7] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))
- ✓ **[VLC]** link against vlc on Unix and libvlc on Windows with dual symlink fallback ([`5b8fa27`](https://github.com/sol-vin/emerald/commit/5b8fa27))

---
## [0.1.6] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))
- ✓ **[CI]** robustly locate and symlink LibVLC dylibs on macOS runners ([`98e5826`](https://github.com/sol-vin/emerald/commit/98e5826))

---
## [0.1.5] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))
- ✓ **[CI]** configure libvlc paths for macOS and ensure VLC on Windows test runner ([`e449653`](https://github.com/sol-vin/emerald/commit/e449653))

---
## [0.1.4] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

### 🐛 Bug Fixes
- ✓ **[DOCS]** track compiled src/docs by scoping root /docs in gitignore ([`4d1a1ed`](https://github.com/sol-vin/emerald/commit/4d1a1ed))

---
## [0.1.3] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))
- ✦ **[CI]** add release CI workflow for Godot addon packaging ([`e5982b3`](https://github.com/sol-vin/emerald/commit/e5982b3))

---
## [0.1.2] - 2026-10-11
### ✨ Features & Improvements
- ✦ initial release of Emerald LibVLC bindings and media player nodes for Lapis ([`0d627b7`](https://github.com/sol-vin/emerald/commit/0d627b7))

---
## [0.1.1] - 2026-10-11
---
## [0.1.0] - 2026-10-11
> Initial release
