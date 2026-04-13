.pragma library

var _queue = []
var _queued = {}
var _readyByKey = {}
var _revision = 0

function _clone(value) {
    return JSON.parse(JSON.stringify(value))
}

function _bumpRevision() {
    _revision += 1
}

function getRevision() {
    return _revision
}

function hasReady(key) {
    return !!_readyByKey[String(key || "")]
}

function readySourceForKey(key) {
    var entry = _readyByKey[String(key || "")]
    return entry && entry.source ? String(entry.source) : ""
}

function requestTask(task) {
    var key = task && task.key ? String(task.key) : ""
    if (!key || _queued[key] || _readyByKey[key]) {
        return false
    }
    _queue.push(_clone(task))
    _queued[key] = true
    _bumpRevision()
    return true
}

function takeNextTask() {
    if (_queue.length <= 0) {
        return null
    }
    var task = _queue.shift()
    if (task && task.key) {
        delete _queued[String(task.key)]
    }
    _bumpRevision()
    return task
}

function markReady(dieType, key, source) {
    var readyKey = String(key || "")
    if (!readyKey) {
        return
    }
    _readyByKey[readyKey] = {
        "dieType": String(dieType || ""),
        "key": readyKey,
        "source": String(source || "")
    }
    delete _queued[readyKey]
    _queue = _queue.filter(function(task) {
        return !task || String(task.key || "") !== readyKey
    })
    _bumpRevision()
}
