const rowsPerPage = 10;
let currentPage = 1;
let filteredCases = [];

function escapeHtml(str) {
    if (str == null) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}
// 
function parseDateRange(val) {
    val = (val || '').trim();
    if (!val) return { from: '', to: '' };
    const parts = val.split(' to ');
    return { from: parts[0] || '', to: parts.length === 2 ? parts[1] : parts[0] };
}
// filter case with search input
function filterCases() {
    const staffRange       = parseDateRange(document.getElementById('staffAppointmentDateSearch').value);
    const appointmentRange = parseDateRange(document.getElementById('appointmentDateSearch').value);
    const patientIdTerm    = (document.getElementById('patientIdSearch').value   || '').trim().toLowerCase();
    const patientNameTerm  = (document.getElementById('patientNameSearch').value || '').trim().toLowerCase();
    const confidenceMin    = (document.getElementById('confidenceSearch').value  || '').trim();
    const statusTerm       = (document.getElementById('examStatusSearch').value  || '').trim();

    filteredCases = finishedCasesData.filter(row => {
        const sad = row.staff_appointment_date || '';
        const ad  = row.appointment_date || '';

        if (staffRange.from && sad < staffRange.from) return false;
        if (staffRange.to   && sad > staffRange.to)   return false;
        if (appointmentRange.from && ad < appointmentRange.from) return false;
        if (appointmentRange.to   && ad > appointmentRange.to)   return false;

        if (patientIdTerm) {
            const pid = 'p' + String(row.patient_id).padStart(7, '0');
            if (!pid.includes(patientIdTerm)) return false;
        }
        if (patientNameTerm && !(row.patient_name || '').toLowerCase().includes(patientNameTerm)) return false;
        if (confidenceMin !== '') {
            const conf = parseFloat(row.confident);
            if (isNaN(conf) || conf < parseFloat(confidenceMin)) return false;
        }
        if (statusTerm && row.appointment_status !== statusTerm) return false;
        return true;
    });

    currentPage = 1;
    displayTable();
}
// display table with pagination
function displayTable() {
    const tbody      = document.getElementById('resultsTableBody');
    const pagination = document.getElementById('pagination');

    tbody.innerHTML = '';

    const startIdx = (currentPage - 1) * rowsPerPage;
    const endIdx   = Math.min(startIdx + rowsPerPage, filteredCases.length);
    const pageRows = filteredCases.slice(startIdx, endIdx);

    if (pageRows.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:#888;">ไม่พบข้อมูลตรงตามเงื่อนไข</td></tr>';

        setupPagination(0);
        return;
    }

    const statusMap = {
        'completed':   'นัดตรวจสำเร็จ',
        'unreachable': 'ติดต่อไม่ได้',
        'rejected':    'คนไข้ปฏิเสธการตรวจ',
        'changeToHos': 'เปลี่ยนไปตรวจโรงพยาบาล'
    };

    pageRows.forEach(row => {
        const tr = document.createElement('tr');
        const patientId   = 'P' + String(row.patient_id).padStart(7, '0');
        const confidence  = parseFloat(row.confident).toFixed(0);
        const statusText  = statusMap[row.appointment_status] || escapeHtml(row.appointment_status);
        const statusClass = 'status-' + (row.appointment_status in statusMap ? row.appointment_status : 'unknown');

        const today = new Date().toISOString().slice(0, 10);
        // วันนัดที่เจ้าหน้าที่ตั้ง กับ วันนัดที่ส่งตรวจ ถ้าเป็นวันในอดีตแล้วจะไม่สามารถลบได้
        const sadDate = (row.staff_appointment_date && row.staff_appointment_date !== '-') ? row.staff_appointment_date.slice(0, 10) : '';
        const sadPast = sadDate && sadDate < today;
        const canReset = !sadPast && ((row.appointment_date && row.appointment_date >= today) || (sadDate && sadDate >= today));
        if (canReset) tr.dataset.predId = row.id;
        if (canReset) tr.dataset.canReset = '1';

        tr.innerHTML = `
            <td>${escapeHtml(row.staff_appointment_date || '-')}</td>
            <td>${escapeHtml(row.appointment_date || '-')}</td>
            <td>${escapeHtml(patientId)}</td>
            <td>${escapeHtml(row.patient_name)}</td>
            <td>${escapeHtml(confidence)}</td>
            <td><span class="${statusClass}">${statusText}</span></td>
            <td>${canReset ? '<button class="btn-delete-case">&#10005;</button>' : ''}</td>
        `;
        if (canReset) {
            tr.querySelector('.btn-delete-case').addEventListener('click', function () {
                if (!confirm('ยืนยันการเปลี่ยนสถานะเคสนี้เป็น pending?')) return;
                deleteCase(row.id);
            });
        }
        tbody.appendChild(tr);
    });

    setupPagination(filteredCases.length);
}

function setupPagination(totalItems) {
    const pagination = document.getElementById('pagination');
    pagination.innerHTML = '';
    const totalPages = Math.ceil(totalItems / rowsPerPage);
    if (totalPages <= 1) return;

    let startPage = Math.max(1, currentPage - 5);
    let endPage   = Math.min(totalPages, startPage + 9);
    startPage     = Math.max(1, endPage - 9);

    if (currentPage > 1) {
        const prev = document.createElement('button');
        prev.textContent = '<<';
        prev.onclick = () => { currentPage--; displayTable(); };
        pagination.appendChild(prev);
    }

    for (let i = startPage; i <= endPage; i++) {
        const btn = document.createElement('button');
        btn.textContent = i;
        if (i === currentPage) btn.classList.add('active');
        btn.onclick = () => { currentPage = i; displayTable(); };
        pagination.appendChild(btn);
    }

    if (currentPage < totalPages) {
        const next = document.createElement('button');
        next.textContent = '>>';
        next.onclick = () => { currentPage++; displayTable(); };
        pagination.appendChild(next);
    }
}
// ปรับขนาด search box ให้ตรงกับ column header
function syncSearchToTable() {
    const ths = document.querySelectorAll('#resultsTable thead th');
    const boxes = document.querySelectorAll('.search-container .search-box');
    if (!ths.length || !boxes.length) return;
    ths.forEach(function(th, i) {
        if (boxes[i]) boxes[i].style.width = th.offsetWidth + 'px';
    });
}

document.addEventListener('DOMContentLoaded', function () {
    flatpickr('#staffAppointmentDateSearch',  { mode: 'range', dateFormat: 'Y-m-d' });
    flatpickr('#appointmentDateSearch',        { mode: 'range', dateFormat: 'Y-m-d' });

    filteredCases = [...finishedCasesData];
    displayTable();
    syncSearchToTable();
    window.addEventListener('resize', syncSearchToTable);
});

function deleteCase(id) {
    const form = document.createElement('form');
    form.method = 'post';
    form.action = 'finishedTask.jsp';
    [['action', 'deleteCase'], ['predId', id]].forEach(([n, v]) => {
        const i = document.createElement('input');
        i.type = 'hidden'; i.name = n; i.value = v;
        form.appendChild(i);
    });
    document.body.appendChild(form);
    form.submit();
}
