<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
    Integer doctorId = (Integer) session.getAttribute("user_id");
    if (doctorId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    String errorMessage = null;

    String input = request.getParameter("patient_id");
    if (input != null && !input.trim().isEmpty()) {
        input = input.trim().toUpperCase();
        if (input.startsWith("P")) {
            input = input.substring(1);
        }

        try {
            int patientIdInput = Integer.parseInt(input);

            String sql =
                " SELECT patient_id, is_active, " +
                " CONCAT(first_name, ' ', last_name) AS patient_name, " +
                " CONCAT('P', LPAD(patient_id,7,'0')) AS patient_code, " +
                " gender, birth_date " +
                " FROM patient WHERE patient_id = ?";

            PreparedStatement stmt = con.prepareStatement(sql);
            stmt.setInt(1, patientIdInput);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                boolean isActive = rs.getBoolean("is_active");
                if (isActive) {
                    session.setAttribute("patient_id",      rs.getInt("patient_id"));
                    session.setAttribute("patientName",     rs.getString("patient_name"));
                    session.setAttribute("patientCode",     rs.getString("patient_code"));
                    session.setAttribute("patientGender",   rs.getString("gender"));
                    session.setAttribute("patientBirthDate",rs.getDate("birth_date"));
                    response.sendRedirect("patientData.jsp");
                    return;
                } else {
                    errorMessage = "บัญชีคนไข้ถูกระงับ";
                }
            } else {
                errorMessage = "ไม่พบคนไข้ในระบบ";
            }
        } catch (Exception e) {
            errorMessage = "เกิดข้อผิดพลาดในการค้นหาคนไข้";
        } 
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../doctor_css/main.css">
<link rel="stylesheet" href="../layout.css">
</head>

<body>
    <%
    request.setAttribute("activePage", "main");
    request.setAttribute("pageTitle", "เลือกคนไข้");
    %>
    <jsp:include page="../include/navbar.jsp" />
    <jsp:include page="../include/header.jsp" />

    <div class="content" id="patientSelectedPage">
        <div id="selectPatientDiv">
            <h2>กรุณากรอกรหัสคนไข้</h2>
            <% if (errorMessage != null) { %>
                <p class="error-message"><%= errorMessage %></p>
            <% } %>
            <form action="main.jsp" method="post">
                <input type="text" name="patient_id" placeholder="รหัสคนไข้" required>
                <button type="submit">เลือกคนไข้</button>
            </form>
        </div>
    </div>
<script src="../script.js"></script>
</body>
</html>