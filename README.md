# Codex Sessions

A lightweight, native macOS list of your unarchived [Codex](https://github.com/openai/codex) sessions, grouped by working directory — so you can pick one up again in the terminal.

- Unarchived sessions grouped by directory, the most recently used first (sub-agent and Guardian review threads are left out, as in the ChatGPT/Codex desktop app)
- One click copies `codex resume <session id>`; right-click to copy just the ID, or the command with a `cd` into the session's directory
- Reloads when the app comes to the front, or with ⌘R
- Written in Swift with SwiftUI only — no Electron, no dependencies

Codex Sessions is read-only: it opens Codex's local state database (`~/.codex/state_*.sqlite`) read-only and never changes it. That database is internal to Codex, so a future Codex update may change it and break this app.

## Requirements

- macOS 14 or later
- Xcode or the Xcode Command Line Tools (Swift 6)

## Build

```sh
./build.sh
```

This produces `build/CodexSessions.app`. `./build.sh --install` also copies it to `~/Applications`.

The app icon is drawn by `make-icon.swift` at build time.

## License

[MIT](LICENSE)
