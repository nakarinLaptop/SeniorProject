<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.time.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
	Integer doctorId  = (Integer) session.getAttribute("user_id");
	Integer patientId = (Integer) session.getAttribute("patient_id");

	if (doctorId == null) {
		response.sendRedirect("../index.jsp");
		return;
	}

	String toastMessage = (String) session.getAttribute("toastMessage");
	String toastType    = (String) session.getAttribute("toastType");
	PreparedStatement stmt = null;
	ResultSet rs = null;

	/* ---------- POST: add / edit / delete ---------- */
	request.setCharacterEncoding("UTF-8");
	if ("POST".equals(request.getMethod())) {
		String action = request.getParameter("action");

		/* ===== DELETE ===== */
		if ("delete".equals(action)) {
			try {
				int delId = Integer.parseInt(request.getParameter("history_id"));
				PreparedStatement chk = con.prepareStatement(
					"SELECT DATE(created_at) AS d FROM medical_history WHERE history_id = ? AND patient_id = ?");
				chk.setInt(1, delId); chk.setInt(2, patientId);
				ResultSet chkRs = chk.executeQuery();
				if (!chkRs.next() || !chkRs.getDate("d").toLocalDate().equals(LocalDate.now())) {
					chkRs.close(); chk.close();
					session.setAttribute("toastMessage", "ไม่สามารถลบได้ เนื่องจากไม่ใช่รายการของวันนี้");
					session.setAttribute("toastType", "error");
					response.sendRedirect("medExamination.jsp?showTable=1");
					return;
				}
				chkRs.close(); chk.close();
				con.setAutoCommit(false);
				PreparedStatement d1 = con.prepareStatement("DELETE FROM medical_history_drug_allergy WHERE history_id = ?");
				d1.setInt(1, delId); d1.executeUpdate(); d1.close();
				PreparedStatement d2 = con.prepareStatement("DELETE FROM medical_history_icd WHERE history_id = ?");
				d2.setInt(1, delId); d2.executeUpdate(); d2.close();
				PreparedStatement d3 = con.prepareStatement("DELETE FROM medical_history WHERE history_id = ? AND patient_id = ?");
				d3.setInt(1, delId); d3.setInt(2, patientId); d3.executeUpdate(); d3.close();
				con.commit();
				session.setAttribute("toastMessage", "ลบข้อมูลสำเร็จ");
				session.setAttribute("toastType", "success");
				response.sendRedirect("medExamination.jsp?showTable=1");
			} catch (Exception e) {
				try { con.rollback(); } catch (Exception ignored) {}
				session.setAttribute("toastMessage", "ลบข้อมูลไม่สำเร็จ: " + e.getMessage());
				session.setAttribute("toastType", "error");
				response.sendRedirect("medExamination.jsp?showTable=1");
			}
			return;
		}

		/* ===== EDIT ===== */
		if ("edit".equals(action)) {
			String historyIdStr  = request.getParameter("edit_history_id");
			String interviewText = request.getParameter("interview_text");
			String[] icdCodes     = request.getParameterValues("icd_codes[]");
			String[] drugAllergies = request.getParameterValues("drug_allergy[]");
			String[] drugDetails   = request.getParameterValues("drug_detail[]");
			try {
				int historyId = Integer.parseInt(historyIdStr);
				// same-day check
				PreparedStatement chk = con.prepareStatement(
					"SELECT DATE(created_at) AS d FROM medical_history WHERE history_id = ? AND patient_id = ?");
				chk.setInt(1, historyId); chk.setInt(2, patientId);
				ResultSet chkRs = chk.executeQuery();
				if (!chkRs.next() || !chkRs.getDate("d").toLocalDate().equals(LocalDate.now())) {
					chkRs.close(); chk.close();
					session.setAttribute("toastMessage", "ไม่สามารถแก้ไขได้ เนื่องจากไม่ใช่รายการของวันนี้");
					session.setAttribute("toastType", "error");
					return;
				}
				chkRs.close(); chk.close();
				con.setAutoCommit(false);
				stmt = con.prepareStatement("UPDATE medical_history SET interview_text = ? WHERE history_id = ?");
				stmt.setString(1, interviewText); stmt.setInt(2, historyId);
				stmt.executeUpdate(); stmt.close();
				stmt = con.prepareStatement("DELETE FROM medical_history_icd WHERE history_id = ?");
				stmt.setInt(1, historyId); stmt.executeUpdate(); stmt.close();
				if (icdCodes != null && icdCodes.length > 0) {
					stmt = con.prepareStatement("INSERT INTO medical_history_icd (history_id, icd_code, created_at) VALUES (?, ?, NOW())");
					for (String c : icdCodes) { stmt.setInt(1, historyId); stmt.setString(2, c); stmt.addBatch(); }
					stmt.executeBatch(); stmt.close();
					stmt = con.prepareStatement("UPDATE patient SET icd10 = ? WHERE patient_id = ?");
					stmt.setString(1, icdCodes[0].trim()); stmt.setInt(2, patientId);
					stmt.executeUpdate(); stmt.close();
				}
				stmt = con.prepareStatement("DELETE FROM medical_history_drug_allergy WHERE history_id = ?");
				stmt.setInt(1, historyId); stmt.executeUpdate(); stmt.close();
				if (drugAllergies != null && drugAllergies.length > 0) {
					stmt = con.prepareStatement("INSERT INTO medical_history_drug_allergy (history_id, drug_name, detail, created_at) VALUES (?, ?, ?, NOW())");
					for (int i = 0; i < drugAllergies.length; i++) {
						stmt.setInt(1, historyId); stmt.setString(2, drugAllergies[i]);
						stmt.setString(3, (drugDetails != null && i < drugDetails.length) ? drugDetails[i] : "");
						stmt.addBatch();
					}
					stmt.executeBatch(); stmt.close();
				}
				con.commit();
				session.setAttribute("toastMessage", "แก้ไขข้อมูลสำเร็จ");
				session.setAttribute("toastType", "success");
				response.sendRedirect("medExamination.jsp?historyId=" + historyId);
			} catch (Exception e) {
				try { con.rollback(); } catch (Exception ignored) {}
				e.printStackTrace();
				session.setAttribute("toastMessage", "แก้ไขข้อมูลไม่สำเร็จ: " + e.getMessage());
				session.setAttribute("toastType", "error");
				response.sendRedirect("medExamination.jsp");
			}
			return;
		}

		/* ===== ADD ===== */
		if ("add".equals(action)) {
			String interviewText = request.getParameter("interview_text");
			String[] icdCodes     = request.getParameterValues("icd_codes[]");
			String[] drugAllergies = request.getParameterValues("drug_allergy[]");
			String[] drugDetails   = request.getParameterValues("drug_detail[]");
			try {
				con.setAutoCommit(false);
				stmt = con.prepareStatement(
					"INSERT INTO medical_history (doctor_id, patient_id, interview_text, created_at) VALUES (?, ?, ?, NOW())",
					Statement.RETURN_GENERATED_KEYS);
				stmt.setInt(1, doctorId); stmt.setInt(2, patientId); stmt.setString(3, interviewText);
				stmt.executeUpdate();
				rs = stmt.getGeneratedKeys();
				int historyId = 0;
				if (rs.next()) historyId = rs.getInt(1);
				rs.close(); stmt.close();
				if (icdCodes != null && icdCodes.length > 0) {
					stmt = con.prepareStatement("INSERT INTO medical_history_icd (history_id, icd_code, created_at) VALUES (?, ?, NOW())");
					for (String c : icdCodes) { stmt.setInt(1, historyId); stmt.setString(2, c); stmt.addBatch(); }
					stmt.executeBatch(); stmt.close();
					stmt = con.prepareStatement("UPDATE patient SET icd10 = ? WHERE patient_id = ?");
					stmt.setString(1, icdCodes[0].trim()); stmt.setInt(2, patientId);
					stmt.executeUpdate(); stmt.close();
				}
				if (drugAllergies != null && drugAllergies.length > 0) {
					stmt = con.prepareStatement("INSERT INTO medical_history_drug_allergy (history_id, drug_name, detail, created_at) VALUES (?, ?, ?, NOW())");
					for (int i = 0; i < drugAllergies.length; i++) {
						stmt.setInt(1, historyId); stmt.setString(2, drugAllergies[i]);
						stmt.setString(3, (drugDetails != null && i < drugDetails.length) ? drugDetails[i] : "");
						stmt.addBatch();
					}
					stmt.executeBatch(); stmt.close();
				}
				con.commit();
				session.setAttribute("toastMessage", "บันทึกข้อมูลสำเร็จ");
				session.setAttribute("toastType", "success");
				response.sendRedirect("medExamination.jsp?historyId=" + historyId);
			} catch (Exception e) {
				try { con.rollback(); } catch (Exception ignored) {}
				e.printStackTrace();
				session.setAttribute("toastMessage", "บันทึกข้อมูลไม่สำเร็จ: " + e.getMessage());
				session.setAttribute("toastType", "error");
				response.sendRedirect("medExamination.jsp");
			}
			return;
		}
	}

	
	String getAction = request.getParameter("action");
	/* ---------- edit and save drug allergy ---------- */
	if ("getDrugAllergy".equals(getAction)) {
		response.setContentType("application/json; charset=UTF-8");
		out.clearBuffer();
		try {
			int hid = Integer.parseInt(request.getParameter("history_id"));
			PreparedStatement ds = con.prepareStatement(
				"SELECT drug_name, detail FROM medical_history_drug_allergy WHERE history_id = ?");
			ds.setInt(1, hid);
			ResultSet dr = ds.executeQuery();
			StringBuilder sb = new StringBuilder("[");
			boolean first = true;
			while (dr.next()) {
				if (!first) sb.append(",");
				sb.append("{\"drug_name\":\"").append(dr.getString("drug_name").replace("\"", "\\\"")).append("\",")
				  .append("\"detail\":\"").append(dr.getString("detail") != null ? dr.getString("detail").replace("\"", "\\\"") : "").append("\"");
				sb.append("}");
				first = false;
			}
			sb.append("]");
			dr.close(); ds.close();
			out.print(sb.toString());
		} catch (Exception e) { out.print("[]"); }
		return;
	}
	/* ---------- edit and save entire history form ---------- */
	if ("getFullHistory".equals(getAction)) {
		response.setContentType("application/json; charset=UTF-8");
		out.clearBuffer();
		try {
			int hid = Integer.parseInt(request.getParameter("history_id"));
			PreparedStatement hs = con.prepareStatement(
				"SELECT mh.history_id, DATE_FORMAT(mh.created_at,'%Y-%m-%d %H:%i:%s') AS created_at, " +
				"CONCAT(u.title,u.first_name,' ',u.last_name) AS doctor_name, mh.interview_text, " +
				"GROUP_CONCAT(DISTINCT CONCAT(i.icd_id,' - ',i.icd_name) SEPARATOR ', ') AS icd_list " +
				"FROM medical_history mh " +
				"JOIN `user` u ON mh.doctor_id = u.user_id " +
				"LEFT JOIN medical_history_icd mhicd ON mh.history_id = mhicd.history_id " +
				"LEFT JOIN `icd-10` i ON mhicd.icd_code = i.icd_id " +
				"WHERE mh.history_id = ? AND mh.patient_id = ? GROUP BY mh.history_id");
			hs.setInt(1, hid); hs.setInt(2, patientId);
			ResultSet hr = hs.executeQuery();
			StringBuilder sb = new StringBuilder();
			if (hr.next()) {
				String txt  = hr.getString("interview_text"); if (txt  == null) txt  = "";
				String icds = hr.getString("icd_list");       if (icds == null) icds = "-";
				String doc  = hr.getString("doctor_name");     if (doc  == null) doc  = "";
				String dt   = hr.getString("created_at");      if (dt   == null) dt   = "";
				sb.append("{\"history\":{\"history_id\":").append(hid)
				  .append(",\"date\":\"").append(dt.replace("\"", "\\\"")).append("\"")
				  .append(",\"doctor\":\"").append(doc.replace("\"", "\\\"")).append("\"")
				  .append(",\"text\":\"").append(txt.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "")).append("\"")
				  .append(",\"icds\":\"").append(icds.replace("\"", "\\\"")).append("\"");
				sb.append("},");
			} else {
				out.print("{}"); hr.close(); hs.close(); return;
			}
			hr.close(); hs.close();
			PreparedStatement ds = con.prepareStatement(
				"SELECT drug_name, detail FROM medical_history_drug_allergy WHERE history_id = ?");
			ds.setInt(1, hid);
			ResultSet dr = ds.executeQuery();
			sb.append("\"drugs\":[");
			boolean first = true;
			while (dr.next()) {
				if (!first) sb.append(",");
				sb.append("{\"drug_name\":\"").append(dr.getString("drug_name").replace("\"", "\\\"")).append("\",")
				  .append("\"detail\":\"").append(dr.getString("detail") != null ? dr.getString("detail").replace("\"", "\\\"") : "").append("\"");
				sb.append("}");
				first = false;
			}
			sb.append("]}");
			dr.close(); ds.close();
			out.print(sb.toString());
		} catch (Exception e) { out.print("{}"); }
		return;
	}

	/* ---------- โหลดข้อมูล ในตาราง ---------- */
	List<Map<String,String>> histories = new ArrayList<>();
	List<Map<String,String>> medicines = new ArrayList<>();
	List<Map<String,String>> icds = new ArrayList<>();

	try {
		String sql =
			"SELECT mh.history_id, mh.doctor_id, " +
			"DATE_FORMAT(mh.created_at, '%Y-%m-%d %H:%i:%s') AS created_at, " +
			"CONCAT(u.title, u.first_name, ' ', u.last_name) AS doctor_name, " +
			"mh.interview_text, " +
			"GROUP_CONCAT(DISTINCT CONCAT(i.icd_id, ' - ', i.icd_name) SEPARATOR ', ') AS icd_list, " +
			"GROUP_CONCAT(DISTINCT da.drug_name SEPARATOR ', ') AS drug_list " +
			"FROM medical_history mh " +
			"JOIN `user` u ON mh.doctor_id = u.user_id " +
			"LEFT JOIN medical_history_icd mhicd ON mh.history_id = mhicd.history_id " +
			"LEFT JOIN `icd-10` i ON mhicd.icd_code = i.icd_id " +
			"LEFT JOIN medical_history_drug_allergy da ON mh.history_id = da.history_id " +
			"WHERE mh.patient_id = ? " +
			"GROUP BY mh.history_id " +
			"ORDER BY mh.history_id DESC";

		stmt = con.prepareStatement(sql);
		stmt.setInt(1, patientId);
		rs = stmt.executeQuery();
		while (rs.next()) {
			Map<String,String> row = new HashMap<>();
			row.put("history_id", rs.getString("history_id"));
			row.put("doctor_id",  rs.getString("doctor_id"));
			row.put("date",       rs.getString("created_at"));
			row.put("doctor",     rs.getString("doctor_name"));
			row.put("text",       rs.getString("interview_text"));
			row.put("icds",       rs.getString("icd_list"));
			row.put("drugs",      rs.getString("drug_list"));
			histories.add(row);
		}
		rs.close();
		stmt.close();

		stmt = con.prepareStatement("SELECT med_id, med_name FROM medicine ORDER BY med_name");
		rs = stmt.executeQuery();
		while (rs.next()) {
			Map<String,String> m = new HashMap<>();
			m.put("id",   rs.getString("med_id"));
			m.put("name", rs.getString("med_name"));
			medicines.add(m);
		}
		rs.close();
		stmt.close();

		stmt = con.prepareStatement("SELECT icd_id, icd_name FROM `icd-10` ORDER BY icd_id");
		rs = stmt.executeQuery();
		while (rs.next()) {
			Map<String,String> i = new HashMap<>();
			i.put("code", rs.getString("icd_id"));
			i.put("name", rs.getString("icd_name"));
			icds.add(i);
		}
		rs.close();
		stmt.close();

	} catch(Exception e) {
		e.printStackTrace();
	}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../doctor_css/medExamination.css">
<link rel="stylesheet" href="../layout.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>
<body>

    <%
        request.setAttribute("activePage", "med");
        request.setAttribute("pageTitle", "ซักประวัติคนไข้");
    %>

    <jsp:include page="../include/navbar.jsp" />
    <jsp:include page="../include/header.jsp" />

    <div class="content" id="medExaminationPage">
        <!-------------------หน้าการซักประวัติ---------------->
        <div class="section" id="historyFormSection">
            <div id="formSectionHeader">
                <div id="medExamDetail">
                </div>
                <div>
                    <button onclick="gotoPage('medExamination.jsp')" id="newExamBtn" style="display: none;">ซักประวัติใหม่</button>
                    <button onclick="showHistoryTable()" id="showHistoryButton">ตารางการซักประวัติ</button>
                </div>
            </div>
            <div id="formSectionContent">
                <form action="medExamination.jsp" method="post" id="historyForm">
                    <input type="hidden" name="action" id="formAction" value="add">
                    <input type="hidden" name="doctor_id" value="<%= doctorId %>">
                    <input type="hidden" name="patient_id" value="<%= patientId %>">
                    
                    <div class="formContainer" id="deatailContainer">
                        <h2>รายละเอียดการซักประวัติ</h2>
                        <textarea name="interview_text" rows="20" required
                            placeholder="กรอกรายละเอียดการซักประวัติคนไข้..."></textarea>
                    </div>
                    <div class="formContainer" id="icdFormContainer">
                        <div class="formContainerHeader">
                            <h2>โรคประจำตัวผู้ป่วย</h2>
                            <button type="button" onclick="openIcdPopup()">เพิ่มโรคประจำตัว</button>
                        </div>
                        <table class="miniTable" id="icdTable">
                            <thead>
                                <tr>
                                    <th>รหัส ICD-10</th>
                                    <th>ชื่อโรค</th>
                                    <th>ลบ</th>
                                </tr>
                            </thead>
                            <tbody></tbody>
                        </table>
                    </div>
                    <div class="formContainer" id="drugAllergyContainer">
                        <div class="formContainerHeader">
                            <h2>ประวัติการแพ้ยา</h2>
                            <button type="button" onclick="openDrugPopup()">เพิ่มยาที่แพ้</button>
                        </div>
                        <table class="miniTable" id="drugAllergyTable">
                            <thead>
                                <tr>
                                    <th>ชื่อยา</th>
                                    <th>อาการแพ้</th>
                                    <th>แก้ไข</th>
                                    <th>ลบ</th>
                                </tr>
                            </thead>
                            <tbody></tbody>
                        </table>
                    </div>
                </form>
            </div>
            <div id="formSectionFooter">
                <button onclick="submitHistoryForm()" id="submitHistoryButton">บันทึกข้อมูลการซักประวัติ</button>
            </div>
        </div>

        <!-- ====== ตารางประวัติการซักประวัติ ====== -->
        <div class="section" id="historyTableSection">
            <div class="section-header">
                <button onclick="showHistoryForm()">ย้อนกลับ</button>
                <h2>รายการซักประวัติคนไข้</h2>
            </div>

            <!-- Search Filters -->
            <div class="search-container">
                <div class="search-box"><input type="text" id="searchDate" placeholder="ค้นหาวันที่..."></div>
                <div class="search-box"><input type="text" id="searchDoctor" placeholder="ค้นหาแพทย์..."></div>
                <div class="search-box"><input type="text" id="searchText" placeholder="ค้นหารายละเอียด..."></div>
                <div class="search-box"><input type="text" id="searchIcd" placeholder="ค้นหาโรค..."></div>
                <div class="search-box"><input type="text" id="searchDrug" placeholder="ค้นหายา..."></div>
                <div class="search-box">
                    <button onclick="filterHistoryTable()" style="width: 100%;">ค้นหา</button>
                </div>
            </div>

            <table class="historyTable" id="historyTable">
                <thead>
                    <tr>
                        <th>วันที่ซักประวัติ</th>
                        <th>แพทย์ผู้ซักประวัติ</th>
                        <th>รายละเอียดการซักประวัติ</th>
                        <th>โรคประจำตัว</th>
                        <th>ยาที่แพ้</th>
                        <th>ดูรายละเอียด</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    if (histories.isEmpty()) {
                %>
                    <tr>
                        <td colspan="6" style="text-align:center;color:#888;">
                            ไม่พบข้อมูลการซักประวัติ
                        </td>
                    </tr>
                <%
                    } else {
                        for (Map<String,String> h : histories) {
                %>
                    <tr data-history-id="<%= h.get("history_id") %>" data-doctor-id="<%= h.get("doctor_id") %>">
                        <td><%= h.get("date") %></td>
                        <td><%= h.get("doctor") %></td>
                        <td><%= h.get("text") != null ? h.get("text") : "-" %></td>
                        <td><%= h.get("icds") != null ? h.get("icds") : "-" %></td>
                        <td><%= h.get("drugs") != null ? h.get("drugs") : "-" %></td>
                        <td>
                            <button onclick="openHistoryView(
                                '<%= h.get("history_id") %>',
                                '<%= h.get("date") %>',
                                '<%= h.get("doctor") %>',
                                `<%= h.get("text") != null ? h.get("text") : "-" %>`,
                                `<%= h.get("icds") != null ? h.get("icds") : "-" %>`,
                                `<%= h.get("drugs") != null ? h.get("drugs") : "-" %>`,
                                '<%= h.get("doctor_id") %>',
                                '<%= doctorId %>'
                            )">
                                ดูรายละเอียด
                            </button>
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

    <!-- ====== DIALOG เลือก ICD-10====== -->
    <div class="Dialog" id="icdPopup">
        <div class="modal-content">
            <span class="close" onclick="closeIcdPopup()">&times;</span>
            <h3>เลือกโรคประจำตัว (ICD-10)</h3>

            <div class="modalHeader">     
                <input type="text" id="icdSearch" placeholder="ค้นหารหัสหรือชื่อโรค..." oninput="filterIcdList()">           
            </div>
            <div id="icdListContainer" class="itemListContainer">
            <% for (Map<String,String> i : icds) { %>
                <div class="itemList" style="display:none;" onclick="selectIcd('<%=i.get("code")%> - <%=i.get("name")%>')">
                    <%=i.get("code")%> - <%=i.get("name")%>
                </div>
            <% } %>
            </div>
            <button onclick="addSelectedIcd()">เพิ่มโรคประจำตัว</button>
        </div>
    </div>
    <!-- ====== DIALOG เลือกยาที่แพ้ ====== -->
    <div class="Dialog" id="drugPopup">
        <div class="modal-content">
            <span class="close" onclick="closeDrugPopup()">&times;</span>
            <h3>เลือกยาที่แพ้</h3>
            
            <div class="modalHeader">                
                <input type="text" id="drugSearch" placeholder="ค้นหาชื่อยา..." oninput="filterDrugList()">
                <button onclick="filterDrugList()">ค้นหา</button>
            </div>
            <div id="drugListContainer" class="itemListContainer">
            <% for (Map<String,String> m : medicines) { %>
                <div class="itemList" style="display:none;" onclick="selectDrug('<%=m.get("name")%>')">
                    <%=m.get("name")%>
                </div>
            <% } %>
            </div>
            <input type="text" placeholder="กรุณาระบุอาการยาที่แพ้" id="drugAllergyInput">
            <button onclick="addDrugWithAllergy()">เพิ่มยาที่แพ้</button>
        </div>
    </div>
    <!-- ====== History Detail Modal ====== -->
    <div id="historyViewModal" class="detail-modal-overlay">
        <div class="detail-modal-box">
            <h3>รายละเอียดการซักประวัติ</h3>
            <div class="detail-modal-info-rows">
                <div class="detail-modal-info-row"><span class="dim-label">วันที่</span><span id="histModalDate"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">แพทย์</span><span id="histModalDoctor"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">รายละเอียด</span><span id="histModalText" style="white-space:pre-wrap;"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">โรคประจำตัว</span><span id="histModalIcds"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">ยาที่แพ้</span><span id="histModalDrugs"></span></div>
            </div>
            <div class="detail-modal-close-row">
                <button class="btn-edit-modal" id="editHistoryBtn">แก้ไข</button>
                <button class="btn-delete-modal" id="deleteHistoryBtn">ลบ</button>
                <button class="btn-close-modal" onclick="closeHistoryDialog()">ปิด</button>
            </div>
        </div>
    </div>

    <script src="../doctor_js/medExamination.js"></script>
    <script>
        var LATEST_HISTORY_ID = <%= histories.isEmpty() ? 0 : Integer.parseInt(histories.get(0).get("history_id")) %>;
    </script>
    <script src="../script.js"></script>
    <jsp:include page="../include/toast.jsp" />
    <%
    String loadHistoryId = request.getParameter("historyId");
    String showTable = request.getParameter("showTable");
    if (loadHistoryId != null && !loadHistoryId.trim().isEmpty()) {
    %>
    <script>document.addEventListener('DOMContentLoaded', function() { loadAndDisplayHistory(<%= loadHistoryId %>); });</script>
    <% } else if ("1".equals(showTable)) { %>
    <script>document.addEventListener('DOMContentLoaded', function() { showHistoryTable(); });</script>
    <% } else if (!histories.isEmpty()) { %>
    <script>document.addEventListener('DOMContentLoaded', function() { prefillTablesFromHistory(<%= histories.get(0).get("history_id") %>); });</script>
    <% } %>

    <%
	if (toastMessage != null) {
		session.removeAttribute("toastMessage");
		session.removeAttribute("toastType");
    %>
    <script>showToast("<%= toastMessage %>", "<%= toastType != null ? toastType : "info" %>");</script>
    <% } %>
</body>
</html>