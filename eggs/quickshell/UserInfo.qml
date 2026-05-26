import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        id: userInfoPanel
        property var modelData
        screen: modelData

        width: 350
        implicitHeight: 100

        anchors {
            right: true
            bottom: true
        }

        margins {
            right: 25
            bottom: 25
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "userinfo"

        color: "transparent"

        property bool showPowerMenu: false

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 12
            border.color: "#d8cab8"
            border.width: 1

            // Main buttons
            Row {
                anchors.fill: parent
                visible: !userInfoPanel.showPowerMenu

                // Kitty button
                Rectangle {
                    width: parent.width / 3
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⌘"
                        color: "#d8cab8"
                        font.pixelSize: 36
                        font.family: "Maple Mono NF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onExited: parent.color = "transparent"
                        onPressed: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.3)
                        onReleased: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onClicked: {
                            var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                            proc.command = ["kitty"]
                            proc.running = true
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#d8cab8"
                }

                // Nautilus button
                Rectangle {
                    width: parent.width / 3 - 2
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "🗀"
                        color: "#d8cab8"
                        font.pixelSize: 36
                        font.family: "Maple Mono NF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onExited: parent.color = "transparent"
                        onPressed: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.3)
                        onReleased: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onClicked: {
                            var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                            proc.command = ["sh", "-c", "GTK_THEME=diinki-retro-dark nautilus"]
                            proc.running = true
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#d8cab8"
                }

                // Power menu button
                Rectangle {
                    width: parent.width / 3 - 2
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⭘"
                        color: "#d8cab8"
                        font.pixelSize: 36
                        font.family: "Maple Mono NF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onExited: parent.color = "transparent"
                        onPressed: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.3)
                        onReleased: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onClicked: userInfoPanel.showPowerMenu = true
                    }
                }
            }

            // Power menu
            Row {
                anchors.fill: parent
                visible: userInfoPanel.showPowerMenu

                // Shutdown button
                Rectangle {
                    width: parent.width / 3
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        color: "#fc4649"
                        font.pixelSize: 36
                        font.family: "Maple Mono NF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(252/255, 70/255, 73/255, 0.1)
                        onExited: parent.color = "transparent"
                        onPressed: parent.color = Qt.rgba(252/255, 70/255, 73/255, 0.3)
                        onReleased: parent.color = Qt.rgba(252/255, 70/255, 73/255, 0.1)
                        onClicked: {
                            var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                            proc.command = ["systemctl", "poweroff"]
                            proc.running = true
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#d8cab8"
                }

                // Sleep button
                Rectangle {
                    width: parent.width / 3 - 2
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏾"
                        color: "#7b91fc"
                        font.pixelSize: 36
                        font.family: "Maple Mono NF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(123/255, 145/255, 252/255, 0.1)
                        onExited: parent.color = "transparent"
                        onPressed: parent.color = Qt.rgba(123/255, 145/255, 252/255, 0.3)
                        onReleased: parent.color = Qt.rgba(123/255, 145/255, 252/255, 0.1)
                        onClicked: {
                            var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                            proc.command = ["systemctl", "suspend"]
                            proc.running = true
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#d8cab8"
                }

                // Close power menu button
                Rectangle {
                    width: parent.width / 3 - 2
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⨯"
                        color: "#d8cab8"
                        font.pixelSize: 36
                        font.family: "Maple Mono NF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onExited: parent.color = "transparent"
                        onPressed: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.3)
                        onReleased: parent.color = Qt.rgba(172/255, 130/255, 233/255, 0.1)
                        onClicked: userInfoPanel.showPowerMenu = false
                    }
                }
            }
        }
    }
}