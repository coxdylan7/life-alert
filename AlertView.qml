import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import "LifeAlert.js" as LifeAlert

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  readonly property var pluginEntry: service && service.pluginEntry ? service.pluginEntry : ({})

  readonly property bool ready: service !== null
  readonly property bool finalMode: ready && service.finalAlarm
  readonly property bool flashMode: ready && service.flashActive && !service.finalAlarm
  readonly property bool powerMode: ready && service.powerToastActive && !service.finalAlarm && !service.flashActive

  readonly property int flashLevel: ready ? service.flashLevel : 100
  readonly property color flashColor: {
    if (flashLevel <= service.soundFrom) return Color.urgent
    if (flashLevel <= 50) return Color.accent
    return Color.foreground
  }

  readonly property int percent: ready ? service.percent : -1
  readonly property int minutes: ready ? service.minutesRemaining : -1
  readonly property int minutesUntilFull: ready ? service.minutesUntilFull : -1
  readonly property bool isDischarging: ready ? service.discharging : true
  readonly property color powerColor: {
    if (!ready) return Color.foreground
    if (service.discharging) return Color.urgent
    return "#4ade80"
  }

  readonly property string timeLabel: {
    if (isDischarging) {
      if (minutes < 0) return ""
      if (minutes === 1) return "1 min of battery left"
      return minutes + " min of battery left"
    } else {
      if (percent >= 100 || (service && service.isFullyCharged && percent >= 99)) return "Fully charged"
      if (minutesUntilFull >= 0) {
        if (minutesUntilFull === 1) return "1 min until full"
        return minutesUntilFull + " min until full"
      }
      if (service && service.isFullyCharged) return "Charging limited — " + percent + "%"
      return ""
    }
  }
  readonly property string flashMessage: {
    if (flashLevel <= 10) return "CRITICAL — PLUG IN NOW"
    if (flashLevel <= 20) return "Critically low — plug in soon"
    if (flashLevel <= 50) return "Low — a charger is a good idea"
    return "Running on battery"
  }

  readonly property string finalStatus: {
    if (!ready) return ""
    if (!service.sleepOnFinal) return "PLUG IN A CHARGER NOW"
    if (service.sleepCanceled) return "SLEEP CANCELED — PLUG IN A CHARGER NOW"
    return "SLEEPING IN " + Math.max(0, service.countdownSeconds) + "s — PRESS ANY KEY TO CANCEL"
  }

  function cancel() {
    if (root.service) root.service.cancelSleep()
  }

  function dismissPower() {
    if (root.service && root.service.dismissPowerToast) root.service.dismissPowerToast()
  }

  readonly property int giant: Math.max(64, Math.round(Style.font.displayLarge * 3.2))
  readonly property int huge: Math.max(40, Math.round(Style.font.displayLarge * 2))

  readonly property int cardRadius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(16)
  readonly property color cardFill: Util.alpha(Color.background, 0.82)
  readonly property color cardBorder: Util.alpha(Color.foreground, 0.22)
  readonly property color cardShadow: Util.alpha(Color.background, 0.55)

  property bool ending: false
  property bool logoVisible: false
  property real logoPhase: 0
  property var logoLines: []
  readonly property int logoLineCount: root.logoLines.length
  readonly property int logoFontSize: Math.max(9, Math.round(Style.font.bodySmall))
  readonly property real logoLineHeight: logoFontSize * 1.25

  readonly property bool logoEnabled: pluginEntry.logoCloseout !== false
  readonly property string logoColorMode: {
    var v = pluginEntry.logoColor
    return typeof v === "string" ? String(v).toLowerCase() : "theme"
  }
  readonly property color logoColor: {
    if (logoColorMode === "white") return Qt.rgba(1, 1, 1, 0.92)
    if (logoColorMode === "black") return Qt.rgba(0, 0, 0, 0.92)
    return Util.alpha(Color.foreground, 0.92)
  }

  readonly property var fallbackLogo: [
    "                 \u2584\u2584\u2584",
    " \u2584\u2588\u2588\u2588\u2588\u2588\u2584    \u2584\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2584    \u2584\u2588\u2588\u2588\u2588\u2588\u2588\u2588   \u2584\u2588\u2588\u2588\u2588\u2588\u2588\u2588   \u2584\u2588\u2588\u2588\u2588\u2588\u2588\u2588   \u2584\u2588   \u2588\u2584    \u2584\u2588   \u2588\u2584",
    "\u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588",
    "\u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2580   \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588",
    "\u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588   \u2588\u2588\u2588 \u2584\u2588\u2588\u2588\u2584\u2584\u2584\u2588\u2588\u2588 \u2584\u2588\u2588\u2588\u2584\u2584\u2584\u2588\u2588\u25C0  \u2588\u2588\u2588       \u2584\u2588\u2588\u2588\u2584\u2584\u2584\u2588\u2588\u2588\u2584 \u2588\u2588\u2588\u2584\u2584\u2584\u2588\u2588\u2588",
    "\u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588   \u2588\u2588\u2588 \u25C0\u2588\u2588\u2588\u25C0\u25C0\u25C0\u2588\u2588\u2588 \u25C0\u2588\u2588\u2588\u25C0\u25C0\u25C0\u25C0    \u2588\u2588\u2588      \u25C0\u25C0\u2588\u2588\u2588\u25C0\u25C0\u25C0\u2588\u2588\u2588  \u25C0\u25C0\u25C0\u25C0\u25C0\u25C0\u2588\u2588\u2588",
    "\u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588 \u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2584   \u2588\u2588\u2588   \u2588\u2588\u2588  \u2584\u2588\u2588   \u2588\u2588\u2588",
    "\u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588   \u2588\u2588\u2588",
    " \u25C0\u2588\u2588\u2588\u2588\u2588\u25C0    \u25C0\u2588   \u2588\u2588\u2588   \u2588\u2580   \u2588\u2588\u2588   \u2588\u2580   \u2588\u2588\u2588   \u2588\u2588\u2588  \u2588\u2588\u2588\u2588\u2588\u2588\u2588\u25C0   \u2588\u2588\u2588   \u2588\u2580    \u25C0\u2588\u2588\u2588\u2588\u2588\u25C0",
    "                                       \u2588\u2588\u2588   \u2588\u2580"
  ].join("\n")

  function sealLogo(raw) {
    if (typeof raw !== "string") return
    var lines = String(raw).split("\n")
    for (var i = lines.length - 1; i >= 0; i--) {
      if (String(lines[i].trim()).length === 0) lines.splice(i, 1)
    }
    if (lines.length > 0) root.logoLines = lines
  }

  function beginClose() {
    if (root.ending) return
    if (!root.logoEnabled) return
    root.ending = true
    root.logoVisible = true
    root.logoPhase = 0
    fadeLogoOut.stop()
    endCloseTimer.stop()
    fadeLogoOut.start()
    endCloseTimer.start()
  }

  function endClose() {
    root.ending = false
    root.logoVisible = false
  }

  function modeChanged() {
    if (root.finalMode || root.flashMode || root.powerMode) {
      root.ending = false
      root.logoVisible = false
      fadeLogoOut.stop()
      endCloseTimer.stop()
    } else if (!root.ending) {
      root.beginClose()
    }
  }

  onFlashModeChanged: root.modeChanged()
  onPowerModeChanged: root.modeChanged()
  onFinalModeChanged: root.modeChanged()

  property FileView brandingFile: FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/branding/screensaver.txt"
    printErrors: false
    onLoaded: root.sealLogo(text())
    onLoadFailed: root.sealLogo(root.fallbackLogo)
  }

  Timer {
    id: fadeLogoOut
    interval: 1400
    repeat: false
    onTriggered: root.logoVisible = false
  }

  Timer {
    id: endCloseTimer
    interval: 1800
    repeat: false
    onTriggered: root.endClose()
  }

  PanelWindow {
    id: panel
    visible: root.ready && (root.finalMode || root.flashMode || root.powerMode || root.ending)
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-life-alert"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.finalMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: root.finalMode
      activeFocusOnTab: false
      Keys.priority: Keys.BeforeItem
      Keys.enabled: root.finalMode
      Keys.onPressed: function(event) {
        root.cancel()
        event.accepted = true
      }

      MouseArea {
        anchors.fill: parent
        onClicked: root.cancel()
      }

      Item {
        id: logoLayer
        anchors.fill: parent
        visible: root.logoVisible
        opacity: root.logoVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        Repeater {
          model: root.logoLines
          delegate: Text {
            required property string modelData
            required property int index
            x: (logoLayer.width - implicitWidth) / 2 + Math.sin(root.logoPhase * 0.05 + index * 0.55) * 7
            y: (logoLayer.height - root.logoLines.length * root.logoLineHeight) / 2 + index * root.logoLineHeight + Math.cos(root.logoPhase * 0.05 + index * 0.4) * 2
            text: modelData
            color: root.logoColor
            font.family: Style.font.family
            font.pixelSize: root.logoFontSize
          }
        }
      }

      NumberAnimation {
        id: logoPhaseAnim
        target: root
        property: "logoPhase"
        from: 0
        to: 360
        duration: 2200
        running: root.logoVisible
        loops: Animation.Infinite
      }

      Item {
        id: finalView
        anchors.fill: parent
        visible: root.finalMode
        opacity: root.finalMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

        Rectangle {
          anchors.fill: parent
          color: Color.background
        }

        Column {
          anchors.centerIn: parent
          spacing: Style.space(20)
          width: Math.min(parent.width - Style.space(96), 1200)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "SHUTDOWN IMMINENT"
            color: Color.urgent
            font.family: Style.font.family
            font.pixelSize: root.giant
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap

            SequentialAnimation on opacity {
              running: root.finalMode
              loops: Animation.Infinite
              NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
              NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.percent + "%"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: root.huge
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeLabel
            color: Util.alpha(Color.foreground, 0.8)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: root.timeLabel.length > 0
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LifeAlert.meter(root.percent, 30)
            color: Color.urgent
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.finalStatus
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }
        }
      }

      Item {
        id: flashView
        anchors.fill: parent
        visible: root.flashMode
        opacity: root.flashMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

        Rectangle {
          id: flashCard
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(120), 640)
          height: flashCol.height + Style.space(48)
          radius: root.cardRadius
          color: root.cardFill
          border.color: root.cardBorder
          border.width: 1
          layer.enabled: true
          layer.smooth: true
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.cardShadow
            shadowBlur: 0.45
            shadowVerticalOffset: 3
          }

          Column {
            id: flashCol
            anchors.centerIn: parent
            width: parent.width - Style.space(56)
            spacing: Style.space(10)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "BATTERY"
              color: Util.alpha(root.flashColor, 0.7)
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.bold: true
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.percent + "%"
              color: root.flashColor
              font.family: Style.font.family
              font.pixelSize: root.giant
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.timeLabel
              color: Util.alpha(root.flashColor, 0.8)
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
              visible: root.timeLabel.length > 0
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: LifeAlert.meter(root.percent, 30)
              color: root.flashColor
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              width: parent.width
              text: root.flashMessage
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
            }
          }
        }
      }

      Item {
        id: powerView
        anchors.fill: parent
        visible: root.powerMode
        opacity: root.powerMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

        MouseArea {
          anchors.fill: parent
          onClicked: root.dismissPower()
        }

        Rectangle {
          id: powerCard
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(120), 640)
          height: powerCol.height + Style.space(48)
          radius: root.cardRadius
          color: root.cardFill
          border.color: root.cardBorder
          border.width: 1
          layer.enabled: true
          layer.smooth: true
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.cardShadow
            shadowBlur: 0.45
            shadowVerticalOffset: 3
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.dismissPower()
          }

          Column {
            id: powerCol
            anchors.centerIn: parent
            width: parent.width - Style.space(56)
            spacing: Style.space(10)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: service && service.discharging ? "UNPLUGGED" : "PLUGGED IN"
              color: Util.alpha(root.powerColor, 0.7)
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.bold: true
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.percent + "%"
              color: root.powerColor
              font.family: Style.font.family
              font.pixelSize: root.giant
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.timeLabel
              color: Util.alpha(root.powerColor, 0.8)
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
              visible: root.timeLabel.length > 0
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: LifeAlert.meter(root.percent, 30)
              color: root.powerColor
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              width: parent.width
              text: service ? service.powerToastMessage : ""
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
            }

            Text {
              width: parent.width
              text: service ? service.powerToastSubMessage : ""
              color: Util.alpha(Color.foreground, 0.6)
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
              visible: service && service.powerToastSubMessage.length > 0
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Tap to dismiss"
              color: Util.alpha(Color.foreground, 0.75)
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
              visible: root.powerMode
            }
          }
        }
      }
    }
  }
}
