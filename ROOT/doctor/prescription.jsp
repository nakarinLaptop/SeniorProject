<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.time.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%!
	private String escapeJson(String value) {
		if (value == null) {
			return "";
		}
		String safe = value.replace("\\", "\\\\");
		safe = safe.replace("\"", "\\\"");
		return safe;
	}
%>
<%
	request.setCharacterEncoding("UTF-8");
	response.setCharacterEncoding("UTF-8");

	Integer doctorId = (Integer) session.getAttribute("user_id");
	Integer patientId = (Integer) session.getAttribute("patient_id");
	String action = request.getParameter("action");

	if (doctorId == null) {
		response.sendRedirect("../index.jsp");
		return;
	}

	if ("save".equals(action)) {
		String prescriptionIdStr = request.getParameter("prescription_id");
		boolean isEdit = prescriptionIdStr != null && !prescriptionIdStr.isEmpty();

		String rightNameStr = request.getParameter("right_id");
		boolean patientHasHealthcareRight = rightNameStr != null
				&& !rightNameStr.trim().isEmpty()
				&& !rightNameStr.equals("PayYourself");
		String healthRightName = patientHasHealthcareRight ? rightNameStr.trim() : null;

		String[] medicineNames = request.getParameterValues("medicine_name[]");
		String[] quantities    = request.getParameterValues("quantity[]");
		String[] units         = request.getParameterValues("unit[]");
		String[] frequencies   = request.getParameterValues("frequency[]");
		String[] helperLabels  = request.getParameterValues("helper_label[]");

		try {
			con.setAutoCommit(false);

			int prescriptionId;

			if (isEdit) {
				prescriptionId = Integer.parseInt(prescriptionIdStr);
			// same-day check
			PreparedStatement chk = con.prepareStatement(
				"SELECT DATE(prescription_datetime) AS d FROM prescription WHERE prescription_id = ? AND patient_id = ?");
			chk.setInt(1, prescriptionId); chk.setInt(2, patientId);
			ResultSet chkRs = chk.executeQuery();
			if (!chkRs.next() || !chkRs.getDate("d").toLocalDate().equals(LocalDate.now())) {
				chkRs.close(); chk.close();
				session.setAttribute("toastMessage", "ไม่สามารถแก้ไขได้ เนื่องจากไม่ใช่รายการของวันนี้");
				session.setAttribute("toastType", "error");
				response.sendRedirect("prescription.jsp");
				return;
			}
			chkRs.close(); chk.close();
				int medCount = (medicineNames != null) ? medicineNames.length : 0;
				String updateSql =
					"UPDATE prescription SET medicine_count = ?, health_right_name = ? " +
					"WHERE prescription_id = ?";
				PreparedStatement updateStmt = con.prepareStatement(updateSql);
				updateStmt.setInt(1, medCount);
				if (healthRightName != null) {
					updateStmt.setString(2, healthRightName);
				} else {
					updateStmt.setNull(2, Types.VARCHAR);
				}
				updateStmt.setInt(3, prescriptionId);
				updateStmt.executeUpdate();
				updateStmt.close();

				PreparedStatement deleteStmt = con.prepareStatement(
					"DELETE FROM prescription_detail WHERE prescription_id = ?");
				deleteStmt.setInt(1, prescriptionId);
				deleteStmt.executeUpdate();
				deleteStmt.close();

			} else {
				String insertPrescriptionSql =
					"INSERT INTO prescription (patient_id, doctor_id, prescription_datetime, medicine_count, health_right_name) " +
					"VALUES (?, ?, NOW(), ?, ?)";
				int medCount = (medicineNames != null) ? medicineNames.length : 0;
				PreparedStatement saveStmt = con.prepareStatement(insertPrescriptionSql, Statement.RETURN_GENERATED_KEYS);
				saveStmt.setInt(1, patientId);
				saveStmt.setInt(2, doctorId);
				saveStmt.setInt(3, medCount);
				if (healthRightName != null) {
					saveStmt.setString(4, healthRightName);
				} else {
					saveStmt.setNull(4, Types.VARCHAR);
				}
				saveStmt.executeUpdate();

				ResultSet generatedKeys = saveStmt.getGeneratedKeys();
				prescriptionId = 0;
				if (generatedKeys.next()) {
					prescriptionId = generatedKeys.getInt(1);
				}
				generatedKeys.close();
				saveStmt.close();
			}

			if (medicineNames != null && medicineNames.length > 0) {
				String insertDetailSql =
					"INSERT INTO prescription_detail (prescription_id, medicine_name, quantity, unit, frequency, helper_label) " +
					"VALUES (?, ?, ?, ?, ?, ?)";
				PreparedStatement detailSaveStmt = con.prepareStatement(insertDetailSql);
				for (int i = 0; i < medicineNames.length; i++) {
					detailSaveStmt.setInt(1, prescriptionId);
					detailSaveStmt.setString(2, medicineNames[i]);
					detailSaveStmt.setInt(3, Integer.parseInt(quantities[i]));
					detailSaveStmt.setString(4, units[i]);
					detailSaveStmt.setString(5, frequencies[i]);
					detailSaveStmt.setString(6, helperLabels[i]);
					detailSaveStmt.addBatch();
				}
				detailSaveStmt.executeBatch();
				detailSaveStmt.close();
			}

			con.commit();
			session.setAttribute("toastMessage", isEdit ? "แก้ไขใบสั่งยาสำเร็จ" : "บันทึกใบสั่งยาสำเร็จ");
			session.setAttribute("toastType", "success");
			response.sendRedirect("prescription.jsp?prescriptionId=" + prescriptionId);
		} catch (Exception e) {
			try {
				con.rollback();
			} catch (Exception rollbackError) {
				rollbackError.printStackTrace();
			}
			e.printStackTrace();
			session.setAttribute("toastMessage", "เกิดข้อผิดพลาด: " + e.getMessage());
			session.setAttribute("toastType", "error");
			response.sendRedirect("prescription.jsp");
		}
		return;
	}
	
	if ("delete".equals(action)) {
		try {
			int delId = Integer.parseInt(request.getParameter("prescription_id"));
			PreparedStatement chk = con.prepareStatement(
				"SELECT DATE(prescription_datetime) AS d FROM prescription WHERE prescription_id = ? AND patient_id = ?");
			chk.setInt(1, delId); chk.setInt(2, patientId);
			ResultSet chkRs = chk.executeQuery();
			if (!chkRs.next() || !chkRs.getDate("d").toLocalDate().equals(LocalDate.now())) {
				chkRs.close(); chk.close();
				session.setAttribute("toastMessage", "ไม่สามารถลบได้ เนื่องจากไม่ใช่รายการของวันนี้");
				session.setAttribute("toastType", "error");
				response.sendRedirect("prescription.jsp?showTable=1");
				return;
			}
			chkRs.close(); chk.close();
			con.setAutoCommit(false);
			PreparedStatement d1 = con.prepareStatement("DELETE FROM prescription_detail WHERE prescription_id = ?");
			d1.setInt(1, delId); d1.executeUpdate(); d1.close();
			PreparedStatement d2 = con.prepareStatement("DELETE FROM prescription WHERE prescription_id = ? AND patient_id = ?");
			d2.setInt(1, delId); d2.setInt(2, patientId); d2.executeUpdate(); d2.close();
			con.commit();
			session.setAttribute("toastMessage", "ลบใบสั่งยาสำเร็จ");
			session.setAttribute("toastType", "success");
			response.sendRedirect("prescription.jsp?showTable=1");
		} catch (Exception e) {
			try { con.rollback(); } catch (Exception ignored) {}
			session.setAttribute("toastMessage", "ลบใบสั่งยาไม่สำเร็จ: " + e.getMessage());
			session.setAttribute("toastType", "error");
			response.sendRedirect("prescription.jsp?showTable=1");
		}
		return;
	}
	// get prescription detail for view and print PDF
	if ("getFullPrescription".equals(action)) {
		response.setContentType("application/json; charset=UTF-8");
		out.clearBuffer();
		try {
			int pid = Integer.parseInt(request.getParameter("prescription_id"));
			PreparedStatement ps = con.prepareStatement(
				"SELECT DATE_FORMAT(prescription_datetime,'%Y-%m-%d %H:%i:%s') AS dt, health_right_name " +
				"FROM prescription WHERE prescription_id = ? AND patient_id = ?");
			ps.setInt(1, pid); ps.setInt(2, patientId);
			ResultSet pr = ps.executeQuery();
			if (!pr.next()) { out.print("{}"); pr.close(); ps.close(); return; }
			String dt = pr.getString("dt"); if (dt == null) dt = "";
			String hr = pr.getString("health_right_name");
			pr.close(); ps.close();
			PreparedStatement ds = con.prepareStatement(
				"SELECT medicine_name, quantity, unit, frequency, helper_label FROM prescription_detail WHERE prescription_id = ? ORDER BY detail_id");
			ds.setInt(1, pid);
			ResultSet dr = ds.executeQuery();
			StringBuilder sb = new StringBuilder();
			sb.append("{\"prescription\":{\"prescriptionId\":").append(pid)
			  .append(",\"date\":\"").append(escapeJson(dt)).append("\"")
			  .append(",\"healthRight\":").append(hr != null ? "\"" + escapeJson(hr) + "\"" : "null")
			  .append("},\"drugs\":[");
			boolean first = true;
			while (dr.next()) {
				if (!first) sb.append(",");
				String hl = dr.getString("helper_label");
				sb.append("{\"medicine_name\":\"").append(escapeJson(dr.getString("medicine_name"))).append("\"")
				  .append(",\"quantity\":\"").append(escapeJson(dr.getString("quantity"))).append("\"")
				  .append(",\"unit\":\"").append(escapeJson(dr.getString("unit"))).append("\"")
				  .append(",\"frequency\":\"").append(escapeJson(dr.getString("frequency"))).append("\"")
				  .append(",\"helper_label\":\"").append(escapeJson(hl != null ? hl : "")).append("\"")
				  .append("}");
				first = false;
			}
			sb.append("]}");
			dr.close(); ds.close();
			out.print(sb.toString());
		} catch (Exception e) { out.print("{}"); }
		return;
	}
	// get prescription detail use in edit prescription
	if ("detail".equals(action)) {
		response.setContentType("application/json; charset=UTF-8");
		out.clearBuffer();
		String prescriptionId = request.getParameter("prescription_id");

		PreparedStatement detailStmt = null;
		ResultSet detailRs = null;
		StringBuilder json = new StringBuilder("[");

		try {
			String detailSql = "SELECT medicine_name, quantity, unit, frequency, helper_label " +
						   "FROM prescription_detail " +
						   "WHERE prescription_id = ? " +
						   "ORDER BY detail_id";

			detailStmt = con.prepareStatement(detailSql);
			detailStmt.setInt(1, Integer.parseInt(prescriptionId));
			detailRs = detailStmt.executeQuery();

			boolean first = true;
			while (detailRs.next()) {
				if (!first) {
					json.append(",");
				}
				first = false;

				String medicineName = detailRs.getString("medicine_name");
				String quantity     = detailRs.getString("quantity");
				String unit         = detailRs.getString("unit");
				String frequency    = detailRs.getString("frequency");
				String helperLabel  = detailRs.getString("helper_label");

				json.append("{");
				json.append("\"medicine_name\":\"").append(escapeJson(medicineName)).append("\",");
				json.append("\"quantity\":\"").append(escapeJson(quantity)).append("\",");
				json.append("\"unit\":\"").append(escapeJson(unit)).append("\",");
				json.append("\"frequency\":\"").append(escapeJson(frequency)).append("\",");
				json.append("\"helper_label\":\"").append(escapeJson(helperLabel)).append("\"");
				json.append("}");
			}

			json.append("]");
			out.print(json.toString());
		} catch (Exception e) {
			response.setStatus(500);
			out.print("[]");
		} 
		return;
	}

	String toastMessage = (String) session.getAttribute("toastMessage");
	String toastType = (String) session.getAttribute("toastType");

	List<Map<String, String>> prescriptions   = new ArrayList<>();
	List<Map<String, String>> medicines       = new ArrayList<>();
	Set<String> latestAllergyDrugNames = new HashSet<>();
	
	String patientRightId = null;
	String patientRightName = "ชำระเงินเอง";
	PreparedStatement stmt = null;
	ResultSet rs = null;

	// prescription table
	try {
		String prescriptionSql = "SELECT pr.prescription_id, pr.doctor_id, " +
						"DATE_FORMAT(pr.prescription_datetime, '%Y-%m-%d %H:%i:%s') AS prescription_datetime, " +
						"pr.medicine_count, " +
						"CONCAT(d.title, d.first_name, ' ', d.last_name) AS doctor_name, " +
						"COALESCE(pr.health_right_name, 'ชำระเงินเอง') AS healthcare_right " +
						"FROM prescription pr " +
						"JOIN `user` d ON pr.doctor_id = d.user_id " +
						"JOIN patient p ON pr.patient_id = p.patient_id " +
						"WHERE pr.patient_id = ? " +
						"ORDER BY pr.prescription_id DESC";

		stmt = con.prepareStatement(prescriptionSql);
		stmt.setInt(1, patientId);
		rs = stmt.executeQuery();

		while (rs.next()) {
			Map<String,String> prescription = new HashMap<>();
			prescription.put("prescription_id", String.valueOf(rs.getInt("prescription_id")));
			prescription.put("date", rs.getString("prescription_datetime"));
			prescription.put("doctor", rs.getString("doctor_name"));
			prescription.put("medicine_count", rs.getString("medicine_count"));
			prescription.put("healthcare_right", rs.getString("healthcare_right"));
			prescriptions.add(prescription);
		}
		rs.close();
		stmt.close();

		// สิทธิการรักษาของคนไข้
		try {
			String patientRightSql = "SELECT right_name FROM patient WHERE patient_id = ?";
			PreparedStatement rightStmt = con.prepareStatement(patientRightSql);
			rightStmt.setInt(1, patientId);
			ResultSet rightRs = rightStmt.executeQuery();
			if (rightRs.next()) {
				String fetchedName = rightRs.getString("right_name");
				if (fetchedName != null && !fetchedName.trim().isEmpty()) {
					patientRightId   = fetchedName.trim();
					patientRightName = fetchedName.trim();
				}
			}
			rightRs.close();
			rightStmt.close();
		} catch (Exception e) {
			e.printStackTrace();
		}

		// รายการยา
		String medicineSql = "SELECT med_id, med_name FROM medicine ORDER BY med_name";
		stmt = con.prepareStatement(medicineSql);
		rs = stmt.executeQuery();
		while (rs.next()) {
			Map<String,String> medicine = new HashMap<>();
			medicine.put("med_id", rs.getString("med_id"));
			medicine.put("med_name", rs.getString("med_name"));
			medicines.add(medicine);
		}
		rs.close();
		stmt.close();

		// ยาที่แพ้ล่าสุดของคนไข้ (จากการซักประวัติล่าสุด)
		String latestHistorySql =
			"SELECT history_id FROM medical_history " +
			"WHERE patient_id = ? ORDER BY created_at DESC, history_id DESC LIMIT 1";
		PreparedStatement latestHistoryStmt = con.prepareStatement(latestHistorySql);
		latestHistoryStmt.setInt(1, patientId);
		ResultSet latestHistoryRs = latestHistoryStmt.executeQuery();
		Integer latestHistoryId = null;
		if (latestHistoryRs.next()) {
			latestHistoryId = latestHistoryRs.getInt("history_id");
		}
		latestHistoryRs.close();
		latestHistoryStmt.close();

		if (latestHistoryId != null) {
			String allergySql =
				"SELECT DISTINCT drug_name FROM medical_history_drug_allergy WHERE history_id = ?";
			PreparedStatement allergyStmt = con.prepareStatement(allergySql);
			allergyStmt.setInt(1, latestHistoryId);
			ResultSet allergyRs = allergyStmt.executeQuery();
			while (allergyRs.next()) {
				String drugName = allergyRs.getString("drug_name");
				if (drugName != null && !drugName.trim().isEmpty()) {
					latestAllergyDrugNames.add(drugName.trim().toLowerCase());
				}
			}
			allergyRs.close();
			allergyStmt.close();
		}
		
	} catch(Exception e) {
		e.printStackTrace();
	} 
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../doctor_css/prescription.css">
<link rel="stylesheet" href="../layout.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>
<body>
	<%
		request.setAttribute("activePage", "prescription");
		request.setAttribute("pageTitle", "ใบสั่งยา");
	%>
	<jsp:include page="../include/navbar.jsp" />
	<jsp:include page="../include/header.jsp" />

	<div class="content" id="prescriptionPage">
		<div class="section" id="addDrugContainer">
			<div id="prescriptionHeader">
				<h3>เพิ่มยาลงในตารางใบสั่งยา</h3>
				<div style="display:flex;gap:10px; flex-direction:row;">
					<div id="buttonContainer"><button onclick="clearPrescriptionForm()">เพิ่มใบสั่งยาใหม่</button></div>
					<div id="buttonContainer"><button onclick="gotoPrescriptionTable()">ดูประวัติ</button></div>	
				</div>
			</div>		
			<!-- gridซ้าย -->
			<div class="section" id="addDrugToTable">				
				<div class="row">
					<label>เลือกยา:</label> 
                        <input id="drugInput" type="text" readonly placeholder="คลิกเพื่อเลือกยา" onclick="openDrugPopup()"> 
				</div>
				<div class="row">
					<label>จำนวน:</label> <input type="number" id="drugAmount" min="1">
				</div>
				<div class="row">
					<label>หน่วย:</label>
					<div class="combobox">
						<input id="drugUnitInput" type="text" placeholder="เลือกหน่วย">
						<div class="combo-list hidden">
							<div class="item">เม็ด</div>
							<div class="item">แผง</div>
							<div class="item">ขวด</div>
						</div>
					</div>
				</div>
				<div class="row">
					<label>ความถี่:</label>
					<div class="combobox">
						<input id="drugUsage" type="text" placeholder="เลือกความถี่">
						<div class="combo-list hidden">
							<div class="item">รับประทาน ครั้งละ 1 เม็ด เวลาปวดหรือมีไข้ ห่างกันอย่างน้อย 6 ชั่วโมง</div>
							<div class="item">รับประทาน ครั้งละ 2 เม็ด เวลาปวดหรือมีไข้ ห่างกันอย่างน้อย 6 ชั่วโมง</div>
							<div class="item">รับประทาน ครั้งละ 1 เม็ด เวลาปวดหรือมีไข้ ห่างกันอย่างน้อย 4-6 ชั่วโมง</div>
							<div class="item">รับประทาน ครั้งละ 1 เม็ดครึ่ง เวลาปวดหรือมีไข้ ห่างกันอย่างน้อย 6 ชั่วโมง</div>
							<div class="item">รับประทาน ครั้งละ 2 เม็ด เวลาปวดหรือมีไข้ ห่างกันอย่างน้อย 4-6 ชั่วโมง</div>
							<div class="item">รับประทาน ครั้งละ 2 เม็ด ทันที</div>
							<div class="item">รับประทาน ครั้งละ 1 เม็ด ห่างกันอย่างน้อย 4 ชั่วโมง เวลาปวดหรือมีไข้ (รอ A)</div>
							<div class="item">รับประทาน ครั้งละ 1 เม็ด ห่างกันอย่างน้อย 6 ชั่วโมง เวลาปวดหรือมีไข้ (รอ A)</div>
							<div class="item">รับประทาน ครั้งละ 2 เม็ด ห่างกันอย่างน้อย 4 ชั่วโมง เวลาปวดหรือมีไข้ (รอ A)</div>
							<div class="item">รับประทาน ครั้งละ 2 เม็ด ห่างกันอย่างน้อย 6 ชั่วโมง เวลาปวดหรือมีไข้ (รอ A)</div>
							<div class="item">รับประทาน ครั้งละ 1 เม็ด</div>
							<div class="item">รับประทาน ครั้งละ 1 เม็ด ก่อนฉีดยา amphotericin B</div>
							<div class="item">วันละ 3 ครั้ง หลังอาหาร</div>
							<div class="item">วันละ 2 ครั้ง หลังอาหาร</div>
							<div class="item">วันละ 1 ครั้ง หลังอาหาร</div>
							<div class="item">วันละ 3 ครั้ง ก่อนอาหาร</div>
							<div class="item">วันละ 2 ครั้ง ก่อนอาหาร</div>
							<div class="item">เช้า-เย็น หลังอาหาร</div>
							<div class="item">ก่อนนอน</div>
							<div class="item">เมื่อมีอาการ</div>
							<div class="item">ทุก 6 ชั่วโมง</div>
							<div class="item">ทุก 8 ชั่วโมง</div>
						</div>
					</div>
				</div>
				<div class="row">
					<label>ฉลากช่วย:</label>
					<div class="combobox">
						<input id="drugHelperLabel" type="text" placeholder="เลือกฉลากช่วย">
						<div class="combo-list hidden">
							<div class="item">ห้ามรับประทานเกิน วันละ 8 เม็ด และไม่ควรติดต่อกันเกิน 5 วัน</div>
							<div class="item">ห้ามรับประทานเกิน วันละ 6 เม็ด</div>
							<div class="item">ไม่ควรรับประทานติดต่อกันเกิน 3 วัน</div>
							<div class="item">ไม่ควรรับประทานติดต่อกันเกิน 7 วัน</div>
						</div>
					</div>
				</div>
				<button onclick="addDrugToTable()">+ เพิ่มลงตาราง</button>
			</div>
			<!-- gridกลาง -->
			<div>
				<!-- เลือกสิทธิการรักษา -->
				<div class="row">
					<label>สิทธิการรักษา:</label> 
					<select id="healthcareRight">
						<% if (patientRightId != null && !patientRightId.trim().isEmpty()) { %>
							<option value="<%= patientRightId %>" selected>
								<%= patientRightName %>
							</option>
						<% } %>
						<option value="PayYourself" <%= patientRightId == null ? "selected" : "" %>>ชำระเงินเอง</option>
					</select>
				</div>
			</div>
			<div id="prescriptionDetail"></div>
			<!-- ตารางยา -->
			<div class="tableContainer">
				<table id="drugTable">
					<thead>
						<tr>
							<th>ชื่อยา</th>
							<th>จำนวน</th>
							<th>หน่วย</th>
							<th>ความถี่</th>
							<th>ฉลากช่วย</th>
							<th>ลบ</th>
						</tr>
					</thead>
					<tbody id="drugTableBody"></tbody>
				</table>
			</div>
			<div id=buttonZone>
				<button onclick="savePrescription()">บันทึกใบสั่งยา</button>
				<button onclick="generatePDF()">พิมพ์ใบสั่งยา (PDF)</button>
			</div>
			
			<!-- Hidden form สำหรับส่งข้อมูล -->
			<form id="prescriptionForm" action="prescription.jsp?action=save" method="post" style="display:none;">
				<div id="hiddenInputs"></div>
			</form>
		</div>

		<!-- ตารางประวัติใบสั่งยา -->
		<div class="section" id="prescriptionTableContainer">
			<button id="backToAddDrugBtn" onclick="gotoAddDrug()">กลับ</button>
			<div class="sectionHeader">
				<h2>ประวัติใบสั่งยา</h2>
			</div>
			
			<!-- Search Filters -->
			<div class="search-container">
				<div class="search-box"><input type="text" id="searchDate" placeholder="ค้นหาวันที่..."></div>
				<div class="search-box"><input type="text" id="searchDoctor" placeholder="ค้นหาแพทย์..."></div>
				<div class="search-box"><input type="text" id="searchHealthRight" placeholder="ค้นหาสิทธิ..."></div>
				<div class="search-box"><input type="text" id="searchMedicineCount" placeholder="ค้นหาจำนวน..."></div>
				<div class="search-box">
					<button onclick="filterPrescriptionTable()" style="width: 100%;">ค้นหา</button>
				</div>
			</div>
			
			<table id="prescriptionTable">
				<thead>
					<tr>
						<th>วัน-เวลา</th>
						<th>แพทย์ผู้ออกใบสั่งยา</th>
						<th>สิทธิการรักษา</th>
						<th>จำนวนประเภทยา</th>
						<th>ดูรายละเอียด</th>
					</tr>
				</thead>
				<tbody>
				<%
					if (prescriptions.isEmpty()) {
				%>
					<tr>
						<td colspan="5" style="text-align:center;color:#888;">
							ไม่พบข้อมูลใบสั่งยา
						</td>
					</tr>
				<%
					} else {
						for (Map<String, String> prescription : prescriptions) {
					%>
					<tr data-prescription-id="<%= prescription.get("prescription_id") %>" 
					    data-date="<%= prescription.get("date") %>" 
					    data-health-right="<%= prescription.get("healthcare_right") %>">
						<td><%= prescription.get("date") %></td>
						<td><%= prescription.get("doctor") %></td>
						<td><%= prescription.get("healthcare_right") %></td>
						<td><%= prescription.get("medicine_count") %></td>
						<td>
							<button onclick="showPrescriptionDialog(this.closest('tr'))">ดูรายละเอียด</button>
						</td>
					</tr>
					<%  
						}
					}
					%>
				</tbody>
			</table>
			<div class="pagination" id="pagination"></div>
		</div>
	</div>

	<!-- dialog for selecting medicine -->
	<div class="dialogBG" id="drugPopup" style="display:none;">
		<div class="modal-content">
			<span class="close" onclick="closeDrugPopup()">&times;</span>
			<h3>เลือกยา</h3>
			<div class="modalHeader">
				<input type="text" id="drugSearch" placeholder="ค้นหาชื่อยา..." oninput="filterDrugList()">
				<p style="color: #e53935;">*หมายเหตุ: ยาที่มีพื้นหลังสีแดงคือยาที่คนไข้แพ้</p>
			</div>
			<div id="drugListContainer" class="itemListContainer">
				<% for (Map<String,String> m : medicines) {
					String medName = m.get("med_name");
					boolean isAllergyDrug = medName != null && latestAllergyDrugNames.contains(medName.trim().toLowerCase());
				%>
				<div class="itemList <%= isAllergyDrug ? "allergy-drug" : "" %>" style="display:none;" data-med-id="<%=m.get("med_id")%>" data-med-name="<%=m.get("med_name")%>" data-is-allergy="<%= isAllergyDrug %>" onclick="selectDrug('<%=m.get("med_id")%>')">
					<%= m.get("med_name") %>
				</div>
				<% } %>
			</div>
			<button type="button" onclick="addSelectedMedicine()">เลือกยา</button>
		</div>
	</div>

    <!-- ====== Prescription Detail Modal ====== -->
    <div id="prescriptionDetailModal" class="detail-modal-overlay">
        <div class="detail-modal-box">
            <h3>รายละเอียดใบสั่งยา</h3>
            <div class="detail-modal-info-rows">
                <div class="detail-modal-info-row"><span class="dim-label">วันที่</span><span id="prescModalDate"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">สิทธิการรักษา</span><span id="prescModalRight"></span></div>
            </div>
            <div id="prescModalContent" style="margin-top:12px;"></div>
            <div class="detail-modal-close-row">
				<div id="leftButtonGroup">
					<button id="printPrescBtn" onclick="generatePDF()">พิมพ์ PDF</button>
				</div>
				<div id="rightButtonGroup">
					<button class="btn-edit-modal" id="editPrescBtn" style="display:none;">แก้ไข</button>
					<button class="btn-delete-modal" id="deletePrescBtn" style="display:none;">ลบ</button>
					<button class="btn-close-modal" onclick="closePrescriptionDetailModal()">ปิด</button>
				</div>
            </div>
        </div>
    </div>
	
	<script>const SERVER_TODAY = "<%= java.time.LocalDate.now() %>";</script>
	<script src="../doctor_js/prescription.js"></script>
	<script src="../script.js"></script>
	<jsp:include page="../include/toast.jsp" />
	<%
	String loadPrescriptionId = request.getParameter("prescriptionId");
	if (loadPrescriptionId != null && !loadPrescriptionId.trim().isEmpty()) {
	%>
	<script>document.addEventListener('DOMContentLoaded', function() { loadAndDisplayPrescription(<%= loadPrescriptionId %>); });</script>
	<% } %>
	<%
	String showPrescTable = request.getParameter("showTable");
	if ("1".equals(showPrescTable)) {
	%>
	<script>document.addEventListener('DOMContentLoaded', function() { gotoPrescriptionTable(); });</script>
	<% } %>
	
	<% if (toastMessage != null) {
		session.removeAttribute("toastMessage");
		session.removeAttribute("toastType");
		String displayType = (toastType != null) ? toastType : "info";
	%>
	<script>
		showToast("<%= toastMessage %>", "<%= displayType %>");
	</script>
	<% } %>

</body>
</html>