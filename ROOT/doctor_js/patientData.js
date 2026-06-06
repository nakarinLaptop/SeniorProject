let histories     = [];
let prescriptions = [];
let predictions   = [];

// import data from tables
document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("#historyTable tbody tr").forEach(row => {
        const _c = row.querySelectorAll("td");
        if (_c.length < 5 || (_c.length === 1 && _c[0].hasAttribute("colspan"))) return;
        histories.push({
            history_id: row.dataset.historyId,
            date:  _c[0]?.innerText.trim() || "", doctor: _c[1]?.innerText.trim() || "",
            text:  _c[2]?.innerText.trim() || "", icds:   _c[3]?.innerText.trim() || "",
            drugs: _c[4]?.innerText.trim() || ""
        });
    });

    document.querySelectorAll("#prescriptionTable tbody tr").forEach(row => {
        const _c = row.querySelectorAll("td");
        if (_c.length < 4 || (_c.length === 1 && _c[0].hasAttribute("colspan"))) return;
        prescriptions.push({
            prescriptionId:  row.dataset.prescriptionId,
            datetime:        _c[0]?.innerText.trim() || "", doctorName:      _c[1]?.innerText.trim() || "",
            healthcareRight: _c[2]?.innerText.trim() || "", amount:          _c[3]?.innerText.trim() || ""
        });
    });

    document.querySelectorAll("#predictionTable tbody tr").forEach(row => {
        const _c = row.querySelectorAll("td");
        if (_c.length < 6 || (_c.length === 1 && _c[0].hasAttribute("colspan"))) return;
        predictions.push({
            id: row.dataset.predId || "",
            date:          _c[0]?.innerText.trim() || "", doctor:        _c[1]?.innerText.trim() || "",
            predictResult: _c[2]?.innerText.trim() || "", doctorSelected: _c[3]?.innerText.trim() || "",
            confident: parseFloat(_c[4]?.innerText.trim()) || 0,
            labList: row.dataset.predLabList || ""
        });
    });

    ["searchDate", "searchPredictDate", "searchPrescDate"].forEach(id => {
        if (document.getElementById(id)) flatpickr("#" + id, { mode: "range", dateFormat: "Y-m-d" });
    });
});
// 3 filter functions
window.filterHistoryTable = function () {
    const sDate   = document.getElementById("searchDate")?.value.toLowerCase() || "";
    const sDoctor = document.getElementById("searchDoctor")?.value.toLowerCase() || "";
    const sText   = document.getElementById("searchText")?.value.toLowerCase() || "";
    const sIcd    = document.getElementById("searchIcd")?.value.toLowerCase() || "";
    const sDrug   = document.getElementById("searchDrug")?.value.toLowerCase() || "";

    renderHistoryTable(histories.filter(h =>
        h.date.toLowerCase().includes(sDate)     &&
        h.doctor.toLowerCase().includes(sDoctor) &&
        h.text.toLowerCase().includes(sText)     &&
        h.icds.toLowerCase().includes(sIcd)      &&
        h.drugs.toLowerCase().includes(sDrug)
    ));
};

window.filterPrescriptionTable = function () {
    const sDate   = document.getElementById("searchPrescDate")?.value.toLowerCase() || "";
    const sDoctor = document.getElementById("searchPrescDoctor")?.value.toLowerCase() || "";
    const sRight  = document.getElementById("searchHealthRight")?.value.toLowerCase() || "";
    const sCount  = document.getElementById("searchMedicineCount")?.value.toLowerCase() || "";

    renderPrescriptionTable(prescriptions.filter(p =>
        p.datetime.toLowerCase().includes(sDate)         &&
        p.doctorName.toLowerCase().includes(sDoctor)     &&
        p.healthcareRight.toLowerCase().includes(sRight) &&
        p.amount.toLowerCase().includes(sCount)
    ));
};

window.filterPredictionTable = function () {
    const sDate     = document.getElementById("searchPredictDate")?.value.toLowerCase() || "";
    const sDoctor   = document.getElementById("searchPredictDoctor")?.value.toLowerCase() || "";
    const sResult   = document.getElementById("searchPredictResult")?.value.toLowerCase() || "";
    const sSelected = document.getElementById("searchDoctorSelected")?.value.toLowerCase() || "";
    const confMin   = parseFloat(document.getElementById("searchConfidentMin")?.value) || 0;
    const confMax   = parseFloat(document.getElementById("searchConfidentMax")?.value) || 100;

    renderPredictionTable(predictions.filter(pred =>
        pred.date.toLowerCase().includes(sDate)               &&
        pred.doctor.toLowerCase().includes(sDoctor)           &&
        pred.predictResult.toLowerCase().includes(sResult)    &&
        pred.doctorSelected.toLowerCase().includes(sSelected) &&
        pred.confident >= confMin && pred.confident <= confMax
    ));
};

// 3 tables
function renderHistoryTable(data) {
    const rows = data.map(h => `
        <tr data-history-id="${h.history_id}">
            <td>${h.date}</td>
            <td>${h.doctor}</td>
            <td class="text-truncate">${h.text}</td>
            <td>${h.icds}</td>
            <td>${h.drugs}</td>
            <td><button class="btn-view" onclick="openHistoryView(this)">ดูรายละเอียด</button></td>
        </tr>`);
    const tbody1 = document.querySelector("#historyTable tbody");
    if (tbody1) tbody1.innerHTML = rows.length ? rows.join("") : '<tr><td colspan="6" style="text-align:center;color:#888;">ไม่พบข้อมูลที่ค้นหา</td></tr>';
}

function renderPrescriptionTable(data) {
    const rows = data.map(p => `
        <tr data-prescription-id="${p.prescriptionId}"
            data-datetime="${p.datetime}"
            data-doctor-name="${p.doctorName}"
            data-healthcare-right="${p.healthcareRight}">
            <td>${p.datetime}</td>
            <td>${p.doctorName}</td>
            <td>${p.healthcareRight}</td>
            <td>${p.amount}</td>
            <td><button class="btn-view" onclick="viewPrescriptionDetail(this)">ดูรายละเอียด</button></td>
        </tr>`);
    const tbody2 = document.querySelector("#prescriptionTable tbody");
    if (tbody2) tbody2.innerHTML = rows.length ? rows.join("") : '<tr><td colspan="5" style="text-align:center;color:#888;">ไม่พบข้อมูลใบสั่งยา</td></tr>';
}

function renderPredictionTable(data) {
    const rows = data.map(pred => `
        <tr data-pred-id="${pred.id || ""}"
            data-pred-date="${pred.date}"
            data-pred-doctor="${pred.doctor}"
            data-pred-result="${pred.predictResult}"
            data-pred-selected="${pred.doctorSelected}"
            data-pred-confident="${pred.confident}"
            data-pred-lab-list="${pred.labList || ""}">
            <td>${pred.date}</td>
            <td>${pred.doctor}</td>
            <td>${pred.predictResult}</td>
            <td>${pred.doctorSelected}</td>
            <td>${pred.confident}</td>
            <td><button class="btn-view" onclick="openPredictionView(this)">ดูรายละเอียด</button></td>
        </tr>`);
    const tbody3 = document.querySelector("#predictionTable tbody");
    if (tbody3) tbody3.innerHTML = rows.length ? rows.join("") : '<tr><td colspan="6" style="text-align:center;color:#888;">ไม่พบข้อมูลการทำนาย</td></tr>';
}

// dialog history, prescription, prediction
window.openHistoryView = function (btn) {
    const tr = btn.closest('tr');
    const tds = tr.querySelectorAll('td');
    document.getElementById('histModalDate').innerText   = tds[0]?.innerText.trim() || '-';
    document.getElementById('histModalDoctor').innerText = tds[1]?.innerText.trim() || '-';
    document.getElementById('histModalText').innerText   = tds[2]?.innerText.trim() || '-';
    document.getElementById('histModalIcds').innerText   = tds[3]?.innerText.trim() || '-';
    document.getElementById('histModalDrugs').innerText  = tds[4]?.innerText.trim() || '-';
    const modal = document.getElementById('historyViewModal');
    modal.dataset.historyId = tr.dataset.historyId || '';
    modal.classList.add('active');
};
window.closeHistoryView = function () {
    document.getElementById('historyViewModal').classList.remove('active');
};

window.viewPrescriptionDetail = function (btn) {
    const tr = btn.closest('tr');
    const prescriptionId  = tr.dataset.prescriptionId;
    const datetime        = tr.dataset.datetime       || '-';
    const doctorName      = tr.dataset.doctorName     || '-';
    const healthcareRight = tr.dataset.healthcareRight || '-';

    const modal   = document.getElementById('prescriptionDetailModal');
    const content = document.getElementById('prescModalContent');
    modal.dataset.prescriptionId = prescriptionId || '';

    const base = `
        <div class="detail-modal-info-rows">
            <div class="detail-modal-info-row"><span class="dim-label">วันที่</span><span>${datetime}</span></div>
            <div class="detail-modal-info-row"><span class="dim-label">แพทย์</span><span>${doctorName}</span></div>
            <div class="detail-modal-info-row"><span class="dim-label">สิทธิการรักษา</span><span>${healthcareRight}</span></div>
        </div>
        <hr style="margin:12px 0;border:none;border-top:1px solid #dee2e6;">
        <p style="font-weight:600;margin:0 0 8px;">รายการยา</p>`;
    content.innerHTML = base + '<p style="text-align:center;color:#888;">กำลังโหลด...</p>';
    modal.classList.add('active');

    fetch('prescription.jsp?action=detail&prescription_id=' + encodeURIComponent(prescriptionId))
        .then(res => res.json())
        .then(data => {
            if (!data || data.length === 0) {
                content.innerHTML = base + '<p style="text-align:center;color:#888;">ไม่พบข้อมูลยา</p>';
                return;
            }
            const rows = data.map(m => `<tr>
                <td>${m.medicine_name || '-'}</td>
                <td>${m.quantity      || '-'}</td>
                <td>${m.unit          || '-'}</td>
                <td>${m.frequency     || '-'}</td>
                <td>${m.helper_label  || '-'}</td>
            </tr>`).join("");
            content.innerHTML = base +
                `<table class="detail-modal-medicine-table"><thead><tr>
                    <th>ชื่อยา</th><th>จำนวน</th><th>หน่วย</th>
                    <th>ความถี่</th><th>คำแนะนำ</th>
                </tr></thead><tbody>${rows}</tbody></table>`;
        })
        .catch(() => {
            content.innerHTML = '<p style="color:red;">โหลดข้อมูลไม่สำเร็จ</p>';
        });
};
window.closePrescriptionDetailModal = function () {
    document.getElementById('prescriptionDetailModal').classList.remove('active');
};

function escapeHtml(value) {
    return String(value ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function formatPercent(value) {
    const n = parseFloat(value);
    return Number.isFinite(n) ? `${n.toFixed(2)}%` : "-";
}

function formatWithLineBreaks(value) {
    let safe = escapeHtml(value ?? "-");
    // เก็บเฉพาะแท็ก <br> จากข้อความที่มาจาก backend
    safe = safe
        .replace(/&lt;\/?\s*br\s*\/?&gt;/gi, "<br>")
        .replace(/&lt;\/?\s*\/br\s*&gt;/gi, "<br>");
    return safe;
}

function clearPredictionDetailRows() {
    const mainBody = document.getElementById('main_list');
    const secBody = document.getElementById('sec_list');
    if (mainBody) mainBody.innerHTML = '';
    if (secBody) secBody.innerHTML = '';
}
// แก้ไขปัญหาข้อมูลซ้ำในรายละเอียดการทำนาย
function normalizeDuplicateKey(value) {
    return String(value ?? "")
        .normalize("NFKC")
        .replace(/<\/?\s*br\s*\/?>/gi, " ")
        .replace(/[\u200B-\u200D\uFEFF]/g, "")
        .replace(/[\[\]\(\),]/g, " ")
        .replace(/\s+/g, " ")
        .trim()
        .toLowerCase();
}

function renderPredictionDetailRows(targetBody, list, detail, per, reason, classPrefix, sharedSeenTitles) {
    if (!targetBody) return;
    targetBody.innerHTML = "";

    if (!Array.isArray(list) || list.length === 0) {
        targetBody.innerHTML = "<tr><td colspan='3' style='text-align:center;color:#888;'>ไม่พบข้อมูลรายละเอียด</td></tr>";
        return;
    }

    const seenRows = new Set();
    const seenTitles = sharedSeenTitles instanceof Set ? sharedSeenTitles : new Set();
    let renderedCount = 0;

    for (let i = 0; i < list.length; i += 1) {
        const listRaw = list?.[i] ?? "-";
        const detailRaw = detail?.[i] ?? "-";
        const reasonRaw = reason?.[i] ?? "-";
        const titleKey = normalizeDuplicateKey(listRaw);
        const rowKey = [
            titleKey,
            normalizeDuplicateKey(detailRaw),
            normalizeDuplicateKey(reasonRaw)
        ].join("|");

        if (titleKey && seenTitles.has(titleKey)) continue;
        if (rowKey && seenRows.has(rowKey)) continue;

        if (titleKey) seenTitles.add(titleKey);
        if (rowKey) seenRows.add(rowKey);

        const listItem = escapeHtml(listRaw);
        const detailItem = formatWithLineBreaks(detailRaw);
        const reasonItem = formatWithLineBreaks(reasonRaw);
        const percentText = escapeHtml(formatPercent(per?.[i]));

        targetBody.innerHTML +=
            "<tr>" +
                `<td class='popup-container ${classPrefix}_l' title='${listItem}' style='border:1px solid #000;'>${listItem}</td>` +
                `<td class='popup-container ${classPrefix}_d' title='${percentText}' style='border:1px solid #000;'>${detailItem}</td>` +
                `<td class='ok popup-container' style='border:1px solid #000;'><span class='check ${classPrefix}_r'>${reasonItem}</span></td>` +
            "</tr>";
        renderedCount += 1;
    }

    if (renderedCount === 0) {
        targetBody.innerHTML = "<tr><td colspan='3' style='text-align:center;color:#888;'>ไม่พบข้อมูลรายละเอียด</td></tr>";
    }
}

window.openPredictionView = function (btn) {
    const tr = btn.closest('tr');
    const d  = tr.dataset;
    const predictionId = d.predId || '';

    document.getElementById('predModalDate').innerText      = d.predDate      || '-';
    document.getElementById('predModalDoctor').innerText    = d.predDoctor    || '-';
    document.getElementById('predModalResult').innerText    = d.predResult    || '-';
    document.getElementById('predModalSelected').innerText  = d.predSelected  || '-';
    document.getElementById('predModalConfident').innerText = d.predConfident || '-';
    document.getElementById('predModalLabList').innerText   = d.predLabList   || '-';

    const mainBody = document.getElementById('main_list');
    const secBody = document.getElementById('sec_list');
    clearPredictionDetailRows();

    document.getElementById('predictionViewModal').classList.add('active');

    if (!predictionId) {
        if (mainBody) mainBody.innerHTML = "<tr><td colspan='3' style='text-align:center;color:#888;'>ไม่พบรหัสการทำนาย</td></tr>";
        if (secBody) secBody.innerHTML = "<tr><td colspan='3' style='text-align:center;color:#888;'>ไม่พบรหัสการทำนาย</td></tr>";
        return;
    }

    fetch('patientData.jsp?action=prediction_detail&id=' + encodeURIComponent(predictionId))
        .then(res => {
            if (!res.ok) throw new Error('fetch failed');
            return res.json();
        })
        .then(data => {
            if (data?.predict_result) {
                document.getElementById('predModalResult').innerText = data.predict_result;
            }
            const sharedSeenTitles = new Set();
            renderPredictionDetailRows(mainBody, data?.main_list, data?.main_detail, data?.main_per, data?.main_reason, 'main', sharedSeenTitles);
            renderPredictionDetailRows(secBody, data?.sec_list, data?.sec_detail, data?.sec_per, data?.sec_reason, 'sec', sharedSeenTitles);
        })
        .catch(() => {
            if (mainBody) mainBody.innerHTML = "<tr><td colspan='3' style='text-align:center;color:red;'>โหลดรายละเอียดไม่สำเร็จ</td></tr>";
            if (secBody) secBody.innerHTML = "<tr><td colspan='3' style='text-align:center;color:red;'>โหลดรายละเอียดไม่สำเร็จ</td></tr>";
        });
};
window.closePredictionView = function () {
    clearPredictionDetailRows();
    document.getElementById('predictionViewModal').classList.remove('active');
};