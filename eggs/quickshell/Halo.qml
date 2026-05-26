import Quickshell
import Quickshell.Wayland
import QtQuick

Variants {
    model: Quickshell.screens.filter(s => s.name === "DP-1")

    PanelWindow {
        id: haloPanel
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
        WlrLayershell.namespace: "halo"

        color: "transparent"

        Canvas {
            id: haloCanvas
            anchors.fill: parent

            property var particles: []
            property real time: 0
            property int numParticles: 800
            property bool initialized: false
            property var perm: []

            Component.onCompleted: {
                initNoise()
                initParticles()
                initialized = true
            }

            function initNoise() {
                var p = []
                for (var i = 0; i < 256; i++) p.push(i)
                for (var i = 255; i > 0; i--) {
                    var j = Math.floor(Math.random() * (i + 1))
                    var tmp = p[i]; p[i] = p[j]; p[j] = tmp
                }
                perm = []
                for (var i = 0; i < 512; i++) perm.push(p[i & 255])
            }

            function fade(t) { return t * t * t * (t * (t * 6 - 15) + 10) }
            function lerp(a, b, t) { return a + t * (b - a) }

            function grad(hash, x, y) {
                var h = hash & 3
                var u = h < 2 ? x : y
                var v = h < 2 ? y : x
                return ((h & 1) ? -u : u) + ((h & 2) ? -v : v)
            }

            function noise(x, y) {
                var xi = Math.floor(x) & 255
                var yi = Math.floor(y) & 255
                var xf = x - Math.floor(x)
                var yf = y - Math.floor(y)
                var u = fade(xf)
                var v = fade(yf)
                var aa = perm[perm[xi] + yi]
                var ab = perm[perm[xi] + yi + 1]
                var ba = perm[perm[xi + 1] + yi]
                var bb = perm[perm[xi + 1] + yi + 1]
                return lerp(
                    lerp(grad(aa, xf, yf), grad(ba, xf - 1, yf), u),
                    lerp(grad(ab, xf, yf - 1), grad(bb, xf - 1, yf - 1), u),
                    v
                )
            }

            function flowAngle(x, y, t) {
                var scale = 0.002
                var n = noise(x * scale + t * 0.2, y * scale + t * 0.15)
                var n2 = noise(x * scale + 200 + t * 0.1, y * scale + 200 + t * 0.2)
                return (n + n2) * Math.PI * 3
            }

            function initParticles() {
                particles = []
                for (var i = 0; i < numParticles; i++) {
                    particles.push({
                        x: Math.random() * width,
                        y: Math.random() * height,
                        vx: 0,
                        vy: 0,
                        life: Math.random(),
                        maxLife: 0.5 + Math.random() * 0.5,
                        speed: 0.5 + Math.random() * 1.5,
                        hue: Math.random() < 0.5
                            ? Math.random() * 30          // reds to oranges
                            : 30 + Math.random() * 30,    // oranges to yellows
                        size: 1 + Math.random() * 2
                    })
                }
            }

            function hueToRgb(hue) {
                // Convert sunset hues (0-60) to RGB strings
                // 0 = red, 15 = orange-red, 30 = orange, 45 = amber, 60 = yellow
                var r, g, b
                if (hue < 15) {
                    // red to orange-red
                    r = 255
                    g = Math.round(hue / 15 * 80)
                    b = 0
                } else if (hue < 30) {
                    // orange-red to orange
                    r = 255
                    g = Math.round(80 + (hue - 15) / 15 * 90)
                    b = 0
                } else if (hue < 45) {
                    // orange to amber
                    r = 255
                    g = Math.round(170 + (hue - 30) / 15 * 60)
                    b = 0
                } else {
                    // amber to yellow
                    r = 255
                    g = Math.round(230 + (hue - 45) / 15 * 25)
                    b = 0
                }
                return "rgb(" + r + "," + g + "," + b + ")"
            }

            onPaint: {
                if (!initialized) return
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                time += 0.005

                for (var i = 0; i < particles.length; i++) {
                    var p = particles[i]
                    var color = hueToRgb(p.hue)
                    
                    var angle = flowAngle(p.x, p.y, time)
                    p.vx = p.vx * 0.92 + Math.cos(angle) * p.speed * 0.5
                    p.vy = p.vy * 0.92 + Math.sin(angle) * p.speed * 0.5
                    p.x += p.vx
                    p.y += p.vy
                    p.life += 0.003

                    var speed = Math.sqrt(p.vx * p.vx + p.vy * p.vy)
                    var alpha = Math.sin(p.life / p.maxLife * Math.PI) * 0.7
                    var lightness = 55 + speed * 8

                    // Core particle
                    ctx.globalAlpha = alpha
                    ctx.beginPath()
                    ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
                    ctx.fillStyle = color
                    ctx.fill()

                    // Glow
                    ctx.globalAlpha = alpha * 0.3
                    ctx.beginPath()
                    ctx.arc(p.x, p.y, p.size * 4, 0, Math.PI * 2)
                    ctx.fillStyle = color
                    ctx.fill()

                    if (p.x < -10 || p.x > width + 10 || p.y < -10 || p.y > height + 10 || p.life > p.maxLife) {
                        p.x = Math.random() * width
                        p.y = Math.random() * height
                        p.vx = 0
                        p.vy = 0
                        p.life = 0
                        p.maxLife = 0.5 + Math.random() * 0.5
                        p.hue = Math.random() < 0.5 ? Math.random() * 30 : 30 + Math.random() * 30
                        p.speed = 0.5 + Math.random() * 1.5
                        p.size = 1 + Math.random() * 2
                    }
                }
                ctx.globalAlpha = 1.0
            }

            Timer {
                interval: 33
                running: true
                repeat: true
                onTriggered: haloCanvas.requestPaint()
            }

            onWidthChanged: if (initialized) initParticles()
            onHeightChanged: if (initialized) initParticles()
        }
    }
}