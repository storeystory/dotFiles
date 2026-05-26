import Quickshell
import Quickshell.Wayland
import QtQuick

Variants {
    model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

    PanelWindow {
        id: rainPanel
        property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "rain"

        color: "transparent"

        Canvas {
            id: rainCanvas
            anchors.fill: parent

            property var drops: []
            property var lightning: null
            property int lightningTimer: 0
            property var chars: [
                "ﾊ","ﾐ","ﾋ","ｰ","ｳ","ｼ","ﾅ","ﾓ","ﾆ","ｻ","ﾜ","ﾂ","ｵ","ﾘ","ｱ","ﾎ","ﾃ","ﾏ","ｹ","ﾒ","ｴ","ｶ","ｷ","ﾑ","ﾕ","ﾗ","ｾ","ﾈ","ｽ","ﾀ","ﾇ","ﾍ",
                "・","ｦ","ɐ","ｲ","ｸ","ｺ","ｿ","ﾁ","ﾄ","ﾉ","ﾌ","ﾔ","ﾖ","ﾙ","ﾚ","ﾛ","ﾝ","0","1","2","3","4","5","7","8","9","Z","T","H"
            ]

            property int colWidth: 16
            property int fontSize: 14

            Component.onCompleted: {
                initDrops()
            }

            function initDrops() {
                drops = []
                var cols = Math.floor(width / colWidth)
                for (var i = 0; i < cols; i++) {
                    drops.push({
                        x: i * colWidth,
                        y: -Math.random() * height,
                        speed: 2 + Math.random() * 4,
                        length: 10 + Math.floor(Math.random() * 20),
                        chars: [],
                        opacity: 0.3 + Math.random() * 0.5
                    })
                    // initialize chars for each drop
                    for (var j = 0; j < 30; j++) {
                        drops[i].chars.push(rainCanvas.chars[Math.floor(Math.random() * rainCanvas.chars.length)])
                    }
                }
            }

            // Pre-generate lightning off the paint cycle
            property var pendingLightning: null

            function generateLightning() {
                var segs = []
                var x = Math.random() * width
                var y = 0
                while (y < height * 0.7) {
                    var nx = x + (Math.random() - 0.5) * 80
                    var ny = y + 30 + Math.random() * 40
                    segs.push({x1: x, y1: y, x2: nx, y2: ny})
                    x = nx
                    y = ny
                }
                pendingLightning = {
                    x: segs[0].x1,
                    segments: segs,
                    alpha: 1.0
                }
                lightningTimer = 8
            }

            function triggerLightning() {
                lightning = {
                    x: Math.random() * width,
                    segments: [],
                    alpha: 1.0
                }
                var x = lightning.x
                var y = 0
                while (y < height * 0.7) {
                    var nx = x + (Math.random() - 0.5) * 80
                    var ny = y + 30 + Math.random() * 40
                    lightning.segments.push({x1: x, y1: y, x2: nx, y2: ny})
                    x = nx
                    y = ny
                }
                lightningTimer = 8
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // Draw lightning
                if (pendingLightning && lightningTimer > 0) {
                    ctx.save()
                    ctx.globalAlpha = lightningTimer / 8
                    ctx.strokeStyle = "#ffffff"
                    ctx.shadowColor = "#aaaaff"
                    ctx.shadowBlur = 15
                    ctx.lineWidth = 1.5
                    for (var s = 0; s < pendingLightning.segments.length; s++) {
                        var seg = pendingLightning.segments[s]
                        ctx.beginPath()
                        ctx.moveTo(seg.x1, seg.y1)
                        ctx.lineTo(seg.x2, seg.y2)
                        ctx.stroke()
                    }
                    ctx.restore()
                    lightningTimer--
                    if (lightningTimer <= 0) pendingLightning = null
                }

                // Draw rain drops
                ctx.font = fontSize + "px 'Maple Mono NF'"
                for (var i = 0; i < drops.length; i++) {
                    var drop = drops[i]

                    for (var j = 0; j < drop.length; j++) {
                        var charY = drop.y - j * fontSize
                        if (charY < 0 || charY > height) continue

                        var alpha
                        if (j === 0) {
                            // head of drop - bright white
                            ctx.fillStyle = "#ffffff"
                            alpha = drop.opacity
                        } else if (j < 3) {
                            // near head - bright purple
                            ctx.fillStyle = "#AC82E9"
                            alpha = drop.opacity * (1 - j * 0.15)
                        } else {
                            // tail - dimmer purple
                            ctx.fillStyle = "#4a2d7a"
                            alpha = drop.opacity * (1 - j / drop.length) * 0.7
                        }

                        ctx.globalAlpha = alpha
                        var charIdx = (Math.floor(drop.y / fontSize) + j) % drop.chars.length
                        ctx.fillText(drop.chars[charIdx], drop.x, charY)
                    }

                    // advance drop
                    drop.y += drop.speed

                    // reset when off screen
                    if (drop.y - drop.length * fontSize > height) {
                        drop.y = -Math.random() * 100
                        drop.speed = 2 + Math.random() * 4
                        drop.opacity = 0.3 + Math.random() * 0.5
                    }

                    // randomly change chars
                    if (Math.random() < 0.05) {
                        var idx = Math.floor(Math.random() * drop.chars.length)
                        drop.chars[idx] = rainCanvas.chars[Math.floor(Math.random() * rainCanvas.chars.length)]
                    }
                }

                ctx.globalAlpha = 1.0
            }

            Timer {
                interval: 33 // ~30fps
                running: true
                repeat: true
                onTriggered: {
                    rainCanvas.requestPaint()
                }
            }

            // Lightning timer - random strikes
            Timer {
                id: lightningTrigger
                interval: 5000
                running: true
                repeat: true
                onTriggered: {
                    if (Math.random() < 0.4) {
                        rainCanvas.generateLightning()
                    }
                    // Randomize next interval
                    interval = 3000 + Math.floor(Math.random() * 7000)
                }
            }

            onWidthChanged: initDrops()
            onHeightChanged: initDrops()
        }
    }
}