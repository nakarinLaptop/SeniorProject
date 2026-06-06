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

let currentPatientId = null;
let patients = (typeof patientsData !== "undefined") ? [...patientsData] : [];

document.addEventListener("DOMContentLoaded", function () {
    const rowsPerPage = 10;
    let currentPage = 1;
    let filteredPatients = [];

    const tableBody = document.querySelector("#patientTable tbody");
    const pagination = document.getElementById("pagination");

    filteredPatients = [...patients];

    flatpickr("#searchDob", {
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

        const d = v => (v && v.trim() !== "") ? v : "-";
        pageItems.forEach(function (p) {
            const tr = document.createElement("tr");
            tr.dataset.id = p.id;
            tr.innerHTML = `
                <td class="col-hidden">${p.id}</td>
                <td>${d(p.patient_code)}</td>
                <td>${d(p.title)}</td>
                <td>${d(p.first_name)}</td>
                <td>${d(p.last_name)}</td>
                <td>${d(p.gender)}</td>
                <td>${d(p.phone_num)}</td>
                <td>${d(p.marriageStatus)}</td>
                <td>${d(p.dob)}</td>
                <td>${d(p.province)}</td>
                <td>${d(p.district)}</td>
                <td>${d(p.subDistrict)}</td>
                <td>${d(p.travelMethod)}</td>
                <td>${d(p.occupation)}</td>
                <td>${d(p.right)}</td>
                <td class="col-action">
                    <button class="search-btn" onclick="openEditDialog('${p.id}')">แก้ไข</button>
                </td>
            `;
            tableBody.appendChild(tr);
        });

        setupPagination(data.length, page);
    }

    function setupPagination(totalItems, page) {
        pagination.innerHTML = "";
        const totalPages = Math.ceil(totalItems / rowsPerPage);
        let startPage = page - 5;

        if (startPage < 1) startPage = 1;

        let endPage = startPage + 9;
        if (endPage > totalPages) {
            endPage = totalPages;
            startPage = Math.max(1, endPage - 9);
        }

        createBtn("<<", Math.max(1, page - 10));

        for (let i = startPage; i <= endPage; i++) {
            createBtn(i, i, i === page);
        }

        createBtn(">>", Math.min(totalPages, page + 10));

        function createBtn(text, goToPage, isActive) {
            const btn = document.createElement("button");
            btn.textContent = text;
            if (isActive) btn.className = "active";
            btn.onclick = () => {
                currentPage = goToPage;
                displayTable(filteredPatients, currentPage);
            };
            pagination.appendChild(btn);
        }
    }

    window.filterPatients = function () {
        const codeTerm = document.getElementById("searchCode").value.trim().toLowerCase();
        const titleTerm = document.getElementById("searchTitle").value.trim().toLowerCase();
        const firstTerm = document.getElementById("searchFirstName").value.trim().toLowerCase();
        const lastTerm = document.getElementById("searchLastName").value.trim().toLowerCase();
        const genderTerm = document.getElementById("searchGender").value.trim().toLowerCase();
        const phoneTerm = document.getElementById("searchPhone").value.trim().toLowerCase();
        const marriageTerm = document.getElementById("searchMarriage").value.trim().toLowerCase();
        const dobTerm = document.getElementById("searchDob").value.trim().toLowerCase();
        const provinceTerm = document.getElementById("searchProvince").value.trim().toLowerCase();
        const districtTerm = document.getElementById("searchDistrict").value.trim().toLowerCase();
        const subDistTerm = document.getElementById("searchSubDistrict").value.trim().toLowerCase();
        const travelTerm = document.getElementById("searchTravel").value.trim().toLowerCase();
        const occupTerm = document.getElementById("searchOccupation").value.trim().toLowerCase();
        const rightTerm = document.getElementById("searchRight").value.trim().toLowerCase();

        const dobRange = parseDateRange(dobTerm);
        filteredPatients = patients.filter(p => {
            if (dobRange.from || dobRange.to) {
                const dobDate = new Date((p.dob || "").split(" ")[0]);
                if (dobRange.from && dobDate < new Date(dobRange.from)) return false;
                if (dobRange.to   && dobDate > new Date(dobRange.to))   return false;
            }
            return (p.patient_code || "").toLowerCase().includes(codeTerm) &&
                (p.title || "").toLowerCase().includes(titleTerm) &&
                (p.first_name || "").toLowerCase().includes(firstTerm) &&
                (p.last_name || "").toLowerCase().includes(lastTerm) &&
                (p.gender || "").toLowerCase().includes(genderTerm) &&
                (p.phone_num || "").toLowerCase().includes(phoneTerm) &&
                (p.marriageStatus || "").toLowerCase().includes(marriageTerm) &&
                (p.province || "").toLowerCase().includes(provinceTerm) &&
                (p.district || "").toLowerCase().includes(districtTerm) &&
                (p.subDistrict || "").toLowerCase().includes(subDistTerm) &&
                (p.travelMethod || "").toLowerCase().includes(travelTerm) &&
                (p.occupation || "").toLowerCase().includes(occupTerm) &&
                (p.right || "").toLowerCase().includes(rightTerm)
        });
        currentPage = 1;
        displayTable(filteredPatients, currentPage);
    };

    displayTable(filteredPatients, currentPage);

    document.getElementById("csvFileInput").addEventListener("change", function () {
        const reader = new FileReader();
        reader.onload = function (e) {
            document.getElementById("csvTextHidden").value = e.target.result;
        };
        reader.readAsText(this.files[0], "UTF-8");
    });

    document.getElementById("csvImportForm").addEventListener("submit", function (e) {
        e.preventDefault();
        if (!prepareCsvSubmit()) return;

        const params = new URLSearchParams({
            action: "importCsv",
            csvText: document.getElementById("csvTextHidden").value
        });

        fetch("patientTable.jsp", {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: params
        })
            .then(res => res.json())
            .then(result => {
                closeCsvDialog();
                closeAddDialog();
                showToast(result.message, result.failed > 0 ? "error" : "success");

                if (result.inserted > 0) {
                    setTimeout(() => location.reload(), 1500);
                }
            })
            .catch(() => showToast("เกิดข้อผิดพลาดในการเชื่อมต่อ", "error"));
    });
});

function backToTable() {
    document.getElementById("rightDetailSection").style.display = "none";
    document.getElementById("patientTableSection").style.display = "block";
}

//add patient dialog
function openAddDialog() {
    document.getElementById("csvImportDialog").style.display = "none";
    document.getElementById("addPatientDialog").style.display = "flex";
}
function closeAddDialog() {
    document.getElementById("addPatientDialog").style.display = "none";
}
// csv add
function openCsvDialog() {
    document.getElementById("csvImportDialog").style.display = "block";
}
function closeCsvDialog() {
    document.getElementById("csvImportDialog").style.display = "none";
    document.getElementById("csvFileInput").value = "";
    document.getElementById("csvTextHidden").value = "";
}
function prepareCsvSubmit() {
    if (!document.getElementById("csvTextHidden").value.trim()) {
        alert("กรุณาเลือกไฟล์ CSV");
        return false;
    }
    return true;
}

// edit patient dialog
function openEditDialog(id) {
    const p = patients.find(x => x.id == id);
    document.getElementById("editPatientId").value = p.id;
    document.getElementById("editTitle").value = p.title || "";
    document.getElementById("editFirstName").value = p.first_name || "";
    document.getElementById("editLastName").value = p.last_name || "";
    document.getElementById("editPhoneNum").value = p.phone_num || "";
    document.getElementById("editProvince").value = p.province || "";
    document.getElementById("editDistrict").value = p.district || "";
    document.getElementById("editSubDistrict").value = p.subDistrict || "";
    document.getElementById("editOccupation").value = p.occupation || "";
    
    const dobRaw = (p.dob || "").split(" ")[0];
    document.getElementById("editDob").value = dobRaw;

    setSelectValue("editGender", p.gender);
    setSelectValue("editMarriageStatus", p.marriageStatus);
    setSelectValue("editTravelMethod", p.travelMethod);
    setSelectValue("editRight", p.right);

    document.getElementById("editPatientDialog").style.display = "flex";
}
// เซ็ตค่า select ให้ตรงกับ value ที่ได้มา
function setSelectValue(selectId, value) {
    const sel = document.getElementById(selectId);
    if (!sel || value == null || value === "") {
        sel.selectedIndex = 0;
        return;
    }
    const val = String(value).trim();
    for (let opt of sel.options) {
        if (String(opt.value).trim() === val) {
            sel.value = opt.value;
            return;
        }
    }
    for (let opt of sel.options) {
        if (String(opt.value).trim().toLowerCase() === val.toLowerCase()) {
            sel.value = opt.value;
            return;
        }
    }
    sel.selectedIndex = 0;
}
function closeEditDialog() {
    document.getElementById("editPatientDialog").style.display = "none";
}
function deletePatient() {
    const id = document.getElementById("editPatientId").value;
    if (!id) return;
    if (!confirm("ยืนยันการลบคนไข้รายนี้?")) return;
    document.getElementById("deletePatientId").value = id;
    document.getElementById("deletePatientForm").submit();
}
function openRestorePatientDialog() {
    document.getElementById("restorePatientDialog").style.display = "flex";
}
function closeRestorePatientDialog() {
    document.getElementById("restorePatientDialog").style.display = "none";
}
function selectRestorePatient(el) {
    document.querySelectorAll("#restorePatientList li").forEach(function(li) {
        li.classList.remove("selected");
    });
    el.classList.add("selected");
}
function confirmRestorePatient() {
    const selected = document.querySelector("#restorePatientList li.selected");
    if (!selected || !selected.dataset.id) {
        alert("กรุณาเลือกคนไข้ที่ต้องการกู้คืน");
        return;
    }
    document.getElementById("restorePatientId").value = selected.dataset.id;
    document.getElementById("restorePatientForm").submit();
}
//csv
function downloadCsvTemplate() {
    const header = '"title","first_name","last_name","gender","phone_num","marriage_status","birth_date","province","district","sub_district","travel_method","occupation","right_name"';
    const example = '"นาย","ชื่อจริง","นามสกุล","ชาย","=""0812345678""","โสด","1990-01-01","กรุงเทพมหานคร","บางรัก","สีลม","รถยนต์ส่วนตัว","พนักงานบริษัท","สิทธิการรักษา"';
    const blob = new Blob(['\uFEFF' + header + '\n' + example], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'patient_template.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}
