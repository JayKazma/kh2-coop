# KH2 Co-op

Two-player online co-op for **Kingdom Hearts II Final Mix** (Steam, Global build) over Steam networking.
The second player appears as a second Sora in the host's party.

Built on [Volpestyle/kh2-multiplayer](https://github.com/Volpestyle/kh2-multiplayer) (GPL-3.0).
This repository holds the launcher and release packages; the mod source is in that project.

## Install

1. Download [**KH2CoopSetup.exe**](https://raw.githubusercontent.com/JayKazma/kh2-coop/main/dist/KH2CoopSetup.exe) and run it (choose a folder, it makes the shortcuts). Or unzip [`dist/kh2coop-update.zip`](dist/kh2coop-update.zip) anywhere and run `KH2Coop.exe`.
2. Steam must be running and signed in. Windows Defender may ask once about the mod's DLL; allow it.
3. The launcher checks for updates on every start and installs them with one click.

## Play

1. Both players: **Start KH2** (the launcher finds the game folder; use `...` if it doesn't).
2. Load into the game. The launcher shows **Your SteamID** once the Steam session is ready; send it to the other player.
3. One player picks **Host**, the other **Join a host**. Each enters the *other* player's SteamID and presses **Connect**.
4. The joiner appears in the host's party after the next room change. Keep **Sora clone mode** the same on both PCs.

## Files

- `KH2Coop.exe` – the launcher (C#, .NET Framework 4.x, WebView2). Source in `src\`, rebuild with `build.bat` (uses the csc.exe that ships with Windows)
- `ui\` – the launcher page, artwork and icon
- `lib\` – Microsoft WebView2 wrappers
- `bin\` – `kh2ctl.exe`, `kh2coop_inject.dll`, `kh2coop_runtime_scaffold.exe`
- `settings.json` – saved game folder, mode and SteamIDs
- `build\rig\logs\` – game, Steam and co-op logs (attach these when reporting a problem)

## Releases

`version.txt` at the repository root is the current version. `dist/kh2coop-update.zip` is the matching package
(`bin\*`, `ui\*`, `lib\*`, `KH2Coop.exe`, `version.txt`, licenses) and `dist/notes.txt` the change notes shown before an update.
The launcher reads these three files from the `main` branch.

To publish a new version: build the mod, then

    python tools/make_release.py --bin <folder with the three binaries> --version 0.1.1 --notes "what changed"

and commit `version.txt` and `dist/`.
