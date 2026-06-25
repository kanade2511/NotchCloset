# NotchCloset

A macOS notch shelf app — drag files, URLs, and text into the notch area, then drag them back out when you need them.

Forked from [NotchDrop](https://github.com/Lakr233/NotchDrop) (MIT).

## Features

- **File shelf** — drag files/folders into the notch tray, keep them accessible without cluttering your desktop
- **URLs & text** — drop links or text snippets alongside your files
- **AirDrop** — share files directly from the tray via the AirDrop plugin
- **PDF OCR** — create searchable PDFs with invisible text layers using Apple's Vision framework
- **Drag out** — drag items back out to any app, Finder, or web upload zone
- **Security-scoped bookmarks** — files stay in their original location (no copies)

## Requirements

- macOS 14.0+
- Apple Silicon or Intel

## Build & Run

```bash
cd NotchCloset
make build       # compile + create .app bundle
make run         # kill existing instance + build + launch
make clean       # remove build artifacts
```

## Project Structure

```
NotchCloset/
├── Sources/NotchCloset/
│   ├── main.swift                  # entry point, PID lock
│   ├── AppDelegate.swift           # window & settings management
│   ├── NotchWindow.swift           # borderless transparent window
│   ├── NotchView.swift             # root SwiftUI view
│   ├── NotchViewModel.swift        # state machine (closed/opened/popping)
│   ├── TrayDrop.swift              # data model, persistence, drag handling
│   ├── PluginManager.swift         # plugin registry
│   ├── OCRPlugin.swift             # PDF OCR plugin (Vision framework)
│   └── ...
├── Makefile                        # build, run, clean targets
└── Package.swift                   # SwiftPM manifest
```

## Plugins

| Plugin | Description |
|---|---|
| AirDrop | Share files via AirDrop directly from the tray |
| OCR | Create searchable PDFs or copy recognized text (built-in Vision framework) |

Plugins can be enabled/disabled in Settings → Plugins.

## License

MIT License — see [LICENSE](LICENSE).

Original copyright (c) 2024 Lakr Aream (NotchDrop).  
Modifications (c) 2026 @kanade2511.
