function gotoPage(page) {
    window.location.href = page;
}
function toggleLogoutMenu() {
    const menu = document.getElementById("logoutMenu");
    menu.style.display = (menu.style.display === "flex") ? "none" : "flex";
}

function selectPatient(patientId) {
    window.location.href = "main.jsp?patient_id=" + patientId;
}
