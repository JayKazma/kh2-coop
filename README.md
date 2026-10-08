# KH2 Co-op

Two-player online co-op for **Kingdom Hearts II Final Mix** (Steam, Global build) over Steam networking.
The second player appears as a second Sora in the host's party.

Built on [Volpestyle/kh2-multiplayer](https://github.com/Volpestyle/kh2-multiplayer) (GPL-3.0).
This repository holds the launcher and release packages; the mod source is in that project.

## Install

1. Download [`dist/kh2coop-update.zip`](dist/kh2coop-update.zip) and unzip it anywhere (for example `Documents\KH2 Co-op`).
2. Run **KH2 Co-op.bat**. Steam must be running and signed in.
3. The launcher checks for updates on every start and installs them with one click.

## Play

1. Both players: **Start KH2** (the launcher finds the game folder; use `...` if it doesn't).
2. Load into the game. The launcher shows **Your SteamID** once the Steam session is ready; send it to the other player.
3. One player picks **Host**, the other **Join a host**. Each enters the *other* player's SteamID and presses **Connect**.
4. The joiner appears in the host's party after the next room change. Keep **Sora clone mode** the same on both PCs.

## Files

- `KH2Coop.ps1` – launcher (Windows PowerShell 5.1, no installs)
- `bin\` – `kh2ctl.exe`, `kh2coop_inject.dll`, `kh2coop_runtime_scaffold.exe`
- `settings.json` – saved game folder, mode and SteamIDs
- `build\rig\logs\` – game, Steam and co-op logs (attach these when reporting a problem)

## Releases

`version.txt` at the repository root is the current version. `dist/kh2coop-update.zip` is the matching package
(`bin\*`, `version.txt`, `KH2Coop.ps1`, licenses) and `dist/notes.txt` the change notes shown before an update.
The launcher reads these three files from the `main` branch.

To publish a new version: build the mod, then

    python tools/make_release.py --bin <folder with the three binaries> --version 0.1.1 --notes "what changed"

and commit `version.txt` and `dist/`.
