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
    let filteredHistories = [];

    const tableBody  = document.querySelector("#historyTable tbody");
    const pagination = document.getElementById("pagination");

    let histories = (typeof historiesData !== "undefined") ? [...historiesData] : [];
    filteredHistories = [...histories];

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

        pageItems.forEach(h => {
            const tr = document.createElement("tr");
            tr.dataset.historyId = h.history_id;
            tr.innerHTML = `
                <td>${h.date || "-"}</td>
                <td>${h.patientCode || "-"}</td>
                <td>${h.patient || "-"}</td>
                <td>${h.doctor || "-"}</td>
                <td>${h.text ? h.text.substring(0, 60) + (h.text.length > 60 ? "..." : "") : "-"}</td>
                <td>${h.icds  || "-"}</td>
                <td>${h.drugs || "-"}</td>
                <td><button class="detail-btn">ดูรายละเอียด</button></td>
            `;
            //add data in modal
            tr.querySelector(".detail-btn").addEventListener("click", () => {
                openHistoryView(h.date, h.doctor, h.patientCode, h.patient, h.text, h.icds, h.drugs);
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
                displayTable(filteredHistories, currentPage);
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

    window.filterHistories = function () {
        const dateRange   = parseDateRange(document.getElementById("searchDate")?.value);
        const codeTerm    = (document.getElementById("searchPatientCode") ?.value || "").trim().toLowerCase();
        const patientTerm = (document.getElementById("searchPatient")     ?.value || "").trim().toLowerCase();
        const doctorTerm  = (document.getElementById("searchDoctor")      ?.value || "").trim().toLowerCase();
        const textTerm    = (document.getElementById("searchText")        ?.value || "").trim().toLowerCase();
        const icdTerm     = (document.getElementById("searchIcd")         ?.value || "").trim().toLowerCase();
        const drugTerm    = (document.getElementById("searchDrug")        ?.value || "").trim().toLowerCase();

        filteredHistories = histories.filter(h => {
            if (dateRange.from || dateRange.to) {
                const historyDate = new Date((h.date || "").split(" ")[0]);
                if (dateRange.from && historyDate < new Date(dateRange.from)) return false;
                if (dateRange.to   && historyDate > new Date(dateRange.to))   return false;
            }
            return (h.patientCode || "").toLowerCase().includes(codeTerm)    &&
                   (h.patient     || "").toLowerCase().includes(patientTerm) &&
                   (h.doctor      || "").toLowerCase().includes(doctorTerm)  &&
                   (h.text        || "").toLowerCase().includes(textTerm)    &&
                   (h.icds        || "").toLowerCase().includes(icdTerm)     &&
                   (h.drugs       || "").toLowerCase().includes(drugTerm);
        });
        currentPage = 1;
        displayTable(filteredHistories, currentPage);
    };

    window.openHistoryView = function (date, doctor, patientCode, patient, text, icds, drugs) {
        document.getElementById("date").textContent        = date        || "-";
        document.getElementById("doctor").textContent      = doctor      || "-";
        document.getElementById("patientCode").textContent = patientCode || "-";
        document.getElementById("patient").textContent     = patient     || "-";
        document.getElementById("drug_allergy").textContent= drugs       || "-";
        document.getElementById("icd10").textContent       = icds        || "-";
        document.getElementById("text").value              = text        || "-";
        document.getElementById("text").readOnly           = true;

        const saveBtn = document.getElementById("saveBtn");
        const editBtn = document.getElementById("editBtn");
        if (saveBtn) saveBtn.style.display = "none";
        if (editBtn) editBtn.style.display = "none";

        document.getElementById("historyViewDialog").style.display = "block";
    };

    window.closeHistoryView = function () {
        document.getElementById("historyViewDialog").style.display = "none";
    };

    /*  ICD / Drug popup (search filter)  */
    window.filterIcdList = function () {
        const term = document.getElementById("icdSearch").value.toLowerCase();
        document.querySelectorAll("#icdPopup .itemList").forEach(el => {
            el.style.display = el.textContent.toLowerCase().includes(term) ? "block" : "none";
        });
    };

    window.filterDrugList = function () {
        const term = document.getElementById("drugSearch").value.toLowerCase();
        document.querySelectorAll("#drugPopup .itemList").forEach(el => {
            el.style.display = el.textContent.toLowerCase().includes(term) ? "block" : "none";
        });
    };

    window.closeIcdPopup  = () => { document.getElementById("icdPopup").style.display  = "none"; };
    window.closeDrugPopup = () => { document.getElementById("drugPopup").style.display = "none"; };

    displayTable(filteredHistories, currentPage);
});
