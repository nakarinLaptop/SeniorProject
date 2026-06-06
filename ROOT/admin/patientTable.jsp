<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
    request.setCharacterEncoding("UTF-8");
	Integer userId = (Integer) session.getAttribute("user_id");
	if (userId == null) {
		response.sendRedirect("../index.jsp");
		return;
	}
	PreparedStatement  stmt = null;
	ResultSet rs = null;
	List<Map<String, String>> patientRightsList = new ArrayList<>();
	String errorMessage = null;
	String toastMsg  = (String) session.getAttribute("toastMessage");
	String toastType = (String) session.getAttribute("toastType");
	if (toastMsg != null) {
		session.removeAttribute("toastMessage");
		session.removeAttribute("toastType");
	}

	// Load healthcare_right 
	try {
		PreparedStatement rightStmt = con.prepareStatement("SELECT right_name FROM healthcare_right ORDER BY right_name");
		ResultSet rightRs = rightStmt.executeQuery();
		while (rightRs.next()) {
			Map<String, String> r = new HashMap<>();
			r.put("right_id",   rightRs.getString("right_name"));
			r.put("right_name", rightRs.getString("right_name"));
			patientRightsList.add(r);
		}
		rightRs.close();
		rightStmt.close();
	} catch (Exception e) {
		e.printStackTrace();
	}

	// import patients from CSV
	if ("importCsv".equals(request.getParameter("action"))) {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		String csvText = request.getParameter("csvText");
		if (csvText == null || csvText.trim().isEmpty()) {
			out.print("{\"success\":false,\"message\":\"ไม่พบข้อมูล CSV\"}");
			return;
		}
		String[] lines = csvText.split("\\r?\\n");
		int inserted = 0;
		int failed = 0;
		// skip header row (index 0)
		for (int li = 1; li < lines.length; li++) {
			String line = lines[li].trim();
			if (line.isEmpty()) continue;
			List<String> fields = new ArrayList<>();
			boolean inQuote = false;
			StringBuilder field = new StringBuilder();
			for (int ci = 0; ci < line.length(); ci++) {
				char c = line.charAt(ci);
				if (c == '"') {
					inQuote = !inQuote;
				} else if (c == ',' && !inQuote) {
					fields.add(field.toString().trim());
					field.setLength(0);
				} else {
					field.append(c);
				}
			}
			fields.add(field.toString().trim());
			if (fields.size() < 12) {
				failed++;
				continue;
			}
			try {
				String insertSql = "INSERT INTO patient "
					+ "(title, first_name, last_name, gender, phone_num, marriage_status, birth_date, "
					+ "province, district, sub_district, travel_method, occupation ,right_name) "
					+ "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
				PreparedStatement insStmt = con.prepareStatement(insertSql);
				insStmt.setString(1, fields.get(0));
				insStmt.setString(2, fields.get(1));
				insStmt.setString(3, fields.get(2));
				insStmt.setString(4, fields.get(3));
				insStmt.setString(5, fields.get(4));
				insStmt.setString(6, fields.get(5));
				String bd = fields.get(6);
				if (bd != null && !bd.isEmpty()) {
					insStmt.setString(7, bd);
				} else {
					insStmt.setNull(7, java.sql.Types.DATE);
				}
				insStmt.setString(8,  fields.get(7));
				insStmt.setString(9,  fields.get(8));
				insStmt.setString(10, fields.get(9));
				insStmt.setString(11, fields.get(10));
				insStmt.setString(12, fields.get(11));
				String rightIdText = fields.size() > 12 ? fields.get(12) : "";
				if (rightIdText != null && !rightIdText.trim().isEmpty()) {
					insStmt.setString(13, rightIdText.trim());
				} else {
					insStmt.setNull(13, java.sql.Types.VARCHAR);
				}
				insStmt.executeUpdate();
				insStmt.close();
				inserted++;
			} catch (Exception ex) {
				failed++;
			}
		}
		String msg = "นำเข้าสำเร็จ " + inserted + " รายการ";
		if (failed > 0) msg += " | ล้มเหลว " + failed + " รายการ";
		out.print("{\"success\":true,\"message\":\"" + msg.replace("\"","'") + "\",\"inserted\":" + inserted + ",\"failed\":" + failed + "}");
		return;
	}

	// add/edit/delete/restore patient
	if ("POST".equalsIgnoreCase(request.getMethod())) {
		String action    = request.getParameter("action");
		String editIdStr = request.getParameter("edit_id");


		if ("add".equals(action)) {
			String newTitle       = request.getParameter("newTitle");
			String newFirst       = request.getParameter("newFirst");
			String newLast        = request.getParameter("newLast");
			String newGender      = request.getParameter("newGender");
			String newMarriage    = request.getParameter("newMarriage");
			String newDob         = request.getParameter("newDob");
			String newPhone       = request.getParameter("newPhone");
			String newProvince    = request.getParameter("newProvince");
			String newDistrict    = request.getParameter("newDistrict");
			String newSubDistrict = request.getParameter("newSubDistrict");
			String newTravel      = request.getParameter("newTravel");
			String newOccupation  = request.getParameter("newOccupation");
			String newRightId     = request.getParameter("newRightId");
			try {
				String insertSql = "INSERT INTO patient "
					+ "(title, first_name, last_name, gender, marriage_status, birth_date, phone_num, "
					+ "province, district, sub_district, travel_method, occupation, right_name) "
					+ "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
				PreparedStatement insStmt = con.prepareStatement(insertSql);
				insStmt.setString(1, newTitle       != null ? newTitle.trim()       : "");
				insStmt.setString(2, newFirst       != null ? newFirst.trim()       : "");
				insStmt.setString(3, newLast        != null ? newLast.trim()        : "");
				insStmt.setString(4, newGender      != null ? newGender.trim()      : "");
				insStmt.setString(5, newMarriage    != null ? newMarriage.trim()    : "");
				if (newDob != null && !newDob.trim().isEmpty()) {
					insStmt.setString(6, newDob.trim());
				} else {
					insStmt.setNull(6, java.sql.Types.DATE);
				}
				insStmt.setString(7, newPhone       != null ? newPhone.trim()       : "");
				insStmt.setString(8, newProvince    != null ? newProvince.trim()    : "");
				insStmt.setString(9, newDistrict    != null ? newDistrict.trim()    : "");
				insStmt.setString(10, newSubDistrict != null ? newSubDistrict.trim() : "");
				insStmt.setString(11, newTravel     != null ? newTravel.trim()      : "");
				insStmt.setString(12, newOccupation != null ? newOccupation.trim()  : "");
				if (newRightId != null && !newRightId.trim().isEmpty()) {
					insStmt.setString(13, newRightId.trim());
				} else {
					insStmt.setNull(13, java.sql.Types.VARCHAR);
				}
				insStmt.executeUpdate();
				insStmt.close();
				session.setAttribute("toastMessage", "เพิ่มคนไข้เรียบร้อย");
				session.setAttribute("toastType", "success");
			} catch (Exception ex) {
				ex.printStackTrace();
				session.setAttribute("toastMessage", "เพิ่มคนไข้ไม่สำเร็จ: " + ex.getMessage());
				session.setAttribute("toastType", "error");
			}
		} else if ("restore".equals(action)) {
			String restoreIdStr = request.getParameter("restore_id");
			try {
				int restoreId = Integer.parseInt(restoreIdStr);
				PreparedStatement restStmt = con.prepareStatement(
					"UPDATE patient SET is_active = 1 WHERE patient_id = ?");
				restStmt.setInt(1, restoreId);
				int rows = restStmt.executeUpdate();
				restStmt.close();
				if (rows == 0) {
					session.setAttribute("toastMessage", "ไม่พบข้อมูลคนไข้ที่ต้องการกู้คืน");
					session.setAttribute("toastType", "error");
				} else {
					session.setAttribute("toastMessage", "กู้คืนคนไข้เรียบร้อย");
					session.setAttribute("toastType", "success");
				}
			} catch (Exception ex) {
				ex.printStackTrace();
				session.setAttribute("toastMessage", "กู้คืนคนไข้ไม่สำเร็จ: " + ex.getMessage());
				session.setAttribute("toastType", "error");
			}
			response.sendRedirect("patientTable.jsp");
			return;
		} else if ("delete".equals(action)) {
			String delIdStr = request.getParameter("delete_id");
			try {
				int delId = Integer.parseInt(delIdStr);
				PreparedStatement delStmt = con.prepareStatement("UPDATE patient SET is_active = 0 WHERE patient_id = ?");
				delStmt.setInt(1, delId);
				int rows = delStmt.executeUpdate();
				delStmt.close();
				if (rows == 0) {
					session.setAttribute("toastMessage", "ไม่พบข้อมูลคนไข้ที่ต้องการลบ (ID: " + delId + ")");
					session.setAttribute("toastType", "error");
				} else {
					session.setAttribute("toastMessage", "ลบคนไข้เรียบร้อย");
					session.setAttribute("toastType", "success");
				}
			} catch (Exception ex) {
				ex.printStackTrace();
				session.setAttribute("toastMessage", "ลบคนไข้ไม่สำเร็จ: " + ex.getMessage());
				session.setAttribute("toastType", "error");
			}
			response.sendRedirect("patientTable.jsp");
			return;
		} else if (editIdStr != null && !editIdStr.isEmpty()) {
			String editTitle       = request.getParameter("editTitle");
			String editFirst       = request.getParameter("editFirstName");
			String editLast        = request.getParameter("editLastName");
			String editGender      = request.getParameter("editGender");
			String editMarriage    = request.getParameter("editMarriageStatus");
			String editDob         = request.getParameter("editDob");
			String editPhone       = request.getParameter("editPhoneNum");
			String editProvince    = request.getParameter("editProvince");
			String editDistrict    = request.getParameter("editDistrict");
			String editSubDistrict = request.getParameter("editSubDistrict");
			String editTravel      = request.getParameter("editTravelMethod");
			String editOccupation  = request.getParameter("editOccupation");
			String editRightId     = request.getParameter("editRightId");
			try {
				int editId = Integer.parseInt(editIdStr);
				String updateSql = "UPDATE patient SET title=?, first_name=?, last_name=?, gender=?, "
					+ "marriage_status=?, birth_date=?, phone_num=?, province=?, district=?, "
					+ "sub_district=?, travel_method=?, occupation=?, right_name=? WHERE patient_id=?";
				PreparedStatement upStmt = con.prepareStatement(updateSql);
				upStmt.setString(1, editTitle       != null ? editTitle.trim()       : "");
				upStmt.setString(2, editFirst       != null ? editFirst.trim()       : "");
				upStmt.setString(3, editLast        != null ? editLast.trim()        : "");
				upStmt.setString(4, editGender      != null ? editGender.trim()      : "");
				upStmt.setString(5, editMarriage    != null ? editMarriage.trim()    : "");
				if (editDob != null && !editDob.trim().isEmpty()) {
					upStmt.setString(6, editDob.trim());
				} else {
					upStmt.setNull(6, java.sql.Types.DATE);
				}
				upStmt.setString(7, editPhone       != null ? editPhone.trim()       : "");
				upStmt.setString(8, editProvince    != null ? editProvince.trim()    : "");
				upStmt.setString(9, editDistrict    != null ? editDistrict.trim()    : "");
				upStmt.setString(10, editSubDistrict != null ? editSubDistrict.trim() : "");
				upStmt.setString(11, editTravel     != null ? editTravel.trim()      : "");
				upStmt.setString(12, editOccupation != null ? editOccupation.trim()  : "");
				if (editRightId != null && !editRightId.trim().isEmpty()) {
					upStmt.setString(13, editRightId.trim());
				} else {
					upStmt.setNull(13, java.sql.Types.VARCHAR);
				}
				upStmt.setInt(14, editId);
				int rows = upStmt.executeUpdate();
				upStmt.close();
				if (rows == 0) {
					session.setAttribute("toastMessage", "ไม่พบข้อมูลคนไข้ที่ต้องการแก้ไข (ID: " + editId + ")");
					session.setAttribute("toastType", "error");
				} else {
					session.setAttribute("toastMessage", "แก้ไขข้อมูลเรียบร้อย");
					session.setAttribute("toastType", "success");
				}
			} catch (Exception ex) {
				ex.printStackTrace();
				session.setAttribute("toastMessage", "แก้ไขข้อมูลไม่สำเร็จ: " + ex.getMessage());
				session.setAttribute("toastType", "error");
				response.sendRedirect("patientTable.jsp");
				return;
			}
		}
		response.sendRedirect("patientTable.jsp");
		return;
	}

	// load deleted patients for restore dialog
	List<Map<String, String>> deletedPatients = new ArrayList<>();
	try {
		PreparedStatement delPStmt = con.prepareStatement(
			"SELECT patient_id, CONCAT(title, first_name, ' ', last_name) AS patient_name, " +
			"CONCAT('P', LPAD(patient_id, 6, '0')) AS patient_code " +
			"FROM patient WHERE is_active = 0 ORDER BY patient_id");
		ResultSet delPRs = delPStmt.executeQuery();
		while (delPRs.next()) {
			Map<String, String> dp = new HashMap<>();
			dp.put("id",   delPRs.getString("patient_id"));
			dp.put("code", delPRs.getString("patient_code"));
			dp.put("name", delPRs.getString("patient_name"));
			deletedPatients.add(dp);
		}
		delPRs.close();
		delPStmt.close();
	} catch (Exception e) {
		e.printStackTrace();
	}

	List<Map<String, String>> patients = new ArrayList<>();
	// patient table
	try {
		String sql = "SELECT patient_id, right_name, title, first_name, last_name, gender, marriage_status, "
			+ "birth_date, phone_num, province, district, sub_district, "
			+ "travel_method, occupation, "
			+ "CONCAT('P', LPAD(patient_id, 6, '0')) AS patient_code "
			+ "FROM patient "
			+ "WHERE is_active = 1 "
			+ "ORDER BY patient_id";

		stmt = con.prepareStatement(sql);
		rs = stmt.executeQuery();
		while (rs.next()) {
			Map<String, String> p = new HashMap<>();
			p.put("id",            rs.getString("patient_id"));
			p.put("patient_code",  rs.getString("patient_code"));
			p.put("title",         rs.getString("title"));
			p.put("first_name",    rs.getString("first_name"));
			p.put("last_name",     rs.getString("last_name"));
			p.put("gender",        rs.getString("gender"));
			p.put("phone_num",     rs.getString("phone_num"));
			p.put("marriageStatus",rs.getString("marriage_status"));
			p.put("dob",           rs.getDate("birth_date") != null ? rs.getDate("birth_date").toString() : "");
			p.put("province",      rs.getString("province"));
			p.put("district",      rs.getString("district"));
			p.put("subDistrict",   rs.getString("sub_district"));
			p.put("travelMethod",  rs.getString("travel_method"));
			p.put("occupation",    rs.getString("occupation"));
			p.put("rightName",     rs.getString("right_name"));
			patients.add(p);
		}
		rs.close();
		stmt.close();


	} catch (Exception e) {
		e.printStackTrace();
		errorMessage = "ไม่สามารถโหลดข้อมูลคนไข้ได้: " + e.getMessage();
	}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../admin_css/patient.css">
<link rel="stylesheet" href="../layout.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>

<body>
	<%
		request.setAttribute("activePage", "patient");
		request.setAttribute("pageTitle", "ข้อมูลคนไข้");
	%>
	<jsp:include page="../include/navbar.jsp" />
	<jsp:include page="../include/header.jsp" />

	<div class="content" id="patientPage">
		<div class="section" id="patientTableSection">
			<div id="addPatientContainer">
				<h2>รายชื่อคนไข้</h2>
				<div>
					<button class="search-btn" onclick="openAddDialog()">เพิ่มคนไข้</button>
					<button class="search-btn" onclick="openRestorePatientDialog()">กู้คืนคนไข้ที่ถูกลบ</button>
				</div>
			</div>

			<div class="search-container">
				<div class="search-box"><input type="text" id="searchCode"         placeholder="รหัสคนไข้..."></div>
				<div class="search-box"><input type="text" id="searchTitle"        placeholder="คำนำหน้า..."></div>
				<div class="search-box"><input type="text" id="searchFirstName"    placeholder="ชื่อ..."></div>
				<div class="search-box"><input type="text" id="searchLastName"     placeholder="นามสกุล..."></div>
				<div class="search-box"><input type="text" id="searchGender"       placeholder="เพศ..."></div>
				<div class="search-box"><input type="text" id="searchPhone"        placeholder="เบอร์โทรศัพท์..."></div>
				<div class="search-box"><input type="text" id="searchMarriage"     placeholder="สถานะสมรส..."></div>
				<div class="search-box"><input type="text" id="searchDob" 		   placeholder="เลือกช่วงวันที่..."></div>
				<div class="search-box"><input type="text" id="searchProvince"     placeholder="จังหวัด..."></div>
				<div class="search-box"><input type="text" id="searchDistrict"     placeholder="อำเภอ..."></div>
				<div class="search-box"><input type="text" id="searchSubDistrict"  placeholder="ตำบล..."></div>
				<div class="search-box"><input type="text" id="searchTravel"       placeholder="การเดินทาง..."></div>
				<div class="search-box"><input type="text" id="searchOccupation"   placeholder="อาชีพ..."></div>
				<div class="search-box"><input type="text" id="searchRight"        placeholder="สิทธิการรักษา..."></div>
				<div class="search-box search-box-btn"><button onclick="filterPatients()" class="search-btn">ค้นหา</button></div>
			</div>

			<table id="patientTable">
				<thead>
					<tr>
					<th class="col-hidden">ID</th>
						<th>รหัสคนไข้</th>
						<th>คำนำหน้า</th>
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
						<th>สิทธิการรักษา</th>
						<th>แก้ไข</th>
					</tr>
				</thead>
				<tbody>
					<%
					if (errorMessage != null) {
					%>
					<tr>
						<td colspan="16" class="error-row"><%=errorMessage%></td>
					</tr>
					<%
					} else {
					for (Map<String, String> p : patients) {
					%>
					<tr data-id="<%=p.get("id")%>">
						<td class="col-hidden"><%=p.get("id")%></td>
						<td><%=p.get("patient_code")%></td>
						<td><%=p.get("title")%></td>
						<td><%=p.get("first_name")%></td>
						<td><%=p.get("last_name")%></td>
						<td><%=p.get("gender")%></td>
						<td><%=p.get("phone_num")%></td>
						<td><%=p.get("marriageStatus")%></td>
						<td><%=p.get("dob")%></td>
						<td><%=p.get("province")%></td>
						<td><%=p.get("district")%></td>
						<td><%=p.get("subDistrict")%></td>
						<td><%=p.get("travelMethod")%></td>
						<td><%=p.get("occupation")%></td>
						<td><%=p.get("rightName")%></td>
						<td class="col-action">
							<button class="search-btn" onclick="openEditDialog('<%=p.get("id")%>')">แก้ไข</button>
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


	<%-- Add Patient Dialog --%>
	<div id="addPatientDialog" class="dialogBG" style="display:none;">
		<%-- Add normal Patient --%>
		<div class="dialogContent">
			<div class="dialogHeader">
				<h2>เพิ่มคนไข้ใหม่</h2>
				<button onclick="openCsvDialog()">เพิ่มด้วย CSV</button>
			</div>
			<form method="POST" action="patientTable.jsp" accept-charset="UTF-8">
				<input type="hidden" name="action" value="add">
				<table class="edit-form-table">
					<tr>
						<td class="label-cell">คำนำหน้า</td>
						<td class="input-cell">
							<select id="addTitle" name="newTitle">
								<option value="นาย">นาย</option>
								<option value="นาง">นาง</option>
								<option value="นางสาว">นางสาว</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">ชื่อ</td>
						<td class="input-cell"><input type="text" id="addFirstName" name="newFirst" required></td>
					</tr>
					<tr>
						<td class="label-cell">นามสกุล</td>
						<td class="input-cell"><input type="text" id="addLastName" name="newLast" required></td>
					</tr>
					<tr>
						<td class="label-cell">เพศ</td>
						<td class="input-cell">
							<select id="addGender" name="newGender">
								<option value="ชาย">ชาย</option>
								<option value="หญิง">หญิง</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">เบอร์โทรศัพท์</td>
						<td class="input-cell"><input type="text" id="addPhoneNum" name="newPhone"></td>
					</tr>
					<tr>
						<td class="label-cell">สถานะการแต่งงาน</td>
						<td class="input-cell">
							<select id="addMarriageStatus" name="newMarriage">
								<option value="โสด">โสด</option>
								<option value="คู่/สมรส">คู่/สมรส</option>
								<option value="หย่า">หย่า</option>
								<option value="หม้าย">หม้าย</option>
								<option value="แยก">แยก</option>
								<option value="ไม่ระบุ">ไม่ระบุ</option>
								<option value="บวช">บวช</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">วันเกิด</td>
						<td class="input-cell"><input type="date" id="addDob" name="newDob"></td>
					</tr>
					<tr>
						<td class="label-cell">จังหวัด</td>
						<td class="input-cell"><input type="text" id="addProvince" name="newProvince"></td>
					</tr>
					<tr>
						<td class="label-cell">อำเภอ/เขต</td>
						<td class="input-cell"><input type="text" id="addDistrict" name="newDistrict"></td>
					</tr>
					<tr>
						<td class="label-cell">ตำบล/แขวง</td>
						<td class="input-cell"><input type="text" id="addSubDistrict" name="newSubDistrict"></td>
					</tr>
					<tr>
						<td class="label-cell">การเดินทาง</td>
						<td class="input-cell">
							<select id="addTravelMethod" name="newTravel">
								<option value="รถยนต์ส่วนตัว">รถยนต์ส่วนตัว</option>
								<option value="รถสาธารณะ">รถสาธารณะ</option>
								<option value="จักรยานยนต์">จักรยานยนต์</option>
								<option value="เดินมา">เดินมา</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">อาชีพ</td>
						<td class="input-cell"><input type="text" id="addOccupation" name="newOccupation"></td>
					</tr>
					<tr>
						<td class="label-cell">สิทธิการรักษา</td>
						<td class="input-cell">
						<select id="addRight" name="newRightId">
								<option value="">-- ไม่มี --</option>
								<% for (Map<String,String> right : patientRightsList) { %>
								<option value="<%=right.get("right_id")%>"><%=right.get("right_name")%></option>
								<% } %>
							</select>
						</td>
					</tr>
				</table>
				<div class="dialogActions">
					<button type="button" class="search-btn btn-secondary" onclick="closeAddDialog()">ยกเลิก</button>
					<button type="submit" class="search-btn">บันทึก</button>
				</div>
			</form>
		</div>

		<%-- CSV Import --%>
		<div id="csvImportDialog" class="dialogBG" style="display:none;">
			<div class="dialogContent" action="patientTable.jsp"  id="csvImportSection">
				<h3>นำเข้าข้อมูลจากไฟล์ CSV</h3>
				<p>CSV: "title","first_name","last_name","gender","phone_num","marriage_status","birth_date","province","district","sub_district","travel_method","occupation","right_name" (right_name ถ้าไม่มีสามารถเว้นว่างได้)</p>
				<button onclick="downloadCsvTemplate()">ดาวโหลด</button>
				<form method="post" action="patientTable.jsp" id="csvImportForm" onsubmit="return prepareCsvSubmit()">
					<div class="csv-import-group">
						<input type="file" id="csvFileInput" accept=".csv">
						<input type="hidden" name="csvText" id="csvTextHidden">
					</div>
					<div class="dialogActions">
						<button type="button" class="search-btn btn-secondary" onclick="closeCsvDialog()">ยกเลิก</button>
						<button type="submit" class="search-btn">นำเข้า</button>
					</div>
				</form>
			</div>
		</div>
	</div>

	<%-- Restore Patient Dialog --%>
	<div id="restorePatientDialog" class="dialogBG" style="display:none;">
		<div class="dialogContent">
			<h3>รายชื่อคนไข้ที่ไม่ได้ใช้งาน</h3>
			<div class="docList">
				<% if (deletedPatients.isEmpty()) { %>
					<p>ไม่มีคนไข้ที่ถูกลบ</p>
				<% } else { %>
					<ul id="restorePatientList">
						<% for (Map<String, String> dp : deletedPatients) { %>
							<li data-id="<%= dp.get("id") %>" onclick="selectRestorePatient(this)">
								<%= dp.get("code") %> - <%= dp.get("name") %>
							</li>
						<% } %>
					</ul>
				<% } %>
			</div>
			<div class="dialogActions">
				<button type="button" class="search-btn btn-secondary" onclick="closeRestorePatientDialog()">ยกเลิก</button>
				<button type="button" class="search-btn" onclick="confirmRestorePatient()">กู้คืนคนไข้</button>
			</div>
		</div>
	</div>

	<%-- Edit Patient Dialog --%>
	<div id="editPatientDialog" class="dialogBG" style="display:none;">
		<div class="dialogContent">
			<div class="dialogHeader">
				<h3>แก้ไขข้อมูลคนไข้</h3>
			</div>
			<form method="post" action="patientTable.jsp">
				<input type="hidden" id="editPatientId" name="edit_id">
				<table class="edit-form-table">
					<tr>
						<td class="label-cell">คำนำหน้า</td>
						<td class="input-cell">
							<select id="editTitle" name="editTitle">
								<option value="นาย">นาย</option>
								<option value="นาง">นาง</option>
								<option value="นางสาว">นางสาว</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">ชื่อ</td>
						<td class="input-cell"><input type="text" id="editFirstName" name="editFirstName" required></td>
					</tr>
					<tr>
						<td class="label-cell">นามสกุล</td>
						<td class="input-cell"><input type="text" id="editLastName" name="editLastName" required></td>
					</tr>
					<tr>
						<td class="label-cell">เพศ</td>
						<td class="input-cell">
							<select id="editGender" name="editGender">
								<option value="ชาย">ชาย</option>
								<option value="หญิง">หญิง</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">เบอร์โทรศัพท์</td>
						<td class="input-cell"><input type="text" id="editPhoneNum" name="editPhoneNum"></td>
					</tr>
					<tr>
						<td class="label-cell">สถานะการแต่งงาน</td>
						<td class="input-cell">
							<select id="editMarriageStatus" name="editMarriageStatus">
								<option value="โสด">โสด</option>
								<option value="คู่/สมรส">คู่/สมรส</option>
								<option value="หย่า">หย่า</option>
								<option value="หม้าย">หม้าย</option>
								<option value="แยก">แยก</option>
								<option value="ไม่ระบุ">ไม่ระบุ</option>
								<option value="บวช">บวช</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">วันเกิด</td>
						<td class="input-cell"><input type="date" id="editDob" name="editDob"></td>
					</tr>
					<tr>
						<td class="label-cell">จังหวัด</td>
						<td class="input-cell"><input type="text" id="editProvince" name="editProvince"></td>
					</tr>
					<tr>
						<td class="label-cell">อำเภอ/เขต</td>
						<td class="input-cell"><input type="text" id="editDistrict" name="editDistrict"></td>
					</tr>
					<tr>
						<td class="label-cell">ตำบล/แขวง</td>
						<td class="input-cell"><input type="text" id="editSubDistrict" name="editSubDistrict"></td>
					</tr>
					<tr>
						<td class="label-cell">การเดินทาง</td>
						<td class="input-cell">
							<select id="editTravelMethod" name="editTravelMethod">
								<option value="รถยนต์ส่วนตัว">รถยนต์ส่วนตัว</option>
								<option value="รถสาธารณะ">รถสาธารณะ</option>
								<option value="จักรยานยนต์">จักรยานยนต์</option>
								<option value="เดินมา">เดินมา</option>
								<option value="อื่นๆ">อื่นๆ</option>
							</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">อาชีพ</td>
						<td class="input-cell"><input type="text" id="editOccupation" name="editOccupation"></td>
					</tr>
					<tr>
						<td class="label-cell">สิทธิการรักษา</td>
						<td class="input-cell">
						<select id="editRight" name="editRightId">
								<option value="">-- ไม่มี --</option>
								<% for (Map<String,String> right : patientRightsList) { %>
								<option value="<%=right.get("right_id")%>"><%=right.get("right_name")%></option>
								<% } %>
							</select>
						</td>
					</tr>
				</table>
				<div class="dialogActions">
					<button type="button" class="search-btn btn-danger" onclick="deletePatient()" style="background-color: red;">ลบคนไข้</button>
					<button type="button" class="search-btn btn-secondary" onclick="closeEditDialog()">ยกเลิก</button>
					<button type="submit" class="search-btn">บันทึก</button>
				</div>
			</form>
		</div>
	</div>

	<%-- Hidden Delete Form --%>
	<form id="deletePatientForm" method="post" action="patientTable.jsp" style="display:none;">
		<input type="hidden" name="action" value="delete">
		<input type="hidden" id="deletePatientId" name="delete_id">
	</form>

	<%-- Hidden Restore Form --%>
	<form id="restorePatientForm" method="post" action="patientTable.jsp" style="display:none;">
		<input type="hidden" name="action" value="restore">
		<input type="hidden" id="restorePatientId" name="restore_id">
	</form>



	<script>
	const patientsData = [
		<% for (Map<String, String> p : patients) { %>
		{
			id:           "<%= p.get("id") %>",
			patient_code: "<%= p.get("patient_code") %>",
			title:        "<%= p.get("title")            != null ? p.get("title").replace("\"", "&quot;").replace("'", "&#39;")        : "-" %>",
			first_name:   "<%= p.get("first_name")       != null ? p.get("first_name").replace("\"", "&quot;").replace("'", "&#39;")   : "-" %>",
			last_name:    "<%= p.get("last_name")     	 != null ? p.get("last_name").replace("\"", "&quot;").replace("'", "&#39;")    : "-" %>",
			gender:       "<%= p.get("gender")        	 != null ? p.get("gender")        : "-" %>",
			phone_num:    "<%= p.get("phone_num")     	 != null ? p.get("phone_num")     : "-" %>",
			marriageStatus: "<%= p.get("marriageStatus") != null ? p.get("marriageStatus") : "-" %>",
			dob:          "<%= p.get("dob")           	 != null ? p.get("dob")           : "-" %>",
			province:     "<%= p.get("province")     	 != null ? p.get("province").replace("\"", "&quot;").replace("'", "&#39;")     : "-" %>",
			district:     "<%= p.get("district")     	 != null ? p.get("district").replace("\"", "&quot;").replace("'", "&#39;")     : "-" %>",
			subDistrict:  "<%= p.get("subDistrict")  	 != null ? p.get("subDistrict").replace("\"", "&quot;").replace("'", "&#39;")  : "-" %>",
			travelMethod: "<%= p.get("travelMethod")  	 != null ? p.get("travelMethod")  : "-" %>",
			occupation:   "<%= p.get("occupation")   	 != null ? p.get("occupation").replace("\"", "&quot;").replace("'", "&#39;")   : "-" %>",
			right:        "<%= p.get("rightName")    	 != null ? p.get("rightName").replace("\"", "&quot;").replace("'", "&#39;")    : "-" %>"
		},
		<% } %>
	];
	</script>
	<script src="../admin_js/patientTable.js"></script>
	<script src="../script.js"></script>
	<jsp:include page="../include/toast.jsp" />
	<% if (toastMsg != null) { %>
	<script>document.addEventListener("DOMContentLoaded", 
			function(){ 
				showToast("<%= toastMsg.replace("\"", "&quot;") %>", "<%= toastType %>"); 
			});</script>
	<% } %>
</body>
</html>
