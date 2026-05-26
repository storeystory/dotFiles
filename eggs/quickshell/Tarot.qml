import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        id: tarotPanel
        property var modelData
        screen: modelData

        width: 275
        implicitHeight: 425

        anchors {
            right: true
            bottom: true
        }

        margins {
            right: 100
            bottom: 150
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "tarot"

        color: "transparent"

        property string tarotName: "Loading..."
        property string tarotMeaning: ""
        property string tarotOrientation: "Upright"
        property string tarotArt: ""

        Process {
            id: tarotProc
            command: ["sh", "-c", "~/.config/eww/scripts/tarot.sh"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    try {
                        var obj = JSON.parse(data)
                        tarotPanel.tarotName = obj.name || "Loading..."
                        tarotPanel.tarotMeaning = obj.meaning || ""
                        artProc.running = true
                    } catch(e) {}
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: artProc
            command: ["sh", "-c", "cat /tmp/eww_tarot_card.html | sed 's/<[^>]*>//g' | sed 's/&amp;/\\&/g; s/&lt;/</g; s/&gt;/>/g'"]
            stdout: SplitParser {
                onRead: data => {
                    if (data && data.trim()) {
                        tarotPanel.tarotArt = data.trim().split("\u0001").join("\n")
                    }
                }
            }
            onRunningChanged: {
                if (running) tarotPanel.tarotArt = ""
            }
            Component.onCompleted: running = true
        }

        Timer {
            interval: 3600000
            running: true
            repeat: true
            onTriggered: tarotProc.running = true
        }

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 12
            border.color: "#AC82E9"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Row {
                    width: parent.width

                    Text {
                        text: "✦ Card of the Day"
                        color: "#AC82E9"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 12
                        font.bold: true
                        width: parent.width - orientationText.width
                    }

                    Text {
                        id: orientationText
                        text: tarotPanel.tarotOrientation
                        color: "#8a7d6e"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 11
                    }
                }

                Text {
                    text: tarotPanel.tarotArt
                    color: "#AC82E9"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 9
                    width: parent.width
                    wrapMode: Text.NoWrap
                    lineHeight: 1.0
                }

                Text {
                    text: tarotPanel.tarotName
                    color: "#d8cab8"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 13
                    font.bold: true
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                Text {
                    text: tarotPanel.tarotMeaning
                    color: "#8a7d6e"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 11
                    width: parent.width
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}