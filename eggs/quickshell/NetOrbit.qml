import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Variants {
    model: Quickshell.screens.filter(s => s.name === "DP-1")

    PanelWindow {
        id: netorbitPanel
        property var modelData
        screen: modelData

        width: 500
        implicitHeight: 355

        anchors {
            right: true
            bottom: true
        }

        margins {
            right: 25
            bottom: 100
        }

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "netorbit"

        color: "transparent"

        // World map dimensions (equirectangular projection)
        property var connections: []
        property int maxConnections: 10
        property int captured: 0
        property int mapped: 0

        Process {
            id: snifferProc
            command: ["python3", "/home/storey/.config/quickshell/netorbit_sniffer.py"]
            stdout: SplitParser {
                onRead: data => {
                    if (!data || !data.trim()) return
                    try {
                        var pkt = JSON.parse(data.trim())
                        netorbitPanel.captured++
                        if (pkt.lat && pkt.lon) {
                            netorbitPanel.mapped++
                            var conns = netorbitPanel.connections.slice()
                            conns.unshift(pkt)
                            if (conns.length > netorbitPanel.maxConnections) {
                                conns = conns.slice(0, netorbitPanel.maxConnections)
                            }
                            netorbitPanel.connections = conns
                            mapCanvas.requestPaint()
                        }
                    } catch(e) {}
                }
            }
            Component.onCompleted: running = true
        }

        Rectangle {
            anchors.fill: parent
            color: "#cc0a0e14"
            radius: 12
            border.color: "#1a4a6e"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                // Title
                Text {
                    text: "— NetOrbit ——————————————————————————————————"
                    color: "#1a8aae"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 9
                    Layout.fillWidth: true
                }

                // World map canvas
                Canvas {
                    id: mapCanvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: 280

                    property real mapX: 0
                    property real mapY: 0
                    property real mapW: width
                    property real mapH: height

                    // Convert lat/lon to canvas coordinates
                    function lonToX(lon) {
                        return (lon + 180) / 360 * mapW
                    }
                    function latToY(lat) {
                        return (90 - lat) / 180 * mapH
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        // Background
                        ctx.fillStyle = "#050a10"
                        ctx.fillRect(0, 0, width, height)

                        // Grid lines
                        ctx.strokeStyle = "#0a1a2a"
                        ctx.lineWidth = 1
                        // Latitude lines
                        for (var lat = -60; lat <= 60; lat += 30) {
                            var y = latToY(lat)
                            ctx.beginPath()
                            ctx.moveTo(0, y)
                            ctx.lineTo(width, y)
                            ctx.stroke()
                        }
                        // Longitude lines
                        for (var lon = -150; lon <= 150; lon += 30) {
                            var x = lonToX(lon)
                            ctx.beginPath()
                            ctx.moveTo(x, 0)
                            ctx.lineTo(x, height)
                            ctx.stroke()
                        }

                        // World map dots (simplified continent outlines)
                        ctx.fillStyle = "#0d2a1a"
                        var landDots = [
                            // North America
                            [-130,60],[-120,60],[-110,60],[-100,60],[-90,60],[-80,60],[-70,60],
                            [-130,55],[-120,55],[-110,55],[-100,55],[-90,55],[-80,55],[-70,55],
                            [-125,50],[-115,50],[-105,50],[-95,50],[-85,50],[-75,50],[-65,50],
                            [-120,45],[-110,45],[-100,45],[-90,45],[-80,45],[-70,45],
                            [-115,40],[-105,40],[-95,40],[-85,40],[-75,40],
                            [-120,35],[-110,35],[-100,35],[-90,35],[-80,35],[-70,35],
                            [-115,30],[-105,30],[-95,30],[-85,30],[-75,30],
                            [-105,25],[-95,25],[-85,25],[-75,25],
                            [-100,20],[-90,20],[-80,20],[-75,20],
                            [-90,15],[-85,15],[-80,15],[-75,15],
                            [-85,10],[-80,10],[-75,10],
                            // South America
                            [-75,5],[-70,5],[-65,5],[-60,5],
                            [-75,0],[-70,0],[-65,0],[-60,0],[-55,0],
                            [-75,-5],[-70,-5],[-65,-5],[-60,-5],[-55,-5],
                            [-70,-10],[-65,-10],[-60,-10],[-55,-10],[-50,-10],
                            [-70,-15],[-65,-15],[-60,-15],[-55,-15],[-50,-15],
                            [-65,-20],[-60,-20],[-55,-20],[-50,-20],[-45,-20],
                            [-60,-25],[-55,-25],[-50,-25],[-45,-25],
                            [-60,-30],[-55,-30],[-50,-30],[-45,-30],
                            [-55,-35],[-50,-35],[-45,-35],
                            [-55,-40],[-50,-40],[-65,-40],
                            [-65,-45],[-70,-45],
                            // Europe
                            [-10,35],[0,35],[10,35],[20,35],
                            [-10,40],[0,40],[10,40],[20,40],[25,40],
                            [-10,45],[0,45],[10,45],[20,45],[25,45],
                            [-5,50],[0,50],[10,50],[15,50],[20,50],[25,50],
                            [-5,55],[0,55],[5,55],[10,55],[15,55],[20,55],[25,55],
                            [0,60],[5,60],[10,60],[15,60],[20,60],[25,60],[30,60],
                            [5,65],[10,65],[15,65],[20,65],[25,65],[28,65],
                            [10,70],[15,70],[20,70],[25,70],
                            // Africa
                            [-10,35],[0,35],[10,35],[20,35],[30,35],
                            [-5,30],[0,30],[10,30],[20,30],[30,30],[35,30],
                            [-5,25],[0,25],[10,25],[20,25],[30,25],[35,25],
                            [0,20],[10,20],[20,20],[30,20],[35,20],[40,20],
                            [5,15],[10,15],[20,15],[30,15],[35,15],[40,15],[45,15],
                            [5,10],[10,10],[20,10],[30,10],[35,10],[40,10],[45,10],
                            [5,5],[10,5],[20,5],[30,5],[35,5],[40,5],
                            [10,0],[20,0],[25,0],[30,0],[35,0],[40,0],
                            [10,-5],[20,-5],[25,-5],[30,-5],[35,-5],
                            [10,-10],[20,-10],[25,-10],[30,-10],[35,-10],
                            [15,-15],[20,-15],[25,-15],[30,-15],[35,-15],
                            [15,-20],[20,-20],[25,-20],[30,-20],[35,-20],
                            [15,-25],[20,-25],[25,-25],[30,-25],[35,-25],
                            [20,-30],[25,-30],[30,-30],
                            [20,-35],[25,-35],[30,-35],
                            // Asia
                            [30,35],[40,35],[50,35],[60,35],[70,35],[80,35],[90,35],[100,35],[110,35],[120,35],
                            [30,40],[40,40],[50,40],[60,40],[70,40],[80,40],[90,40],[100,40],[110,40],[120,40],[130,40],
                            [40,45],[50,45],[60,45],[70,45],[80,45],[90,45],[100,45],[110,45],[120,45],[130,45],
                            [40,50],[50,50],[60,50],[70,50],[80,50],[90,50],[100,50],[110,50],[120,50],[130,50],[140,50],
                            [40,55],[50,55],[60,55],[70,55],[80,55],[90,55],[100,55],[110,55],[120,55],[130,55],[140,55],
                            [60,60],[70,60],[80,60],[90,60],[100,60],[110,60],[120,60],[130,60],[140,60],
                            [60,65],[70,65],[80,65],[90,65],[100,65],[110,65],[120,65],[130,65],
                            [60,70],[70,70],[80,70],[90,70],[100,70],[110,70],[120,70],
                            // Southeast Asia
                            [100,20],[105,20],[110,20],[115,20],[120,20],
                            [100,15],[105,15],[110,15],[115,15],[120,15],
                            [100,10],[105,10],[110,10],[115,10],[120,10],[125,10],
                            [105,5],[110,5],[115,5],[120,5],[125,5],
                            [110,0],[115,0],[120,0],[125,0],[130,0],
                            [115,-5],[120,-5],[125,-5],[130,-5],
                            // Japan/Korea
                            [130,35],[135,35],[140,35],[145,35],
                            [130,40],[135,40],[140,40],[145,40],
                            // Australia
                            [115,-25],[120,-25],[125,-25],[130,-25],[135,-25],[140,-25],[145,-25],[150,-25],
                            [115,-30],[120,-30],[125,-30],[130,-30],[135,-30],[140,-30],[145,-30],[150,-30],
                            [120,-35],[125,-35],[130,-35],[135,-35],[140,-35],[145,-35],[150,-35],
                            [125,-40],[130,-40],[135,-40],[140,-40],[145,-40],[150,-40],
                            [130,-45],[135,-45],[140,-45],[145,-45],
                        ]

                        for (var i = 0; i < landDots.length; i++) {
                            var dx = lonToX(landDots[i][0])
                            var dy = latToY(landDots[i][1])
                            ctx.fillRect(dx-2, dy-2, 4, 4)
                        }

                        // Draw home location (Waltham MA)
                        var homeX = lonToX(-71.24)
                        var homeY = latToY(42.38)
                        ctx.beginPath()
                        ctx.arc(homeX, homeY, 4, 0, Math.PI * 2)
                        ctx.fillStyle = "#00ff88"
                        ctx.fill()

                        // Draw connections
                        var colors = ["#00ccff", "#00ffcc", "#ffcc00", "#ff6600", "#cc00ff", "#ff0066"]
                        for (var i = 0; i < netorbitPanel.connections.length; i++) {
                            var conn = netorbitPanel.connections[i]
                            var destX = lonToX(conn.lon)
                            var destY = latToY(conn.lat)
                            var alpha = 1.0 - (i / netorbitPanel.connections.length) * 0.7
                            var color = colors[i % colors.length]

                            // Draw arc line from home to destination
                            ctx.beginPath()
                            ctx.moveTo(homeX, homeY)

                            // Control point for arc
                            var cpX = (homeX + destX) / 2
                            var cpY = Math.min(homeY, destY) - 40
                            ctx.quadraticCurveTo(cpX, cpY, destX, destY)
                            ctx.strokeStyle = color
                            ctx.globalAlpha = alpha * 0.6
                            ctx.lineWidth = 1
                            ctx.stroke()

                            // Draw destination dot
                            ctx.beginPath()
                            ctx.arc(destX, destY, i === 0 ? 5 : 3, 0, Math.PI * 2)
                            ctx.fillStyle = color
                            ctx.globalAlpha = alpha
                            ctx.fill()

                            // Pulse ring on most recent
                            if (i === 0) {
                                ctx.beginPath()
                                ctx.arc(destX, destY, 8, 0, Math.PI * 2)
                                ctx.strokeStyle = color
                                ctx.globalAlpha = 0.3
                                ctx.lineWidth = 2
                                ctx.stroke()
                            }
                        }

                        ctx.globalAlpha = 1.0
                    }
                }

                // Separator
                Text {
                    text: "— Last 10 connections ————————————————————————"
                    color: "#1a8aae"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 9
                    Layout.fillWidth: true
                }

                // Scrolling ticker
                Rectangle {
                    Layout.fillWidth: true
                    height: 20
                    color: "#050a10"
                    clip: true

                    property string tickerContent: ""

                    // Update text only when animation completes a cycle
                    Connections {
                        target: netorbitPanel
                        function onConnectionsChanged() {
                            tickerText.pendingText = netorbitPanel.connections.map(c =>
                                "  ◆  " + c.ip + "  " + c.country + (c.city ? " / " + c.city : "") + "  [" + c.size + "B]"
                            ).join("")
                            if (!tickerAnim.running) {
                                tickerText.text = tickerText.pendingText
                                tickerAnim.restart()
                            }
                        }
                    }

                    Text {
                        id: tickerText
                        property string pendingText: ""
                        text: "  Listening for connections..."
                        color: "#00ccff"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width

                        NumberAnimation {
                            id: tickerAnim
                            target: tickerText
                            property: "x"
                            from: tickerText.parent.width
                            to: -tickerText.implicitWidth
                            duration: tickerText.implicitWidth * 15
                            loops: 1
                            running: false
                            onStopped: {
                                // When animation finishes, load pending text and restart
                                if (tickerText.pendingText !== "") {
                                    tickerText.text = tickerText.pendingText
                                    tickerText.pendingText = ""
                                }
                                tickerAnim.from = tickerText.parent.width
                                tickerAnim.to = -tickerText.implicitWidth
                                tickerAnim.duration = tickerText.implicitWidth * 15
                                tickerAnim.start()
                            }
                        }

                        Component.onCompleted: {
                            tickerAnim.from = parent.width
                            tickerAnim.to = -implicitWidth
                            tickerAnim.duration = 8000
                            tickerAnim.start()
                        }
                    }
                }

                // Status bar
                Text {
                    text: "— Status ————————————————————————————————————"
                    color: "#1a8aae"
                    font.family: "Maple Mono NF"
                    font.pixelSize: 9
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 20
                    Text {
                        text: "captured=" + netorbitPanel.captured
                        color: "#00ff88"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 9
                        font.bold: true
                    }
                    Text {
                        text: "mapped=" + netorbitPanel.mapped
                        color: "#ffcc00"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 9
                        font.bold: true
                    }
                    Text {
                        text: "Listening on: enp4s0"
                        color: "#8a7d6e"
                        font.family: "Maple Mono NF"
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}