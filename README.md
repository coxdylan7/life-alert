# Life Alert

Escalating battery-drain warnings for the Omarchy shell. Shows full-screen
warning cards as your battery drains through configurable thresholds, plays a
sound at extreme levels, fires Omarchy's `battery-low` hook, and — at the very
end — briefly flashes a cancelable "sleep now" screen that suspends the machine
before the battery dies.

## Features

- Full-screen warning cards at each threshold you configure (defaults:
  75 / 50 / 30 / 20 / 10%), each shown for a few seconds without blocking the
  desktop.
- An urgent sound (`dialog-warning.oga` via `mpv`) once the battery drops to or
  below a configurable level (default: 20%).
- Omarchy's `battery-low` hook fired at ≤ 10%, so other automation attached to
  that event runs too.
- A final, attention-grabbing full-screen alarm when charge reaches
  `finalPercent` (default 3%). Press any key or click to dismiss it; otherwise
  it counts down and runs `systemctl suspend`.
- Polls the battery every few seconds, speeding up when the situation becomes
  critical.
- Fires each level **once per drain cycle** — re-arms only after you charge
  back above the level. Dismissing the final alarm keeps it quiet until you
  charge back above `finalPercent`.
- Instant plug/unplug overlays — a full-screen card appears for a few seconds whenever the charger is connected or disconnected, showing the current charge and estimated runtime (tap to dismiss).

## Requirements

- Omarchy (Quickshell shell) — developed and tested on Omarchy Quattro.
- `systemd` (`systemctl suspend`) for the final auto-sleep.
- `mpv` for the warning sound.
- The freedesktop sound theme (`/usr/share/sounds/freedesktop/stereo/dialog-warning.oga`).
- `omarchy-hook` (ships with Omarchy) for the `battery-low` event.

**Security note:** this plugin runs unsandboxed, like all Omarchy shell
plugins. Review the source before installing.

## Installation

```sh
omarchy plugin add https://github.com/coxdylan7/life-alert --enable
```

Then tell the shell where to find the plugin **and configure it** by adding an
entry to the `plugins` array in `~/.config/omarchy/shell.json`:

```json
{
  "plugins": [
    {
      "id": "djc.life-alert",
      "levels": [75, 50, 30, 20, 10],
      "criticalMinutes": 5,
      "finalPercent": 3,
      "pollSeconds": 15,
      "criticalPollSeconds": 5,
      "flashSeconds": 12,
      "soundFrom": 20,
      "sleepOnFinal": true,
      "sleepCountdownSeconds": 30,
      "powerToastSeconds": 4
    }
  ]
}
```

The config above is the default; all keys are optional.

## Configuration

| Key | Default | Description |
| --- | --- | --- |
| `levels` | `[75, 50, 30, 20, 10]` | Battery percentages (descending) at which to show a warning card. |
| `criticalMinutes` | `5` | When estimated runtime drops to this many minutes, polling speeds up. |
| `finalPercent` | `3` | Charge level at which the final, blocking alarm appears. |
| `pollSeconds` | `15` | Poll interval while discharging, normally. |
| `criticalPollSeconds` | `5` | Poll interval in critical conditions (≤ `criticalMinutes` or ≤ lowest level). |
| `flashSeconds` | `12` | How long each warning card stays on screen. |
| `soundFrom` | `20` | Levels at or below this play the warning sound. |
| `sleepOnFinal` | `true` | Whether the final alarm suspends after the countdown. |
| `sleepCountdownSeconds` | `30` | Seconds from the final alarm until `systemctl suspend`, unless a key is pressed. |
| `powerToastSeconds` | `4` | How long the plug/unplug overlay stays on screen. |

### Behavior details

- Warning cards are non-blocking; the final alarm grabs the keyboard so any key
  (or a click) dismisses it.
- When `sleepOnFinal` is `false`, the final alarm only warns — it never
  suspends your machine.
- Pressing a key during the final countdown cancels the sleep AND dismisses the
  overlay for the rest of that drain cycle.

## Removal

```sh
omarchy plugin remove djc.life-alert
```

Then delete the `djc.life-alert` entry from the `plugins` array in
`~/.config/omarchy/shell.json`, or run `omarchy plugin disable djc.life-alert`
to just turn it off.

## Development

The plugin is a `service` + `overlay` plugin. Its entry points are
`Service.qml` (battery monitoring and state machine) and `AlertView.qml` (the
overlay UI), with helpers in `LifeAlert.js`.

Validate the folder with:

```sh
omarchy plugin validate .
```

## License

MIT — see [LICENSE](LICENSE).