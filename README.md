# Mudlet Installer

A cross-platform installer application for [Mudlet](https://www.mudlet.org/), the MUD client. Downloads and installs Mudlet pre-configured for specific game communities.

## Download

Mudlet can be downloaded from [mudlet.org/download](https://www.mudlet.org/download). If you want a version pre-configured for a particular game, installers are available at [github.com/Mudlet/bootstrap/releases](https://github.com/Mudlet/bootstrap/releases).

## Supported Platforms

- Windows
- macOS
- Linux (AppImage)

## Building

Requires Qt 6.9+ with Core, Widgets, Network, and StateMachine modules.

```bash
cmake -B build
cmake --build build
```

## License

See the [Mudlet repository](https://github.com/Mudlet/Mudlet) for license information.
