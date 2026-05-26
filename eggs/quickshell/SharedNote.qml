import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        id: sharedNotePanel
        property var modelData
        screen: modelData

        width: 325
        implicitHeight: 25

        anchors {
            right: true
            bottom: true
        }

        margins {
            right: 400
            bottom: 25
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "sharednote"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        color: "transparent"

        property string noteText: ""

        Process {
            id: noteReadProc
            command: ["sh", "-c", "cat ~/.config/quickshell/shared/note.txt 2>/dev/null"]
            stdout: SplitParser {
                onRead: data => {
                    if (data !== null) sharedNotePanel.noteText = data
                }
            }
            Component.onCompleted: running = true
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: noteReadProc.running = true
        }

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 8
            border.color: "#AC82E9"
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                Text {
                    text: "✎"
                    color: "#8a7d6e"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: noteInput
                    width: parent.width - 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: sharedNotePanel.noteText
                    color: "#d8cab8"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 13
                    selectByMouse: true
                    clip: true

                    onTextEdited: {
                        var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', noteInput)
                        proc.command = ["sh", "-c", "echo " + JSON.stringify(noteInput.text) + " > ~/.config/quickshell/shared/note.txt"]
                        proc.running = true
                    }
                }
            }
        }
    }
}