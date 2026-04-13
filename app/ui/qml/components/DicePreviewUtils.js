.pragma library

function cloneStyle(style) {
    var legacyGlow = Number(style && style.textShadowIntensity !== undefined ? style.textShadowIntensity : 100)
    var glowRadius = Number(style && style.textGlowRadius !== undefined ? style.textGlowRadius : legacyGlow)
    var glowOpacity = Number(style && style.textGlowOpacity !== undefined ? style.textGlowOpacity : legacyGlow)
    return {
        "scalePercent": Number(style && style.scalePercent !== undefined ? style.scalePercent : 100),
        "color": String(style && style.color ? style.color : "#C9C9C9"),
        "gradientEnabled": Boolean(style && style.gradientEnabled),
        "gradientCenterColor": String(style && style.gradientCenterColor ? style.gradientCenterColor : "#FFFFFF"),
        "gradientSharpness": Number(style && style.gradientSharpness !== undefined ? style.gradientSharpness : 50),
        "gradientOffset": Number(style && style.gradientOffset !== undefined ? style.gradientOffset : 50),
        "fontColor": String(style && style.fontColor ? style.fontColor : "#1F1F1F"),
        "textStrokeColor": String(style && style.textStrokeColor ? style.textStrokeColor : "#EEEEEE"),
        "textGlowRadius": Math.max(0, Math.min(200, glowRadius)),
        "textGlowOpacity": Math.max(0, Math.min(200, glowOpacity)),
        "edgeColor": String(style && style.edgeColor ? style.edgeColor : "#D4D4D4"),
        "edgeWidth": Number(style && style.edgeWidth !== undefined ? style.edgeWidth : 0.0)
    }
}

function styleToWebPayload(styleObj) {
    var src = styleObj && typeof styleObj === "object" ? styleObj : cloneStyle(null)
    return {
        "scalePercent": Number(src.scalePercent !== undefined ? src.scalePercent : 100),
        "faceColor": String(src.color || "#C9C9C9"),
        "gradientEnabled": Boolean(src.gradientEnabled),
        "gradientCenterColor": String(src.gradientCenterColor || "#FFFFFF"),
        "gradientSharpness": Math.max(0, Math.min(1, Number(src.gradientSharpness || 50) / 100.0)),
        "gradientOffset": Math.max(0, Math.min(1, Number(src.gradientOffset || 50) / 100.0)),
        "textColor": String(src.fontColor || "#1F1F1F"),
        "textStrokeColor": String(src.textStrokeColor || "#EEEEEE"),
        "textGlowRadius": Math.max(0, Math.min(2, Number(src.textGlowRadius !== undefined ? src.textGlowRadius : 100) / 100.0)),
        "textGlowOpacity": Math.max(0, Math.min(2, Number(src.textGlowOpacity !== undefined ? src.textGlowOpacity : 100) / 100.0)),
        "edgeColor": String(src.edgeColor || "#D4D4D4"),
        "edgeWidth": Number(src.edgeWidth !== undefined ? src.edgeWidth : 0.0)
    }
}

function styleToTemplateSnapshotPayload(styleObj) {
    var payload = styleToWebPayload(styleObj)
    payload.scalePercent = Number(payload.scalePercent || 100) * 2.25
    return payload
}

function styleToMainPreviewPayload(styleObj, dieType) {
    var payload = styleToWebPayload(styleObj)
    var key = String(dieType || "d6").toLowerCase()
    var scaleFactors = {
        "d4": 1.56,
        "d6": 1.56,
        "d8": 1.54,
        "d10": 1.5,
        "d12": 1.42,
        "d20": 1.38,
        "d100": 1.5
    }
    payload.scalePercent = Number(payload.scalePercent || 100) * Number(scaleFactors[key] || 1.46)
    return payload
}

function resolveMainPreviewSpec(dieType, styleOverride) {
    var key = String(dieType || "d6").toLowerCase()
    var modelKind = key === "d100" ? "d10t" : key
    var style = styleOverride && typeof styleOverride === "object" ? cloneStyle(styleOverride) : cloneStyle(null)
    var payload = styleToMainPreviewPayload(style, key)
    return {
        "dieType": key,
        "modelKind": modelKind,
        "payload": payload
    }
}

function buildMainPreviewSnapshotKey(dieType, styleObj, poseVersion) {
    var spec = resolveMainPreviewSpec(dieType, styleObj)
    return JSON.stringify({
        "variant": "main-preview",
        "poseVersion": Number(poseVersion || 1),
        "dieType": spec.dieType,
        "modelKind": spec.modelKind,
        "payload": spec.payload
    })
}
