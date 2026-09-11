import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "LifeAlert.js" as LifeAlert

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "djc.life-alert"

  readonly property var pluginEntry: LifeAlert.pluginEntry(shell, pluginId)
  readonly property var levels: LifeAlert.normalizeLevels(pluginEntry.levels)

  readonly property int lowestLevel: root.levels.length > 0 ? root.levels[root.levels.length - 1] : 10
  readonly property int finalPercent: LifeAlert.configInt(pluginEntry, "finalPercent", 3)
  readonly property int criticalMinutes: LifeAlert.configInt(pluginEntry, "criticalMinutes", 5)
  readonly property int soundFrom: LifeAlert.configInt(pluginEntry, "soundFrom", 20)
  readonly property int pollSeconds: LifeAlert.configInt(pluginEntry, "pollSeconds", 15)
  readonly property int criticalPollSeconds: LifeAlert.configInt(pluginEntry, "criticalPollSeconds", 5)
  readonly property int flashSeconds: LifeAlert.configInt(pluginEntry, "flashSeconds", 12)
  readonly property int sleepCountdownSeconds: LifeAlert.configInt(pluginEntry, "sleepCountdownSeconds", 30)
  readonly property bool sleepOnFinal: pluginEntry.sleepOnFinal !== false
  readonly property int powerToastSeconds: LifeAlert.configInt(pluginEntry, "powerToastSeconds", 4)

  property int percent: -1
  property int minutesRemaining: -1
  property int minutesUntilFull: -1
  property bool discharging: false
  property bool isFullyCharged: false
  property double lastPowerTransitionMs: 0
  property var armed: ({})
  property bool flashActive: false
  property int flashLevel: -1
  property bool finalAlarm: false
  property bool sleepCanceled: false
  property bool dismissed: false
  property int countdownSeconds: 0
  property bool powerToastActive: false
  property string powerToastMessage: ""
  property string powerToastSubMessage: ""

  function showPowerToast(nowDischarging) {
    if (root.finalAlarm) return
    if (nowDischarging) {
      powerToastMessage = "CHARGER DISCONNECTED"
      powerToastSubMessage = "Running on battery — " + percent + "%"
      console.log("life-alert: charger disconnected at " + percent + "%")
    } else {
      powerToastMessage = "CHARGER CONNECTED"
      powerToastSubMessage = "On AC power — " + percent + "%"
      console.log("life-alert: charger connected at " + percent + "%")
    }
    powerToastActive = true
    powerToastTimer.restart()
  }

  function dismissPowerToast() {
    powerToastActive = false
    powerToastTimer.stop()
  }

  function checkBattery() {
    var prevDischarging = root.discharging
    var prevPercent = root.percent
    var prevMinutesRemaining = root.minutesRemaining
    var prevMinutesUntilFull = root.minutesUntilFull
    percent = LifeAlert.batteryPercentage(UPower.displayDevice)
    discharging = LifeAlert.isDischarging(UPower.displayDevice, UPower.onBattery, UPowerDeviceState.Discharging)
    isFullyCharged = !!(UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
    minutesRemaining = LifeAlert.minutesRemaining(UPower.displayDevice)
    minutesUntilFull = LifeAlert.minutesUntilFull(UPower.displayDevice)

    pollTimer.interval = pollingInterval()

    var nowMs = Date.now()
    var justTransitioned = (prevPercent >= 0 && prevDischarging !== discharging)
    if (justTransitioned) {
      lastPowerTransitionMs = nowMs
      showPowerToast(discharging)
    } else if (discharging && minutesRemaining >= 0 && prevMinutesRemaining < 0 && (nowMs - lastPowerTransitionMs) < 30000) {
      // Minutes just became available shortly after unplug — re-show toast with time above bar
      showPowerToast(discharging)
    } else if (!discharging && minutesUntilFull >= 0 && prevMinutesUntilFull < 0 && (nowMs - lastPowerTransitionMs) < 30000) {
      // Minutes until full just became available after plug-in — re-show
      showPowerToast(discharging)
    }

    if (!discharging) {
      deactivateFinal()
      flashActive = false
      dismissed = false
      rearmAll()
      return
    }

    for (var i = 0; i < root.levels.length; i++) {
      var level = root.levels[i]
      if (percent > level) {
        root.armed[level] = true
      } else if (root.armed[level]) {
        root.armed[level] = false
        fireLevel(level)
      }
    }

    if (root.finalPercent > 0 && percent >= 0 && percent <= root.finalPercent) {
      if (root.dismissed) deactivateFinal()
      else activateFinal()
    } else {
      root.dismissed = false
      deactivateFinal()
    }
  }

  function pollingInterval() {
    if (!root.discharging) return root.pollSeconds * 1000
    var critical = (root.minutesRemaining >= 0 && root.minutesRemaining <= root.criticalMinutes)
      || (root.percent >= 0 && root.percent <= root.lowestLevel)
    return (critical ? root.criticalPollSeconds : root.pollSeconds) * 1000
  }

  function rearmAll() {
    var next = {}
    for (var i = 0; i < root.levels.length; i++) next[root.levels[i]] = true
    root.armed = next
  }

  function fireLevel(level) {
    console.log("life-alert: level reached " + level + " at " + root.percent + "%")
    flashLevel = level
    flashActive = true
    flashTimer.restart()
    if (level <= root.soundFrom) playWarning()
    if (level <= 10) runBatteryLowHook(level)
  }

  function playWarning() {
    if (soundProc.running) return
    soundProc.command = [
      "mpv", "--no-video", "--audio-display=no", "--really-quiet",
      "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
    ]
    soundProc.running = true
  }

  function runBatteryLowHook(level) {
    if (hookProc.running) return
    hookProc.command = ["omarchy-hook", "battery-low", String(level)]
    hookProc.running = true
  }

  function activateFinal() {
    if (!root.finalAlarm) {
      console.log("life-alert: final alarm at " + root.percent + "%")
      root.finalAlarm = true
      root.sleepCanceled = false
    }
    if (root.sleepOnFinal && !root.sleepCanceled && root.countdownSeconds <= 0) {
      root.countdownSeconds = root.sleepCountdownSeconds
      countdownTimer.start()
    }
  }

  function deactivateFinal() {
    if (!root.finalAlarm) return
    root.finalAlarm = false
    root.sleepCanceled = false
    root.countdownSeconds = 0
    countdownTimer.stop()
  }

  function cancelSleep() {
    if (!root.finalAlarm) return
    console.log("life-alert: alarm dismissed by user")
    root.dismissed = true
    deactivateFinal()
  }

  function suspendNow() {
    console.log("life-alert: suspending (countdown expired)")
    if (suspendProc.running) return
    suspendProc.command = ["systemctl", "suspend"]
    suspendProc.running = true
  }

  Process { id: soundProc }

  Process { id: hookProc }

  Process {
    id: suspendProc
    onExited: function(exitCode) {
      root.countdownSeconds = 0
    }
  }

  Timer {
    id: flashTimer
    interval: root.flashSeconds * 1000
    onTriggered: root.flashActive = false
  }

  Timer {
    id: powerToastTimer
    interval: root.powerToastSeconds * 1000
    onTriggered: root.powerToastActive = false
  }

  Timer {
    id: countdownTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.countdownSeconds -= 1
      if (root.countdownSeconds <= 0) {
        countdownTimer.stop()
        root.suspendNow()
      }
    }
  }

  Timer {
    id: pollTimer
    interval: root.pollSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkBattery()
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() {
      root.checkBattery()
    }
  }
}