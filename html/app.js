// Rename-safe storage key: bound to whatever the resource is named at runtime.
// Lets multiple instances / forks coexist in the same client localStorage.
const RESOURCE_NAME = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'dev-handling';
const LOCALE_STORAGE_KEY = 'dh_locale_' + RESOURCE_NAME;

let allHandlingData = {};
let initialSnapshot = {};
let currentPlate = null;
let activeCategory = 'engine';
let activeCharts = {};
let currentLocales = {};
let allLocalesData = {};
let activeLocale = localStorage.getItem(LOCALE_STORAGE_KEY) || 'en';

const GEAR_RATIOS = {
    1: [0.9],
    2: [3.33, 0.9],
    3: [3.33, 1.565, 0.9],
    4: [3.33, 1.826, 1.222, 0.9],
    5: [3.33, 1.934, 1.358, 1.054, 0.9],
    6: [3.333, 1.949, 1.392, 1.095, 0.946, 0.9],
    7: [3.333, 1.949, 1.392, 1.095, 0.946, 0.9, 0.9],
    8: [3.333, 1.949, 1.392, 1.095, 0.946, 0.9, 0.9, 0.9]
};

const CATEGORY_MAP = {
    'fInitialDriveForce': 'engine', 'fInitialDriveMaxFlatVel': 'engine', 'nInitialDriveGears': 'engine', 'fDriveBiasFront': 'engine', 'fDriveInertia': 'engine', 'fClutchChangeRateScaleUpShift': 'engine', 'fClutchChangeRateScaleDownShift': 'engine', 'fPetrolTankVolume': 'engine', 'fOilVolume': 'engine',
    'fBrakeForce': 'brakes', 'fBrakeBiasFront': 'brakes', 'fHandBrakeForce': 'brakes',
    'fTractionCurveMax': 'traction', 'fTractionCurveMin': 'traction', 'fTractionCurveLateral': 'traction', 'fTractionBiasFront': 'traction', 'fTractionLossMult': 'traction', 'fLowSpeedTractionLossMult': 'traction', 'fSteeringLock': 'traction', 'fTractionSpringDeltaMax': 'traction', 'fCamberStiffnesss': 'traction',
    'fSuspensionForce': 'suspension', 'fSuspensionCompDamp': 'suspension', 'fSuspensionReboundDamp': 'suspension', 'fSuspensionRaise': 'suspension', 'fSuspensionUpperLimit': 'suspension', 'fSuspensionLowerLimit': 'suspension', 'fAntiRollBarForce': 'suspension', 'fAntiRollBarBiasFront': 'suspension', 'fSuspensionBiasFront': 'suspension', 'fRollCentreHeightFront': 'suspension', 'fRollCentreHeightRear': 'suspension',
    'fInitialDragCoeff': 'physics', 'fMass': 'physics', 'fDownforceModifier': 'physics', 'vecCentreOfMassOffset': 'physics', 'fPercentSubmerged': 'physics', 'vecInertiaMultiplier': 'physics', 'fSeatOffsetDistX': 'physics', 'fSeatOffsetDistY': 'physics', 'fSeatOffsetDistZ': 'physics', 'fCollisionDamageMult': 'physics', 'fWeaponDamageMult': 'physics', 'fDeformationDamageMult': 'physics', 'fEngineDamageMult': 'physics'
};

let telemetryActive = false;
let speedHistory = [];
let lastTimes = { time100: null, time150: null, time200: null, timeQmile: null, timeHmile: null };
let shouldReopenUI = true;
let telemetryUnit = 'kmh';

window.addEventListener('message', function (event) {
    if (event.data.type === "openHandlingEditor") {
        document.getElementById('app').classList.remove('hidden');
        document.getElementById('veh-name').innerText = event.data.vehicleName || 'UNKNOWN';
        document.getElementById('veh-plate').innerText = event.data.plate || '...';

        let plate = event.data.plate || '...';

        allLocalesData = event.data.locales || {};
        if (!localStorage.getItem(LOCALE_STORAGE_KEY)) {
            activeLocale = event.data.defaultLocale || 'en';
            localStorage.setItem(LOCALE_STORAGE_KEY, activeLocale);
        }
        currentLocales = allLocalesData[activeLocale] || {};

        document.querySelectorAll('[data-i18n]').forEach(function(el) {
            var tKey = el.getAttribute('data-i18n');
            if (currentLocales[tKey]) el.innerText = currentLocales[tKey];
        });

        var catData = { engine: [], brakes: [], traction: [], suspension: [], physics: [] };

        if (event.data.data) {
            for (var key in event.data.data) {
                var prop = event.data.data[key];
                var cat = CATEGORY_MAP[key] || 'physics';
                if (prop.type === "vector" || prop.type === "string") continue;
                catData[cat].push({
                    name: key,
                    label: currentLocales['name_' + key] || prop.name || key,
                    desc: currentLocales['desc_' + key] || prop.description || "Handling configuration value.",
                    type: prop.type,
                    min: prop.min != null ? prop.min : 0,
                    max: prop.max != null ? prop.max : 10,
                    value: parseFloat(event.data.values[key]) || 0,
                    display: (event.data.displayData && event.data.displayData[key]) || { value: parseFloat(event.data.values[key]) || 0 }
                });
            }
        }

        allHandlingData = catData;
        if (currentPlate !== plate) {
            currentPlate = plate;
            initialSnapshot = JSON.parse(JSON.stringify(catData));
        }
        SwitchTab(activeCategory);
    }
    else if (event.data.type === "updateDisplay") {
        for (var key in event.data.displayData) {
            var displayObj = event.data.displayData[key];
            var displayContainer = document.getElementById('display-container-' + key);
            if (displayContainer) displayContainer.innerHTML = GetDisplayValueHTML(key, displayObj);
            for (var cat in allHandlingData) {
                var item = allHandlingData[cat].find(function(i) { return i.name === key; });
                if (item) item.display = displayObj;
            }
        }
    }
    else if (event.data.type === "copyXML") {
        navigator.clipboard.writeText(event.data.xml).catch(function() {
            var el = document.createElement('textarea');
            el.value = event.data.xml;
            document.body.appendChild(el);
            el.select();
            document.execCommand('copy');
            document.body.removeChild(el);
        });
        showToast();
    }
    else if (event.data.type === "updateTelemetry") {
        updateTelemetryUI(event.data);
    }
    else if (event.data.type === "closeTelemetry") {
        closeTelemetryUI();
    }
    else if (event.data.type === "updateLimit") {
        for (var cat in allHandlingData) {
            var item = allHandlingData[cat].find(function(i) { return i.name === event.data.param; });
            if (item) {
                item.min = event.data.min;
                item.max = event.data.max;
                var inputEl = document.getElementById('input-' + event.data.param);
                if (inputEl) { inputEl.min = item.min; inputEl.max = item.max; }
            }
        }
    }
});

document.onkeyup = function (data) {
    if (data.which == 27) {
        if (!document.getElementById('telemetry-ui').classList.contains('hidden')) {
            closeTelemetryUI();
            fetch('https://' + GetParentResourceName() + '/stopTelemetry', { method: 'POST', body: JSON.stringify({}) });
        } else if (!document.getElementById('telemetry-duration-modal').classList.contains('hidden')) {
            CloseTelemetryModal();
        } else if (!document.getElementById('mods-modal').classList.contains('hidden')) {
            CloseModsModal();
        } else if (!document.getElementById('limits-modal').classList.contains('hidden')) {
            CloseLimitsModal();
        } else if (!document.getElementById('language-modal').classList.contains('hidden')) {
            CloseLanguageModal();
        } else {
            CloseUI();
        }
    }
};

function CloseUI() { document.getElementById('app').classList.add('hidden'); fetch('https://' + GetParentResourceName() + '/close', { method: 'POST', body: JSON.stringify({}) }); }
function ForceRefresh() { fetch('https://' + GetParentResourceName() + '/respawnVehicle', { method: 'POST', body: JSON.stringify({}) }); }

function setLanguage(lang) {
    if (!allLocalesData[lang]) return;
    activeLocale = lang;
    localStorage.setItem(LOCALE_STORAGE_KEY, lang);
    currentLocales = allLocalesData[lang] || {};

    document.querySelectorAll('[data-i18n]').forEach(function(el) {
        var tKey = el.getAttribute('data-i18n');
        if (currentLocales[tKey]) el.innerText = currentLocales[tKey];
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach(function(el) {
        var tKey = el.getAttribute('data-i18n-placeholder');
        if (currentLocales[tKey]) el.placeholder = currentLocales[tKey];
    });

    if (allHandlingData) {
        for (var cat in allHandlingData) {
            allHandlingData[cat].forEach(function(item) {
                item.label = currentLocales['name_' + item.name] || item.name;
                item.desc = currentLocales['desc_' + item.name] || "Handling configuration value.";
            });
        }
    }
    SwitchTab(activeCategory);
    CloseLanguageModal();
}

function OpenLanguageModal() { document.getElementById('language-modal').classList.remove('hidden'); }
function CloseLanguageModal() { document.getElementById('language-modal').classList.add('hidden'); }

function OpenLimitsModal() {
    var container = document.getElementById('limits-container');
    container.innerHTML = '';
    var searchInput = document.getElementById('limits-search');
    if (searchInput) searchInput.value = '';

    var allParams = [];
    for (var cat in allHandlingData) allParams = allParams.concat(allHandlingData[cat]);
    allParams.sort(function(a, b) { return a.name.localeCompare(b.name); });

    allParams.forEach(function(item) {
        if (item.type === 'vector' || item.type === 'string') return;
        var html = '<div class="limit-card" data-name="' + item.name.toLowerCase() + '" data-label="' + item.label.toLowerCase() + '">' +
            '<div class="limit-card-info"><span class="limit-card-label">' + item.label + '</span><span class="limit-card-key">' + item.name + '</span></div>' +
            '<div class="limit-card-controls">' +
            '<div class="limit-input-group"><label>MIN</label><input type="number" id="limit-min-' + item.name + '" value="' + item.min + '" step="any"></div>' +
            '<div class="limit-input-group"><label>MAX</label><input type="number" id="limit-max-' + item.name + '" value="' + item.max + '" step="any"></div>' +
            '<button class="limit-save-btn" onclick="SaveLimitBtn(\'' + item.name + '\')"><i class="fa-solid fa-check"></i></button>' +
            '</div></div>';
        container.innerHTML += html;
    });

    document.getElementById('limits-modal').classList.remove('hidden');
}

function CloseLimitsModal() { document.getElementById('limits-modal').classList.add('hidden'); }

function FilterLimits() {
    var query = document.getElementById('limits-search').value.toLowerCase();
    document.querySelectorAll('.limit-card').forEach(function(card) {
        var name = card.getAttribute('data-name');
        var label = card.getAttribute('data-label');
        card.style.display = (name.includes(query) || label.includes(query)) ? '' : 'none';
    });
}

function SaveLimitBtn(param) {
    var minVal = parseFloat(document.getElementById('limit-min-' + param).value);
    var maxVal = parseFloat(document.getElementById('limit-max-' + param).value);
    fetch('https://' + GetParentResourceName() + '/saveLimit', { method: 'POST', body: JSON.stringify({ param: param, min: minVal, max: maxVal }) });

    var btn = document.querySelector('button[onclick="SaveLimitBtn(\'' + param + '\')"]');
    if (btn) {
        btn.classList.add('saved');
        setTimeout(function() { btn.classList.remove('saved'); }, 1200);
    }
}

function SwitchTab(category) {
    activeCategory = category;
    document.querySelectorAll('.nav-btn').forEach(function(btn) { btn.classList.remove('active'); });
    document.getElementById('tab-' + category).classList.add('active');
    document.getElementById('page-title').innerText = (currentLocales['ui_' + category] || category).toUpperCase();
    document.getElementById('breadcrumb-cat').innerText = currentLocales['ui_' + category] || category;
    RenderCards(category);
}

function GetGlobalValue(name) {
    for (var cat in allHandlingData) {
        var found = allHandlingData[cat].find(function(item) { return item.name === name; });
        if (found) return parseFloat(found.value);
    }
    return 0;
}

function GetDisplayValueHTML(name, displayObj) {
    if (!displayObj) displayObj = { value: 0 };
    if (name === 'fInitialDriveMaxFlatVel') {
        var limitType = displayObj.isDragLimited ? "DRAG LTD" : "GEAR LTD";
        var limitCls = displayObj.isDragLimited ? "badge-orange" : "badge-blue";
        return '<div class="val-display"><span class="val-main">' + displayObj.value + '</span><span class="val-unit">' + (displayObj.unit || 'KM/H') + '</span><span class="val-raw">[' + (displayObj.raw || '—') + ']</span><span class="val-badge ' + limitCls + '">' + limitType + '</span></div>';
    }
    if (displayObj.unit) {
        return '<div class="val-display"><span class="val-main">' + displayObj.value + '</span><span class="val-unit">' + displayObj.unit + '</span></div>';
    }
    return '<div class="val-display"><span class="val-main">' + displayObj.value + '</span></div>';
}

function OnSliderMove(category, name, value, type) {
    var numVal = (type === 'int' || type === 'integer') ? parseInt(value) : parseFloat(value);
    var item = allHandlingData[category] && allHandlingData[category].find(function(x) { return x.name === name; });
    if (item) item.value = numVal;

    var displayContainer = document.getElementById('display-container-' + name);
    if (displayContainer && !['fInitialDriveForce', 'fMass', 'fBrakeForce', 'fInitialDriveMaxFlatVel', 'fInitialDragCoeff'].includes(name)) {
        displayContainer.innerHTML = GetDisplayValueHTML(name, { value: parseFloat(value).toFixed(3) });
    }

    // Update slider fill track
    var inputEl = document.getElementById('input-' + name);
    if (inputEl) updateSliderFill(inputEl);

    var chartId = 'chart-' + name;
    if (activeCharts[chartId]) UpdateChartData(name, activeCharts[chartId], numVal);
    if (category === 'traction' && activeCharts['chart-fTractionCurveMax']) UpdateTractionRadar(activeCharts['chart-fTractionCurveMax']);
}

function UpdateValue(category, name, value, type) {
    OnSliderMove(category, name, value, type);
    var numVal = (type === 'int' || type === 'integer') ? parseInt(value) : parseFloat(value);
    var initialItem = initialSnapshot[category] && initialSnapshot[category].find(function(x) { return x.name === name; });
    var resetBtn = document.getElementById('reset-' + name);
    if (initialItem && resetBtn) {
        if (Math.abs(initialItem.value - numVal) > 0.001) resetBtn.classList.remove('hidden');
        else resetBtn.classList.add('hidden');
    }
    fetch('https://' + GetParentResourceName() + '/updateHandling', { method: 'POST', body: JSON.stringify({ key: name, value: value }) });
}

function RevertSingle(category, name) {
    var initialItem = initialSnapshot[category] && initialSnapshot[category].find(function(x) { return x.name === name; });
    if (initialItem) {
        var inputEl = document.getElementById('input-' + name);
        if (inputEl) { inputEl.value = initialItem.value; updateSliderFill(inputEl); }
        UpdateValue(category, name, initialItem.value, initialItem.type);
    }
}

function ConfirmReset() {
    CloseResetModal();
    for (var catName in initialSnapshot) {
        initialSnapshot[catName].forEach(function(item) {
            if (item.type !== 'vector' && item.type !== 'string') {
                var inputEl = document.getElementById('input-' + item.name);
                if (inputEl) { inputEl.value = item.value; updateSliderFill(inputEl); }
                UpdateValue(catName, item.name, item.value, item.type);
            }
        });
    }
    RenderCards(activeCategory);
}

function updateSliderFill(input) {
    var min = parseFloat(input.min) || 0;
    var max = parseFloat(input.max) || 1;
    var val = parseFloat(input.value) || 0;
    var pct = ((val - min) / (max - min)) * 100;
    input.style.setProperty('--fill', pct + '%');
}

// Charts
Chart.defaults.color = '#404060';
Chart.defaults.font.family = 'JetBrains Mono';

function InitAccelChart(id, val) {
    var ctx = document.getElementById(id).getContext('2d');
    var g = ctx.createLinearGradient(0, 0, 0, 80);
    g.addColorStop(0, 'rgba(79,139,255,0.35)');
    g.addColorStop(1, 'rgba(79,139,255,0)');
    activeCharts[id] = new Chart(ctx, { type: 'line', data: { labels: ['1','2','3','4','5'], datasets: [{ data: [val, val*0.9, val*0.8, val*0.6, val*0.4], borderColor: '#4f8bff', borderWidth: 2, fill: true, backgroundColor: g, pointRadius: 0, tension: 0.4 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { display: false }, y: { display: false } } } });
}
function InitDragChart(id, val) {
    var ctx = document.getElementById(id).getContext('2d');
    var g = ctx.createLinearGradient(0, 0, 0, 80);
    g.addColorStop(0, 'rgba(249,115,22,0.35)');
    g.addColorStop(1, 'rgba(249,115,22,0)');
    var speeds = [50,100,150,200,250];
    var resistance = speeds.map(function(s) { return ((Math.sqrt((s/3.6)/5)/100)*val)*5; });
    activeCharts[id] = new Chart(ctx, { type: 'line', data: { labels: ['50','100','150','200','250'], datasets: [{ data: resistance, borderColor: '#f97316', borderWidth: 2, fill: true, backgroundColor: g, pointRadius: 0 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { display: true, ticks: { color: '#404060', font: { size: 8 } } }, y: { display: false } } } });
}
function InitGearChart(id, val) {
    var ctx = document.getElementById(id).getContext('2d');
    var gears = Math.min(Math.max(parseInt(val), 1), 8);
    var ratios = GEAR_RATIOS[gears] || GEAR_RATIOS[8];
    activeCharts[id] = new Chart(ctx, { type: 'line', data: { labels: ratios.map(function(_,i){return i+1;}), datasets: [{ data: ratios.map(function(r){return r*1.5;}), borderColor: '#1ecfa0', borderWidth: 2, stepped: true, backgroundColor: 'rgba(30,207,160,0.1)', fill: true, pointRadius: 0 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { display: true, ticks: { color: '#404060' } }, y: { display: false } } } });
}
function InitBiasChart(id, val) {
    var ctx = document.getElementById(id).getContext('2d');
    activeCharts[id] = new Chart(ctx, { type: 'bar', data: { labels: [''], datasets: [{ label: 'F', data: [val], backgroundColor: '#4f8bff', barThickness: 8, borderRadius: 4 }, { label: 'R', data: [1.0-val], backgroundColor: '#ff4060', barThickness: 8, borderRadius: 4 }] }, options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { stacked: true, display: false }, y: { stacked: true, display: false } } } });
}
function InitSuspensionChart(id, val) {
    var ctx = document.getElementById(id).getContext('2d');
    activeCharts[id] = new Chart(ctx, { type: 'bar', data: { labels: [''], datasets: [{ data: [val], backgroundColor: val > 3 ? '#f97316' : '#1ecfa0', borderRadius: 4 }] }, options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { min: 0, max: 8, display: true, grid: { color: '#1a1c2e' } }, y: { display: false } } } });
}
function InitTractionRadar(id) {
    var ctx = document.getElementById(id).getContext('2d');
    var max = GetGlobalValue('fTractionCurveMax') || 2.0;
    var min = GetGlobalValue('fTractionCurveMin') || 2.0;
    var lat = (GetGlobalValue('fTractionCurveLateral') || 20.0) / 10;
    var loss = 3.0 - (GetGlobalValue('fTractionLossMult') || 1.0);
    activeCharts[id] = new Chart(ctx, { type: 'radar', data: { labels: ['Max','Slide','Lat','Dirt'], datasets: [{ label: 'Grip', data: [max,min,lat,loss], fill: true, backgroundColor: 'rgba(79,139,255,0.15)', borderColor: '#4f8bff', pointBackgroundColor: '#fff', pointBorderColor: '#4f8bff', pointRadius: 3 }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { r: { angleLines: { color: '#1a1c2e' }, grid: { color: '#1a1c2e' }, pointLabels: { color: '#505570', font: { size: 9 } }, ticks: { display: false } } } } });
}
function UpdateTractionRadar(chart) {
    var max = GetGlobalValue('fTractionCurveMax') || 2.0;
    var min = GetGlobalValue('fTractionCurveMin') || 2.0;
    var lat = (GetGlobalValue('fTractionCurveLateral') || 20.0) / 10;
    var loss = 3.0 - (GetGlobalValue('fTractionLossMult') || 1.0);
    chart.data.datasets[0].data = [max,min,lat,loss];
    chart.update();
}
function UpdateChartData(name, chart, val) {
    if (name === 'fInitialDriveForce') chart.data.datasets[0].data = [val, val*0.9, val*0.8, val*0.6, val*0.4];
    else if (name === 'fBrakeBiasFront') { chart.data.datasets[0].data = [val]; chart.data.datasets[1].data = [1.0-val]; }
    else if (name === 'fSuspensionForce') { chart.data.datasets[0].data = [val]; chart.data.datasets[0].backgroundColor = val > 3 ? '#f97316' : '#1ecfa0'; }
    else if (name === 'fInitialDragCoeff') { var speeds=[50,100,150,200,250]; chart.data.datasets[0].data = speeds.map(function(s){return((Math.sqrt((s/3.6)/5)/100)*val)*5;}); }
    else if (name === 'nInitialDriveGears') { var gears=Math.min(Math.max(parseInt(val),1),8); var ratios=GEAR_RATIOS[gears]||GEAR_RATIOS[8]; chart.data.labels=ratios.map(function(_,i){return i+1;}); chart.data.datasets[0].data=ratios.map(function(r){return r*1.5;}); }
    chart.update('none');
}

function RenderCards(category) {
    var container = document.getElementById('cards-container');
    if (!container) return;
    container.innerHTML = '';
    Object.values(activeCharts).forEach(function(c) { c.destroy(); });
    activeCharts = {};

    if (!allHandlingData[category]) return;

    allHandlingData[category].forEach(function(item) {
        var desc = item.desc || "Handling configuration value.";
        var initialItem = initialSnapshot[category] && initialSnapshot[category].find(function(x) { return x.name === item.name; });
        var initialVal = initialItem ? initialItem.value : item.value;
        var min = item.min != null ? item.min : 0;
        var max = item.max != null ? item.max : 10;
        var range = max - min;
        var pct = range > 0 ? ((item.value - min) / range) * 100 : 0;
        var originPct = range > 0 ? ((initialVal - min) / range) * 100 : 0;

        var canvasId = 'chart-' + item.name;
        var hasChart = ['fInitialDriveForce','fBrakeBiasFront','fSuspensionForce','fInitialDragCoeff','nInitialDriveGears','fTractionCurveMax'].includes(item.name);
        var chartHtml = hasChart ? '<div class="dh-chart-wrap"><canvas id="' + canvasId + '"></canvas></div>' : '';

        var valueDisplayHtml = GetDisplayValueHTML(item.name, item.display);
        var step = (item.type === 'int' || item.type === 'integer') ? 1 : 0.001;
        var isModified = Math.abs(initialVal - item.value) > 0.001;

        var card = document.createElement('div');
        card.className = 'dh-card';

        card.innerHTML =
            '<div class="dh-card-header">' +
                '<div class="dh-card-title-wrap">' +
                    '<h3 class="dh-card-title">' + item.label + '</h3>' +
                    '<span class="dh-card-key">' + item.name + '</span>' +
                '</div>' +
                '<button id="reset-' + item.name + '" onclick="RevertSingle(\'' + category + '\',\'' + item.name + '\')" class="dh-revert-btn' + (isModified ? '' : ' hidden') + '" title="Revert"><i class="fa-solid fa-rotate-left"></i></button>' +
            '</div>' +
            chartHtml +
            '<div id="display-container-' + item.name + '" class="dh-val-wrap">' + valueDisplayHtml + '</div>' +
            '<div class="dh-slider-wrap">' +
                '<div class="dh-origin" style="left:' + originPct + '%" title="Stock value"></div>' +
                '<input type="range" id="input-' + item.name + '" class="dh-slider" min="' + min + '" max="' + max + '" step="' + step + '" value="' + item.value + '" style="--fill:' + pct + '%" oninput="OnSliderMove(\'' + category + '\',\'' + item.name + '\',this.value,\'' + item.type + '\')" onchange="UpdateValue(\'' + category + '\',\'' + item.name + '\',this.value,\'' + item.type + '\')">' +
            '</div>' +
            '<div class="dh-card-desc">' + desc + '</div>';

        container.appendChild(card);

        if (hasChart) {
            (function(iname, cid, ival) {
                setTimeout(function() {
                    if (iname === 'fInitialDriveForce') InitAccelChart(cid, ival);
                    if (iname === 'fBrakeBiasFront') InitBiasChart(cid, ival);
                    if (iname === 'fSuspensionForce') InitSuspensionChart(cid, ival);
                    if (iname === 'fInitialDragCoeff') InitDragChart(cid, ival);
                    if (iname === 'nInitialDriveGears') InitGearChart(cid, ival);
                    if (iname === 'fTractionCurveMax') InitTractionRadar(cid);
                }, 50);
            })(item.name, canvasId, item.value);
        }
    });
}

function showToast() {
    var toast = document.getElementById('copy-toast');
    toast.classList.remove('hidden');
    toast.classList.add('show');
    setTimeout(function() { toast.classList.remove('show'); setTimeout(function() { toast.classList.add('hidden'); }, 300); }, 3000);
}

function ExportToClipboard() {
    fetch('https://' + GetParentResourceName() + '/exportXML', { method: 'POST', body: JSON.stringify({}) });
}
function OpenResetModal() { document.getElementById('reset-modal').classList.remove('hidden'); }
function CloseResetModal() { document.getElementById('reset-modal').classList.add('hidden'); }

function OpenTelemetryModal() { document.getElementById('telemetry-duration-modal').classList.remove('hidden'); }
function CloseTelemetryModal() { document.getElementById('telemetry-duration-modal').classList.add('hidden'); }

function setTelemetryUnit(unit) {
    telemetryUnit = unit;
    document.getElementById('btn-unit-kmh').className = 'unit-btn' + (unit === 'kmh' ? ' active' : '');
    document.getElementById('btn-unit-mph').className = 'unit-btn' + (unit === 'mph' ? ' active' : '');
}

function confirmTelemetry(duration) {
    shouldReopenUI = document.getElementById('reopen-ui-toggle').checked;
    CloseTelemetryModal();
    document.getElementById('app').classList.add('hidden');

    speedHistory = [];
    document.getElementById('telemetry-ui').classList.remove('hidden');
    document.getElementById('tel-unit-label').innerText = telemetryUnit.toUpperCase();

    if (telemetryUnit === 'mph') {
        document.getElementById('label-0-100').innerText = '0-60';
        document.getElementById('label-0-150').innerText = '0-100';
        document.getElementById('label-0-200').innerText = '0-130';
    } else {
        document.getElementById('label-0-100').innerText = '0-100';
        document.getElementById('label-0-150').innerText = '0-150';
        document.getElementById('label-0-200').innerText = '0-200';
    }

    document.getElementById('old-timer-100').innerText = lastTimes.time100 ? lastTimes.time100.toFixed(2) + 's' : '--';
    document.getElementById('old-timer-150').innerText = lastTimes.time150 ? lastTimes.time150.toFixed(2) + 's' : '--';
    document.getElementById('old-timer-200').innerText = lastTimes.time200 ? lastTimes.time200.toFixed(2) + 's' : '--';
    document.getElementById('old-timer-qmile').innerText = lastTimes.timeQmile ? lastTimes.timeQmile.toFixed(2) + 's' : '--';
    document.getElementById('old-timer-hmile').innerText = lastTimes.timeHmile ? lastTimes.timeHmile.toFixed(2) + 's' : '--';

    fetch('https://' + GetParentResourceName() + '/startTelemetry', { method: 'POST', body: JSON.stringify({ duration: duration, unit: telemetryUnit }) });
}

function OpenModsModal() {
    fetch('https://' + GetParentResourceName() + '/requestVehicleMods', { method: 'POST', body: JSON.stringify({}) })
    .then(function(resp) { return resp.json(); })
    .then(function(data) {
        if (data.stock) {
            document.getElementById('stock-engine').innerText = 'Stock: Lvl ' + (data.stock.engine + 1);
            document.getElementById('stock-brakes').innerText = 'Stock: Lvl ' + (data.stock.brakes + 1);
            document.getElementById('stock-transmission').innerText = 'Stock: Lvl ' + (data.stock.transmission + 1);
            document.getElementById('stock-suspension').innerText = 'Stock: Lvl ' + (data.stock.suspension + 1);
            document.getElementById('stock-turbo').innerText = 'Stock: ' + (data.stock.turbo ? 'Enabled' : 'Disabled');
            document.getElementById('mod-engine').checked = false;
            document.getElementById('mod-brakes').checked = false;
            document.getElementById('mod-transmission').checked = false;
            document.getElementById('mod-suspension').checked = false;
            document.getElementById('mod-turbo').checked = false;
        }
        document.getElementById('mods-modal').classList.remove('hidden');
    });
}
function CloseModsModal() { document.getElementById('mods-modal').classList.add('hidden'); }

function ApplyVehicleMods() {
    var mods = {
        engine: document.getElementById('mod-engine').checked ? 3 : null,
        brakes: document.getElementById('mod-brakes').checked ? 2 : null,
        transmission: document.getElementById('mod-transmission').checked ? 2 : null,
        suspension: document.getElementById('mod-suspension').checked ? 3 : null,
        turbo: document.getElementById('mod-turbo').checked ? true : null
    };
    fetch('https://' + GetParentResourceName() + '/setVehicleMods', { method: 'POST', body: JSON.stringify({ mods: mods }) });
    CloseModsModal();
}

function drawGraph() {
    var canvas = document.getElementById('speedGraph');
    if (!canvas) return;
    var ctx = canvas.getContext('2d');
    canvas.width = canvas.parentElement.clientWidth;
    canvas.height = canvas.parentElement.clientHeight;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    if (speedHistory.length < 2) return;

    var maxSpeed = Math.max.apply(null, speedHistory.concat([100]));
    var stepX = canvas.width / (speedHistory.length - 1);

    ctx.beginPath();
    ctx.strokeStyle = '#4f8bff';
    ctx.lineWidth = 2.5;
    ctx.lineJoin = 'round';
    for (var i = 0; i < speedHistory.length; i++) {
        var x = i * stepX;
        var y = canvas.height - ((speedHistory[i] / maxSpeed) * canvas.height * 0.88);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
    }
    ctx.stroke();

    var grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
    grad.addColorStop(0, 'rgba(79,139,255,0.3)');
    grad.addColorStop(1, 'rgba(79,139,255,0)');
    ctx.lineTo(canvas.width, canvas.height);
    ctx.lineTo(0, canvas.height);
    ctx.fillStyle = grad;
    ctx.fill();
}

function updateTelemetryUI(data) {
    document.getElementById('tel-speed').innerText = data.speed;
    document.getElementById('tel-gear').innerText = data.gear;
    document.getElementById('tel-ts').innerText = data.topSpeed;
    document.getElementById('telemetry-countdown').innerText = 'REC — ' + data.timeLeft + 's';

    document.getElementById('timer-100').innerText = data.time100 ? data.time100.toFixed(2) + 's' : '--';
    document.getElementById('timer-150').innerText = data.time150 ? data.time150.toFixed(2) + 's' : '--';
    document.getElementById('timer-200').innerText = data.time200 ? data.time200.toFixed(2) + 's' : '--';
    document.getElementById('timer-qmile').innerText = data.timeQmile ? data.timeQmile.toFixed(2) + 's' : '--';
    document.getElementById('timer-hmile').innerText = data.timeHmile ? data.timeHmile.toFixed(2) + 's' : '--';

    if (data.speed >= 0 && data.hasStartedMoving) { speedHistory.push(data.speed); drawGraph(); }

    lastTimes.time100 = data.time100 || lastTimes.time100;
    lastTimes.time150 = data.time150 || lastTimes.time150;
    lastTimes.time200 = data.time200 || lastTimes.time200;
    lastTimes.timeQmile = data.timeQmile || lastTimes.timeQmile;
    lastTimes.timeHmile = data.timeHmile || lastTimes.timeHmile;
}

function closeTelemetryUI() {
    document.getElementById('telemetry-ui').classList.add('hidden');
    
    // Piccolo delay per permettere al client Lua di "affondare" l'input ESC
    // ed evitare che l'apertura immediata del menu con focus catturi l'input di pausa
    setTimeout(() => {
        if (shouldReopenUI) document.getElementById('app').classList.remove('hidden');
        fetch('https://' + GetParentResourceName() + '/stopTelemetry', { 
            method: 'POST', 
            body: JSON.stringify({ reopen: shouldReopenUI }) 
        });
    }, 150);
}
