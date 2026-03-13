import QtQuick
import QtQuick3D

Item {
    id: root
    anchors.fill: parent

    property var dice2dItems: []
    property bool d6AnimationActive: false
    property real cubeY: 90
    property real cubeRotX: -240
    property real cubeRotY: 20
    property real cubeRotZ: 40
    property bool useProxyFallback: true
    property bool d6ProxyVisible: false
    property real d6ProxyY: -140
    property real d6ProxyRot: -120
    property real d6ProxyScale: 0.72

    function trigger2D(diceList) {
        if (!diceList || diceList.length === 0) {
            return
        }
        var items = []
        var baseY = Math.max(120, root.height * 0.34)
        var maxPerRow = Math.max(1, Math.floor((root.width - 120) / 86))
        var rowCount = Math.ceil(diceList.length / maxPerRow)
        var firstRowCount = Math.min(maxPerRow, diceList.length)
        var startX = Math.max(60, (root.width - (firstRowCount * 86)) / 2)
        for (var i = 0; i < diceList.length; i++) {
            var row = Math.floor(i / maxPerRow)
            var col = i % maxPerRow
            items.push({
                "uid": Date.now() + i,
                "sides": Number(diceList[i]),
                "targetX": startX + col * 86,
                "targetY": baseY + row * 86,
                "startRot": (Math.random() * 220) - 110,
                "endRot": (Math.random() * 36) - 18
            })
        }
        dice2dItems = items
        clear2dTimer.restart()
    }

    function triggerD6() {
        console.log("[dice-visual] triggerD6")
        d6AnimationActive = true
        if (useProxyFallback) {
            d6ProxyVisible = true
            d6ProxyY = -140
            d6ProxyRot = -120
            d6ProxyScale = 0.72
        } else {
            d6ProxyVisible = false
        }
        cubeY = 130
        cubeRotX = -320
        cubeRotY = 30
        cubeRotZ = 60
        if (!useProxyFallback) {
            d6DropAnim.restart()
            d6RotXAnim.restart()
            d6RotYAnim.restart()
            d6RotZAnim.restart()
        }
        if (useProxyFallback) {
            d6ProxyDropAnim.restart()
            d6ProxyRotAnim.restart()
            d6ProxyScaleAnim.restart()
        }
        d6FinishTimer.restart()
    }

    function clearAll() {
        dice2dItems = []
        d6AnimationActive = false
        d6ProxyVisible = false
    }

    Item {
        id: dice2dOverlay
        anchors.fill: parent
        visible: root.dice2dItems.length > 0
        z: 1

        Repeater {
            model: root.dice2dItems
            delegate: Item {
                required property var modelData
                width: 72
                height: 72
                x: modelData.targetX
                y: -130
                rotation: modelData.startRot
                opacity: 0.0

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: "#343A46"
                    border.width: 2
                    border.color: "#C7D2EB"
                }

                Text {
                    anchors.centerIn: parent
                    text: "d" + String(modelData.sides)
                    color: "#F0F2F8"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }

                SequentialAnimation on opacity {
                    running: true
                    NumberAnimation { to: 1.0; duration: 110 }
                    PauseAnimation { duration: 1600 }
                    NumberAnimation { to: 0.0; duration: 320 }
                }

                SequentialAnimation on y {
                    running: true
                    NumberAnimation {
                        to: modelData.targetY
                        duration: 760
                        easing.type: Easing.OutBounce
                    }
                    PauseAnimation { duration: 520 }
                }

                NumberAnimation on rotation {
                    running: true
                    to: modelData.endRot
                    duration: 1100
                    easing.type: Easing.OutCubic
                }

                NumberAnimation on scale {
                    running: true
                    from: 0.75
                    to: 1.0
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }

        Timer {
            id: clear2dTimer
            interval: 2600
            repeat: false
            onTriggered: root.dice2dItems = []
        }
    }

    Item {
        id: d6Overlay
        anchors.fill: parent
        visible: root.d6AnimationActive
        z: 2

        View3D {
            visible: !root.useProxyFallback
            anchors.fill: parent
            camera: d6Camera
            environment: SceneEnvironment {
                backgroundMode: SceneEnvironment.Transparent
                antialiasingMode: SceneEnvironment.MSAA
                antialiasingQuality: SceneEnvironment.High
            }

            PerspectiveCamera {
                id: d6Camera
                position: Qt.vector3d(0, 10, 180)
                eulerRotation: Qt.vector3d(-2, 0, 0)
                clipNear: 1
                clipFar: 2000
            }

            DirectionalLight {
                eulerRotation: Qt.vector3d(-45, -25, 0)
                brightness: 40
            }

            PointLight {
                position: Qt.vector3d(0, 90, 180)
                brightness: 36
            }

            Model {
                id: d6Cube
                source: "#Cube"
                position: Qt.vector3d(0, root.cubeY, 0)
                eulerRotation: Qt.vector3d(root.cubeRotX, root.cubeRotY, root.cubeRotZ)
                scale: Qt.vector3d(46, 46, 46)
                materials: DefaultMaterial {
                    diffuseColor: "#FFFFFF"
                }
            }
        }


        Item {
            id: d6Proxy
            visible: root.useProxyFallback && root.d6ProxyVisible
            width: 112
            height: 112
            x: (root.width - width) * 0.5
            y: root.d6ProxyY
            rotation: root.d6ProxyRot
            scale: root.d6ProxyScale
            opacity: root.d6ProxyVisible ? 1 : 0

            Rectangle {
                id: faceFront
                x: 26
                y: 34
                width: 58
                height: 58
                radius: 8
                color: "#DDE2EE"
                border.width: 2
                border.color: "#A5AEC4"
            }

            Rectangle {
                id: faceTop
                x: 35
                y: 18
                width: 58
                height: 30
                color: "#F1F4FA"
                border.width: 1
                border.color: "#B9C2D8"
                transform: [
                    Rotation { origin.x: 0; origin.y: faceTop.height; angle: -20; axis { x: 1; y: 0; z: 0 } },
                    Rotation { origin.x: 0; origin.y: faceTop.height; angle: -28; axis { x: 0; y: 0; z: 1 } }
                ]
            }

            Rectangle {
                id: faceSide
                x: 80
                y: 35
                width: 26
                height: 58
                color: "#C8D0E2"
                border.width: 1
                border.color: "#99A4BE"
                transform: Rotation { origin.x: 0; origin.y: 0; angle: -25; axis { x: 0; y: 0; z: 1 } }
            }

            Text {
                anchors.centerIn: faceFront
                text: "6"
                color: "#2A2F3A"
                font.pixelSize: 26
                font.weight: Font.Black
            }

            Rectangle {
                id: shadow
                width: 72
                height: 16
                radius: 8
                color: "#000000"
                opacity: 0.22
                x: 22
                y: 92
                scale: 1.0 + Math.max(0, (92 - d6Proxy.y) / 220)
            }
        }

        NumberAnimation {
            id: d6DropAnim
            target: root
            property: "cubeY"
            from: 130
            to: -20
            duration: 940
            easing.type: Easing.OutBounce
        }

        NumberAnimation {
            id: d6RotXAnim
            target: root
            property: "cubeRotX"
            from: -320
            to: 0
            duration: 940
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: d6RotYAnim
            target: root
            property: "cubeRotY"
            from: 30
            to: 280
            duration: 940
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: d6RotZAnim
            target: root
            property: "cubeRotZ"
            from: 60
            to: 12
            duration: 940
            easing.type: Easing.OutCubic
        }


        NumberAnimation {
            id: d6ProxyDropAnim
            target: root
            property: "d6ProxyY"
            from: -140
            to: 210
            duration: 980
            easing.type: Easing.OutBounce
        }

        NumberAnimation {
            id: d6ProxyRotAnim
            target: root
            property: "d6ProxyRot"
            from: -120
            to: -6
            duration: 980
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: d6ProxyScaleAnim
            target: root
            property: "d6ProxyScale"
            from: 0.72
            to: 1.0
            duration: 380
            easing.type: Easing.OutCubic
        }

        Timer {
            id: d6FinishTimer
            interval: 1900
            repeat: false
            onTriggered: {
                root.d6AnimationActive = false
                root.d6ProxyVisible = false
            }
        }
    }
}
