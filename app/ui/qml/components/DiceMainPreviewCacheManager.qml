import QtQuick
import QtWebEngine
import "DiceMainPreviewCacheStore.js" as DiceMainPreviewCacheStore
import "DicePreviewUtils.js" as DicePreviewUtils

Item {
    id: manager
    visible: true
    opacity: 0.0
    x: -10000
    y: -10000
    width: 1
    height: 1

    property var dieStyles: ({})
    property var dieTypes: (["d4", "d6", "d8", "d10", "d12", "d20", "d100"])
    property int poseVersion: 1
    property url cacheDirUrl: ""
    property bool renderingEnabled: false
    property bool prewarmEnabled: false
    property var activeEntries: ({})
    property var expectedEntries: ({})
    property int observedStoreRevision: -1
    property bool snapshotWebReady: false
    property bool snapshotBusy: false
    property var snapshotCurrentTask: null

    function normalizeDieType(dieType) {
        return String(dieType || "d6").toLowerCase()
    }

    function styleForDie(dieType) {
        var key = normalizeDieType(dieType)
        return DicePreviewUtils.cloneStyle(dieStyles && dieStyles[key] ? dieStyles[key] : null)
    }

    function hashText(text) {
        var src = String(text || "")
        var hash = 2166136261
        for (var i = 0; i < src.length; ++i) {
            hash ^= src.charCodeAt(i)
            hash = Math.imul(hash, 16777619)
        }
        var value = (hash >>> 0).toString(16)
        while (value.length < 8) {
            value = "0" + value
        }
        return value
    }

    function cacheFileUrlForKey(cacheKey) {
        var base = String(cacheDirUrl || "")
        if (!base.length) {
            return ""
        }
        if (base.charAt(base.length - 1) !== "/") {
            base += "/"
        }
        return base + hashText(cacheKey) + ".png"
    }

    function localPathFromUrl(urlValue) {
        var text = String(urlValue || "")
        if (text.indexOf("file:///") === 0) {
            return decodeURIComponent(text.substring(8))
        }
        if (text.indexOf("file://") === 0) {
            return decodeURIComponent(text.substring(7))
        }
        return text
    }

    function readySourceUrl(sourceUrl) {
        return String(sourceUrl || "")
    }


    function assignActiveEntry(dieType, cacheKey, sourceUrl) {
        var key = normalizeDieType(dieType)
        var next = Object.assign({}, activeEntries || {})
        next[key] = {
            "key": String(cacheKey || ""),
            "source": String(sourceUrl || "")
        }
        activeEntries = next
    }

    function ensureExpectedEntry(dieType) {
        var key = normalizeDieType(dieType)
        var style = styleForDie(key)
        var spec = DicePreviewUtils.resolveMainPreviewSpec(key, style)
        var cacheKey = DicePreviewUtils.buildMainPreviewSnapshotKey(key, style, poseVersion)
        var fileUrl = cacheFileUrlForKey(cacheKey)
        var nextExpected = Object.assign({}, expectedEntries || {})
        nextExpected[key] = {
            "dieType": key,
            "key": cacheKey,
            "modelKind": spec.modelKind,
            "payload": spec.payload,
            "fileUrl": fileUrl
        }
        expectedEntries = nextExpected

        var readySource = DiceMainPreviewCacheStore.readySourceForKey(cacheKey)
        if (readySource.length > 0) {
            assignActiveEntry(key, cacheKey, readySourceUrl(readySource))
        } else {
            DiceMainPreviewCacheStore.requestTask({
                "key": cacheKey,
                "dieType": key,
                "modelKind": spec.modelKind,
                "payload": spec.payload,
                "fileUrl": fileUrl
            })
        }

        if (renderingEnabled) {
            processQueue()
        }
    }

    function prewarmAll() {
        for (var i = 0; i < dieTypes.length; ++i) {
            ensureExpectedEntry(dieTypes[i])
        }
    }

    function invalidateDie(dieType) {
        ensureExpectedEntry(dieType)
    }

    function ensureSnapshotForDie(dieType) {
        ensureExpectedEntry(dieType)
    }

    function snapshotSourceForDie(dieType) {
        var key = normalizeDieType(dieType)
        var entry = activeEntries && activeEntries[key] ? activeEntries[key] : null
        return entry && entry.source ? String(entry.source) : ""
    }

    function snapshotReadyForDie(dieType) {
        return snapshotSourceForDie(dieType).length > 0
    }

    function syncFromStore() {
        var revision = Number(DiceMainPreviewCacheStore.getRevision())
        if (revision === observedStoreRevision) {
            return
        }
        observedStoreRevision = revision
        var next = Object.assign({}, activeEntries || {})
        for (var i = 0; i < dieTypes.length; ++i) {
            var dieType = normalizeDieType(dieTypes[i])
            var expected = expectedEntries && expectedEntries[dieType] ? expectedEntries[dieType] : null
            if (!expected) {
                continue
            }
            var readySource = DiceMainPreviewCacheStore.readySourceForKey(expected.key)
            if (readySource.length > 0) {
                next[dieType] = {
                    "key": expected.key,
                    "source": readySourceUrl(readySource)
                }
            }
        }
        activeEntries = next
        if (renderingEnabled) {
            processQueue()
        }
    }

    function runPreviewScene(webView, renderVariant, presentation, kind, payload, startRoll) {
        if (!webView) {
            return
        }
        var script = "(function(){"
        script += "if(window.setPreviewRenderVariant){window.setPreviewRenderVariant(" + JSON.stringify(String(renderVariant || "default")) + ");}"
        script += "if(window.setPreviewPresentationMode){window.setPreviewPresentationMode(" + JSON.stringify(String(presentation || "roll")) + ");}"
        script += "if(window.setStyleOverrides){window.setStyleOverrides(" + JSON.stringify(payload || {}) + ");}"
        script += "if(window.setPreviewDieKind){window.setPreviewDieKind(" + JSON.stringify(String(kind || "d6")) + ");}"
        if (startRoll) {
            script += "if(window.startPreviewRoll){window.startPreviewRoll();}"
        }
        script += "})();"
        webView.runJavaScript(script)
    }

    function processQueue() {
        if (!renderingEnabled || !snapshotWebReady || snapshotBusy || !snapshotWebLoader.item) {
            return
        }
        var task = DiceMainPreviewCacheStore.takeNextTask()
        while (task && DiceMainPreviewCacheStore.hasReady(task.key)) {
            task = DiceMainPreviewCacheStore.takeNextTask()
        }
        if (!task) {
            return
        }
        snapshotCurrentTask = task
        snapshotBusy = true
        runPreviewScene(snapshotWebLoader.item, "main", "static", task.modelKind, task.payload, true)
        var captureKind = String(task.modelKind || "")
        snapshotCaptureTimer.interval = captureKind === "d20" ? 420 : (captureKind === "d4" ? 300 : 150)
        snapshotCaptureTimer.restart()
    }

    function handleCaptured(result) {
        var task = snapshotCurrentTask
        if (task && result) {
            var savePath = localPathFromUrl(task.fileUrl)
            var saved = false
            if (savePath.length > 0 && result.saveToFile) {
                saved = result.saveToFile(savePath)
            }
            var readySource = saved ? task.fileUrl : (result.url ? String(result.url) : "")
            if (readySource.length > 0) {
                DiceMainPreviewCacheStore.markReady(task.dieType, task.key, readySource)
            }
        }
        snapshotBusy = false
        snapshotCurrentTask = null
        syncFromStore()
        processQueue()
    }

    function captureCurrentTask() {
        if (!snapshotBusy || !snapshotCurrentTask || !snapshotWebLoader.item) {
            return
        }
        snapshotWebLoader.item.grabToImage(function(result) {
            manager.handleCaptured(result)
        })
    }

    onDieStylesChanged: prewarmAll()
    onPoseVersionChanged: prewarmAll()

    Component.onCompleted: {
        syncFromStore()
        if (prewarmEnabled) {
            prewarmAll()
        }
    }

    Timer {
        id: storeSyncTimer
        interval: 120
        repeat: true
        running: true
        onTriggered: manager.syncFromStore()
    }

    Loader {
        id: snapshotWebLoader
        active: manager.renderingEnabled
        sourceComponent: Component {
            WebEngineView {
                x: -10000
                y: -10000
                width: 96
                height: 96
                visible: true
                enabled: true
                backgroundColor: "#00000000"
                url: Qt.resolvedUrl("../../web/dice_physics.html")
                onLoadingChanged: function(req) {
                    if (req.status === WebEngineView.LoadFailedStatus) {
                        manager.snapshotWebReady = false
                        return
                    }
                    if (req.status === WebEngineView.LoadSucceededStatus) {
                        manager.snapshotWebReady = true
                        manager.processQueue()
                    }
                }
            }
        }
    }

    Timer {
        id: snapshotCaptureTimer
        interval: 180
        repeat: false
        onTriggered: manager.captureCurrentTask()
    }
}
