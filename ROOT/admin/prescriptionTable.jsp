<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.time.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
	Integer adminId = (Integer) session.getAttribute("user_id");
	if (adminId == null) {
		response.sendRedirect("../index.jsp");
		return;
	}

	String errorMessage = null;

	List<Map<String, String>> patients = new ArrayList<>();

	try {
		String sql =
			"SELECT " +
			"pr.prescription_id, " +
			"pr.patient_id, " +
			"pr.doctor_id, " +
			"DATE_FORMAT(pr.prescription_datetime, '%Y-%m-%d %H:%i:%s') AS prescription_datetime, " +
			"pr.medicine_count, " +
			"CONCAT(d.title, d.first_name, ' ', d.last_name) AS doctor_name, " +
			"CONCAT(p.title, p.first_name, ' ', p.last_name) AS patient_name, " +
			"CONCAT('P', LPAD(pr.patient_id, 6, '0')) AS patient_code " +
			"FROM prescription pr " +
			"JOIN `user` d ON pr.doctor_id = d.user_id " +
			"JOIN patient p ON pr.patient_id = p.patient_id " +
			"ORDER BY pr.prescription_id DESC";

		PreparedStatement stmt = con.prepareStatement(sql);
		ResultSet rs = stmt.executeQuery();

		while (rs.next()) {
			Map<String,String> row = new HashMap<>();
			row.put("prescription_id", rs.getString("prescription_id"));
			row.put("date", rs.getString("prescription_datetime"));
			row.put("patientCode", rs.getString("patient_code"));
			row.put("patient", rs.getString("patient_name"));
			row.put("doctor", rs.getString("doctor_name"));
			row.put("medicine_count", rs.getString("medicine_count"));
			patients.add(row);
		}

	} catch(Exception e){
		e.printStackTrace();
		errorMessage = "ไม่สามารถโหลดข้อมูลได้: " + e.getMessage();

	}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../admin_css/prescription.css">
<link rel="stylesheet" href="../layout.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>
<body>
	<%
	request.setAttribute("activePage", "prescription");
	request.setAttribute("pageTitle", "ประวัติใบสั่งยา");
	%>
	<jsp:include page="../include/navbar.jsp" />
	<jsp:include page="../include/header.jsp" />

	<div class="content" id="prescriptionPage">
		<div class="section" id="prescriptionTableContainerAdmin">
			<div class="sectionHeader">
				<h2>รายการใบสั่งยา</h2>
			</div>

			<div class="search-container">
				<div class="search-box"><input type="text" id="searchDate" placeholder="เลือกช่วงวันที่..."></div>
				<div class="search-box"><input type="text" id="searchPatientCode" placeholder="ค้นหารหัสคนไข้..."></div>
				<div class="search-box"><input type="text" id="searchPatient" placeholder="ค้นหาชื่อคนไข้..."></div>
				<div class="search-box"><input type="text" id="searchDoctor" placeholder="ค้นหาแพทย์..."></div>
				<div class="search-box"><input type="text" id="searchMedicineCount" placeholder="ค้นหาจำนวนยา..."></div>
				<div class="search-box">
					<button onclick="filterPrescriptions()" style="width: 100%;">ค้นหา</button>
				</div>
			</div>
			<table id="prescriptionTable">
				<thead>
					<tr>
						<th>วันที่สั่งยา</th>
						<th>รหัสคนไข้</th>
						<th>ชื่อคนไข้</th>
						<th>แพทย์ผู้ออกใบสั่งยา</th>
						<th>จำนวนยา</th>
						<th>ดูรายละเอียด</th>
					</tr>
				</thead>
				<tbody>
				<%
					for (Map<String, String> p : patients) { 
				%>
					<tr data-prescription-id="<%= p.get("prescription_id") %>">
						<td><%= p.get("date") %></td>
						<td><%= p.get("patientCode") %></td>
						<td><%= p.get("patient") %></td>
						<td><%= p.get("doctor") %></td>
						<td><%= p.get("medicine_count") %></td>
						<td><button class="detail-btn">รายละเอียด</button></td>
					</tr>
					<%  
					}     
					%>
				</tbody>
			</table>
			<div class="pagination" id="pagination"></div>
		</div>

		<!-- ====== รายละเอียดใบสั่งยา ====== -->
		<div class="section" id="prescriptionDetailSection">
			<div class="sectionHeader">
				<button class="back-btn" onclick="backToTable()">&#8592; กลับ</button>
				<h2>รายละเอียดใบสั่งยา</h2>
			</div>

			<div class="detail-info-grid">
				<div class="detail-info-item"><span class="detail-label">วันเวลา</span><span id="pvDate" class="detail-value"></span></div>
				<div class="detail-info-item"><span class="detail-label">แพทย์</span><span id="pvDoctor" class="detail-value"></span></div>
				<div class="detail-info-item"><span class="detail-label">รหัสคนไข้</span><span id="pvPatientCode" class="detail-value"></span></div>
				<div class="detail-info-item"><span class="detail-label">ชื่อคนไข้</span><span id="pvPatient" class="detail-value"></span></div>
			</div>

			<hr>

			<h3>รายการยา</h3>
			<div id="medicineTable-wrapper">
				<table id="medicineTable">
					<thead>
						<tr>
							<th>ชื่อยา</th>
							<th>จำนวน</th>
							<th>หน่วย</th>
							<th>วิธีใช้</th>
							<th>หมายเหตุ</th>
						</tr>
					</thead>
					<tbody></tbody>
				</table>
			</div>
		</div>

	</div>

	<script>
		const prescriptionsData = [
			<% for (Map<String, String> p : patients) { %>
			{
				prescription_id: "<%= p.get("prescription_id") %>",
				date:            "<%= p.get("date") %>",
				patientCode:     "<%= p.get("patientCode") %>",
				patient:         "<%= p.get("patient") %>",
				doctor:          "<%= p.get("doctor") %>",
				medicine_count:  "<%= p.get("medicine_count") %>"
			},
			<% } %>
		];
	</script>
	<script src="../admin_js/prescription.js"></script>
	<script src="../script.js"></script>
	<jsp:include page="../include/toast.jsp" />
</body>
</html>