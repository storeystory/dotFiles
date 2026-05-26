import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "DP-1")

    PanelWindow {
        id: nasaPanel
        property var modelData
        screen: modelData

        width: 350
        implicitHeight: 350

        anchors {
            left: true
            bottom: true
        }

        margins {
            left: 425
            bottom: 100
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "nasa"

        color: "transparent"

        property string nasaTitle: "Loading..."
        property string nasaExplanation: ""
        property string nasaImage: "/tmp/nasa_apod.jpg"

        Process {
            id: nasaProc
            command: ["sh", "-c", "source ~/.config/bash/secrets.sh && ~/.config/quickshell/scripts/nasa.sh"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    try {
                        var obj = JSON.parse(data)
                        nasaPanel.nasaTitle = obj.title || "Loading..."
                        nasaPanel.nasaExplanation = obj.explanation || ""
                        nasaPanel.nasaImage = "/tmp/nasa_apod.jpg"
                    } catch(e) {}
                }
            }
            Component.onCompleted: running = true
        }

        Timer {
            interval: 86400000 // 24 hours
            running: true
            repeat: true
            onTriggered: nasaProc.running = true
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
                spacing: 6

                Text {
                    text: "NASA — Astronomy Picture of the Day"
                    color: "#AC82E9"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 11
                    font.bold: true
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                Image {
                    source: "file://" + nasaPanel.nasaImage
                    width: parent.width
                    height: 180
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                }

                Text {
                    text: nasaPanel.nasaTitle
                    color: "#d8cab8"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 11
                    font.bold: true
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                Flickable {
                    width: parent.width
                    height: 100
                    contentHeight: explanationText.implicitHeight
                    clip: true

                    Text {
                        id: explanationText
                        text: nasaPanel.nasaExplanation
                        color: "#8a7d6e"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 10
                        width: parent.width
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}