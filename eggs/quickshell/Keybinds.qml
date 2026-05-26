import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        id: keybindsPanel
        property var modelData
        screen: modelData

        property bool showBinds: false

        // Animate height change
        Behavior on implicitHeight {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        implicitHeight: showBinds ? 450 : 40

        width: 345

        anchors {
            left: true
            top: true
        }

        margins {
            left: 25
            top: 50
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "keybinds"

        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 12
            border.color: "#d8cab8"
            border.width: 1
            clip: true  // important — clips content when collapsed

            // Clickable title bar
            Rectangle {
                id: titleBar
                width: parent.width
                height: 40
                color: "transparent"
                z: 1

                Text {
                    anchors.centerIn: parent
                    text: (keybindsPanel.showBinds ? "▾" : "▸") + "  ✦ Keybinds"
                    color: "#AC82E9"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: keybindsPanel.showBinds = !keybindsPanel.showBinds
                }
            }

            Flickable {
                anchors.top: titleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                anchors.topMargin: 0
                contentHeight: keybindsColumn.implicitHeight
                clip: true
                visible: keybindsPanel.showBinds

                Column {
                    id: keybindsColumn
                    width: parent.width
                    spacing: 12

                    // Section component inline
                    component KeySection: Column {
                        property string title: ""
                        property var binds: []
                        width: parent.width
                        spacing: 4

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#d8cab8"
                            opacity: 0.3
                        }

                        Text {
                            text: title
                            color: "#AC82E9"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Repeater {
                            model: binds
                            Row {
                                spacing: 8
                                Text {
                                    text: modelData[0]
                                    color: "#AC82E9"
                                    font.family: "Maple Mono NF"
                                    font.pixelSize: 11
                                    width: 160
                                }
                                Text {
                                    text: modelData[1]
                                    color: "#d8cab8"
                                    font.family: "Maple Mono NF"
                                    font.pixelSize: 11
                                    opacity: 0.85
                                    wrapMode: Text.Wrap
                                    width: 160
                                }
                            }
                        }
                    }

                    Text {
                        text: "✦ Keybinds"
                        color: "#AC82E9"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    KeySection {
                        title: "Applications"
                        binds: [
                            ["Alt + Return", "Terminal"],
                            ["Alt + D", "App Launcher"],
                            ["Alt + E", "File Explorer"],
                            ["Alt + O", "Obsidian"],
                            ["Alt + Shift + P", "Steam"],
                            ["Alt + Shift + V", "VS Code"],
                            ["Alt + C", "Calculator"],
                        ]
                    }

                    KeySection {
                        title: "Windows"
                        binds: [
                            ["Alt + Q", "Kill Window"],
                            ["Alt + F", "Fullscreen"],
                            ["Alt + Shift + Space", "Float Toggle"],
                            ["Alt + Shift + C", "Reload Sway"],
                            ["Alt + Shift + E", "Exit Sway"],
                        ]
                    }

                    KeySection {
                        title: "Navigation"
                        binds: [
                            ["Alt + H/J/K/L", "Focus Left/Down/Up/Right"],
                            ["Alt + Arrows", "Focus Left/Down/Up/Right"],
                            ["Alt + 1-0", "Switch Workspace"],
                            ["Alt + A", "Focus Parent"],
                            ["Alt + Tab", "Window Switcher"],
                        ]
                    }

                    KeySection {
                        title: "Move Windows"
                        binds: [
                            ["Alt + Shift + H/J/K/L", "Move Window"],
                            ["Alt + Shift + Arrows", "Move Window"],
                            ["Alt + Shift + 1-0", "To Workspace"],
                            ["Alt + Shift + -", "To Scratchpad"],
                            ["Alt + -", "Cycle Scratchpad"],
                        ]
                    }

                    KeySection {
                        title: "Screenshots"
                        binds: [
                            ["Alt + P", "Capture Region → Clipboard"],
                            ["Alt + Shift + I", "Save Clipboard Image"],
                        ]
                    }

                    KeySection {
                        title: "Clipboard"
                        binds: [
                            ["Alt + V", "Clipboard History"],
                        ]
                    }
                }
            }
        }
    }
}