import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        id: foldersPanel
        property var modelData
        screen: modelData

        width: 50
        implicitHeight: 425

        anchors {
            right: true
            bottom: true
        }

        margins {
            right: 25
            bottom: 150
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "folders"

        color: "transparent"


        property string hoveredTip: ""
        property bool showTip: false

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 12
            border.color: "#d8cab8"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: [
                        { icon: "󰉍", path: "/home/storey/Downloads", tip: "Downloads" },
                        { icon: "󰈙", path: "/home/storey/Documents", tip: "Documents" },
                        { icon: "󰉏", path: "/home/storey/Pictures", tip: "Pictures" },
                        { icon: "󰕧", path: "/home/storey/Videos", tip: "Videos" },
                        { icon: "󰓦", path: "/home/storey/SyncThing", tip: "SyncThing" },
                        { icon: "󰲋", path: "/mnt/STRG/Proj", tip: "Projects" },
                        { icon: "󰂿", path: "/mnt/STRG/Media/RPGs", tip: "RPGs" },
                    ]

                    Rectangle {
                        width: 40
                        height: 40
                        color: "transparent"
                        radius: 6

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: "#8a7d6e"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 22
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                                foldersPanel.hoveredTip = modelData.tip
                                foldersPanel.showTip = true
                            }
                            onExited: {
                                parent.color = "transparent"
                                foldersPanel.showTip = false
                            }
                            onPressed: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.3)
                            onReleased: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                            onClicked: {
                                var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                proc.command = ["nautilus", modelData.path]
                                proc.running = true
                            }
                        }

                        PopupWindow {
                            id: tooltipPopup
                            visible: foldersPanel.showTip
                            width: 120
                            height: 30

                            anchor.window: foldersPanel
                            anchor.rect.x: -130
                            anchor.rect.y: 0
                            anchor.rect.width: 0
                            anchor.rect.height: foldersPanel.height

                            color: "transparent"

                            Rectangle {
                                anchors.fill: parent
                                color: "#cc141216"
                                border.color: "#AC82E9"
                                border.width: 1
                                radius: 4

                                Text {
                                    anchors.centerIn: parent
                                    text: foldersPanel.hoveredTip
                                    color: "#d8cab8"
                                    font.family: "Maple Mono NF"
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}