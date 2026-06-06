# rcon-script

Management and installation scripts for [rcon](https://github.com/tavut846/Rcon).

## One-click Install

```bash
wget -N https://raw.githubusercontent.com/tavut846/Rcon/master/rcon-script/install.sh && bash install.sh
```

## Usage

```
rcon              - Show management menu
rcon start        - Start rcon
rcon stop         - Stop rcon
rcon restart      - Restart rcon
rcon status       - Show rcon status
rcon enable       - Enable rcon on boot
rcon disable      - Disable rcon on boot
rcon log          - View rcon logs
rcon x25519       - Generate x25519 key pair
rcon generate     - Generate rcon config file
rcon update       - Update rcon
rcon update x.x.x - Update rcon to specific version
rcon install      - Install rcon
rcon uninstall    - Uninstall rcon
rcon version      - Show rcon version
```

## Files

| File | Description |
|------|-------------|
| `install.sh` | Installation script |
| `initconfig.sh` | Interactive config generator |
| `rcon.sh` | Management script (installed to `/usr/bin/rcon`) |
| `rcon.service` | systemd service unit |
