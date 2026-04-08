.pragma library

function detectMediaTypeFromValue(rawValue, fallbackType) {
    var value = String(rawValue || "").trim().toLowerCase()
    if (value.length === 0) {
        return fallbackType || "color"
    }
    var clean = value.split("?")[0].split("#")[0]
    if (clean.match(/\.(png|jpg|jpeg|webp|bmp|gif)$/)) {
        return "image"
    }
    if (clean.match(/\.(mp4|webm|mkv|avi|mov|wmv|m4v)$/)) {
        return "video"
    }
    return fallbackType || "color"
}

function normalizeColorValue(rawValue, fallbackColor) {
    var value = String(rawValue || "").trim()
    if (value.length === 0) {
        return fallbackColor || "#000000"
    }
    if (value.length === 9 && value[0] === "#") {
        return "#" + value.slice(3)
    }
    return value
}

function toPreviewSourceUrl(rawValue) {
    var value = String(rawValue || "").trim()
    if (value.length === 0) {
        return ""
    }
    if (value.indexOf("file://") === 0
            || value.indexOf("http://") === 0
            || value.indexOf("https://") === 0
            || value.indexOf("qrc:/") === 0) {
        return value
    }
    return "file:///" + value.replace(/\\/g, "/")
}
