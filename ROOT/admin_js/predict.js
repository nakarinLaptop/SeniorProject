function escapeHtml(str) {
    if (str == null) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function parseDateRange(val) {
    val = (val || '').trim();
    if (!val) return { from: '', to: '' };
    const parts = val.split(' to ');
    return { from: parts[0] || '', to: parts.length === 2 ? parts[1] : parts[0] };
}

document.addEventListener("DOMContentLoaded", function () {
    const rowsPerPage = 10;
    let currentPage = 1;
    let filteredPredictions = [];

    const tableBody  = document.querySelector("#predictTable tbody");
    const pagination = document.getElementById("pagination");

    let predictions = (typeof predictionsData !== "undefined") ? [...predictionsData] : [];
    filteredPredictions = [...predictions];

    flatpickr("#searchDate", {
        mode: "range",
        dateFormat: "Y-m-d",
    });
    //แก้ confidnet เป็น%
    function formatConfident(val) {
        if (!val || val === "null") return "-";
        const num = parseFloat(val);
        if (isNaN(num)) return "-";
        const pct = num <= 1 ? num * 100 : num;
        return pct.toFixed(1) + "%";
    }

    function statusBadge(status) {
        const map = {
            pending:     '<span class="status-pending">pending</span>',
            completed:   '<span class="status-completed">completed</span>',
            unreachable: '<span class="status-unreachable">unreachable</span>',
            rejected:    '<span class="status-rejected">rejected</span>',
        };
        return map[status] || (status || "-");
    }

    function displayTable(data, page) {
        tableBody.innerHTML = "";
        const start = (page - 1) * rowsPerPage;
        const pageItems = data.slice(start, start + rowsPerPage);

        if (pageItems.length === 0) {
            const tr = document.createElement("tr");
            tr.innerHTML = "<td>ไม่พบข้อมูล</td>";
            tableBody.appendChild(tr);
            setupPagination(0, 1);
            return;
        }

        pageItems.forEach(p => {
            const tr = document.createElement("tr");
            tr.dataset.id = p.id;
            tr.innerHTML = `
                <td>${p.created_at      || "-"}</td>
                <td>${p.patient_code    || "-"}</td>
                <td>${p.patient_name    || "-"}</td>
                <td>${p.doctor_name     || "-"}</td>
                <td>${p.predict_result  || "-"}</td>
                <td>${p.doctor_selected || "-"}</td>
                <td>${formatConfident(p.confident)}</td>
                <td>${statusBadge(p.appointment_status)}</td>
            `;
            tableBody.appendChild(tr);
        });

        setupPagination(data.length, page);
    }

    function setupPagination(totalItems, page) {
        pagination.innerHTML = "";
        const totalPages = Math.ceil(totalItems / rowsPerPage);
        if (totalPages <= 1) return;

        function createBtn(text, goToPage, isActive, disabled) {
            const btn = document.createElement("button");
            btn.textContent = text;
            if (isActive) btn.className = "active";
            if (disabled) {
                btn.disabled = true;
                btn.style.opacity = "0.4";
            }
            btn.onclick = () => {
                if (disabled || isActive) return;
                currentPage = goToPage;
                displayTable(filteredPredictions, currentPage);
            };
            pagination.appendChild(btn);
        }

        const showArrows = totalPages > 10;

        if (showArrows) createBtn("<<", page - 1, false, page === 1);

        let startPage = Math.max(1, page - 5);
        let endPage = Math.min(totalPages, startPage + 9);
        startPage = Math.max(1, endPage - 9);

        for (let i = startPage; i <= endPage; i++) {
            createBtn(i, i, i === page, false);
        }

        if (showArrows) createBtn(">>", page + 1, false, page === totalPages);
    }

    window.filterPredictions = function () {
        const dateTerm     = (document.getElementById("searchDate")              ?.value || "").trim();
        const codeTerm     = (document.getElementById("searchPatientCode")       ?.value || "").trim().toLowerCase();
        const patientTerm  = (document.getElementById("searchPatient")           ?.value || "").trim().toLowerCase();
        const doctorTerm   = (document.getElementById("searchDoctor")            ?.value || "").trim().toLowerCase();
        const predictTerm  = (document.getElementById("searchPredictResult")     ?.value || "").trim().toLowerCase();
        const selectedTerm = (document.getElementById("searchDoctorSelected")    ?.value || "").trim().toLowerCase();
        const statusTerm   = (document.getElementById("searchAppointmentStatus") ?.value || "").trim().toLowerCase();
        const confMinRaw  = document.getElementById("searchConfidentMin")?.value.trim();
        const confMaxRaw  = document.getElementById("searchConfidentMax")?.value.trim();
        const confMin     = confMinRaw !== "" ? parseFloat(confMinRaw) : null;
        const confMax     = confMaxRaw !== "" ? parseFloat(confMaxRaw) : null;

        const dateRange    = parseDateRange(dateTerm);
        filteredPredictions = predictions.filter(p => {
            if (dateRange.from || dateRange.to) {
                const d = new Date((p.created_at || "").split(" ")[0]);
                if (dateRange.from && d < new Date(dateRange.from)) return false;
                if (dateRange.to   && d > new Date(dateRange.to))   return false;
            }
            // Confident
            let confMatch = true;
            if (confMin !== null || confMax !== null) {
                const raw = parseFloat(p.confident);
                if (!isNaN(raw)) {
                    const pct = raw <= 1 ? raw * 100 : raw;
                    if (confMin !== null && pct < confMin) confMatch = false;
                    if (confMax !== null && pct > confMax) confMatch = false;
                } else {
                    confMatch = false;
                }
            }
            return confMatch &&
                (p.patient_code       || "").toLowerCase().includes(codeTerm)     &&
                (p.patient_name       || "").toLowerCase().includes(patientTerm)  &&
                (p.doctor_name        || "").toLowerCase().includes(doctorTerm)   &&
                (p.predict_result     || "").toLowerCase().includes(predictTerm)  &&
                (p.doctor_selected    || "").toLowerCase().includes(selectedTerm) &&
                (p.appointment_status || "").toLowerCase().includes(statusTerm);
        });
        currentPage = 1;
        displayTable(filteredPredictions, currentPage);
    };

    displayTable(filteredPredictions, currentPage);
});
