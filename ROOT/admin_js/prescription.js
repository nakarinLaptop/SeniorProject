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
    let filteredPrescriptions = [];

    const tableBody  = document.querySelector("#prescriptionTable tbody");
    const pagination = document.getElementById("pagination");

    let prescriptions = (typeof prescriptionsData !== "undefined") ? [...prescriptionsData] : [];
    filteredPrescriptions = [...prescriptions];

    flatpickr("#searchDate", {
        mode: "range",
        dateFormat: "Y-m-d",
    });

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
            tr.dataset.prescriptionId = p.prescription_id;
            tr.innerHTML = `
                <td>${p.date            || "-"}</td>
                <td>${p.patientCode     || "-"}</td>
                <td>${p.patient         || "-"}</td>
                <td>${p.doctor          || "-"}</td>
                <td>${p.medicine_count  || "0"}</td>
                <td><button class="detail-btn">ดูรายละเอียด</button></td>
            `;
            tr.querySelector(".detail-btn").addEventListener("click", () => {
                viewPrescriptionDetail(p.prescription_id);
            });
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
                displayTable(filteredPrescriptions, currentPage);
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

    window.filterPrescriptions = function () {
        const dateRange   = parseDateRange(document.getElementById("searchDate")?.value);
        const codeTerm    = (document.getElementById("searchPatientCode")   ?.value || "").trim().toLowerCase();
        const patientTerm = (document.getElementById("searchPatient")       ?.value || "").trim().toLowerCase();
        const doctorTerm  = (document.getElementById("searchDoctor")        ?.value || "").trim().toLowerCase();
        const countTerm   = (document.getElementById("searchMedicineCount") ?.value || "").trim().toLowerCase();

        filteredPrescriptions = prescriptions.filter(p => {
            if (dateRange.from || dateRange.to) {
                const prescDate = new Date((p.date || "").split(" ")[0]);
                if (dateRange.from && prescDate < new Date(dateRange.from)) return false;
                if (dateRange.to   && prescDate > new Date(dateRange.to))   return false;
            }
            return (p.patientCode    || "").toLowerCase().includes(codeTerm)    &&
                   (p.patient        || "").toLowerCase().includes(patientTerm) &&
                   (p.doctor         || "").toLowerCase().includes(doctorTerm)  &&
                   (p.medicine_count || "").toLowerCase().includes(countTerm);
        });
        currentPage = 1;
        displayTable(filteredPrescriptions, currentPage);
    };

    window.viewPrescriptionDetail = function (prescriptionId) {
        const tableSection  = document.getElementById("prescriptionTableContainerAdmin");
        const detailSection = document.getElementById("prescriptionDetailSection");

        const p = prescriptions.find(x => x.prescription_id == prescriptionId);
        if (p) {
            document.getElementById("pvDate").textContent        = p.date        || "-";
            document.getElementById("pvPatientCode").textContent = p.patientCode || "-";
            document.getElementById("pvPatient").textContent     = p.patient     || "-";
            document.getElementById("pvDoctor").textContent      = p.doctor      || "-";
        }

        const tbody = document.querySelector("#medicineTable tbody");
        tbody.innerHTML = "<tr><td>-</td></tr>";

        tableSection.style.display  = "none";
        detailSection.classList.add("open");

        fetch(`../doctor/prescription.jsp?action=detail&prescription_id=${encodeURIComponent(prescriptionId)}`)
            .then(r => r.json())
            .then(medicines => {
                tbody.innerHTML = "";
                if (!medicines || medicines.length === 0) {
                    tbody.innerHTML = `<tr><td>ไม่พบรายการยา</td></tr>`;
                    return;
                }
                medicines.forEach(m => {
                    const tr = document.createElement("tr");
                    tr.innerHTML = `
                        <td>${m.medicine_name || "-"}</td>
                        <td>${m.quantity      || "-"}</td>
                        <td>${m.unit          || "-"}</td>
                        <td>${m.frequency     || "-"}</td>
                        <td>${m.helper_label  || "-"}</td>
                    `;
                    tbody.appendChild(tr);
                });
            })
            .catch(() => {
                tbody.innerHTML = `<tr><td>ไม่สามารถโหลดรายละเอียดได้</td></tr>`;
            });
    };

    displayTable(filteredPrescriptions, currentPage);
});

function backToTable() {
    document.getElementById("prescriptionDetailSection").classList.remove("open");
    document.getElementById("prescriptionTableContainerAdmin").style.display = "";
}