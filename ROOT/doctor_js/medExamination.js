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

/* ---------- Open old history from table ---------- */
function openHistoryView(historyId, date, doctor, text, icds, drugs) {
    // เช็คว่าเลยวันไหม
    const today = new Date().toISOString().slice(0, 10);
    const recordDate = date ? date.slice(0, 10) : "";
    if (recordDate !== today) {
        showToast("ไม่สามารถแก้ไขได้ เนื่องจากไม่ใช่รายการของวันนี้", "error");
        return;
    }else showHistoryForm(true);

    document.getElementById("medExaminationPage").classList.add("editing-mode");

    let historyIdInput = document.getElementById("edit_history_id");
    if (!historyIdInput) {
        historyIdInput = document.createElement("input");
        historyIdInput.type = "hidden";
        historyIdInput.id = "edit_history_id";
        historyIdInput.name = "edit_history_id";
        document.getElementById("historyForm").appendChild(historyIdInput);
    }
    historyIdInput.value = historyId;
    // ข้อมูลขึ้นเมื่อกำลังแก้ไข
    document.getElementById("medExamDetail").innerHTML =
        '<div style="padding: 12px 16px; background: #fff3cd; border-left: 4px solid #ff9800; border-radius: 4px; display: inline-block;">' +
        '<b>กำลังแก้ไข:</b> ' + date + '<br>' +
        '<small style="color: #666;">แพทย์: ' + doctor + '</small>' +
        '</div>';

    const textarea = document.querySelector('[name="interview_text"]');
    textarea.value = text;
    textarea.readOnly = false;
    textarea.style.backgroundColor = "";

    // icd table
    const icdTableBody = document.querySelector("#icdTable tbody");
    icdTableBody.innerHTML = "";
    if (icds && icds !== "-") {
        const icdList = icds.split(", ");
        for (let i = 0; i < icdList.length; i++) {
            const icdParts = icdList[i].split(" - ");
            const icdCode = icdParts[0];
            const icdName = icdParts.slice(1).join(" - ");
            const icdRow = document.createElement("tr");
            icdRow.innerHTML =
                '<td>' + icdCode + '<input type="hidden" name="icd_codes[]" value="' + icdCode + '"></td>' +
                '<td>' + icdName + '</td>' +
                '<td><button type="button" onclick="this.closest(\'tr\').remove()">ลบ</button></td>';
            icdTableBody.appendChild(icdRow);
        }
    }
    // drug allergy table
    const drugTableBody = document.querySelector("#drugAllergyTable tbody");
    drugTableBody.innerHTML = "";

    fetch(`medExamination.jsp?history_id=${historyId}&action=getDrugAllergy`)
        .then(response => {
            return response.text();
        })
        .then(text => {
            return JSON.parse(text);
        })
        .then(drugData => {
            if (drugData && drugData.length > 0) {
                drugData.forEach(item => {
                    const drugName = item.drug_name || '';
                    const detail = item.detail || '';
                    const row = document.createElement("tr");
                    row.innerHTML = `
                        <td class="editable-drug">${drugName}<input type="hidden" name="drug_allergy[]" value="${drugName}"></td>
                        <td class="editable-detail">${detail}<input type="hidden" name="drug_detail[]" value="${detail}"></td>
                        <td><button type="button" onclick="editDrugRow(this)">แก้ไข</button></td>
                        <td><button type="button" onclick="this.closest('tr').remove()">ลบ</button></td>
                    `;
                    drugTableBody.appendChild(row);
                });
            } else {
                console.log("No drug allergy data found");
            }
        })
        .catch(error => {
            console.error('Error loading drug allergy details:', error);
        });

    const submitButton = document.getElementById("submitHistoryButton");
    submitButton.style.display = "block";
    submitButton.textContent = "บันทึกการแก้ไข";
    document.getElementById("newExamBtn").style.display = "inline-block";
}

/* ---------- Load and display history after update ---------- */
function loadAndDisplayHistory(historyId) {
    fetch("medExamination.jsp?history_id=" + historyId + "&action=getFullHistory")
        .then(response => response.json())
        .then(data => {
            if (data && data.history) {
                const h = data.history;

                let editHistoryIdInput = document.getElementById("edit_history_id");
                if (!editHistoryIdInput) {
                    editHistoryIdInput = document.createElement("input");
                    editHistoryIdInput.type = "hidden";
                    editHistoryIdInput.id = "edit_history_id";
                    editHistoryIdInput.name = "edit_history_id";
                    document.getElementById("historyForm").appendChild(editHistoryIdInput);
                }
                editHistoryIdInput.value = historyId;

                document.getElementById("medExaminationPage").classList.add("editing-mode");
                document.getElementById("medExamDetail").innerHTML =
                    '<div style="padding: 12px 16px; background: #fff3cd; border-left: 4px solid #ff9800; border-radius: 4px; display: inline-block;">' +
                    '<b>กำลังแก้ไข:</b> ' + h.date + '<br>' +
                    '<small style="color: #666;">แพทย์: ' + (h.doctor || "") + '</small>' +
                    '</div>';

                // กรอกข้อมูลการซักประวัติ
                const textarea = document.querySelector('[name="interview_text"]');
                textarea.value = h.text || "";
                textarea.readOnly = false;

                // กรอก ICD-10
                const icdTableBody = document.querySelector("#icdTable tbody");
                icdTableBody.innerHTML = "";
                if (h.icds && h.icds !== "-") {
                    const icdList = h.icds.split(", ");
                    for (let i = 0; i < icdList.length; i++) {
                        const icdParts = icdList[i].split(" - ");
                        const icdCode = icdParts[0];
                        const icdName = icdParts.slice(1).join(" - ");
                        const icdRow = document.createElement("tr");
                        icdRow.innerHTML =
                            '<td>' + icdCode + '<input type="hidden" name="icd_codes[]" value="' + icdCode + '"></td>' +
                            '<td>' + icdName + '</td>' +
                            '<td><button type="button" onclick="this.closest(\'tr\').remove()">ลบ</button></td>';
                        icdTableBody.appendChild(icdRow);
                    }
                }

                // กรอกยาที่แพ้
                const drugTableBody = document.querySelector("#drugAllergyTable tbody");
                drugTableBody.innerHTML = "";
                if (data.drugs && data.drugs.length > 0) {
                    for (let j = 0; j < data.drugs.length; j++) {
                        const drugName = data.drugs[j].drug_name || "";
                        const detail = data.drugs[j].detail || "";
                        const row = document.createElement("tr");
                        row.innerHTML =
                            '<td class="editable-drug">' + drugName + '<input type="hidden" name="drug_allergy[]" value="' + drugName + '"></td>' +
                            '<td class="editable-detail">' + detail + '<input type="hidden" name="drug_detail[]" value="' + detail + '"></td>' +
                            '<td><button type="button" onclick="editDrugRow(this)">แก้ไข</button></td>' +
                            '<td><button type="button" onclick="this.closest(\'tr\').remove()">ลบ</button></td>';
                        drugTableBody.appendChild(row);
                    }
                }

                // สลับ display ปุ่มและข้อความ
                const submitButton = document.getElementById("submitHistoryButton");
                submitButton.style.display = "block";
                submitButton.textContent = "บันทึกการแก้ไข";
                document.getElementById("newExamBtn").style.display = "inline-block";
            }
        });
}

/* ---------- บันทึกประวัติ ---------- */
function submitHistoryForm() {
    const form = document.getElementById("historyForm");
    const interviewText = form.querySelector('[name="interview_text"]').value.trim();
    if (!interviewText) {
        showToast("กรุณากรอกรายละเอียดการซักประวัติ", "error");
        return;
    }
    const editHistoryId = document.getElementById("edit_history_id");
    const isEdit = editHistoryId && editHistoryId.value;
    document.getElementById("formAction").value = isEdit ? "edit" : "add";
    form.submit();
}

/* ---------- ICD ---------- */
let selectedIcdCode = "";
let selectedIcdName = "";

function openIcdPopup() {
    selectedIcdCode = "";
    selectedIcdName = "";
    document.getElementById("icdPopup").style.display = "block";
}
function closeIcdPopup() {
    document.getElementById("icdPopup").style.display = "none";
    document.getElementById("icdSearch").value = "";
    selectedIcdCode = "";
    selectedIcdName = "";
    const items = document.querySelectorAll("#icdPopup .itemList");
    for (let i = 0; i < items.length; i++) {
        items[i].style.display = "none";
        items[i].classList.remove("selected");
    }
}
function selectIcd(fullText) {
    const parts = fullText.split(" - ");
    selectedIcdCode = parts[0];
    selectedIcdName = parts.slice(1).join(" - ");

    const items = document.querySelectorAll("#icdPopup .itemList");
    for (let i = 0; i < items.length; i++) {
        if (items[i].textContent.trim() === fullText) {
            items[i].classList.add("selected");
        } else {
            items[i].classList.remove("selected");
        }
    }
}
function addSelectedIcd() {
    if (!selectedIcdCode) {
        showToast("กรุณาเลือกโรคประจำตัว", "error");
        return;
    }

    const existingRows = document.querySelectorAll("#icdTable tbody tr");
    for (let i = 0; i < existingRows.length; i++) {
        const hiddenInput = existingRows[i].querySelector('input[name="icd_codes[]"]');
        if (hiddenInput && hiddenInput.value === selectedIcdCode) {
            showToast("รหัส ICD นี้ถูกเพิ่มแล้ว", "error");
            return;
        }
    }
    // add to table
    const tbody = document.querySelector("#icdTable tbody");
    const row = document.createElement("tr");
    row.innerHTML =
        '<td>' + selectedIcdCode + '<input type="hidden" name="icd_codes[]" value="' + selectedIcdCode + '"></td>' +
        '<td>' + selectedIcdName + '</td>' +
        '<td><button type="button" onclick="this.closest(\'tr\').remove()">ลบ</button></td>';
    tbody.appendChild(row);
    closeIcdPopup();
}
function filterIcdList() {
    const term = document.getElementById("icdSearch").value.toLowerCase().trim();
    const items = document.querySelectorAll("#icdPopup .itemList");

    if (term === "") {
        for (let i = 0; i < items.length; i++) {
            items[i].style.display = "none";
        }
        return;
    }

    for (let i = 0; i < items.length; i++) {
        const text = items[i].textContent.toLowerCase();
        const dashIndex = text.indexOf(" - ");
        const code = dashIndex >= 0 ? text.substring(0, dashIndex) : text;
        const name = dashIndex >= 0 ? text.substring(dashIndex + 3) : "";

        if (code.indexOf(term) >= 0 || name.indexOf(term) >= 0) {
            items[i].style.display = "block";
        } else {
            items[i].style.display = "none";
        }
    }
}

/* ---------- DRUG allergy ---------- */
let selectedDrugName = "";
function openDrugPopup() {
    document.getElementById("drugPopup").style.display = "block";
}
function closeDrugPopup() {
    document.getElementById("drugPopup").style.display = "none";
    document.getElementById("drugSearch").value = "";
    document.getElementById("drugAllergyInput").value = "";
    selectedDrugName = "";
    const items = document.querySelectorAll("#drugPopup .itemList");
    for (let i = 0; i < items.length; i++) {
        items[i].style.display = "none";
        items[i].classList.remove("selected");
    }
}
function selectDrug(name) {
    selectedDrugName = name;
    const items = document.querySelectorAll("#drugPopup .itemList");
    for (let i = 0; i < items.length; i++) {
        if (items[i].textContent.trim() === name) {
            items[i].classList.add("selected");
        } else {
            items[i].classList.remove("selected");
        }
    }
}
function addDrugWithAllergy() {
    if (!selectedDrugName) {
        showToast("กรุณาเลือกยาที่แพ้", "error");
        return;
    }

    const existingRows = document.querySelectorAll("#drugAllergyTable tbody tr");
    for (let i = 0; i < existingRows.length; i++) {
        const hiddenInput = existingRows[i].querySelector('input[name="drug_allergy[]"]');
        if (hiddenInput && hiddenInput.value === selectedDrugName) {
            showToast("ยานี้ถูกเพิ่มแล้ว", "error");
            return;
        }
    }

    const symptom = document.getElementById("drugAllergyInput").value.trim();
    const tbody = document.querySelector("#drugAllergyTable tbody");
    const row = document.createElement("tr");
    row.innerHTML =
        '<td class="editable-drug">' + selectedDrugName + '<input type="hidden" name="drug_allergy[]" value="' + selectedDrugName + '"></td>' +
        '<td class="editable-detail">' + symptom + '<input type="hidden" name="drug_detail[]" value="' + symptom + '"></td>' +
        '<td><button type="button" onclick="editDrugRow(this)">แก้ไข</button></td>' +
        '<td><button type="button" onclick="this.closest(\'tr\').remove()">ลบ</button></td>';
    tbody.appendChild(row);
    closeDrugPopup();
}
function editDrugRow(button) {
    const row = button.closest("tr");
    const drugCell = row.querySelector(".editable-drug");
    const detailCell = row.querySelector(".editable-detail");
    const hiddenDrug = drugCell.querySelector('input[name="drug_allergy[]"]');
    const hiddenDetail = detailCell.querySelector('input[name="drug_detail[]"]');
    // edit mode
    if (button.textContent === "แก้ไข") {
        const currentDrug = hiddenDrug.value;
        const currentDetail = hiddenDetail.value;

        drugCell.innerHTML = '<input type="text" class="edit-drug" value="' + currentDrug + '"><input type="hidden" name="drug_allergy[]" value="' + currentDrug + '">';
        detailCell.innerHTML = '<input type="text" class="edit-detail" value="' + currentDetail + '"><input type="hidden" name="drug_detail[]" value="' + currentDetail + '">';
        button.textContent = "บันทึก";
    }
    // save mode 
    else {
        const newDrug = row.querySelector(".edit-drug").value.trim();
        const newDetail = row.querySelector(".edit-detail").value.trim();

        if (!newDrug) {
            showToast("กรุณากรอกชื่อยา", "error");
            return;
        }

        drugCell.innerHTML = newDrug + '<input type="hidden" name="drug_allergy[]" value="' + newDrug + '">';
        detailCell.innerHTML = newDetail + '<input type="hidden" name="drug_detail[]" value="' + newDetail + '">';
        button.textContent = "แก้ไข";
    }
}
function filterDrugList() {
    const term = document.getElementById("drugSearch").value.toLowerCase().trim();
    const items = document.querySelectorAll("#drugPopup .itemList");

    if (term === "") {
        for (let i = 0; i < items.length; i++) {
            items[i].style.display = "none";
        }
        return;
    }

    for (let i = 0; i < items.length; i++) {
        const name = items[i].textContent.toLowerCase();
        if (name.indexOf(term) >= 0) {
            items[i].style.display = "block";
        } else {
            items[i].style.display = "none";
        }
    }
}

/* ----------------- History table ----------------------*/
function showHistoryTable() {
    document.getElementById("historyFormSection").style.display = "none";
    document.getElementById("historyTableSection").style.display = "block";
    document.getElementById("medExaminationPage").classList.remove("editing-mode");
}
function showHistoryForm(skipPrefill) {
    document.getElementById("historyTableSection").style.display = "none";
    document.getElementById("historyFormSection").style.display = "flex";
    document.getElementById("newExamBtn").style.display = "none";

    clearFormData();
    if (!skipPrefill && typeof LATEST_HISTORY_ID !== 'undefined' && LATEST_HISTORY_ID > 0) {
        prefillTablesFromHistory(LATEST_HISTORY_ID);
    }
}
function showHistoryDialog(h) {
    document.getElementById("histModalDate").innerText   = h.date   || "-";
    document.getElementById("histModalDoctor").innerText = h.doctor || "-";
    document.getElementById("histModalText").innerText   = h.text   || "-";
    document.getElementById("histModalIcds").innerText   = h.icds   || "-";
    document.getElementById("histModalDrugs").innerText  = h.drugs  || "-";

    const today      = new Date().toISOString().slice(0, 10);
    const recordDate = h.date ? h.date.slice(0, 10) : "";
    const isToday    = recordDate === today;

    const editBtn   = document.getElementById("editHistoryBtn");
    const deleteBtn = document.getElementById("deleteHistoryBtn");

    if (editBtn) {
        editBtn.style.display = isToday ? "inline-block" : "none";
        editBtn.onclick = function () {
            closeHistoryDialog();
            openHistoryView(h.history_id, h.date, h.doctor, h.text, h.icds, h.drugs);
        };
    }
    if (deleteBtn) {
        deleteBtn.style.display = isToday ? "inline-block" : "none";
        deleteBtn.onclick = function () { deleteHistory(h.history_id); };
    }

    document.getElementById("historyViewModal").classList.add("active");
}
function closeHistoryDialog(){
    document.getElementById("historyViewModal").classList.remove("active");
}
function deleteHistory(historyId) {
    if (!confirm("ต้องการลบรายการซักประวัตินี้หรือไม่?")) return;
    const form = document.createElement("form");
    form.method = "POST";
    form.action = "medExamination.jsp";
    const actionInput = document.createElement("input");
    actionInput.type = "hidden"; actionInput.name = "action"; actionInput.value = "delete";
    form.appendChild(actionInput);
    const idInput = document.createElement("input");
    idInput.type = "hidden"; idInput.name = "history_id"; idInput.value = historyId;
    form.appendChild(idInput);
    document.body.appendChild(form);
    form.submit();
}
function clearFormData() {
    document.getElementById("medExaminationPage").classList.remove("editing-mode");
    document.getElementById("medExamDetail").innerHTML = "";

    const editHistoryId = document.getElementById("edit_history_id");
    if (editHistoryId) {
        editHistoryId.remove();
    }

    const textarea = document.querySelector('[name="interview_text"]');
    textarea.value = "";
    textarea.readOnly = false;
    textarea.style.backgroundColor = "";

    document.querySelector("#icdTable tbody").innerHTML = "";
    document.querySelector("#drugAllergyTable tbody").innerHTML = "";

    const submitButton = document.getElementById("submitHistoryButton");
    submitButton.style.display = "block";
    submitButton.textContent = "บันทึกข้อมูลการซักประวัติ";
}

/* ---------- DOMContentLoaded ---------- */
document.addEventListener("DOMContentLoaded", function () {
    const rowsPerPage = 10;
    let currentPage = 1;
    let histories = [];
    let filteredHistories = [];

    const table = document.getElementById("historyTable");
    const tableBody = table.querySelector("tbody");
    const pagination = document.getElementById("pagination");
    
    function loadHistoriesFromTable() {
        histories = [];
        const rows = tableBody.querySelectorAll("tr");

        for (let i = 0; i < rows.length; i++) {
            const cols = rows[i].querySelectorAll("td");

            if (cols.length === 1 && cols[0].hasAttribute("colspan")) {
                continue;
            }
            if (cols.length < 5) {
                continue;
            }

            histories.push({
                history_id: rows[i].dataset.historyId,
                doctor_id: rows[i].dataset.doctorId,
                date: cols[0].innerText.trim(),
                doctor: cols[1].innerText.trim(),
                text: cols[2].innerText.trim(),
                icds: cols[3].innerText.trim(),
                drugs: cols[4].innerText.trim()
            });
        }

        filteredHistories = histories.slice();
    }

    function displayTable(data, page) {
        tableBody.innerHTML = "";

        const start = (page - 1) * rowsPerPage;
        const end = start + rowsPerPage;
        const pageItems = data.slice(start, end);

        for (let i = 0; i < pageItems.length; i++) {
            const h = pageItems[i];
            const tr = document.createElement("tr");
            tr.dataset.historyId = h.history_id;
            tr.dataset.doctorId = h.doctor_id;

            tr.innerHTML =
                '<td>' + h.date + '</td>' +
                '<td>' + h.doctor + '</td>' +
                '<td>' + h.text + '</td>' +
                '<td>' + h.icds + '</td>' +
                '<td>' + h.drugs + '</td>' +
                '<td></td>';

            const buttonCell = tr.lastElementChild;
            const detailButton = document.createElement("button");
            detailButton.type = "button";
            detailButton.textContent = "ดูรายละเอียด";
            detailButton.onclick = function () {
                showHistoryDialog(h);
            };
            buttonCell.appendChild(detailButton);

            tableBody.appendChild(tr);
        }

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

    loadHistoriesFromTable();
    displayTable(filteredHistories, currentPage);
    setupPagination(filteredHistories.length, currentPage);

    flatpickr("#searchDate", {
        mode: "range",
        dateFormat: "Y-m-d",
    });

    // ฟังก์ชัน filter ตาราง
    window.filterHistoryTable = function () {
        const dateRange    = parseDateRange(document.getElementById("searchDate").value);
        const searchDoctor = document.getElementById("searchDoctor").value.toLowerCase();
        const searchText   = document.getElementById("searchText").value.toLowerCase();
        const searchIcd    = document.getElementById("searchIcd").value.toLowerCase();
        const searchDrug   = document.getElementById("searchDrug").value.toLowerCase();

        filteredHistories = histories.filter(function(h) {
            if (dateRange.from || dateRange.to) {
                const historyDate = new Date(h.date.split(" ")[0]);
                if (dateRange.from && historyDate < new Date(dateRange.from)) return false;
                if (dateRange.to   && historyDate > new Date(dateRange.to))   return false;
            }
            if (!h.doctor.toLowerCase().includes(searchDoctor)) return false;
            if (!h.text.toLowerCase().includes(searchText))     return false;
            if (!h.icds.toLowerCase().includes(searchIcd))      return false;
            if (!h.drugs.toLowerCase().includes(searchDrug))    return false;
            return true;
        });

        currentPage = 1;
        displayTable(filteredHistories, currentPage);
    };

});

/* ---------- Pre-fill ICD + drug allergy tables from latest history on fresh page load ---------- */
function prefillTablesFromHistory(histId) {
    fetch("medExamination.jsp?history_id=" + histId + "&action=getFullHistory")
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (!data || !data.history) return;
            var h = data.history;

            // Fill ICD table
            var icdTableBody = document.querySelector("#icdTable tbody");
            icdTableBody.innerHTML = "";
            if (h.icds && h.icds !== "-") {
                var icdList = h.icds.split(", ");
                for (var i = 0; i < icdList.length; i++) {
                    var icdParts = icdList[i].split(" - ");
                    var icdCode = icdParts[0];
                    var icdName = icdParts.slice(1).join(" - ");
                    var icdRow = document.createElement("tr");
                    icdRow.innerHTML =
                        '<td>' + icdCode + '<input type="hidden" name="icd_codes[]" value="' + icdCode + '"></td>' +
                        '<td>' + icdName + '</td>' +
                        '<td><button type="button" onclick="this.closest(\'tr\').remove()">ลบ</button></td>';
                    icdTableBody.appendChild(icdRow);
                }
            }

            // Fill drug allergy table
            var drugTableBody = document.querySelector("#drugAllergyTable tbody");
            drugTableBody.innerHTML = "";
            if (data.drugs && data.drugs.length > 0) {
                for (var j = 0; j < data.drugs.length; j++) {
                    var drugName = data.drugs[j].drug_name || "";
                    var detail = data.drugs[j].detail || "";
                    var row = document.createElement("tr");
                    row.innerHTML =
                        '<td class="editable-drug">' + drugName + '<input type="hidden" name="drug_allergy[]" value="' + drugName + '"></td>' +
                        '<td class="editable-detail">' + detail + '<input type="hidden" name="drug_detail[]" value="' + detail + '"></td>' +
                        '<td><button type="button" onclick="editDrugRow(this)">แก้ไข</button></td>' +
                        '<td><button type="button" onclick="this.closest(\'tr\').remove()">ลบ</button></td>';
                    drugTableBody.appendChild(row);
                }
            }
        })
        .catch(function() {});
}