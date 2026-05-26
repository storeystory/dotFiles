import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

ShellRoot {
    id: root

    // Theme colors
    property color colBg: "#141216"
    property color colFg: "#d8cab8"
    property color colMuted: "#8a7d6e"
    property color colPurple: "#AC82E9"
    property color colRed: "#fc4649"
    property color colYellow: "#fcb167"
    property color colBlue: "#7b91fc"
    property color colCyan: "#AC82E9"

    // Font
    property string fontFamily: "Maple Mono NF"
    property int fontSize: 14

    // System info properties
    property int cpuUsage: 0
    property int memUsage: 0
    property int diskUsage: 0
    property int volumeLevel: 0

    //notification daemon
    property bool notifsDnd: false

    // Network properties
    property string netDown: "0 B/s"
    property string netUp: "0 B/s"
    property var lastRxBytes: 0
    property var lastTxBytes: 0
    property string netInterface: "enp4s0"

    // CPU tracking
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    // GPU properties
    property string gpuUsage: "0"
    property string gpuType: "nvidia"

    // Bluetooth properties
    property string btStatus: "󰂲"
    property string btDevice: ""
    property bool btConnected: false

    // Syncthing properties
    property string syncStatus: "󰓦"
    property int syncConnected: 0
    property bool syncOnline: false
    property bool syncActive: false
    property int syncAnimFrame: 0

    //network speed
    Process {
        id: netProc
        command: ["sh", "-c", "cat /proc/net/dev | grep " + root.netInterface]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var rx = parseInt(parts[1]) || 0
                var tx = parseInt(parts[9]) || 0
                if (root.lastRxBytes > 0) {
                    var rxDiff = rx - root.lastRxBytes
                    var txDiff = tx - root.lastTxBytes
                    root.netDown = root.formatBytes(rxDiff / 2)
                    root.netUp = root.formatBytes(txDiff / 2)
                }
                root.lastRxBytes = rx
                root.lastTxBytes = tx
            }
        }
        Component.onCompleted: running = true
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return Math.round(bytes) + " B/s"
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " K/s"
        return (bytes / 1048576).toFixed(1) + " M/s"
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var user = parseInt(parts[1]) || 0
                var nice = parseInt(parts[2]) || 0
                var system = parseInt(parts[3]) || 0
                var idle = parseInt(parts[4]) || 0
                var iowait = parseInt(parts[5]) || 0
                var irq = parseInt(parts[6]) || 0
                var softirq = parseInt(parts[7]) || 0
                var total = user + nice + system + idle + iowait + irq + softirq
                var idleTime = idle + iowait
                if (lastCpuTotal > 0) {
                    var totalDiff = total - lastCpuTotal
                    var idleDiff = idleTime - lastCpuIdle
                    if (totalDiff > 0) {
                        cpuUsage = Math.round(100 * (totalDiff - idleDiff) / totalDiff)
                    }
                }
                lastCpuTotal = total
                lastCpuIdle = idleTime
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || cat /sys/class/drm/card1/gt_cur_freq_mhz 2>/dev/null || cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var val = data.trim()
                if (val) root.gpuUsage = val
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: btProc
        command: ["sh", "-c", "bluetoothctl info 2>/dev/null | grep -E 'Name|Connected'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                if (data.includes("Connected: yes")) {
                    root.btConnected = true
                    root.btStatus = "󰂱"
                } else if (data.includes("Name:")) {
                    var match = data.match(/Name: (.+)/)
                    if (match) root.btDevice = match[1].trim()
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                if (!root.btConnected) {
                    root.btStatus = "󰂲"
                    root.btDevice = ""
                }
                root.btConnected = false
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df / | tail -1"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var percentStr = parts[4] || "0%"
                diskUsage = parseInt(percentStr.replace('%', '')) || 0
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var match = data.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    volumeLevel = Math.round(parseFloat(match[1]) * 100)
                }
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: notifProc
        command: ["swaync-client", "--get-dnd"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                root.notifsDnd = data.trim() === "true"
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: syncProc
        command: ["sh", "-c", "curl -s -m 2 http://localhost:8384/rest/noauth/health 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                root.syncOnline = data.includes("OK")
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: syncConnProc
        command: ["sh", "-c", "curl -s -m 2 -H \"X-API-Key: $(grep -oP '(?<=<apikey>).*(?=</apikey>)' ~/.local/state/syncthing/config.xml)\" http://localhost:8384/rest/system/connections | jq '[.connections | to_entries[] | select(.value.connected == true)] | length' 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var n = parseInt(data.trim())
                if (!isNaN(n)) root.syncConnected = n
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: syncActiveProc
        command: ["sh", "-c", "curl -s -m 2 -H \"X-API-Key: $(grep -oP '(?<=<apikey>).*(?=</apikey>)' ~/.local/state/syncthing/config.xml)\" http://localhost:8384/rest/db/completion | jq '.needBytes > 0' 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                root.syncActive = data.trim() === "true"
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 250
        running: root.syncActive
        repeat: true
        onTriggered: {
            root.syncAnimFrame = (root.syncAnimFrame + 1) % 4
            var frames = ["󰑐", "󰑙", "󰑏", "󰑎"]
            root.syncStatus = frames[root.syncAnimFrame]
        }
        onRunningChanged: {
            if (!running) root.syncStatus = "󰓦"
        }
    }

    // Slow timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            gpuProc.running = true
            netProc.running = true
            notifProc.running = true
            syncProc.running = true
            syncConnProc.running = true
            syncActiveProc.running = true
            volProc.running = true
            btProc.running = true
        }
    }

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: {}
    }

    // Widgets
    Sysinfo {}
    Weather {}
    Media {}
    Tarot {}
    Nasa {}
    SharedNote {}
    Folders {}
    UserInfo {}
    Rain {}
    Halo {}
    NetOrbit {}
    Keybinds {}

// ── INVISIBLE SPACE RESERVATION ───────────────────────────────
Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        screen: modelData

        anchors { top: true; left: true; right: true }
        implicitHeight: 42
        color: "transparent"

        WlrLayershell.exclusiveZone: 30
    }
}

// ── LEFT PILL ─────────────────────────────────────────────────
Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        screen: modelData

        anchors { top: true; left: true }
        implicitHeight: 34
        width: leftRow.implicitWidth + 20
        color: "transparent"

        margins { top: 4; left: 8 }

        WlrLayershell.exclusiveZone: -1

        Rectangle {
            anchors.fill: parent
            color: "#cc141216"
            radius: 10
            border.color: "#33d8cab8"
            border.width: 1

            Row {
                id: leftRow
                anchors.centerIn: parent
                spacing: 0

                Item { width: 10 }

                Text {
                    text: "󰍛 " + cpuUsage + "%"
                    color: root.colYellow
                    font.pixelSize: root.fontSize
                    font.family: root.fontFamily
                    font.bold: true
                    width: 70
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                Text {
                    text: "󰘚 " + memUsage + "%"
                    color: root.colCyan
                    font.pixelSize: root.fontSize
                    font.family: root.fontFamily
                    font.bold: true
                    width: 70
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                Text {
                    text: "󰾲 " + root.gpuUsage + "%"
                    color: root.colPurple
                    font.pixelSize: root.fontSize
                    font.family: root.fontFamily
                    font.bold: true
                    width: 70
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                Text {
                    text: "🖴 " + diskUsage + "%"
                    color: root.colBlue
                    font.pixelSize: root.fontSize
                    font.family: root.fontFamily
                    font.bold: true
                    width: 70
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                Text {
                    text: "󰇚 " + netDown + "  󰕒 " + netUp
                    color: root.colBlue
                    font.pixelSize: root.fontSize
                    font.family: root.fontFamily
                    font.bold: true
                    width: 200
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 10 }
            }
        }
    }
}
    // ── CENTER PILL ───────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 34
            color: "transparent"

            margins { top: 4 }

            WlrLayershell.exclusiveZone: -1

            Item {
                anchors.fill: parent

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 28
                    color: "#cc141216"
                    radius: 10
                    border.color: "#33d8cab8"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "〇"
                        color: root.colFg
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                            proc.command = ["rofi", "-show", "drun", "-show-icons"]
                            proc.running = true
                        }
                    }
                }
            }
        }
    }

    // ── RIGHT PILL ────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData

            anchors { top: true; right: true }
            implicitHeight: 34
            width: rightRow.implicitWidth + 20
            color: "transparent"

            margins { top: 4; right: 8 }

            WlrLayershell.exclusiveZone: -1

            Rectangle {
                anchors.fill: parent
                color: "#cc141216"
                radius: 10
                border.color: "#33d8cab8"
                border.width: 1

                Row {
                    id: rightRow
                    anchors.centerIn: parent
                    spacing: 0

                    Item { width: 10 }

                    // System tray
                    Repeater {
                        model: SystemTray.items
                        Item {
                            width: 28
                            height: 34
                            Image {
                                anchors.centerIn: parent
                                source: modelData.icon
                                width: 16
                                height: 16
                                smooth: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (event.button === Qt.LeftButton) modelData.activate()
                                    else modelData.secondaryActivate()
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                    // Syncthing
                    Text {
                        text: root.syncStatus + " " + root.syncConnected
                        color: root.syncOnline ? (root.syncActive ? root.colYellow : root.colFg) : root.colMuted
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        width: 50
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                proc.command = ["xdg-open", "http://localhost:8384"]
                                proc.running = true
                            }
                        }
                    }

                    Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                    // Notifications
                    Text {
                        text: root.notifsDnd ? "󰂛" : "󰂚"
                        color: root.notifsDnd ? root.colMuted : root.colFg
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        width: 36
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: event => {
                                if (event.button === Qt.LeftButton) {
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                    proc.command = ["swaync-client", "--toggle-panel"]
                                    proc.running = true
                                } else if (event.button === Qt.RightButton) {
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                    proc.command = ["swaync-client", "--toggle-dnd"]
                                    proc.running = true
                                    Qt.callLater(() => notifProc.running = true)
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                    // Clipboard
                    Text {
                        text: "󰅌"
                        color: root.colFg
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        width: 36
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: event => {
                                if (event.button === Qt.LeftButton) {
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                    proc.command = ["sh", "-c", "cliphist list | rofi -dmenu | cliphist decode | wl-copy"]
                                    proc.running = true
                                } else if (event.button === Qt.RightButton) {
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                    proc.command = ["cliphist", "wipe"]
                                    proc.running = true
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                    // Bluetooth
                    Text {
                        text: root.btStatus + (root.btDevice !== "" ? " " + root.btDevice : "" + root.battery)
                        color: root.btConnected ? root.colBlue : root.colMuted
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        width: root.btDevice !== "" ? 225 : 36
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: event => {
                                if (event.button === Qt.LeftButton) {
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                    proc.command = ["blueman-manager"]
                                    proc.running = true
                                } else if (event.button === Qt.RightButton) {
                                    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                    proc.command = ["bluetoothctl", "power", root.btConnected ? "off" : "on"]
                                    proc.running = true
                                    Qt.callLater(() => btProc.running = true)
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                    // Volume
                    Text {
                        id: volText
                        text: root.volumeLevel <= 0 ? "󰝟 Muted" :
                            root.volumeLevel < 33 ? "󰕿 " + root.volumeLevel + "%" :
                            root.volumeLevel < 66 ? "󰖀 " + root.volumeLevel + "%" :
                            "󰕾 " + root.volumeLevel + "%"
                        color: root.volumeLevel <= 0 ? root.colMuted : root.colPurple
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        width: 65
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                proc.command = ["pavucontrol"]
                                proc.running = true
                            }
                            onWheel: event => {
                                var delta = event.angleDelta.y > 0 ? "5%" : "-5%"
                                var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', parent)
                                proc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta]
                                proc.running = true
                                volProc.running = true
                            }
                        }
                    }

                    Rectangle { width: 1; height: 16; color: root.colMuted; anchors.verticalCenter: parent.verticalCenter }

                    // Clock
                    Text {
                        id: clockText
                        text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                        color: root.colCyan
                        font.pixelSize: root.fontSize
                        font.family: root.fontFamily
                        font.bold: true
                        width: 180
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                        }
                    }

                    Item { width: 10 }
                }
            }
        }
    }
}