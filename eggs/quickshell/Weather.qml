import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        property var modelData
        screen: modelData

        width: 150
        implicitHeight: 25

        anchors {
            right: true
            top: true
        }

        margins {
            right: 25
            top: 50
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "weather"

        color: "transparent"

        property string weatherText: "Loading..."

        Process {
            id: weatherProc
            command: ["sh", "-c", "source ~/.config/bash/secrets.sh && ~/.config/eww/scripts/weather.sh"]
            stdout: SplitParser {
                onRead: data => {
                    if (data && data.trim()) weatherText = data.trim()
                }
            }
            stderr: SplitParser {
                onRead: data => {
                    if (data && data.trim()) weatherText = "ERR: " + data.trim()
                }
            }
            Component.onCompleted: running = true
        }

        Timer {
            interval: 600000
            running: true
            repeat: true
            onTriggered: weatherProc.running = true
        }

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 12
            border.color: "#d8cab8"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: weatherText
                color: "#d8cab8"
                font.family: "Maple Mono NF"
                font.pixelSize: 14
            }
        }
    }
}