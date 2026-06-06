document.addEventListener("DOMContentLoaded", function () {
    const rowsPerPage = 10;
    let currentPage = 1;
    let filteredAdmins = [];

    const tableBody = document.querySelector("#adminTable tbody");
    const pagination = document.getElementById("pagination");

    let admins = (typeof adminsData !== "undefined") ? [...adminsData] : [];
    filteredAdmins = [...admins];

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

        pageItems.forEach(function (d) {
            const tr = document.createElement("tr");
            tr.dataset.id = d.id;
            const titleEsc = (d.title || "").replace(/'/g, "\\'");
            const firstEsc = (d.first_name || "").replace(/'/g, "\\'");
            const lastEsc = (d.last_name || "").replace(/'/g, "\\'");
            const usernameEsc = (d.username || "").replace(/'/g, "\\'");
            tr.innerHTML = `
                <td class="col-hidden">${d.id}</td>
                <td>${d.admin_code}</td>
                <td>${d.title}</td>
                <td>${d.first_name}</td>
                <td>${d.last_name}</td>
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
                displayTable(filteredAdmins, currentPage);
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

    window.filterAdmins = function () {
        const codeTerm = document.getElementById("searchCode").value.trim().toLowerCase();
        const titleTerm = document.getElementById("searchTitle").value.trim().toLowerCase();
        const firstTerm = document.getElementById("searchFirstName").value.trim().toLowerCase();
        const lastTerm = document.getElementById("searchLastName").value.trim().toLowerCase();

        filteredAdmins = admins.filter(d =>
            (d.admin_code || "").toLowerCase().includes(codeTerm) &&
            (d.title || "").toLowerCase().includes(titleTerm) &&
            (d.first_name || "").toLowerCase().includes(firstTerm) &&
            (d.last_name || "").toLowerCase().includes(lastTerm)
        );
        currentPage = 1;
        displayTable(filteredAdmins, currentPage);
    };
    displayTable(filteredAdmins, currentPage);
});

function openAddDialog() {
    document.getElementById("addAdminDialog").style.display = "flex";
}
function closeAddDialog() {
    document.getElementById("addAdminDialog").style.display = "none";
}

function openEditDialog(id, title, firstName, lastName, username) {
    document.getElementById("editAdminId").value = id;
    document.getElementById("editAdminTitle").value = title;
    document.getElementById("editAdminFirstName").value = firstName;
    document.getElementById("editAdminLastName").value = lastName;
    document.getElementById("editAdminUsername").value = username;
    document.getElementById("editAdminPassword").value = "";
    document.getElementById("editAdminPasswordConfirm").value = "";
    document.getElementById("editAdminDialog").style.display = "flex";
}
function validateEditForm() {
    const pw = document.getElementById("editAdminPassword").value;
    const pw2 = document.getElementById("editAdminPasswordConfirm").value;
    if (pw !== pw2) {
        alert("รหัสผ่านไม่ตรงกัน กรุณากรอกใหม่");
        return false;
    }
    return true;
}
function closeEditDialog() {
    document.getElementById("editAdminDialog").style.display = "none";
}
function deleteAdmin() {
    const id = document.getElementById("editAdminId").value;
    if (!id) return;
    if (!confirm("ยืนยันการลบผู้ดูแลระบบรายนี้?")) return;
    document.getElementById("deleteAdminId").value = id;
    document.getElementById("deleteAdminForm").submit();
}
function openRestoreAdminDialog() {
    document.getElementById("restoreAdminDialog").style.display = "flex";
}
function closeRestoreAdminDialog() {
    document.getElementById("restoreAdminDialog").style.display = "none";
}
function selectRestoreAdmin(el) {
    document.querySelectorAll("#restoreAdminList li").forEach(function (li) {
        li.classList.remove("selected");
    });
    el.classList.add("selected");
}
function confirmRestoreAdmin() {
    const selected = document.querySelector("#restoreAdminList li.selected");
    if (!selected || !selected.dataset.id) {
        alert("กรุณาเลือกผู้ดูแลระบบที่ต้องการกู้คืน");
        return;
    }
    document.getElementById("restoreAdminId").value = selected.dataset.id;
    document.getElementById("restoreAdminForm").submit();
}
