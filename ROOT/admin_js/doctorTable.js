document.addEventListener("DOMContentLoaded", function () {
    const rowsPerPage = 10;
    let currentPage = 1;
    let filteredDoctors = [];

    const tableBody = document.querySelector("#doctorTable tbody");
    const pagination = document.getElementById("pagination");

    let doctors = (typeof doctorsData !== "undefined") ? [...doctorsData] : [];
    filteredDoctors = [...doctors];

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

        pageItems.forEach(function(d) {
            const tr = document.createElement("tr");
            tr.dataset.id = d.id;
            const titleEsc    = (d.title      || "").replace(/'/g, "\\'");
            const firstEsc    = (d.first_name || "").replace(/'/g, "\\'");
            const lastEsc     = (d.last_name  || "").replace(/'/g, "\\'");
            const usernameEsc = (d.username   || "").replace(/'/g, "\\'");
            tr.innerHTML = `
                <td class="col-hidden">${d.id}</td>
                <td>${d.doctor_code}</td>
                <td>${d.title}</td>
                <td>${d.first_name}</td>
                <td>${d.last_name}</td>
                <td class="col-center">${d.exam_count || "0"}</td>
                <td class="col-center">${d.predict_count || "0"}</td>
                <td class="col-center">${d.prescription_count || "0"}</td>
                <td class="col-action">
                    <button class="search-btn"
                        onclick="openEditDialog('${d.id}','${titleEsc}','${firstEsc}','${lastEsc}','${usernameEsc}')">แก้ไข</button>
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
                displayTable(filteredDoctors, currentPage);
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
    
    window.filterDoctors = function () {
        const codeTerm     = document.getElementById("searchCode").value.trim().toLowerCase();
        const titleTerm    = document.getElementById("searchTitle").value.trim().toLowerCase();
        const firstTerm    = document.getElementById("searchFirstName").value.trim().toLowerCase();
        const lastTerm     = document.getElementById("searchLastName").value.trim().toLowerCase();
        const examTerm     = document.getElementById("searchExam").value.trim().toLowerCase();
        const predictTerm  = document.getElementById("searchPredict").value.trim().toLowerCase();
        const prescTerm    = document.getElementById("searchPrescription").value.trim().toLowerCase();

        filteredDoctors = doctors.filter(d =>
            (d.doctor_code        || "").toLowerCase().includes(codeTerm)    &&
            (d.title              || "").toLowerCase().includes(titleTerm)   &&
            (d.first_name         || "").toLowerCase().includes(firstTerm)   &&
            (d.last_name          || "").toLowerCase().includes(lastTerm)    &&
            (d.exam_count         || "").toLowerCase().includes(examTerm)    &&
            (d.predict_count      || "").toLowerCase().includes(predictTerm) &&
            (d.prescription_count || "").toLowerCase().includes(prescTerm)
        );
        currentPage = 1;
        displayTable(filteredDoctors, currentPage);
    };
    displayTable(filteredDoctors, currentPage);
});

function openAddDialog() {
    document.getElementById("addDoctorDialog").style.display = "flex";
}
function closeAddDialog() {
    document.getElementById("addDoctorDialog").style.display = "none";
}

function openEditDialog(id, title, firstName, lastName, username) {
    document.getElementById("editDoctorId").value        = id;
    document.getElementById("editDoctorTitle").value     = title;
    document.getElementById("editDoctorFirstName").value = firstName;
    document.getElementById("editDoctorLastName").value  = lastName;
    document.getElementById("editDoctorUsername").value  = username;
    document.getElementById("editDoctorPassword").value  = "";
    document.getElementById("editDoctorPasswordConfirm").value = "";
    document.getElementById("editDoctorDialog").style.display = "flex";
}
function validateEditForm() {
    const pw  = document.getElementById("editDoctorPassword").value;
    const pw2 = document.getElementById("editDoctorPasswordConfirm").value;
    if (pw !== pw2) {
        alert("รหัสผ่านไม่ตรงกัน กรุณากรอกใหม่");
        return false;
    }
    return true;
}
function closeEditDialog() {
    document.getElementById("editDoctorDialog").style.display = "none";
}
function deleteDoctor() {
    const id = document.getElementById("editDoctorId").value;
    if (!id) return;
    if (!confirm("ยืนยันการลบแพทย์รายนี้?")) return;
    document.getElementById("deleteDoctorId").value = id;
    document.getElementById("deleteDoctorForm").submit();
}
function openRestoreDoctorDialog() {
    document.getElementById("restoreDoctorDialog").style.display = "flex";
}
function closeRestoreDoctorDialog() {
    document.getElementById("restoreDoctorDialog").style.display = "none";
}
function selectRestoreDoctor(el) {
    document.querySelectorAll("#restoreDoctorList li").forEach(function(li) {
        li.classList.remove("selected");
    });
    el.classList.add("selected");
}
function confirmRestoreDoctor() {
    const selected = document.querySelector("#restoreDoctorList li.selected");
    if (!selected || !selected.dataset.id) {
        alert("กรุณาเลือกแพทย์ที่ต้องการกู้คืน");
        return;
    }
    document.getElementById("restoreDoctorId").value = selected.dataset.id;
    document.getElementById("restoreDoctorForm").submit();
}
