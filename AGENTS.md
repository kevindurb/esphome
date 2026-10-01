# AGENTS.md

ESPHome configuration repository. YAML-only — no application source code. Each top-level `*.yml` defines firmware for one device; `common/` holds shared packages.

## Structure

- `*.yml` (root) — one file per device: `garage-relay`, `kitchen-lamp`, `living-room-lamp`, `master-bedroom-switches`, `office-lights`, `sprinkler-controller`. Each defines `substitutions:` then includes shared packages.
- `common/` — reusable packages included with `!include`:
  - `base.yml` — esphome core, `api`, `ota` (uses `!secret ota_password`), `logger`
  - `wifi.yml` — wifi with static IP from `${static_ip}` (gateway `192.168.1.1`, subnet `255.255.0.0`)
  - `time.yml` — sntp, timezone `America/Denver`
  - `shelly.yml` — Shelly 2.5 board config (`esp8266`, board `esp01_1m`)
  - `sonoff-s31.yml` — Sonoff S31: UART/power monitoring (cse7766), relay output, button, status LED
- `secrets.yaml` — `wifi_ssid`, `wifi_password`, `ota_password`. Gitignored; referenced via `!secret`. Never commit or print values.
- `dist/` — compiled firmware artifacts (`<name>.bin.gz`) committed for self-hosted OTA/web flashing. Regenerate with `just dist`, never hand-edit.
- `.esphome/` — build cache/idf data. Gitignored.
- `justfile` — build commands (uses `brew bundle exec`).
- `Containerfile` — esphome dashboard container image. `.containerignore` keeps build tooling out of it.
- `.forgejo/workflows/build.yml` — CI builds/publishes the dashboard image to GHCR on pushes to `main` and daily at 2AM UTC.

## Commands

Requires Homebrew with `just` and esphome (see `Brewfile`; esphome 2026.9.1 at time of writing):

```sh
just compile <name>   # compile <name>.yml — this is the validation step
just run <name>       # compile + flash the device
just dist <name>      # compile + gzip + copy to dist/<name>.bin.gz
```

Quick syntax-only check: `brew bundle exec esphome config <name>.yml`

## Conventions

- Device files set `substitutions:` with `name`, `friendly_name`, `area`, `static_ip`, then include `common/base.yml`, `common/wifi.yml`, the hardware package (`shelly.yml` or `sonoff-s31.yml` when applicable), and `common/time.yml`.
- Static IPs are sequential in `192.168.137.x` (garage-relay .1, master-bedroom-switches .2, office-lights .3, kitchen-lamp .4, living-room-lamp .5, sprinkler-controller .6).
- Name entities with `${friendly_name}` so substitutions flow through.
- Hardware packages own device-specific pins; keep pin definitions in `common/` rather than duplicating per device.
- Expose only what Home Assistant needs; mark raw pins/relays `internal: true` (see `master-bedroom-switches.yml`, `sprinkler-controller.yml`).
- Only ESP32 devices declare `esp32:` with an explicit framework (`sprinkler-controller` uses `esp-idf`); ESP8266 board selection stays in the hardware packages.

## Gotchas

- Adding or renaming a device: create `<name>.yml` from an existing one, update substitutions, include relevant packages. The filename stem must match the `name` substitution and is what all `just` targets accept.
- Editing `common/*.yml` affects every device that includes it — compile all consumers after changes.
- `dist/*.bin.gz` files are tracked in git; after updating a device config, run `just dist <name>` to refresh its artifact.
- YAML mistakes surface as compile errors — always `just compile` (or `esphome config`) after edits; there is no linter configured.