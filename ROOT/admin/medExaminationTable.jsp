<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
    Integer doctorId  = (Integer) session.getAttribute("user_id");
    if (doctorId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    List<Map<String,String>> histories = new ArrayList<>();
    List<Map<String,String>> medicines = new ArrayList<>();
    List<Map<String,String>> icds = new ArrayList<>();

    try {
        String sqlHistory =
            "SELECT mh.history_id, mh.patient_id, DATE_FORMAT(mh.created_at, '%Y-%m-%d %H:%i:%s') AS created_at, " +
            "CONCAT(u.title, u.first_name, ' ', u.last_name) AS doctor_name, " +
            "CONCAT(p.title, p.first_name, ' ', p.last_name) AS patient_name, " +
            "mh.interview_text, " +
            "GROUP_CONCAT(DISTINCT CONCAT(i.icd_id, ' - ', i.icd_name) SEPARATOR ', ') AS icd_list, " +
            "GROUP_CONCAT(DISTINCT da.drug_name SEPARATOR ', ') AS drug_list " +
            "FROM medical_history mh " +
            "JOIN `user` u ON mh.doctor_id = u.user_id " +
            "JOIN patient p ON mh.patient_id = p.patient_id " +
            "LEFT JOIN medical_history_icd mhicd ON mh.history_id = mhicd.history_id " +
            "LEFT JOIN `icd-10` i ON mhicd.icd_code = i.icd_id " +
            "LEFT JOIN medical_history_drug_allergy da ON mh.history_id = da.history_id " +
            "GROUP BY mh.history_id " +
            "ORDER BY mh.history_id DESC";

        PreparedStatement stmt = con.prepareStatement(sqlHistory);
        ResultSet rs = stmt.executeQuery();

        while (rs.next()) {
            Map<String,String> row = new HashMap<>();
            int pid = rs.getInt("patient_id");
            row.put("history_id", rs.getString("history_id"));
            row.put("date", rs.getString("created_at"));
            row.put("patientCode", String.format("P%06d", pid));
            row.put("patient", rs.getString("patient_name"));
            row.put("doctor", rs.getString("doctor_name"));
            row.put("text", rs.getString("interview_text"));
            row.put("icds", rs.getString("icd_list"));
            row.put("drugs", rs.getString("drug_list"));

            histories.add(row);
        }
        rs.close();
        stmt.close();

        /* ---------- MEDICINE ---------- */
        String sqlMedicine = "SELECT med_id, med_name FROM medicine ORDER BY med_name";
        stmt = con.prepareStatement(sqlMedicine);
        rs = stmt.executeQuery();

        while (rs.next()) {
            Map<String,String> m = new HashMap<>();
            m.put("id", rs.getString("med_id"));
            m.put("name", rs.getString("med_name"));
            medicines.add(m);
        }
        rs.close();
        stmt.close();

        /* ---------- ICD-10 ---------- */
        String sqlIcd = "SELECT icd_id, icd_name FROM `icd-10` ORDER BY icd_id";
        stmt = con.prepareStatement(sqlIcd);
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
<link rel="stylesheet" href="../admin_css/medExamination.css">
<link rel="stylesheet" href="../layout.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>

<body>

<%
    request.setAttribute("activePage", "med");
    request.setAttribute("pageTitle", "ประวัติการซักประวัติคนไข้");
%>

<jsp:include page="../include/navbar.jsp" />
<jsp:include page="../include/header.jsp" />

<div class="content" id="medExaminationPage">

    <!-- ====== ตารางประวัติการซักประวัติ ====== -->
    <div class="section" id="historyTableSectionAdmin">
        <div class="section-header">
            <h2>รายการซักประวัติคนไข้</h2>
        </div>

		<div class="search-container">
			<div class="search-box"><input type="text" id="searchDate" placeholder="เลือกช่วงวันที่..."></div>
			<div class="search-box"><input type="text" id="searchPatientCode" placeholder="ค้นหารหัสคนไข้..."></div>
			<div class="search-box"><input type="text" id="searchPatient" placeholder="ค้นหาชื่อคนไข้..."></div>
			<div class="search-box"><input type="text" id="searchDoctor" placeholder="ค้นหาแพทย์..."></div>
			<div class="search-box"><input type="text" id="searchText" placeholder="ค้นหารายละเอียด..."></div>
			<div class="search-box"><input type="text" id="searchIcd" placeholder="ค้นหาโรค..."></div>
			<div class="search-box"><input type="text" id="searchDrug" placeholder="ค้นหายาที่แพ้..."></div>
			<div class="search-box">
				<button onclick="filterHistories()" style="width: 100%;">ค้นหา</button>
			</div>
		</div>

        <table class="historyTable" id="historyTable">
            <thead>
                <tr>
                    <th>วันที่ซักประวัติ</th>
					<th>รหัสคนไข้</th>
                    <th>ชื่อคนไข้</th>
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
                    <td colspan="8" style="text-align:center;color:#888;">
                        ไม่พบข้อมูลการซักประวัติ
                    </td>
                </tr>
            <%
                } else {
                    for (Map<String,String> h : histories) {
            %>
                <tr data-history-id="<%= h.get("history_id") %>">
                    <td><%= h.get("date") %></td>
                    <td><%= h.get("patientCode") %></td>
                    <td><%= h.get("patient") %></td>
                    <td><%= h.get("doctor") %></td>
                    <td><%= h.get("text") != null ? h.get("text") : "-" %></td>
                    <td><%= h.get("icds") != null ? h.get("icds") : "-" %></td>
                    <td><%= h.get("drugs") != null ? h.get("drugs") : "-" %></td>
                    <td>
                        <button onclick="openHistoryView(
                            '<%= h.get("date") %>',
                            '<%= h.get("doctor") %>',
                            '<%= h.get("patientCode") %>',
                            '<%= h.get("patient") %>',
                            `<%= h.get("text") != null ? h.get("text") : "-" %>`,
                            `<%= h.get("icds") != null ? h.get("icds") : "-" %>`,
                            `<%= h.get("drugs") != null ? h.get("drugs") : "-" %>`
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
    <!-- ====== DIALOG เลือก ICD-10 และยาที่แพ้ ====== -->
    <div class="Dialog" id="icdPopup">
        <div class="modal-content">
            <span class="close" onclick="closeIcdPopup()">&times;</span>
            <h3>เลือกโรคประจำตัว (ICD-10)</h3>

            <input type="text" id="icdSearch" placeholder="ค้นหารหัสหรือชื่อโรค..."
                onkeyup="filterIcdList()">
            <% for (Map<String,String> i : icds) { %>
                <div class="itemList" onclick="selectIcd('<%=i.get("code")%>','<%=i.get("name")%>')">
                    <%=i.get("code")%> - <%=i.get("name")%>
                </div>
            <% } %>
        </div>
    </div>
    <div class="Dialog" id="drugPopup">
        <div class="modal-content">
            <span class="close" onclick="closeDrugPopup()">&times;</span>
            <h3>เลือกยาที่แพ้</h3>

            <input type="text" id="drugSearch" placeholder="ค้นหาชื่อยา..."
                onkeyup="filterDrugList()">
            <% for (Map<String,String> m : medicines) { %>
                <div class="itemList" onclick="selectDrug('<%=m.get("name")%>')">
                    <%=m.get("name")%>
                </div>
            <% } %>
        </div>
    </div>

</div>


<!-- ====== DIALOG ดูซักประวัติ ====== -->
<div id="historyViewDialog" class="Dialog">
    <div class="modal-content">
        <span class="close" onclick="closeHistoryView()">&times;</span>
        <h2>รายละเอียดการซักประวัติ</h2>
        
        <div class="info-block">
            <p><b>วันเวลา:</b> <span id="date"></span></p>
            <p><b>แพทย์:</b> <span id="doctor"></span></p>
        </div>

        <hr>

        <div class="info-block">
            <p><b>รหัสคนไข้:</b> <span id="patientCode"></span></p>
            <p><b>ชื่อคนไข้:</b> <span id="patient"></span></p>
        </div>

        <hr>

        <div>
            <input type="hidden" id="historyId">
            <div>
                <p><b>ยาที่แพ้:</b> <span id="drug_allergy"></span></p>
                <p><b>โรคประจำตัว:</b> <span id="icd10"></span></p>
                <b>รายละเอียด</b>
                <textarea id="text"
                        class="text-box"
                        rows="8"
                        readonly></textarea>
            </div>
        </div>

        <div style="text-align:right; margin-top:15px;">
            <button id="editBtn" onclick="enableEdit()">แก้ไข</button>
            <button id="saveBtn" onclick="saveHistory()" style="display:none;">บันทึก</button>
            <button onclick="closeHistoryView()">ยกเลิก</button>
        </div>
    </div>
</div>

<script>
const historiesData = [
    <% for (Map<String,String> h : histories) { %>
    {
        history_id:  "<%= h.get("history_id") %>",
        date:        "<%= h.get("date") %>",
        patientCode: "<%= h.get("patientCode") %>",
        patient:     "<%= h.get("patient") %>",
        doctor:      "<%= h.get("doctor") %>",
        text:        `<%= h.get("text")  != null ? h.get("text")  : "" %>`,
        icds:        `<%= h.get("icds")  != null ? h.get("icds")  : "" %>`,
        drugs:       `<%= h.get("drugs") != null ? h.get("drugs") : "" %>`
    },
    <% } %>
];
</script>
<script src="../admin_js/medExamination.js"></script>
<script src="../script.js"></script>
<jsp:include page="../include/toast.jsp" />
</body>
</html>