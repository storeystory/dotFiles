import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        id: mediaPanel
        property var modelData
        screen: modelData

        width: 300
        implicitHeight: 175

        anchors {
            left: true
            bottom: true
        }

        margins {
            left: 25
            bottom: 50
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "media"

        color: "transparent"

        property string mediaTitle: "Nothing playing"
        property string mediaArtist: ""
        property string mediaStatus: "stopped"
        property string albumArt: ""
        property real mediaPosition: 0
        property real mediaLength: 1
        property var cavaBars: []

        Process {
            id: mediaProc
            command: ["sh", "-c", "~/.config/quickshell/scripts/media.sh"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    try {
                        var obj = JSON.parse(data)
                        mediaPanel.mediaTitle = obj.title || "Nothing playing"
                        mediaPanel.mediaArtist = obj.artist || ""
                        mediaPanel.mediaStatus = obj.status || "stopped"
                        mediaPanel.mediaPosition = obj.position || 0
                        mediaPanel.mediaLength = obj.length || 1
                    } catch(e) {
                        mediaPanel.mediaTitle = "Parse error: " + e
                    }
                }
            }
            stderr: SplitParser {
                onRead: data => {
                    if (data && data.trim()) mediaPanel.mediaTitle = "ERR: " + data.trim()
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: albumArtProc
            command: ["sh", "-c", "~/.config/eww/scripts/album_art.sh"]
            stdout: SplitParser {
                onRead: data => {
                    if (data && data.trim()) mediaPanel.albumArt = data.trim()
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: cavaProc
            command: ["cava", "-p", "/home/storey/.config/cava/quickshell.conf"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    var parts = data.trim().split(";").filter(s => s.trim() !== "")
                    if (parts.length > 0) {
                        mediaPanel.cavaBars = parts.map(s => parseInt(s) || 0)
                    }
                }
            }
            Component.onCompleted: running = true
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                mediaProc.running = true
                albumArtProc.running = true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 12
            border.color: "#d8cab8"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                
                // Cava visualizer
                Item {
                    Layout.fillWidth: true
                    height: 30

                    Row {
                        anchors.fill: parent
                        spacing: 2

                        Repeater {
                            model: mediaPanel.cavaBars.length

                            Rectangle {
                                width: (parent.width / Math.max(mediaPanel.cavaBars.length, 1)) - 2
                                height: 30 * (mediaPanel.cavaBars[index] / 20)
                                anchors.bottom: parent.bottom
                                color: "#AC82E9"
                                radius: 1
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Album art
                    Rectangle {
                        width: 80
                        height: 80
                        color: "#111014"
                        radius: 6

                        Image {
                            anchors.fill: parent
                            source: mediaPanel.albumArt !== "" ? "file://" + mediaPanel.albumArt : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: mediaPanel.albumArt !== ""
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: mediaPanel.mediaTitle
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: mediaPanel.mediaArtist
                            color: "#AC82E9"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Progress bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            color: "#2a2630"
                            radius: 2

                            Rectangle {
                                width: parent.width * (mediaPanel.mediaPosition / mediaPanel.mediaLength)
                                height: parent.height
                                color: "#AC82E9"
                                radius: 2
                            }
                        }

                        // Controls
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Text {
                                text: "󰒮"
                                color: "#d8cab8"
                                font.family: "Maple Mono NF"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                        proc.command = ["playerctl", "previous"]
                                        proc.running = true
                                    }
                                }
                            }

                            Text {
                                text: mediaPanel.mediaStatus === "Playing" ? "󰏤" : "󰐊"
                                color: "#AC82E9"
                                font.family: "Maple Mono NF"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                        proc.command = ["playerctl", "play-pause"]
                                        proc.running = true
                                        Qt.callLater(() => mediaProc.running = true)
                                    }
                                }
                            }

                            Text {
                                text: "󰒭"
                                color: "#d8cab8"
                                font.family: "Maple Mono NF"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                        proc.command = ["playerctl", "next"]
                                        proc.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}