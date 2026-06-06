// เปลี่ยนสี case-row ตามสถานะ
function changeRowColor(selectEl) {
    const row = selectEl.closest('.case-row');
    if (!row) return;

    const status = selectEl.value;

    row.classList.remove('complete', 'changeToHos', 'rejected');

    if (status === 'completed') {
        row.classList.add('complete');
    } else if (status === 'changeToHos') {
        row.classList.add('changeToHos');
    } else if (status === 'rejected') {
        row.classList.add('rejected');
    }
}

function toggleAppointmentDateInput(selectEl) {
    const row = selectEl.closest('.case-row');
    if (!row) return;

    const dateInput = row.querySelector('.appointment-datetime');
    if (!dateInput) return;

    const isCompleted = selectEl.value === 'completed';
    dateInput.style.display = isCompleted ? 'block' : 'none';

    if (!isCompleted) {
        dateInput.value = '';
    } else {
        //lock date input to today or later
        const now = new Date();
        const pad = n => String(n).padStart(2, '0');
        const todayMin = now.getFullYear() + '-' + pad(now.getMonth()+1) + '-' + pad(now.getDate()) + 'T00:00';
        dateInput.min = todayMin;
    }
}
// ที่จดบันทึกเพิ่มเติมสำหรับแต่ละคนไข้
let currentSelectedPredId = null;
const noteCache = {};

function setupNoteEditor() {
    const noteArea = document.getElementById('staffAppointmentNote');
    if (!noteArea) return;

    noteArea.addEventListener('input', function () {
        if (currentSelectedPredId !== null) {
            noteCache[currentSelectedPredId] = noteArea.value;
        }
    });
}

// เปลี่ยนสีตาม dropdown สถานะ
document.addEventListener('change', function (e) {
    if (e.target.classList.contains('status-select')) {
        changeRowColor(e.target);
        toggleAppointmentDateInput(e.target);
    }
});
// แสดง/ซ่อน input วันที่ตามสถานะ
document.addEventListener('DOMContentLoaded', function () {
    const selects = document.querySelectorAll('.status-select');
    selects.forEach(select => {
        changeRowColor(select);
        toggleAppointmentDateInput(select);
    });

    const pad = n => String(n).padStart(2, '0');
    const now = new Date();
    const todayMin = now.getFullYear() + '-' + pad(now.getMonth()+1) + '-' + pad(now.getDate()) + 'T00:00';
    document.querySelectorAll('.appointment-datetime').forEach(function(inp) {
        inp.min = todayMin;
    });
    setupNoteEditor();
});

// บันทึกสถานะทั้งหมด
function saveAllStatus() {
    const statusSelects = document.querySelectorAll('.status-select');
    const form = document.getElementById('statusForm');
    if (!form) {
        showToast('ไม่พบฟอร์มสำหรับบันทึก', 'error');
        return;
    }

    form.innerHTML = '';
    let hasUpdates = false;
    let missingDateInput = null;

    statusSelects.forEach(select => {
        const predId = select.getAttribute('data-pred-id');
        const status = select.value;
        const row = select.closest('.case-row');
        const appointmentInput = row ? row.querySelector('.appointment-datetime') : null;
        const appointmentDatetime = appointmentInput ? appointmentInput.value : '';
        const appointmentNote = noteCache[predId] || '';

        if (predId && status) {
            if (status === 'completed' && !appointmentDatetime) {
                if (!missingDateInput) missingDateInput = appointmentInput;
                return;
            }

            hasUpdates = true;

            const idInput = document.createElement('input');
            idInput.type = 'hidden';
            idInput.name = 'predictionId';
            idInput.value = predId;
            form.appendChild(idInput);

            const statusInput = document.createElement('input');
            statusInput.type = 'hidden';
            statusInput.name = 'appointmentStatus';
            statusInput.value = status;
            form.appendChild(statusInput);

            const datetimeInput = document.createElement('input');
            datetimeInput.type = 'hidden';
            datetimeInput.name = 'appointmentDatetime';
            datetimeInput.value = appointmentDatetime;
            form.appendChild(datetimeInput);

            const noteInput = document.createElement('input');
            noteInput.type = 'hidden';
            noteInput.name = 'appointmentNote';
            noteInput.value = appointmentNote;
            form.appendChild(noteInput);
        }
    });

    if (missingDateInput) {
        showToast('กรุณาเลือกวันที่นัดตรวจสำหรับสถานะนัดตรวจสำเร็จ', 'error');
        missingDateInput.style.display = 'block';
        missingDateInput.focus();
        return;
    }

    if (!hasUpdates) {
        showToast('กรุณาเลือกสถานะสำหรับคนไข้ที่ต้องการบันทึก', 'error');
        return;
    }

    form.submit();
}

function calculateAge(birthDateStr) {
    if (!birthDateStr) return "-";
    const birth = new Date(birthDateStr);
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const m = today.getMonth() - birth.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
    return age;
}

function escapeHtml(value) {
    return String(value ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

let selectedRow = null;
function loadCaseDetail(rowElement) {
    const ds = rowElement.dataset;
    const newSelectedPredId = ds.predId;
    const noteArea = document.getElementById('staffAppointmentNote');

    if (currentSelectedPredId !== null && noteArea) {
        noteCache[currentSelectedPredId] = noteArea.value;
    }

    if (selectedRow) {
        selectedRow.style.background = "";
    }
    rowElement.style.background = "#969595";
    selectedRow = rowElement;
    currentSelectedPredId = newSelectedPredId;

    if (noteArea) {
        if (noteCache[newSelectedPredId] === undefined) {
            noteCache[newSelectedPredId] = ds.staffAppointmentNote || '';
        }
        noteArea.value = noteCache[newSelectedPredId] || '';
    }

    document.getElementById("patientCode").innerText = "รหัสคนไข้ : " + (ds.patientCode || "-");
    document.getElementById("patientName").innerText = "ชื่อ นามสกุล : " + (ds.fullname || "-");
    document.getElementById("patientGender").innerText = "เพศ : " + (ds.gender || "-");
    document.getElementById("patientAge").innerText = "อายุ : " + calculateAge(ds.birthDate) + " ปี";
    document.getElementById("patientAddress").innerText = "ที่อยู่ : " + (ds.address || "-");
    document.getElementById("patientMarriageStatus").innerText = "สถานะการแต่งงาน : " + (ds.marriageStatus || "-");
    document.getElementById("patientOccupation").innerText = "อาชีพ : " + (ds.occupation || "-");
    document.getElementById("patientICD10").innerText = "โรคประจำตัว : " + (ds.icd10 || "-");
    document.getElementById("patientPhoneNum").innerText = "เบอร์โทรศัพท์ : " + (ds.phoneNum || "-");
    document.getElementById("patientLabList").innerText = "รายการแล็บที่ต้องตรวจ : " + (ds.labList || "-");
}

