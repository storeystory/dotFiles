import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "DP-1")
    PanelWindow {
        property var modelData
        screen: modelData
        id: sysinfoWidget

        width: 350
        implicitHeight: 350

        anchors {
            left: true
            bottom: true
        }

        margins {
            left: 50
            bottom: 100
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "sysinfo"

        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 12
            border.color: "#d8cab8"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Raven GIF placeholder — we'll use an AnimatedImage
                AnimatedImage {
                    source: "file:///home/storey/.config/quickshell/images/raven_small.gif"
                    Layout.preferredWidth: 280
                    Layout.preferredHeight: 130
                    Layout.alignment: Qt.AlignHCenter
                    fillMode: Image.PreserveAspectFit
                    playing: true
                }

                // CPU Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: "transparent"

                    Rectangle {
                        width: 2
                        height: parent.height
                        color: "#d8cab8"
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 2

                        Text {
                            text: "CPU"
                            color: "#AC82E9"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            text: "AMD Ryzen 7 3700X"
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "8 Cores  16 Threads"
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Freq: " + cpuFreq + "  Max: 4427MHz"
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                        }
                    }
                }

                // RAM Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 2

                        Text {
                            text: "RAM"
                            color: "#AC82E9"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            text: "32GiB DDR4 3600MT/s"
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Used: " + ramUsed + "GiB"
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                        }
                    }
                }

                // GPU Section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        spacing: 2

                        Text {
                            text: "GPU"
                            color: "#AC82E9"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            text: "RTX 3060 Ti  8GiB VRAM"
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Freq: " + gpuFreq + "MHz"
                            color: "#d8cab8"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // Data properties
        property string cpuFreq: "0MHz"
        property string ramUsed: "0"
        property string gpuFreq: "0"

        Process {
            id: sysProc
            command: ["sh", "-c", "grep 'cpu MHz' /proc/cpuinfo | awk '{sum += $4; count++} END {printf \"%.0f\", sum/count}'"]
            stdout: SplitParser {
                onRead: data => {
                    if (data && data.trim()) sysinfoWidget.cpuFreq = data.trim() + "MHz"
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: ramProc
            command: ["sh", "-c", "free -g | awk '/Mem:/ {print $3}'"]
            stdout: SplitParser {
                onRead: data => {
                    if (data && data.trim()) sysinfoWidget.ramUsed = data.trim()
                }
            }
            Component.onCompleted: running = true
        }

        Process {
            id: gpuFreqProc
            command: ["sh", "-c", "nvidia-smi --query-gpu=clocks.gr --format=csv,noheader,nounits 2>/dev/null || cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo 0"]
            stdout: SplitParser {
                onRead: data => {
                    if (data && data.trim()) sysinfoWidget.gpuFreq = data.trim()
                }
            }
            Component.onCompleted: running = true
        }

        Timer {
            interval: 3000
            running: true
            repeat: true
            onTriggered: {
                sysProc.running = true
                ramProc.running = true
                gpuFreqProc.running = true
            }
        }
    }
}