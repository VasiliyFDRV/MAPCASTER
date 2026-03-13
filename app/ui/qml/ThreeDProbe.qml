import QtQuick
import QtQuick.Window
import QtQuick3D

Window {
    id: probeWindow
    width: 900
    height: 600
    visible: true
    color: "#101114"
    title: "MAPCASTER 3D Probe"

    Rectangle {
        anchors.fill: parent
        color: "#16181d"
    }

    View3D {
        id: view3d
        anchors.fill: parent
        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }
        camera: cam

        PerspectiveCamera {
            id: cam
            position: Qt.vector3d(0, 0, 300)
            eulerRotation: Qt.vector3d(0, 0, 0)
            clipNear: 1
            clipFar: 5000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, -30, 0)
            brightness: 45
        }

        PointLight {
            position: Qt.vector3d(0, 80, 220)
            brightness: 40
        }

        Model {
            id: cube
            source: "#Cube"
            scale: Qt.vector3d(60, 60, 60)
            materials: DefaultMaterial {
                diffuseColor: "#FFFFFF"
            }
        }

        NumberAnimation {
            target: cube
            property: "eulerRotation.y"
            running: true
            from: 0
            to: 360
            duration: 2400
            loops: Animation.Infinite
        }

        NumberAnimation {
            target: cube
            property: "eulerRotation.x"
            running: true
            from: 0
            to: 360
            duration: 3600
            loops: Animation.Infinite
        }
    }


    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        color: "#E8EAEE"
        font.pixelSize: 14
        text: "3D Probe: если виден вращающийся белый куб, QtQuick3D работает"
    }
}
