<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
	Integer adminId = (Integer) session.getAttribute("user_id");

	if (adminId == null) {
		response.sendRedirect("../index.jsp");
		return;
	}

	String errorMessage = null;
	List<Map<String, String>> predictions = new ArrayList<>();
	//table
	try {
		String sql =
			"SELECT " +
			"pred.id, " +
			"CONCAT('P', LPAD(pred.patient_id, 6, '0')) AS patient_code, " +
			"CONCAT(p.first_name, ' ', p.last_name) AS patient_name, " +
			"CONCAT(d.title, d.first_name, ' ', d.last_name) AS doctor_name, " +
			"pred.predict_result, " +
			"pred.doctor_selected, " +
			"pred.confident, " +
			"pred.appointment_status, " +
			"DATE_FORMAT(pred.created_at, '%Y-%m-%d %H:%i:%s') AS created_at " +
			"FROM prediction pred " +
			"JOIN `user` d ON pred.doctor_id = d.user_id " +
			"JOIN patient p ON pred.patient_id = p.patient_id " +
			"ORDER BY pred.id DESC";

		PreparedStatement stmt = con.prepareStatement(sql);
		ResultSet rs = stmt.executeQuery();

		while (rs.next()) {
			Map<String, String> row = new HashMap<>();
			row.put("id",                 rs.getString("id"));
			row.put("patient_code",       rs.getString("patient_code"));
			row.put("patient_name",       rs.getString("patient_name"));
			row.put("doctor_name",        rs.getString("doctor_name"));
			row.put("predict_result",     rs.getString("predict_result"));
			row.put("doctor_selected",    rs.getString("doctor_selected"));
			row.put("confident",          rs.getString("confident"));
			row.put("appointment_status", rs.getString("appointment_status"));
			row.put("created_at",         rs.getString("created_at"));
			predictions.add(row);
		}

	} catch (Exception e) {
		e.printStackTrace();
		errorMessage = "ไม่สามารถโหลดข้อมูลได้: " + e.getMessage();
	} 
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../admin_css/predict.css">
<link rel="stylesheet" href="../layout.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>
<body>
<%
	request.setAttribute("activePage", "predict");
	request.setAttribute("pageTitle", "ประวัติการทำนายสถานที่ตรวจสุขภาพ");
%>
<jsp:include page="../include/navbar.jsp" />
<jsp:include page="../include/header.jsp" />

<div class="content" id="predictPage">
	<div class="sectionHeader">
		<h2>รายการการทำนายสถานที่ตรวจสุขภาพ</h2>
		<button class="search-btn" onclick="filterPredictions()">ค้นหา</button>
	</div>

	<div class="search-container">
		<div class="search-box"><input type="text" id="searchDate"              placeholder="เลือกช่วงวันที่..."></div>
		<div class="search-box"><input type="text" id="searchPatientCode"       placeholder="รหัสคนไข้..."></div>
		<div class="search-box"><input type="text" id="searchPatient"           placeholder="ชื่อคนไข้..."></div>
		<div class="search-box"><input type="text" id="searchDoctor"            placeholder="แพทย์..."></div>
		<div class="search-box">
			<select id="searchPredictResult">
				<option value="">ผลทำนาย (ทั้งหมด)</option>
				<option value="home">home</option>
				<option value="hospital">hospital</option>
			</select>
		</div>
		<div class="search-box">
			<select id="searchDoctorSelected">
				<option value="">แพทย์เลือก (ทั้งหมด)</option>
				<option value="home">home</option>
				<option value="hospital">hospital</option>
			</select>
		</div>
		<div class="search-box confident-range-box">
			<input type="number" id="searchConfidentMin" min="0" max="100" step="0.1" placeholder="ความมั่นใจ % ต่ำสุด">
			<input type="number" id="searchConfidentMax" min="0" max="100" step="0.1" placeholder="ความมั่นใจ % สูงสุด">
		</div>
		<div class="search-box">
			<select id="searchAppointmentStatus">
				<option value="">สถานะนัดหมาย (ทั้งหมด)</option>
				<option value="pending">pending</option>
				<option value="completed">completed</option>
				<option value="unreachable">unreachable</option>
				<option value="rejected">rejected</option>
			</select>
		</div>
	</div>
	<table id="predictTable">
		<thead>
			<tr>
				<th>วันที่ทำนาย</th>
				<th>รหัสคนไข้</th>
				<th>ชื่อคนไข้</th>
				<th>แพทย์</th>
				<th>ผลทำนาย</th>
				<th>แพทย์เลือก</th>
				<th>ความมั่นใจ</th>
				<th>สถานะนัดหมาย</th>
			</tr>
		</thead>
		<tbody>
		<%
		for (Map<String, String> pred : predictions) {
		%>
			<tr>
				<td><%=pred.get("created_at")%></td>
				<td><%=pred.get("patient_code")%></td>
				<td><%=pred.get("patient_name")%></td>
				<td><%=pred.get("doctor_name")%></td>
				<td><%=pred.get("predict_result")%></td>
				<td><%=pred.get("doctor_selected")%></td>
				<td><%=pred.get("confident")%></td>
				<td><%=pred.get("appointment_status")%></td>
			</tr>
		<%
		}
		%>
		</tbody>
	</table>
	<div class="pagination" id="pagination"></div>
</div>

<script>
	const predictionsData = [
		<% for (Map<String, String> pred : predictions) { %>
		{
			id:                 "<%=pred.get("id")%>",
			created_at:         "<%=pred.get("created_at")%>",
			patient_code:       "<%=pred.get("patient_code")%>",
			patient_name:       "<%=pred.get("patient_name")%>",
			doctor_name:        "<%=pred.get("doctor_name")%>",
			predict_result:     "<%=pred.get("predict_result")%>",
			doctor_selected:    "<%=pred.get("doctor_selected")%>",
			confident:          "<%=pred.get("confident")%>",
			appointment_status: "<%=pred.get("appointment_status")%>"
		},
		<% } %>
	];
</script>
<script src="../admin_js/predict.js"></script>
<script src="../script.js"></script>
<jsp:include page="../include/toast.jsp" />
</body>
</html>