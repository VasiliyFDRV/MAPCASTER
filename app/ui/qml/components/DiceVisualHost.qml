import QtQuick
import "neumo"

Item {
    id: root

    property alias overlayZ: diceWebOverlay.z
    property alias fallbackOverlayZ: mapDiceOverlay.z
    property string visualTarget: "map"
    property bool includeFallback2D: true
    property var neumoTheme: null

    function shouldUseStandardPhysicsVisual(payload) {
        if (!payload || payload.kind !== "standard") {
            return false
        }
        if (!payload.request_id || Number(payload.request_id) <= 0) {
            return false
        }
        if (!payload.dice || payload.dice.length <= 0) {
            return false
        }
        for (var i = 0; i < payload.dice.length; i++) {
            var s = Number(payload.dice[i])
            if (s !== 4 && s !== 6 && s !== 8 && s !== 10 && s !== 12) {
                return false
            }
        }
        return true
    }

    function shouldUseD20PhysicsVisual(payload) {
        if (!payload || payload.kind !== "d20") {
            return false
        }
        if (!payload.request_id || Number(payload.request_id) <= 0) {
            return false
        }
        if (!payload.dice || payload.dice.length <= 0) {
            return false
        }
        for (var i = 0; i < payload.dice.length; i++) {
            if (Number(payload.dice[i]) !== 20) {
                return false
            }
        }
        return true
    }

    function shouldUseD100PhysicsVisual(payload) {
        if (!payload || payload.kind !== "d100") {
            return false
        }
        if (!payload.request_id || Number(payload.request_id) <= 0) {
            return false
        }
        if (!payload.dice || payload.dice.length !== 2) {
            return false
        }
        return Number(payload.dice[0]) === 10 && Number(payload.dice[1]) === 10
    }

    function pushDiceStylesToOverlay() {
        if (!diceWebOverlay || !diceWebOverlay.setStyleBag) {
            return
        }
        var bag = {}
        if (typeof appController !== "undefined" && appController && appController.diceStyles) {
            bag = appController.diceStyles
        }
        diceWebOverlay.setStyleBag(bag)
    }

    function shouldAcceptVisualPayload(payload) {
        if (!payload) {
            return false
        }
        var target = String(payload.target || "map")
        return target === String(visualTarget || "map")
    }

    function shouldAcceptClearPayload(payload) {
        if (!payload || payload.target === undefined || payload.target === null || payload.target === "") {
            return true
        }
        return String(payload.target) === String(visualTarget || "map")
    }

    function clearVisuals() {
        diceWebOverlay.clear()
        if (includeFallback2D && mapDiceOverlay) {
            mapDiceOverlay.clearAll()
        }
    }

    function triggerVisualPayload(payload) {
        if (!payload || !payload.dice) {
            return
        }
        pushDiceStylesToOverlay()
        if (shouldUseD100PhysicsVisual(payload)) {
            console.log("[dice-visual] " + visualTarget + " -> 3d d100 2xd10")
            diceWebOverlay.triggerD100(Number(payload.request_id || 0))
        } else if (shouldUseD20PhysicsVisual(payload)) {
            console.log("[dice-visual] " + visualTarget + " -> 3d d20", "count=" + payload.dice.length)
            diceWebOverlay.triggerD20Batch(
                Number(payload.request_id || 0),
                Number(payload.dice.length || 0),
                Boolean(payload.append),
                String(payload.d20_mode || "normal")
            )
        } else if (shouldUseStandardPhysicsVisual(payload)) {
            var d4Count = 0
            var d6Count = 0
            var d8Count = 0
            var d10Count = 0
            var d12Count = 0
            for (var i = 0; i < payload.dice.length; i++) {
                var sides = Number(payload.dice[i])
                if (sides === 4) {
                    d4Count += 1
                } else if (sides === 6) {
                    d6Count += 1
                } else if (sides === 8) {
                    d8Count += 1
                } else if (sides === 10) {
                    d10Count += 1
                } else if (sides === 12) {
                    d12Count += 1
                }
            }
            console.log("[dice-visual] " + visualTarget + " -> 3d standard", "d4=" + d4Count, "d6=" + d6Count, "d8=" + d8Count, "d10=" + d10Count, "d12=" + d12Count)
            diceWebOverlay.triggerStandardBatch(
                Number(payload.request_id || 0),
                Number(d4Count || 0),
                Number(d6Count || 0),
                Number(d8Count || 0),
                Number(d10Count || 0),
                Number(d12Count || 0),
                Boolean(payload.append)
            )
        } else if (includeFallback2D && mapDiceOverlay) {
            console.log("[dice-visual] " + visualTarget + " -> 2d", payload.dice.length)
            mapDiceOverlay.trigger2D(payload.dice)
        }
    }

    DiceWebOverlay {
        id: diceWebOverlay
        anchors.fill: parent
        z: 1
    }

    MapDiceOverlay {
        id: mapDiceOverlay
        anchors.fill: parent
        z: 0
        visible: includeFallback2D
    }

    Connections {
        target: appController
        function onSettingsChanged() {
            root.pushDiceStylesToOverlay()
        }
    }

    Connections {
        target: diceWebOverlay
        function onD6BatchResultReady(requestId, values) {
            console.log("[dice-ui-debug] " + visualTarget + " onD6BatchResultReady request=" + requestId + " values=" + JSON.stringify(values))
            if (requestId > 0 && values && values.length > 0) {
                diceController.submit_physics_d6_batch_result(requestId, values)
            }
        }
        function onStandardBatchResultReady(requestId, sides, values) {
            console.log("[dice-ui-debug] " + visualTarget + " onStandardBatchResultReady request=" + requestId + " sides=" + sides + " values=" + JSON.stringify(values))
            if (requestId > 0 && sides > 0 && values && values.length > 0) {
                diceController.submit_physics_standard_batch_result(requestId, sides, values)
            }
        }
        function onD20BatchResultReady(requestId, values) {
            console.log("[dice-ui-debug] " + visualTarget + " onD20BatchResultReady request=" + requestId + " values=" + JSON.stringify(values))
            if (requestId > 0 && values && values.length > 0) {
                diceController.submit_physics_d20_batch_result(requestId, values)
            }
        }
        function onD100ResultReady(requestId, tensValue, onesValue) {
            console.log("[dice-ui-debug] " + visualTarget + " onD100ResultReady request=" + requestId + " tens=" + tensValue + " ones=" + onesValue)
            if (requestId > 0) {
                diceController.submit_physics_d100_result(requestId, Number(tensValue), Number(onesValue))
            }
        }
    }

    Connections {
        target: eventBus
        function handleBusEvent(eventName, payload) {
            if (eventName === "dice.visual.clear_requested") {
                if (root.shouldAcceptClearPayload(payload)) {
                    root.clearVisuals()
                }
                return
            }
            if (eventName !== "dice.visual_roll_requested") {
                return
            }
            if (!root.shouldAcceptVisualPayload(payload)) {
                return
            }
            root.triggerVisualPayload(payload)
        }
        function onEventEmitted(eventName, payload) {
            handleBusEvent(eventName, payload)
        }
    }

    Component.onCompleted: pushDiceStylesToOverlay()
}
