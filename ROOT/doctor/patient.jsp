<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.time.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
	Integer doctorId = (Integer) session.getAttribute("user_id");
	if (doctorId == null) {
	    response.sendRedirect("../index.jsp");
	    return;
	}

	String errorMessage = null;
	List<Map<String, String>> patients = new ArrayList<>();

	PreparedStatement stmt = null;
	ResultSet rs = null;
	try {
		String sql =
			"SELECT patient_id, first_name, last_name, gender, phone_num, marriage_status, " +
			"       birth_date, province, district, sub_district, travel_method, occupation, " +
			"       CONCAT('P', LPAD(patient_id, 6, '0')) AS patient_code " +
			"FROM patient ORDER BY patient_id";

		stmt = con.prepareStatement(sql);
		rs = stmt.executeQuery();

		while (rs.next()) {
			Map<String, String> p = new HashMap<>();
			p.put("id",             rs.getString("patient_id"));
			p.put("patient_code",   rs.getString("patient_code"));
			p.put("first_name",     rs.getString("first_name") != null ? rs.getString("first_name") : "-");
			p.put("last_name",      rs.getString("last_name") != null ? rs.getString("last_name") : "-");
			p.put("gender",         rs.getString("gender") != null ? rs.getString("gender") : "-");
			p.put("phone_num",      rs.getString("phone_num") != null ? rs.getString("phone_num") : "-");
			p.put("marriageStatus", rs.getString("marriage_status") != null ? rs.getString("marriage_status") : "-");
			p.put("province",       rs.getString("province") != null ? rs.getString("province") : "-");
			p.put("district",       rs.getString("district") != null ? rs.getString("district") : "-");
			p.put("subDistrict",    rs.getString("sub_district") != null ? rs.getString("sub_district") : "-");
			p.put("travelMethod",   rs.getString("travel_method") != null ? rs.getString("travel_method") : "-");
			p.put("occupation",     rs.getString("occupation") != null ? rs.getString("occupation") : "-");

			java.sql.Date birthDate = rs.getDate("birth_date");
			if (birthDate != null) {
				java.time.LocalDate ld = birthDate.toLocalDate();
				p.put("dob", String.format("%02d/%02d/%04d", ld.getDayOfMonth(), ld.getMonthValue(), ld.getYear() + 543));
			} else {
				p.put("dob", "-");
			}
			patients.add(p);
		}
	} catch (Exception e) {
		errorMessage = "ไม่สามารถโหลดข้อมูลคนไข้ได้: " + e.getMessage();
	} 
	// chosing patient
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

            stmt = con.prepareStatement(sql);
            stmt.setInt(1, patientIdInput);
            rs = stmt.executeQuery();

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
<link rel="stylesheet" href="../doctor_css/patient.css">
<link rel="stylesheet" href="../layout.css">
</head>

<body>
	<%
	request.setAttribute("activePage", "patient");
	request.setAttribute("pageTitle", "รายชื่อคนไข้");
	%>
	<jsp:include page="../include/navbar.jsp" />
	<jsp:include page="../include/header.jsp" />

	<div class="content" id="patientPage">
		<div id="addPatientContainer">
			<h2>รายชื่อคนไข้ในระบบ</h2>
		</div>

		<div class="search-container">
			<div class="search-box"><input type="text" id="searchCode" placeholder="ค้นหารหัสคนไข้..."></div>
			<div class="search-box"><input type="text" id="searchFirstName" placeholder="ค้นหาชื่อ..."></div>
			<div class="search-box"><input type="text" id="searchLastName" placeholder="ค้นหานามสกุล..."></div>
			<div class="search-box"><input type="text" id="searchGender" placeholder="ค้นหาเพศ..."></div>
			<div class="search-box"><input type="text" id="searchPhone" placeholder="ค้นหาเบอร์โทรศัพท์..."></div>
			<div class="search-box"><input type="text" id="searchMarriageStatus" placeholder="ค้นหาสถานะการแต่งงาน..."></div>
			<div class="search-box"><input type="text" id="searchDob" placeholder="ค้นหาวันเกิด..."></div>
			<div class="search-box"><input type="text" id="searchProvince" placeholder="ค้นหาจังหวัด..."></div>
			<div class="search-box"><input type="text" id="searchDistrict" placeholder="ค้นหาอำเภอ..."></div>
			<div class="search-box"><input type="text" id="searchSubDistrict" placeholder="ค้นหาตำบล..."></div>
			<div class="search-box"><input type="text" id="searchTravelMethod" placeholder="ค้นหาการเดินทาง..."></div>
			<div class="search-box"><input type="text" id="searchOccupation" placeholder="ค้นหาอาชีพ..."></div>
			<button onclick="filterPatients()">ค้นหา</button>
		</div>

		<table id="patientTable">
			<thead>
				<tr>
					<th style="display:none;">ID</th>
					<th>รหัสคนไข้</th>
					<th>ชื่อ</th>
					<th>นามสกุล</th>
					<th>เพศ</th>
					<th>เบอร์โทรศัพท์</th>
					<th>สถานะการแต่งงาน</th>
					<th>วันเกิด</th>
					<th>จังหวัด</th>
					<th>อำเภอ</th>
					<th>ตำบล</th>
					<th>การเดินทาง</th>
					<th>อาชีพ</th>
					<th>เลือกคนไข้</th>
				</tr>
			</thead>
			<tbody></tbody>
		</table>

		<div class="pagination" id="pagination"></div>
	</div>
	
	<script>
		const patientsData = [
			<% for (Map<String, String> p : patients) { %>
			{
				id: "<%= p.get("id") %>",
				patient_code: "<%= p.get("patient_code") %>",
				first_name: "<%= p.get("first_name") %>",
				last_name: "<%= p.get("last_name") %>",
				gender: "<%= p.get("gender") %>",
				phone_num: "<%= p.get("phone_num") %>",
				marriageStatus: "<%= p.get("marriageStatus") %>",
				dob: "<%= p.get("dob") %>",
				province: "<%= p.get("province") %>",
				district: "<%= p.get("district") %>",
				subDistrict: "<%= p.get("subDistrict") %>",
				travelMethod: "<%= p.get("travelMethod") %>",
				occupation: "<%= p.get("occupation") %>"
			},
			<% } %>
		];
	</script>
	<script src="../doctor_js/patient.js"></script>
	<script src="../script.js"></script>
	<jsp:include page="../include/toast.jsp" />
	<% if (errorMessage != null) { %>
	<script>
		document.addEventListener("DOMContentLoaded", function() {
			showToast("<%= errorMessage %>", "error");
		});
	</script>
	<% } %>
</body>
</html>
