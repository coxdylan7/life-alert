function batteryPercentage(device) {
  if (!device || !device.isPresent) return -1
  return Math.round(Number(device.percentage || 0) * 100)
}

function isDischarging(device, onBattery, dischargingState) {
  return !!(device && device.isPresent && onBattery && device.state === dischargingState)
}

function minutesRemaining(device) {
  if (!device || !device.isPresent) return -1
  var tte = Number(device.timeToEmpty || 0)
  if (isFinite(tte) && tte > 0) return Math.max(0, Math.round(tte / 60))
  var energy = Number(device.energy || 0)
  var rate = Number(device.changeRate || 0)
  if (!isFinite(energy) || energy <= 0 || !isFinite(rate) || rate <= 0) return -1
  return Math.max(0, Math.round((energy / rate) * 60))
}

function minutesUntilFull(device) {
  if (!device || !device.isPresent) return -1
  var ttf = Number(device.timeToFull || 0)
  if (isFinite(ttf) && ttf > 0) return Math.max(0, Math.round(ttf / 60))
  var energy = Number(device.energy || 0)
  // Quickshell exposes capacity as energyCapacity, not energyFull
  var energyFull = Number(device.energyCapacity !== undefined ? device.energyCapacity : device.energyFull || 0)
  if (!isFinite(energyFull) && device.energyFull !== undefined) energyFull = Number(device.energyFull || 0)
  var rate = Number(device.changeRate || 0)
  // When charging, energy increases — remaining energy until full is energyFull - energy.
  // changeRate may be reported as absolute value or positive while charging; use absolute.
  if (!isFinite(energy) || !isFinite(energyFull) || energyFull <= 0) return -1
  var remaining = energyFull - energy
  if (remaining <= 0) return 0
  if (!isFinite(rate) || rate === 0) {
    // No current rate — estimate with nominal 15W charging if we have remaining
    // so UI shows minutes at 96% threshold where UPower reports 0W
    if (remaining > 0 && remaining < 5) {
      // Assume 15W nominal charging for small remaining at threshold
      return Math.max(0, Math.round((remaining / 15) * 60))
    }
    return -1
  }
  var absRate = Math.abs(rate)
  if (!isFinite(absRate) || absRate <= 0) return -1
  return Math.max(0, Math.round((remaining / absRate) * 60))
}

function pluginEntry(shell, pluginId) {
  var cfg = shell ? shell.shellConfig : null
  var list = cfg && Array.isArray(cfg.plugins) ? cfg.plugins : []
  for (var i = 0; i < list.length; i++) {
    if (list[i] && String(list[i].id || "") === pluginId) return list[i]
  }
  return {}
}

function configInt(entry, key, fallback) {
  var v = entry[key]
  var n = Number(v)
  return isFinite(n) && n >= 0 ? Math.round(n) : fallback
}

function normalizeLevels(raw) {
  var list = (Array.isArray(raw) ? raw : [75, 50, 30, 20, 10])
    .map(function (v) {
      var n = Math.round(Number(v))
      return isFinite(n) ? n : -1
    })
    .filter(function (v) { return v >= 1 && v <= 100 })
  var seen = {}
  var out = []
  for (var i = 0; i < list.length; i++) {
    if (seen[list[i]]) continue
    seen[list[i]] = true
    out.push(list[i])
  }
  out.sort(function (a, b) { return b - a })
  return out
}

function meter(percent, width) {
  var w = Math.max(1, Math.round(width) || 1)
  var filled = Math.max(0, Math.min(w, Math.round((Math.max(0, Math.min(100, percent)) / 100) * w)))
  var out = ""
  for (var i = 0; i < w; i++) out += i < filled ? "█" : "░"
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    batteryPercentage: batteryPercentage,
    isDischarging: isDischarging,
    minutesRemaining: minutesRemaining,
    minutesUntilFull: minutesUntilFull,
    pluginEntry: pluginEntry,
    configInt: configInt,
    normalizeLevels: normalizeLevels,
    meter: meter
  }
}