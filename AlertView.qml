import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "LifeAlert.js" as LifeAlert

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null

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
  readonly property color powerColor: {
    if (!ready) return Color.foreground
    if (service.discharging) {
      if (percent <= 20) return Color.urgent
      if (percent <= 50) return Color.accent
      return Color.foreground
    }
    return Color.accent
  }

  readonly property string timeLabel: {
    if (minutes < 0) return ""
    if (minutes >= 120) return Math.round(minutes / 60) + "h of battery left"
    if (minutes === 1) return "1 min of battery left"
    return minutes + " min of battery left"
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

  PanelWindow {
    id: panel
    visible: root.ready && (root.finalMode || root.flashMode || root.powerMode)
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
        id: finalView
        anchors.fill: parent
        visible: root.finalMode
        opacity: root.finalMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

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

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeLabel
            color: Util.alpha(Color.foreground, 0.6)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            visible: root.timeLabel.length > 0
          }
        }
      }

      Item {
        id: flashView
        anchors.fill: parent
        visible: root.flashMode
        opacity: root.flashMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Column {
          anchors.centerIn: parent
          spacing: Style.space(10)
          width: Math.min(parent.width - Style.space(80), 900)

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
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.flashMessage
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeLabel
            color: Util.alpha(Color.foreground, 0.6)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            visible: root.timeLabel.length > 0
          }
        }
      }

      Item {
        id: powerView
        anchors.fill: parent
        visible: root.powerMode
        opacity: root.powerMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        MouseArea {
          anchors.fill: parent
          onClicked: root.dismissPower()
        }

        Column {
          anchors.centerIn: parent
          spacing: Style.space(10)
          width: Math.min(parent.width - Style.space(80), 900)

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
            anchors.horizontalCenter: parent.horizontalCenter
            text: service ? service.powerToastMessage : ""
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
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
            text: root.timeLabel
            color: Util.alpha(Color.foreground, 0.6)
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            visible: root.timeLabel.length > 0
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Tap to dismiss"
            color: Util.alpha(Color.foreground, 0.35)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            visible: root.powerMode
          }
        }
      }
    }
  }
}
