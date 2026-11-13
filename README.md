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

## Acknowledgements

Windows code signing provided by [SignPath.io](https://about.signpath.io), certificate by [SignPath Foundation](https://signpath.org).

## License

MudletInstaller is licensed under the GNU General Public License, version 2 or (at your option) any later version, the same as [Mudlet](https://github.com/Mudlet/Mudlet). See [COPYING](COPYING).
