document.addEventListener("DOMContentLoaded", function () {
    const rowsPerPage = 10;
    let currentPage = 1;
    let filteredPatients = [];

    const tableBody = document.querySelector("#patientTable tbody");
    const pagination = document.getElementById("pagination");

    let patients = (typeof patientsData !== "undefined") ? [...patientsData] : [];
    filteredPatients = [...patients];

    function displayTable(data, page) {
        tableBody.innerHTML = "";
        const start = (page - 1) * rowsPerPage;
        const pageItems = data.slice(start, start + rowsPerPage);

        if (pageItems.length === 0) {
            const tr = document.createElement("tr");
            tr.innerHTML = "<td>ไม่พบข้อมูล</td>";
            tableBody.appendChild(tr);
            setupPagination(0, page);
            return;
        }

        pageItems.forEach(p => {
            const tr = document.createElement("tr");
            tr.dataset.id = p.id;
            tr.innerHTML = `
                <td style="display:none;">${p.id}</td>
                <td>${p.patient_code}</td>
                <td>${p.first_name}</td>
                <td>${p.last_name}</td>
                <td>${p.gender}</td>
                <td>${p.phone_num}</td>
                <td>${p.marriageStatus}</td>
                <td>${p.dob}</td>
                <td>${p.province}</td>
                <td>${p.district}</td>
                <td>${p.subDistrict}</td>
                <td>${p.travelMethod}</td>
                <td>${p.occupation}</td>
                <td><button onclick="selectPatient(${p.id})">เลือก</button></td>
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
        const codeTerm     = document.getElementById("searchCode").value.trim().toLowerCase();
        const firstTerm    = document.getElementById("searchFirstName").value.trim().toLowerCase();
        const lastTerm     = document.getElementById("searchLastName").value.trim().toLowerCase();
        const genderTerm   = document.getElementById("searchGender").value.trim().toLowerCase();
        const phoneTerm    = document.getElementById("searchPhone").value.trim().toLowerCase();
        const marriageTerm = document.getElementById("searchMarriageStatus").value.trim().toLowerCase();
        const dobTerm      = document.getElementById("searchDob").value.trim().toLowerCase();
        const provinceTerm = document.getElementById("searchProvince").value.trim().toLowerCase();
        const districtTerm = document.getElementById("searchDistrict").value.trim().toLowerCase();
        const subDistTerm  = document.getElementById("searchSubDistrict").value.trim().toLowerCase();
        const travelTerm   = document.getElementById("searchTravelMethod").value.trim().toLowerCase();
        const occupTerm    = document.getElementById("searchOccupation").value.trim().toLowerCase();

        filteredPatients = patients.filter(p =>
            p.patient_code.toLowerCase().includes(codeTerm)     &&
            p.first_name.toLowerCase().includes(firstTerm)      &&
            p.last_name.toLowerCase().includes(lastTerm)        &&
            p.gender.toLowerCase().includes(genderTerm)         &&
            p.phone_num.toLowerCase().includes(phoneTerm)       &&
            p.marriageStatus.toLowerCase().includes(marriageTerm) &&
            p.dob.toLowerCase().includes(dobTerm)               &&
            p.province.toLowerCase().includes(provinceTerm)     &&
            p.district.toLowerCase().includes(districtTerm)     &&
            p.subDistrict.toLowerCase().includes(subDistTerm)   &&
            p.travelMethod.toLowerCase().includes(travelTerm)   &&
            p.occupation.toLowerCase().includes(occupTerm)
        );
        currentPage = 1;
        displayTable(filteredPatients, currentPage);
    };

    displayTable(filteredPatients, currentPage);
});

function selectPatient(patientId) {
    window.location.href = `patient.jsp?patient_id=${patientId}`;
}
