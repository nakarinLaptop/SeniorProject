<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
    Integer staffId = (Integer) session.getAttribute("user_id");
    if (staffId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }
    String toastMessage = (String) session.getAttribute("toastMessage");
    String toastType = (String) session.getAttribute("toastType");
    if (toastMessage != null) {
        session.removeAttribute("toastMessage");
        session.removeAttribute("toastType");
    }
    if ("deleteCase".equals(request.getParameter("action"))) {
        String predIdStr = request.getParameter("predId");
        try {
            PreparedStatement updStmt = con.prepareStatement(
                "UPDATE prediction SET appointment_status = 'pending', staff_appointment_date = NULL, staff_appointment_note = NULL WHERE id = ? AND (staff_appointment_date IS NULL OR DATE(staff_appointment_date) >= CURDATE()) AND (appointment_date >= CURDATE() OR DATE(staff_appointment_date) >= CURDATE())");
            updStmt.setInt(1, Integer.parseInt(predIdStr));
            updStmt.executeUpdate();
            updStmt.close();
            session.setAttribute("toastMessage", "เปลี่ยนสถานะเป็น pending สำเร็จ");
            session.setAttribute("toastType", "success");
        } catch (Exception e) {
            session.setAttribute("toastMessage", "เกิดข้อผิดพลาด: " + e.getMessage());
            session.setAttribute("toastType", "error");
        }
        response.sendRedirect("finishedTask.jsp");
        return;
    }

    String errorMessage = null;
    List<Map<String, String>> finishedCases = new ArrayList<>();

    try {
        String sql =
            "SELECT p.id, p.patient_id, p.confident, p.appointment_status, " +
            "DATE_FORMAT(p.staff_appointment_date, '%Y-%m-%d %H:%i') AS staff_appointment_date, " +
            "DATE_FORMAT(p.appointment_date, '%Y-%m-%d') AS appointment_date, " +
            "pt.first_name, pt.last_name " +
            "FROM prediction p " +
            "JOIN patient pt ON p.patient_id = pt.patient_id " +
            "WHERE p.appointment_status != 'pending' " +
            "ORDER BY p.appointment_date DESC";

        PreparedStatement caseStmt = con.prepareStatement(sql);
        ResultSet caseRs = caseStmt.executeQuery();

        while (caseRs.next()) {
            Map<String, String> row = new HashMap<>();
            row.put("id",                 caseRs.getString("id"));
            row.put("patient_id",         caseRs.getString("patient_id"));
            row.put("patient_name",       caseRs.getString("first_name") + " " + caseRs.getString("last_name"));
            row.put("confident",          caseRs.getString("confident"));
            row.put("appointment_status", caseRs.getString("appointment_status"));
            row.put("staff_appointment_date", caseRs.getString("staff_appointment_date") != null ? caseRs.getString("staff_appointment_date") : "-");
            row.put("appointment_date", caseRs.getString("appointment_date"));
            finishedCases.add(row);
        }
    } catch (Exception e) {
        e.printStackTrace();
        errorMessage = "Error :"+ e.getMessage();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
    <link rel="stylesheet" href="../layout.css">
    <link rel="stylesheet" href="../staff_css/finishedTask.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>
<body>
    <%
        request.setAttribute("activePage", "finishedTask");
        request.setAttribute("pageTitle", "งานตรวจคนไข้ที่เสร็จแล้ว");
    %>
    <jsp:include page="../include/navbar.jsp" />
    <jsp:include page="../include/header.jsp" />
    	
    <div class="content" id="mainPage">
        <!-- Results Section -->
        <div id="resultsSection" class="results-container">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                <h2 style="margin:0;">งานตรวจคนไข้ที่เสร็จแล้ว</h2>
                <button class="btn-search" onclick="filterCases()">ค้นหา</button>
            </div>
            <!-- Search Section -->
            <div class="search-container">
                <div class="search-box">
                    <label for="staffAppointmentDateSearch">ช่วงวันที่นัดตรวจ:</label>
                    <input type="text" id="staffAppointmentDateSearch" class="search-input" placeholder="เลือกช่วงวันที่..." readonly>
                </div>
                <div class="search-box">
                    <label for="appointmentDateSearch">ช่วงวันที่ต้องส่งตรวจ:</label>
                    <input type="text" id="appointmentDateSearch" class="search-input" placeholder="เลือกช่วงวันที่..." readonly>
                </div>
                <div class="search-box">
                    <label for="patientIdSearch">รหัสคนไข้:</label>
                    <input type="text" id="patientIdSearch" class="search-input" placeholder="เช่น P0000001">
                </div>
                <div class="search-box">
                    <label for="patientNameSearch">ชื่อคนไข้:</label>
                    <input type="text" id="patientNameSearch" class="search-input" placeholder="ชื่อ-นามสกุล">
                </div>
                <div class="search-box">
                    <label for="confidenceSearch">ความมั่นใจ (%):</label>
                    <input type="number" id="confidenceSearch" class="search-input" placeholder="0-100" min="0" max="100">
                </div>
                <div class="search-box">
                    <label for="examStatusSearch">สถานะการตรวจ:</label>
                    <select id="examStatusSearch" class="search-input">
                        <option value="">-- ทั้งหมด --</option>
                        <option value="completed">นัดตรวจสำเร็จ</option>
                        <option value="changeToHos">เปลี่ยนไปตรวจโรงพยาบาล</option>
                        <option value="rejected">คนไข้ปฏิเสธการตรวจ</option>
                        <option value="unreachable">ติดต่อไม่ได้</option>
                    </select>
                </div>
                <div class="search-box" style="width:40px; min-width:40px; visibility:hidden;">
                </div>
            </div>

            <div class="table-wrapper">
                <table id="resultsTable" class="results-table">
                    <thead>
                        <tr>
                            <th>วันที่นัดตรวจ</th>
                            <th>วันที่ต้องส่งตรวจ</th>
                            <th>รหัสคนไข้</th>
                            <th>ชื่อคนไข้</th>
                            <th>ความมั่นใจ (%)</th>
                            <th>สถานะการตรวจ</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody id="resultsTableBody">
                    </tbody>
                </table>
            </div>
            <div class="pagination" id="pagination"></div>
        </div>    
    </div>

    <script>
    const finishedCasesData = [
        <% for (Map<String, String> c : finishedCases) { %>
        {
            id:                 "<%=c.get("id")%>",
            patient_id:         "<%=c.get("patient_id")%>",
            patient_name:       "<%=c.get("patient_name")%>",
            confident:          "<%=c.get("confident")%>",
            appointment_status: "<%=c.get("appointment_status")%>",
            staff_appointment_date: "<%=c.get("staff_appointment_date")%>",
            appointment_date: "<%=c.get("appointment_date")%>"
        },
        <% } %>
    ];
    </script>

    <% if (toastMessage != null) { %>
    <script>
        showToast("<%= toastMessage %>", "<%= toastType != null ? toastType : "info" %>");
    </script>
    <% } %>

    <jsp:include page="../include/toast.jsp" />
    <script src="../script.js"></script>
    <script src="../staff_js/finishedTask.js"></script>
</body>
</html>