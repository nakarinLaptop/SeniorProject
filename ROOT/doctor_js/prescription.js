const DEFAULT_DRUG_AMOUNT = "20";
const DEFAULT_DRUG_UNIT = "เม็ด";
const DEFAULT_DRUG_USAGE = "วันละ 3 ครั้ง หลังอาหาร";

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

document.addEventListener("DOMContentLoaded", function(){
    document.getElementById("prescriptionPage").classList.remove("editing-mode");
    // Set default quantity to 20
    var drugAmountInput = document.getElementById("drugAmount");
    if (drugAmountInput) drugAmountInput.value = DEFAULT_DRUG_AMOUNT;

    // Set default unit
    var drugUnitInput = document.getElementById("drugUnitInput");
    if (drugUnitInput) drugUnitInput.value = DEFAULT_DRUG_UNIT;

    // Set default frequency
    var drugUsageInput = document.getElementById("drugUsage");
    if (drugUsageInput) drugUsageInput.value = DEFAULT_DRUG_USAGE;

    const rowsPerPage = 10;
    let currentPage = 1;

    const tableBody = document.querySelector("#prescriptionTable tbody");
    const pagination = document.getElementById("pagination");

    let prescriptions = [];
    let filteredPrescriptions = [];
    
    function loadPrescriptionsFromTable() {
        prescriptions = [];
        const rows = tableBody.querySelectorAll("tr");

        rows.forEach(function(row) {
            const cols = row.querySelectorAll("td");
            if (cols.length < 5) return;

            prescriptions.push({
                prescriptionId:  row.dataset.prescriptionId || "",
                datetime:        cols[0].innerText.trim(),
                doctorName:      cols[1].innerText.trim(),
                healthcareRight: cols[2].innerText.trim(),
                amount:          cols[3].innerText.trim(),
                date:            row.dataset.date || "",
                healthRightId:   row.dataset.healthRightId || ""
            });
        });
        filteredPrescriptions = [...prescriptions];
    }

    function displayTable(data, page){
        tableBody.innerHTML = "";

        const start = (page-1)*rowsPerPage;
        const end = start + rowsPerPage;
        const paginated = data.slice(start, end);

        paginated.forEach(p=>{
            let tr = document.createElement("tr");
            tr.dataset.prescriptionId = p.prescriptionId;
            tr.dataset.date           = p.date;
            tr.dataset.healthRightId  = p.healthRightId;
            tr.dataset.healthRight    = p.healthcareRight;
            tr.innerHTML = `
                <td>${p.datetime}</td>
                <td>${p.doctorName}</td>
                <td>${p.healthcareRight}</td>
                <td>${p.amount}</td>
                <td>
                    <button class="detailBtn" onclick="showPrescriptionDialog(this.closest('tr'))">ดูรายละเอียด</button>
                </td>
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

    loadPrescriptionsFromTable();
    displayTable(filteredPrescriptions, currentPage);
    
    flatpickr("#searchDate", {
        mode: "range",
        dateFormat: "Y-m-d",
    });
    

    window.filterPrescriptionTable = function() {
        const dateRange           = parseDateRange(document.getElementById("searchDate").value);
        const searchDoctor        = document.getElementById("searchDoctor").value.toLowerCase();
        const searchHealthRight   = document.getElementById("searchHealthRight").value.toLowerCase();
        const searchMedicineCount = document.getElementById("searchMedicineCount").value.toLowerCase();

        filteredPrescriptions = prescriptions.filter(function(p) {
            if (dateRange.from || dateRange.to) {
                const prescDate = new Date(p.datetime.split(" ")[0]);
                if (dateRange.from && prescDate < new Date(dateRange.from)) return false;
                if (dateRange.to   && prescDate > new Date(dateRange.to))   return false;
            }
            if (!p.doctorName.toLowerCase().includes(searchDoctor))           return false;
            if (!p.healthcareRight.toLowerCase().includes(searchHealthRight)) return false;
            if (!p.amount.toLowerCase().includes(searchMedicineCount))        return false;
            return true;
        });

        currentPage = 1;
        displayTable(filteredPrescriptions, currentPage);
        setupPagination(filteredPrescriptions.length, currentPage);
    };

    // auto-load after save/edit
    const urlParams = new URLSearchParams(window.location.search);
    const editPrescId = urlParams.get('prescriptionId');
    if (editPrescId) {
        loadAndDisplayPrescription(parseInt(editPrescId));
    }
});

// combobox
document.addEventListener("DOMContentLoaded", () => {
    const comboboxes = document.querySelectorAll(".combobox");

    comboboxes.forEach(comboBox => {
        const input = comboBox.querySelector("input");
        const list = comboBox.querySelector(".combo-list");
        const items = comboBox.querySelectorAll(".item");

        if (!input || !list || items.length === 0) return;

        input.addEventListener("focus", () => {
            list.classList.remove("hidden");
        });

        items.forEach(item => {
            item.addEventListener("click", () => {
                input.value = item.textContent;
                list.classList.add("hidden");
                items.forEach(i => i.style.display = "block");
            });
        });

        input.addEventListener("input", () => {
            const filter = input.value.toLowerCase();
            items.forEach(item => {
                const text = item.textContent.toLowerCase();
                item.style.display = text.includes(filter) ? "block" : "none";
            });
        });

        // ปิด list เมื่อคลิกนอก combobox
        document.addEventListener("click", (e) => {
            if (!comboBox.contains(e.target)) {
                list.classList.add("hidden");
            }
        });
    });
});

function addDrugToTable() {
    const drugInput = document.getElementById("drugInput");
    const drugAmount = document.getElementById("drugAmount");
    const drugUnitInput = document.getElementById("drugUnitInput");
    const drugUsage = document.getElementById("drugUsage");
    const drugHelperLabel = document.getElementById("drugHelperLabel");
    
    const name = drugInput ? drugInput.value : "";
    const amount = drugAmount.value.trim();
    const unit = drugUnitInput.value.trim();
    const frequency = drugUsage.value.trim();
    const helperLabel = drugHelperLabel.value.trim();

    // check input
    if (!name) {
        showToast("กรุณาเลือกยา", "error");
        return;
    }
    if (!amount || amount <= 0) {
        showToast("กรุณาระบุจำนวนที่ถูกต้อง", "error");
        return;
    }
    if (!unit) {
        showToast("กรุณาระบุหน่วย", "error");
        return;
    }
    if (!frequency) {
        showToast("กรุณาระบุความถี่", "error");
        return;
    }

    const existingRows = document.querySelectorAll("#drugTable tbody tr");
    for (let i = 0; i < existingRows.length; i++) {
        const cellName = existingRows[i].querySelector("td:first-child");
        if (cellName && cellName.textContent.trim() === name) {
            showToast("ยานี้ถูกเพิ่มในตารางแล้ว", "error");
            return;
        }
    }
    
    const tbody = document.querySelector("#drugTable tbody");
    const row = document.createElement("tr");
    const isAllergyDrug = drugInput && drugInput.dataset.isAllergy === "true";
    if (isAllergyDrug) {
        row.style.backgroundColor = "#ffe1e1";
        row.style.borderLeft = "4px solid #e53935";
    }
    row.innerHTML = `
        <td>${escapeHtml(name)}</td>
        <td>${escapeHtml(amount)}</td>
        <td>${escapeHtml(unit)}</td>
        <td>${escapeHtml(frequency)}</td>
        <td>${escapeHtml(helperLabel)}</td>
        <td>
            <button type="button" onclick="removeDrugRow(this)">ลบ</button>
        </td>
    `;

    tbody.appendChild(row);
    refreshDrugTableEmpty();

    // Reset form to defaults after adding
    drugAmount.value = DEFAULT_DRUG_AMOUNT;
    drugUnitInput.value = DEFAULT_DRUG_UNIT;
    drugUsage.value = DEFAULT_DRUG_USAGE;
    drugHelperLabel.value = "";
    if (drugInput) {
        drugInput.value = "";
        drugInput.dataset.isAllergy = "false";
        drugInput.style.backgroundColor = "";
        drugInput.style.borderColor = "";
    }
}




function refreshDrugTableEmpty() {
    const tbody = document.querySelector("#drugTable tbody");
    if (!tbody) return;
    const realRows = Array.from(tbody.querySelectorAll("tr")).filter(r => !r.dataset.emptyPlaceholder);
    let placeholder = tbody.querySelector("tr[data-empty-placeholder]");
    if (realRows.length === 0) {
        if (!placeholder) {
            const tr = document.createElement("tr");
            tr.dataset.emptyPlaceholder = "true";
            tr.innerHTML = "<td colspan='6' style='text-align:center;padding:14px;color:#888;'>ไม่มีการสั่งยา</td>";
            tbody.appendChild(tr);
        }
    } else {
        if (placeholder) placeholder.remove();
    }
}

function removeDrugRow(btn) {
    btn.closest("tr").remove();
    refreshDrugTableEmpty();
}

function addHiddenInput(container, name, value) {
    const input = document.createElement("input");
    input.type  = "hidden";
    input.name  = name;
    input.value = value;
    container.appendChild(input);
}

function savePrescription() {
    const tbody = document.querySelector("#drugTable tbody");
    if (!tbody) {
        showToast("ไม่พบตารางยา", "error");
        return;
    }

    const rows = Array.from(tbody.querySelectorAll("tr")).filter(r => !r.dataset.emptyPlaceholder);

    const container = document.getElementById("hiddenInputs");
    if (!container) {
        showToast("ไม่พบฟอร์มสำหรับบันทึก", "error");
        return;
    }
    container.innerHTML = "";

    const prescriptionIdInput = document.getElementById("currentPrescriptionId");
    if (prescriptionIdInput && prescriptionIdInput.value) {
        addHiddenInput(container, "prescription_id", prescriptionIdInput.value);
    }

    const healthcareRightSelect = document.getElementById("healthcareRight");
    const rightIdValue = healthcareRightSelect ? healthcareRightSelect.value : "PayYourself";
    addHiddenInput(container, "right_id", rightIdValue);

    if (rows.length === 0) {
        addHiddenInput(container, "no_medicine", "true");
    } else {
        rows.forEach(function(row) {
            const cells = row.querySelectorAll("td");
            addHiddenInput(container, "medicine_name[]", cells[0].textContent.trim());
            addHiddenInput(container, "quantity[]",      cells[1].textContent.trim());
            addHiddenInput(container, "unit[]",          cells[2].textContent.trim());
            addHiddenInput(container, "frequency[]",     cells[3].textContent.trim());
            addHiddenInput(container, "helper_label[]",  cells[4].textContent.trim());
        });
    }

    const form = document.getElementById("prescriptionForm");
    if (!form) {
        showToast("ไม่พบฟอร์มสำหรับส่งข้อมูล", "error");
        return;
    }
    form.submit();
}

let selectedMedicineName = "";

function openDrugPopup() {
    selectedMedicineName = "";
    const popup = document.getElementById("drugPopup");
    if (popup) {
        popup.style.display = "block";
        const items = popup.querySelectorAll(".itemList");
        items.forEach(i=> i.style.display = "none");
    }
}
function closeDrugPopup() {
    const popup = document.getElementById("drugPopup");
    if (popup) {
        popup.style.display = "none";
        document.getElementById("drugSearch").value = "";
        selectedMedicineName = "";
        const items = popup.querySelectorAll(".itemList");
        items.forEach(item => {
            item.style.display = "none";
            item.classList.remove("selected");
        });
    }
}

function selectDrug(id) {
    const selectedItem = document.querySelector(`#drugPopup .itemList[data-med-id="${id}"]`);
    if (selectedItem) {
        selectedMedicineName = selectedItem.dataset.medName;

        const drugInput = document.getElementById("drugInput");
        const isAllergyDrug = selectedItem.dataset.isAllergy === "true";
        if (drugInput) {
            drugInput.dataset.isAllergy = isAllergyDrug ? "true" : "false";
        }
    }
    const items = document.querySelectorAll("#drugPopup .itemList");
    items.forEach(function(item) {
        if (item.dataset.medId === id) {
            item.classList.add("selected");
        } else {
            item.classList.remove("selected");
        }
    });
}

function filterDrugList() {
    const term = document.getElementById("drugSearch").value.toLowerCase().trim();
    const items = document.querySelectorAll("#drugPopup .itemList");

    const seenNames = new Set();

    items.forEach(item => {
        const name = item.textContent.toLowerCase().trim();
        const isMatch = name.includes(term);

        if (isMatch && !seenNames.has(name)) {
            item.style.display = "block";
            seenNames.add(name);
        } else {
            item.style.display = "none";
        }
    });
}

function addSelectedMedicine() {
    if (!selectedMedicineName) {
        showToast("กรุณาเลือกยา", "error");
        return;
    }
    const input = document.getElementById("drugInput");
    if (input) {
        input.value = selectedMedicineName;
        const isAllergyDrug = input.dataset.isAllergy === "true";
        if (isAllergyDrug) {
            input.style.backgroundColor = "#ffe1e1";
            input.style.borderColor = "#e53935";
            showToast("คำเตือน: คนไข้แพ้ยานี้จากประวัติล่าสุด", "error");
        } else {
            input.style.backgroundColor = "";
            input.style.borderColor = "";
        }
    }
    closeDrugPopup();
}

function editPrescription() {
    document.getElementById("prescriptionDB").style.display = "none";
    document.getElementById("prescriptionPage").style.display = "grid";
}

function generatePDF() {
    const modalActive = document.getElementById("prescriptionDetailModal").classList.contains("active");

    var rows, rightText, issuedAt;

    if (modalActive) {
        const contentEl = document.getElementById("prescModalContent");
        rows = contentEl ? Array.from(contentEl.querySelectorAll("tbody tr")) : [];
        rightText = document.getElementById("prescModalRight").innerText || "-";
        issuedAt  = document.getElementById("prescModalDate").innerText  || "-";
    } else {
        const tbody = document.querySelector("#drugTable tbody");
        if (!tbody) {
            showToast("ไม่พบข้อมูลสำหรับพิมพ์", "error");
            return;
        }
        rows = Array.from(tbody.querySelectorAll("tr"))
            .filter(function(row) { return row.querySelectorAll("td").length >= 6; });
        const healthcareRight = document.getElementById("healthcareRight");
        rightText = healthcareRight && healthcareRight.selectedOptions.length
            ? healthcareRight.selectedOptions[0].textContent.trim()
            : "-";
        const now = new Date();
        issuedAt = now.toLocaleString("th-TH", {
            year: "numeric", month: "2-digit", day: "2-digit",
            hour: "2-digit", minute: "2-digit"
        });
    }

    const bodyRowsHtml = rows.map(function(row, index) {
        const cells = row.querySelectorAll("td");
        const name = cells[0] ? cells[0].textContent.trim() : "";
        const quantity = cells[1] ? cells[1].textContent.trim() : "";
        const unit = cells[2] ? cells[2].textContent.trim() : "";
        const frequency = cells[3] ? cells[3].textContent.trim() : "";
        const helperLabel = cells[4] ? cells[4].textContent.trim() : "";

        return "<tr>" +
            "<td>" + (index + 1) + "</td>" +
            "<td>" + escapeHtml(name) + "</td>" +
            "<td>" + escapeHtml(quantity) + "</td>" +
            "<td>" + escapeHtml(unit) + "</td>" +
            "<td>" + escapeHtml(frequency) + "</td>" +
            "<td>" + escapeHtml(helperLabel) + "</td>" +
            "</tr>";
    }).join("");

    const printWindow = window.open("", "_blank", "width=1100,height=850");

    const noneMedHtml = "<tr><td colspan='6' style='text-align:center;padding:12px;color:#888;'>ไม่มีการสั่งยา</td></tr>";

    const printableHtml = "<!doctype html>" +
        "<html><head><meta charset='UTF-8'>" +
        "<style>" +
        "@page{size:A4;margin:0;}" +
        "*{box-sizing:border-box;}" +
        "body{font-family:'TH Sarabun New','Tahoma',sans-serif;color:#222;margin:0; padding:12mm;}" +
        ".paper{width:100%;}" +
        ".head{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:10px;}" +
        "h1{margin:0;font-size:28px;}" +
        ".meta{font-size:14px;line-height:1.45;}" +
        "table{width:100%;border-collapse:collapse;margin-top:10px;font-size:14px;}" +
        "th,td{border:1px solid #888;padding:6px 8px;vertical-align:top;}" +
        "th{background:#f2f2f2;text-align:center;}" +
        "td:nth-child(1),td:nth-child(3),td:nth-child(4){text-align:center;}" +
        ".foot{margin-top:24px;display:flex;justify-content:space-between;font-size:14px;}" +
        ".sign{width:220px;text-align:center;}" +
        ".line{margin-top:40px;border-top:1px solid #333;padding-top:4px;}" +
        "</style></head><body>" +
        "<div class='paper'>" +
        "<div class='head'>" +
        "<h1>ใบสั่งยา</h1>" +
        "<div class='meta'>" +
        "<div><strong>วันที่ออกใบสั่งยา:</strong> " + escapeHtml(issuedAt) + "</div>" +
        "<div><strong>สิทธิการรักษา:</strong> " + escapeHtml(rightText) + "</div>" +
        "<div><strong>จำนวนรายการยา:</strong> " + rows.length + "</div>" +
        "</div></div>" +
        "<table>" +
        "<thead><tr>" +
        "<th style='width:40px'>ลำดับ</th>" +
        "<th>ชื่อยา</th>" +
        "<th style='width:70px'>จำนวน</th>" +
        "<th style='width:90px'>หน่วย</th>" +
        "<th style='width:230px'>ความถี่</th>" +
        "<th style='width:260px'>ฉลากช่วย</th>" +
        "</tr></thead>" +
        "<tbody>" + (rows.length > 0 ? bodyRowsHtml : noneMedHtml) + "</tbody>" +
        "</table>" +
        "<div class='foot'>" +
        "<div class='sign'><div class='line'>ผู้สั่งยา</div></div>" +
        "<div class='sign'><div class='line'>ผู้รับยา</div></div>" +
        "</div>" +
        "</div>" +
        "<script>window.onload=function(){window.focus();window.print();};window.onafterprint=function(){window.close();};<\/script>" +
        "</body></html>";

    printWindow.document.open();
    printWindow.document.write(printableHtml);
    printWindow.document.close();
}

function gotoPrescriptionTable() {
    document.getElementById("prescriptionPage").classList.remove("editing-mode");
    
    document.getElementById("prescriptionTableContainer").style.display = "block";
    document.getElementById("addDrugContainer").style.display = "none";
}
function gotoAddDrug() {
    document.getElementById("prescriptionPage").classList.remove("editing-mode");
    
    document.getElementById("prescriptionTableContainer").style.display = "none";
    document.getElementById("addDrugContainer").style.display = "grid";
    
    document.querySelector("#drugTable tbody").innerHTML = "";
    refreshDrugTableEmpty();
    document.getElementById("prescriptionDetail").innerHTML = "";
    document.getElementById("healthcareRight").selectedIndex = 0;
    
    const prescriptionIdInput = document.getElementById("currentPrescriptionId");
    if (prescriptionIdInput) {
        prescriptionIdInput.remove();
    }
}

function clearPrescriptionForm() {
    document.getElementById("prescriptionPage").classList.remove("editing-mode");

    document.querySelector("#drugTable tbody").innerHTML = "";
    refreshDrugTableEmpty();
    document.getElementById("prescriptionDetail").innerHTML = "";
    document.getElementById("healthcareRight").selectedIndex = 0;

    const prescriptionIdInput = document.getElementById("currentPrescriptionId");
    if (prescriptionIdInput) {
        prescriptionIdInput.remove();
    }

    document.getElementById("drugAmount").value = DEFAULT_DRUG_AMOUNT;
    document.getElementById("drugUnitInput").value = DEFAULT_DRUG_UNIT;
    document.getElementById("drugUsage").value = DEFAULT_DRUG_USAGE;
    const drugInput = document.getElementById("drugInput");
    if (drugInput) {
        drugInput.value = "";
        drugInput.dataset.isAllergy = "false";
        drugInput.style.backgroundColor = "";
        drugInput.style.borderColor = "";
    }
}

function viewPrescriptionDetailById(prescriptionId, date, healthRightId) {
    document.getElementById("prescriptionPage").classList.add("editing-mode");

    document.getElementById("prescriptionTableContainer").style.display = "none";
    document.getElementById("addDrugContainer").style.display = "grid";

    document.getElementById("prescriptionDetail").innerHTML = `
        <p style="margin: 10px 0; padding: 12px 16px; background-color: #fff3cd; border-left: 4px solid #ff9800; border-radius: 4px; font-weight: bold; color: #333;">
            <strong>📋 กำลังแก้ไข:</strong> ${date}
        </p>
    `;

    const hasHealthRight = healthRightId && healthRightId !== 'null';
    document.getElementById("healthcareRight").value = hasHealthRight ? healthRightId : "PayYourself";

    let prescriptionIdInput = document.getElementById("currentPrescriptionId");
    if (!prescriptionIdInput) {
        prescriptionIdInput = document.createElement("input");
        prescriptionIdInput.type = "hidden";
        prescriptionIdInput.id   = "currentPrescriptionId";
        document.getElementById("addDrugContainer").appendChild(prescriptionIdInput);
    }
    prescriptionIdInput.value = prescriptionId;

    fetch(`prescription.jsp?action=detail&prescription_id=${encodeURIComponent(prescriptionId)}`)
        .then(function(response) { return response.json(); })
        .then(function(medicines) {
            const tbody = document.querySelector("#drugTable tbody");
            tbody.innerHTML = "";

            if (!medicines || medicines.length === 0) {
                tbody.innerHTML = `<tr><td colspan="6" style="text-align:center;">ไม่พบข้อมูลยา</td></tr>`;
                return;
            }

            medicines.forEach(function(medicine) {
                const medRow = document.createElement("tr");
                medRow.innerHTML = `
                    <td>${medicine.medicine_name}</td>
                    <td>${medicine.quantity}</td>
                    <td>${medicine.unit}</td>
                    <td>${medicine.frequency}</td>
                    <td>${medicine.helper_label}</td>
                    <td><button type="button" onclick="removeDrugRow(this)">ลบ</button></td>
                `;
                tbody.appendChild(medRow);
            });
            refreshDrugTableEmpty();
        })
        .catch(function(error) {
            showToast("เกิดข้อผิดพลาดในการโหลดข้อมูล: " + error.message, "error");
        });
}

function closePrescriptionDetailModal() {
    document.getElementById("prescriptionDetailModal").classList.remove("active");
}

function showPrescriptionDialog(row) {
    const prescriptionId  = row.dataset.prescriptionId || "";
    const date            = row.dataset.date            || "";
    const healthcareRight = row.dataset.healthRight     || row.dataset.healthcareRight || "-";
    const healthRightId   = row.dataset.healthRightId   || "";

    document.getElementById("prescModalDate").innerText  = date            || "-";
    document.getElementById("prescModalRight").innerText = healthcareRight || "-";
    document.getElementById("prescModalContent").innerHTML = "กำลังโหลด...";

    const today   = (typeof SERVER_TODAY !== 'undefined') ? SERVER_TODAY : new Date().toISOString().slice(0, 10);
    const isToday = date && date.slice(0, 10) === today;

    const editBtn   = document.getElementById("editPrescBtn");
    const deleteBtn = document.getElementById("deletePrescBtn");

    editBtn.style.display   = isToday ? "inline-block" : "none";
    deleteBtn.style.display = isToday ? "inline-block" : "none";

    editBtn.onclick = function() {
        closePrescriptionDetailModal();
        loadAndDisplayPrescription(prescriptionId);
    };
    deleteBtn.onclick = function() {
        deletePrescriptionById(prescriptionId);
    };

    document.getElementById("prescriptionDetailModal").classList.add("active");

    fetch(`prescription.jsp?action=detail&prescription_id=${encodeURIComponent(prescriptionId)}`)
        .then(function(res) { return res.json(); })
        .then(function(medicines) {
            const content = document.getElementById("prescModalContent");
            if (!medicines || medicines.length === 0) {
                content.innerHTML = '<p style="color:#888;text-align:center;">ไม่พบข้อมูลยา</p>';
                return;
            }
            let html = '<table style="width:100%;border-collapse:collapse;font-size:14px;">';
            html += '<thead><tr style="background:#007bff;color:#fff;">';
            html += '<th style="padding:6px 8px;">ชื่อยา</th><th style="padding:6px 8px;">จำนวน</th><th style="padding:6px 8px;">หน่วย</th><th style="padding:6px 8px;">ความถี่</th><th style="padding:6px 8px;">ฉลากช่วย</th>';
            html += '</tr></thead><tbody>';
            medicines.forEach(function(m) {
                html += '<tr style="border-bottom:1px solid #eee;">';
                html += '<td style="padding:6px 8px;">'                     + escapeHtml(m.medicine_name)     + '</td>';
                html += '<td style="padding:6px 8px;text-align:center;">'   + escapeHtml(m.quantity)          + '</td>';
                html += '<td style="padding:6px 8px;text-align:center;">'   + escapeHtml(m.unit)              + '</td>';
                html += '<td style="padding:6px 8px;">'                     + escapeHtml(m.frequency)         + '</td>';
                html += '<td style="padding:6px 8px;">'                     + escapeHtml(m.helper_label || '') + '</td>';
                html += '</tr>';
            });
            html += '</tbody></table>';
            content.innerHTML = html;
        })
        .catch(function() {
            document.getElementById("prescModalContent").innerHTML = '<p style="color:red;">เกิดข้อผิดพลาด</p>';
        });
}

function deletePrescriptionById(prescriptionId) {
    if (!confirm("ต้องการลบใบสั่งยานี้หรือไม่?")) return;
    const form = document.createElement("form");
    form.method = "POST";
    form.action = "prescription.jsp?action=delete";
    const idInput = document.createElement("input");
    idInput.type = "hidden"; idInput.name = "prescription_id"; idInput.value = prescriptionId;
    form.appendChild(idInput);
    document.body.appendChild(form);
    form.submit();
}

function loadAndDisplayPrescription(prescriptionId) {
    fetch(`prescription.jsp?action=getFullPrescription&prescription_id=${encodeURIComponent(prescriptionId)}`)
        .then(res => res.json())
        .then(data => {
            if (!data || !data.prescription) return;
            const p = data.prescription;
            document.getElementById("prescriptionTableContainer").style.display = "none";
            document.getElementById("addDrugContainer").style.display = "grid";
            document.getElementById("prescriptionPage").classList.add("editing-mode");
            document.getElementById("prescriptionDetail").innerHTML =
                '<p style="margin:10px 0;padding:12px 16px;background:#fff3cd;border-left:4px solid #ff9800;border-radius:4px;font-weight:bold;color:#333;">' +
                '<strong>กำลังแก้ไข:</strong> ' + escapeHtml(p.date) + '</p>';
            const hr = p.healthRight;
            document.getElementById("healthcareRight").value = (hr && hr !== 'null') ? hr : "PayYourself";
            let prescriptionIdInput = document.getElementById("currentPrescriptionId");
            if (!prescriptionIdInput) {
                prescriptionIdInput = document.createElement("input");
                prescriptionIdInput.type = "hidden";
                prescriptionIdInput.id = "currentPrescriptionId";
                document.getElementById("addDrugContainer").appendChild(prescriptionIdInput);
            }
            prescriptionIdInput.value = prescriptionId;
            const tbody = document.querySelector("#drugTable tbody");
            tbody.innerHTML = "";
            if (data.drugs && data.drugs.length > 0) {
                data.drugs.forEach(function(medicine) {
                    const medRow = document.createElement("tr");
                    medRow.innerHTML =
                        '<td>' + escapeHtml(medicine.medicine_name) + '</td>' +
                        '<td>' + escapeHtml(medicine.quantity) + '</td>' +
                        '<td>' + escapeHtml(medicine.unit) + '</td>' +
                        '<td>' + escapeHtml(medicine.frequency) + '</td>' +
                        '<td>' + escapeHtml(medicine.helper_label) + '</td>' +
                        '<td><button type="button" onclick="removeDrugRow(this)">ลบ</button></td>';
                    tbody.appendChild(medRow);
                });
            }
            refreshDrugTableEmpty();
        })
        .catch(err => console.error('Error loading prescription:', err));
}