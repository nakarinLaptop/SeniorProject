<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.time.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%!
    // 
    private String jsonEscape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }

    private String[] splitListValue(String raw) {
        if (raw == null) return new String[0];
        String value = raw.trim();
        if (value.startsWith("[") && value.endsWith("]") && value.length() >= 2) {
            value = value.substring(1, value.length() - 1).trim();
        }
        if (value.isEmpty()) return new String[0];

        if (value.contains("\"") || value.contains("'")) {
            List<String> parts = new ArrayList<>();
            StringBuilder current = new StringBuilder();
            char quote = 0;
            boolean escaped = false;

            for (int i = 0; i < value.length(); i++) {
                char ch = value.charAt(i);

                if (escaped) {
                    current.append(ch);
                    escaped = false;
                    continue;
                }

                if (ch == '\\') {
                    if (quote != 0) {
                        escaped = true;
                    } else {
                        current.append(ch);
                    }
                    continue;
                }

                if (quote != 0) {
                    if (ch == quote) {
                        quote = 0;
                    } else {
                        current.append(ch);
                    }
                    continue;
                }

                if (ch == '\'' || ch == '\"') {
                    quote = ch;
                    continue;
                }

                if (ch == ',') {
                    String token = current.toString().trim();
                    if (!token.isEmpty()) parts.add(token);
                    current.setLength(0);
                    continue;
                }

                current.append(ch);
            }

            String token = current.toString().trim();
            if (!token.isEmpty()) parts.add(token);
            return parts.toArray(new String[0]);
        }

        return value.split("\\s*,\\s*");
    }

    private String toJsonArray(String raw) {
        String[] items = splitListValue(raw);
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < items.length; i++) {
            if (i > 0) json.append(',');
            json.append('"').append(jsonEscape(items[i])).append('"');
        }
        json.append(']');
        return json.toString();
    }
%>
<%
    Integer doctorId  = (Integer) session.getAttribute("user_id");
    Integer patientId = (Integer) session.getAttribute("patient_id");

    if (doctorId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }
    // reason in predict dialog
    String action = request.getParameter("action");
    if ("prediction_detail".equals(action)) {
        response.setContentType("application/json; charset=UTF-8");

        PreparedStatement detailStmt = null;
        ResultSet detailRs = null;

        try {
            String idParam = request.getParameter("id");
            if (patientId == null || idParam == null || idParam.trim().isEmpty()) {
                out.print("{\"main_list\":[],\"main_detail\":[],\"main_reason\":[],\"main_per\":[],\"sec_list\":[],\"sec_detail\":[],\"sec_reason\":[],\"sec_per\":[]}");
                return;
            }

            int predictionId = Integer.parseInt(idParam);
            String sqlDetail =
                "SELECT predict_result, main_list, main_detail, main_reason, main_per, " +
                "sec_list, sec_detail, sec_reason, sec_per " +
                "FROM prediction WHERE id = ? AND patient_id = ? LIMIT 1";

            detailStmt = con.prepareStatement(sqlDetail);
            detailStmt.setInt(1, predictionId);
            detailStmt.setInt(2, patientId);
            detailRs = detailStmt.executeQuery();

            if (detailRs.next()) {
                StringBuilder json = new StringBuilder("{");
                json.append("\"predict_result\":\"").append(jsonEscape(detailRs.getString("predict_result"))).append("\",");
                json.append("\"main_list\":").append(toJsonArray(detailRs.getString("main_list"))).append(',');
                json.append("\"main_detail\":").append(toJsonArray(detailRs.getString("main_detail"))).append(',');
                json.append("\"main_reason\":").append(toJsonArray(detailRs.getString("main_reason"))).append(',');
                json.append("\"main_per\":").append(toJsonArray(detailRs.getString("main_per"))).append(',');
                json.append("\"sec_list\":").append(toJsonArray(detailRs.getString("sec_list"))).append(',');
                json.append("\"sec_detail\":").append(toJsonArray(detailRs.getString("sec_detail"))).append(',');
                json.append("\"sec_reason\":").append(toJsonArray(detailRs.getString("sec_reason"))).append(',');
                json.append("\"sec_per\":").append(toJsonArray(detailRs.getString("sec_per")));
                json.append('}');
                out.print(json.toString());
            } else {
                out.print("{\"main_list\":[],\"main_detail\":[],\"main_reason\":[],\"main_per\":[],\"sec_list\":[],\"sec_detail\":[],\"sec_reason\":[],\"sec_per\":[]}");
            }
        } catch (Exception e) {
            out.print("{\"error\":\"");
            out.print(jsonEscape(e.getMessage()));
            out.print("\",\"main_list\":[],\"main_detail\":[],\"main_reason\":[],\"main_per\":[],\"sec_list\":[],\"sec_detail\":[],\"sec_reason\":[],\"sec_per\":[]}");
        } 
        return;
    }

    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    String patientCode = "";
    String patientName = "";
    String patientTitle = "";
    String patientGender = "";
    String patientPhone = "";
    String patientBirthDate = "";
    String patientProvince = "";
    String patientDistrict = "";
    String patientSubDistrict = "";
    String patientOccupation = "";
    String patientMarriageStatus = "";
    String patientRights = "";
    List<Map<String,String>> patientRightsList = new ArrayList<>();
    // Load patient data
    if (patientId != null) {
        try {
            patientCode = String.format("P%06d", patientId);
            String sqlPatient = "SELECT *,DATE_FORMAT(birth_date, '%d-%m-%Y') AS birth_date FROM patient WHERE patient_id = ?";
            stmt = con.prepareStatement(sqlPatient);
            stmt.setInt(1, patientId);
            rs = stmt.executeQuery();
            if (rs.next()) {
                patientTitle = rs.getString("title");
                patientName = rs.getString("first_name") + " " + rs.getString("last_name");
                patientGender = rs.getString("gender");
                patientPhone = rs.getString("phone_num");

                java.time.LocalDate birthDate = rs.getDate("birth_date").toLocalDate();
                int age = java.time.Period.between(birthDate, java.time.LocalDate.now()).getYears();
                patientBirthDate = String.valueOf(age);

                patientProvince = rs.getString("province");
                patientDistrict = rs.getString("district");
                patientSubDistrict = rs.getString("sub_district");
                patientOccupation = rs.getString("occupation");
                patientMarriageStatus = rs.getString("marriage_status");
                patientRights = rs.getString("right_name");
            }
            rs.close();
            stmt.close();


        } catch (Exception e) {
            out.println("<div style='color:red'><b>Error loading patient data or rights: " + e.getMessage() + "</b></div>");
            if (rs != null) try { rs.close(); } catch (Exception ex) {}
            if (stmt != null) try { stmt.close(); } catch (Exception ex) {}
        }
    } else {
        out.println("Invalid or missing patient ID");
    }

    List<Map<String,String>> medExaminations = new ArrayList<>();
    List<Map<String,String>> histories = new ArrayList<>();
    List<Map<String,String>> medicines = new ArrayList<>();
    List<Map<String,String>> icds = new ArrayList<>();

    List<Map<String,String>> prescriptions = new ArrayList<>();
    List<Map<String,String>> predictions = new ArrayList<>();

    // sql 3 tables: medical_history, prescription, prediction
    try {
        /* ---------- Medical Examination ---------- */
        String sqlHistory =
            "SELECT mh.history_id, mh.doctor_id, " +
            "DATE_FORMAT(mh.created_at, '%Y-%m-%d %H:%i:%s') AS created_at, " +
            "p.patient_id, " +
            "CONCAT(u.title, u.first_name, ' ', u.last_name) AS doctor_name, " +
            "CONCAT(p.title, p.first_name, ' ', p.last_name) AS patient_name, " +
            "mh.interview_text, " +

            "GROUP_CONCAT(DISTINCT CONCAT(i.icd_id, ' - ', i.icd_name) SEPARATOR ', ') AS icd_list, " +

            "GROUP_CONCAT(DISTINCT da.drug_name SEPARATOR ', ') AS drug_list, " +
            "GROUP_CONCAT(DISTINCT da.detail SEPARATOR ', ') AS drug_detail_list " +

            "FROM medical_history mh " +
            "JOIN `user` u ON mh.doctor_id = u.user_id " +
            "JOIN patient p ON mh.patient_id = p.patient_id " +

            "LEFT JOIN medical_history_icd mhicd ON mh.history_id = mhicd.history_id " +
            "LEFT JOIN `icd-10` i ON mhicd.icd_code = i.icd_id " +

            "LEFT JOIN medical_history_drug_allergy da ON mh.history_id = da.history_id " +

            "WHERE mh.patient_id = ? " +
            "GROUP BY mh.history_id " +
            "ORDER BY mh.history_id DESC";


        stmt = con.prepareStatement(sqlHistory);
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();

        while (rs.next()) {
            Map<String,String> row = new HashMap<>();
            int pid = rs.getInt("patient_id");

            row.put("history_id", rs.getString("history_id"));
            row.put("doctor_id", rs.getString("doctor_id"));
            row.put("date", rs.getString("created_at"));
            
            row.put("patientCode", String.format("P%06d", pid));
            row.put("patient", rs.getString("patient_name"));
            row.put("doctor", rs.getString("doctor_name"));
            row.put("text", rs.getString("interview_text"));
            row.put("icds", rs.getString("icd_list"));
            row.put("drugs", rs.getString("drug_list"));
            row.put("drug_details", rs.getString("drug_detail_list"));

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


		/* ---------- PREDICTION ---------- */
		String sqlPrediction =
			"SELECT pred.id, " +
			"CONCAT(d.title, d.first_name, ' ', d.last_name) AS doctor_name, " +
			"pred.predict_result, pred.doctor_selected, pred.confident, pred.lab_list, " +
			"DATE_FORMAT(pred.created_at, '%Y-%m-%d %H:%i:%s') AS created_at " +
			"FROM prediction pred " +
			"JOIN `user` d ON pred.doctor_id = d.user_id " +
			"WHERE pred.patient_id = ? " +
			"ORDER BY pred.id DESC";

		stmt = con.prepareStatement(sqlPrediction);
		stmt.setInt(1, patientId);
		rs = stmt.executeQuery();

		while (rs.next()) {
			Map<String,String> row = new HashMap<>();
			row.put("id",             rs.getString("id"));
			row.put("date",           rs.getString("created_at"));
			row.put("doctor",         rs.getString("doctor_name"));
			row.put("predict_result", rs.getString("predict_result"));
			row.put("doctor_selected",rs.getString("doctor_selected"));
			row.put("confident",      rs.getString("confident"));
			row.put("lab_list",       rs.getString("lab_list"));
			predictions.add(row);
		}
		rs.close();
		stmt.close();

        /* ---------- prescription ---------- */
		String sqlPrescription = "SELECT pr.prescription_id, pr.doctor_id, " +
					"DATE_FORMAT(pr.prescription_datetime, '%Y-%m-%d %H:%i:%s') AS prescription_datetime, " +
					"pr.medicine_count, " +
					"CONCAT(d.title, d.first_name, ' ', d.last_name) AS doctor_name, " +
					"COALESCE(pr.health_right_name, 'ชำระเงินเอง') AS healthcare_right " +
					"FROM prescription pr " +
					"JOIN `user` d ON pr.doctor_id = d.user_id " +
					"WHERE pr.patient_id = ? " +
					"ORDER BY pr.prescription_id DESC";

		stmt = con.prepareStatement(sqlPrescription);
		stmt.setInt(1, patientId);
		rs = stmt.executeQuery();

		while (rs.next()) {
			Map<String,String> row = new HashMap<>();
			row.put("prescription_id", String.valueOf(rs.getInt("prescription_id")));
			row.put("date", rs.getString("prescription_datetime"));
			row.put("doctor", rs.getString("doctor_name"));
			row.put("medicine_count", rs.getString("medicine_count"));
			row.put("healthcare_right", rs.getString("healthcare_right"));
			prescriptions.add(row);
		}
		rs.close();
		stmt.close();

    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch(Exception ignored){}
        if (stmt != null) try { stmt.close(); } catch(Exception ignored){}
        if (con != null) try { con.close(); } catch(Exception ignored){}
    }

 
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../layout.css">
<link rel="stylesheet" href="../doctor_css/patientData.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
</head>

<body>

    <%
        request.setAttribute("activePage", "patientData");
        request.setAttribute("pageTitle", "ประวัติคนไข้");
    %>

    <jsp:include page="../include/navbar.jsp" />
    <jsp:include page="../include/header.jsp" />

    <div class="content" id="patientDataPage">
        <h2>ประวัติคนไข้</h2>

        <div class="patient-info">
            <p>
                ชื่อ : <%= patientTitle %> <%= patientName %><br>
                เพศ : <%= patientGender %><br>
                อายุ : <%= patientBirthDate %> ปี<br>
                เบอร์โทร: <%= patientPhone %><br>
                สถานะการสมรส : <%= patientMarriageStatus %><br>
                อาชีพ: <%= patientOccupation %><br>
                ที่อยู่: <%= patientSubDistrict %> <%= patientDistrict %> <%= patientProvince %><br>
                สิทธิการรักษา: <%= (patientRights == null || patientRights.trim().isEmpty()) ? "-" : patientRights %>
            </p>
        </div>

        <!-- ====== ตารางการซักประวัติ ====== -->
        <div class="table-section">
            <h2>รายการซักประวัติคนไข้</h2>
            <div class="search-container">
                <div class="search-box"><input type="text" id="searchDate" placeholder="ค้นหาวันที่..."></div>
                <div class="search-box"><input type="text" id="searchDoctor" placeholder="ค้นหาแพทย์..."></div>
                <div class="search-box"><input type="text" id="searchText" placeholder="ค้นหารายละเอียด..."></div>
                <div class="search-box"><input type="text" id="searchIcd" placeholder="ค้นหาโรค..."></div>
                <div class="search-box"><input type="text" id="searchDrug" placeholder="ค้นหายา..."></div>
                <div class="search-box">
                    <button class="btn-search" onclick="filterHistoryTable()">ค้นหา</button>
                </div>
            </div>

            <div class="summaryTableContainer">
                <table class="summaryTable" id="historyTable">
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
                        <% if (histories.isEmpty()) { %>
                            <tr>
                                <td colspan="6" style="text-align: center; color: #888;">
                                    ไม่พบข้อมูลการซักประวัติ
                                </td>
                            </tr>
                        <% } else {
                            for (Map<String, String> h : histories) { %>
                            <tr data-history-id="<%= h.get("history_id") %>">
                                <td><%= h.get("date") %></td>
                                <td><%= h.get("doctor") %></td>
                                <td class="text-truncate"><%= h.get("text") != null ? h.get("text") : "-" %></td>
                                <td><%= h.get("icds") != null ? h.get("icds") : "-" %></td>
                                <td><%= h.get("drugs") != null ? h.get("drugs") : "-" %></td>
                                <td>
                                    <button class="btn-view" onclick="openHistoryView(this)">
                                        ดูรายละเอียด
                                    </button>
                                </td>
                            </tr>
                            <% }
                        } %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ====== ตารางการทำนาย ====== -->
        <div class="table-section">
            <h2>รายการการทำนายสถานที่ตรวจสุขภาพ</h2>
            <div class="search-container">
                <div class="search-box"><input type="text" id="searchPredictDate" placeholder="ค้นหาวันที่..."></div>
                <div class="search-box"><input type="text" id="searchPredictDoctor" placeholder="ค้นหาแพทย์..."></div>
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
                <div class="search-box search-box-stacked">
                    <input type="number" id="searchConfidentMin" min="0" max="100" step="0.1" placeholder="ความมั่นใจ % ต่ำสุด">
                    <input type="number" id="searchConfidentMax" min="0" max="100" step="0.1" placeholder="ความมั่นใจ % สูงสุด">
                </div>
                <div class="search-box">
                    <button class="btn-search" onclick="filterPredictionTable()">ค้นหา</button>
                </div>
            </div>

            <div class="summaryTableContainer">
                <table class="summaryTable" id="predictionTable">
                    <thead>
                        <tr>
                            <th>วันที่ทำนาย</th>
                            <th>แพทย์</th>
                            <th>ผลทำนาย</th>
                            <th>แพทย์เลือก</th>
                            <th>ความมั่นใจ (%)</th>
                            <th>ดูรายละเอียด</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        if (predictions.isEmpty()) {
                    %>
                        <tr>
                            <td colspan="6" style="text-align:center;color:#888;">ไม่พบข้อมูลการทำนาย</td>
                        </tr>
                    <%
                        } else {
                            for (Map<String, String> pred : predictions) {
                    %>
                        <tr data-pred-id="<%= pred.get("id") %>"
                            data-pred-date="<%= pred.get("date") %>"
                            data-pred-doctor="<%= pred.get("doctor") %>"
                            data-pred-result="<%= pred.get("predict_result") != null ? pred.get("predict_result") : "-" %>"
                            data-pred-selected="<%= pred.get("doctor_selected") != null ? pred.get("doctor_selected") : "-" %>"
                            data-pred-confident="<%= pred.get("confident") != null ? pred.get("confident") : "-" %>"
                            data-pred-lab-list="<%= pred.get("lab_list") != null ? pred.get("lab_list") : "" %>">
                            <td><%= pred.get("date") %></td>
                            <td><%= pred.get("doctor") %></td>
                            <td><%= pred.get("predict_result") != null ? pred.get("predict_result") : "-" %></td>
                            <td><%= pred.get("doctor_selected") != null ? pred.get("doctor_selected") : "-" %></td>
                            <td><%= pred.get("confident") != null ? pred.get("confident") : "-" %></td>
                            <td><button class="btn-view" onclick="openPredictionView(this)">ดูรายละเอียด</button></td>
                        </tr>
                    <%
                            }
                        }
                    %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ====== ตารางการสั่งยา ====== -->
        <div class="table-section">
            <h2>รายการใบสั่งยา</h2>
            <div class="search-container">
                <div class="search-box"><input type="text" id="searchPrescDate" placeholder="ค้นหาวันที่..."></div>
                <div class="search-box"><input type="text" id="searchPrescDoctor" placeholder="ค้นหาแพทย์..."></div>
                <div class="search-box"><input type="text" id="searchHealthRight" placeholder="ค้นหาสิทธิ..."></div>
                <div class="search-box"><input type="text" id="searchMedicineCount" placeholder="ค้นหาจำนวน..."></div>
                <div class="search-box">
                    <button class="btn-search" onclick="filterPrescriptionTable()">ค้นหา</button>
                </div>
            </div>

            <div class="summaryTableContainer">
                <table class="summaryTable" id="prescriptionTable">
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
                            for (Map<String, String> p : prescriptions) { 
                        %>
                        <tr data-prescription-id="<%= p.get("prescription_id") %>" 
                            data-datetime="<%= p.get("date") %>"
                            data-doctor-name="<%= p.get("doctor") %>"
                            data-healthcare-right="<%= p.get("healthcare_right") %>">
                            <td><%= p.get("date") %></td>
                            <td><%= p.get("doctor") %></td>
                            <td><%= p.get("healthcare_right") %></td>
                            <td><%= p.get("medicine_count") %></td>
                            <td>
                                <button class="btn-view" onclick="viewPrescriptionDetail(this)">ดูรายละเอียด</button>
                            </td>
                        </tr>
                        <%  
                            }     
                        }
                        %>
                    </tbody>
                </table>
            </div>
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
                <button class="btn-close-modal" onclick="closeHistoryView()">ปิด</button>
            </div>
        </div>
    </div>

    <!-- ====== Prediction Detail Modal ====== -->
    <div id="predictionViewModal" class="detail-modal-overlay">
        <div class="detail-modal-box">
            <h3>รายละเอียดการทำนาย</h3>
            <div class="detail-modal-info-rows">
                <div class="detail-modal-info-row"><span class="dim-label">วันที่ทำนาย</span><span id="predModalDate"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">แพทย์</span><span id="predModalDoctor"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">ผลทำนาย</span><span id="predModalResult"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">แพทย์เลือก</span><span id="predModalSelected"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">ความมั่นใจ (%)</span><span id="predModalConfident"></span></div>
                <div class="detail-modal-info-row"><span class="dim-label">แล็บที่เลือก</span><span id="predModalLabList" style="overflow-wrap: break-word;"></span></div>
            </div>
            
            <div id="predModalContent">
                <table class="result-table" style="text-align: center; width: 100%;">
                    <thead>
                        <tr>
                            <th style="background-color: green;">รายการ</th>
                            <th style="background-color: green;">ผลการประเมิน</th>
                            <th style="background-color: green;">เหตุผลรองรับ</th>
                        </tr>
                    </thead>
                    <tbody id="main_list">
                                    
                    </tbody>
                </table>
            
                                
                <div id="sec_title" style="text-align: left; margin-left: 5%; margin-top: 10px;">ปัจจัยที่ควรพริจารณาเพิ่ม</div>
            
                <table class="result-table" style="text-align: center; width: 100%;">
                    <thead>
                        <tr style="height: 40px;">
                            <th style="background-color: green;">รายการ</th>
                            <th style="background-color: green;">ผลการประเมิน</th>
                            <th style="background-color: green;">เหตุผลรองรับ</th>
                        </tr>
                    </thead>
                    <tbody id="sec_list">
                                    
                    </tbody>
                </table>
            </div>

            <div class="detail-modal-close-row">
                <button class="btn-close-modal" onclick="closePredictionView()">ปิด</button>
            </div>
        </div>
    </div>

    <!-- ====== Prescription Detail Modal ====== -->
    <div id="prescriptionDetailModal" class="detail-modal-overlay">
        <div class="detail-modal-box">
            <h3>รายละเอียดใบสั่งยา</h3>
            <div id="prescModalContent">กำลังโหลด...</div>
            <div class="detail-modal-close-row">
                <button class="btn-close-modal" onclick="closePrescriptionDetailModal()">ปิด</button>
            </div>
        </div>
    </div>

    <script src="../doctor_js/patientData.js"></script>
    <script src="../script.js"></script>
    <jsp:include page="../include/toast.jsp" />
    
    <%
        String toastMessage = (String) session.getAttribute("toastMessage");
        String toastType = (String) session.getAttribute("toastType");
        if (toastMessage != null && toastType != null) {
            session.removeAttribute("toastMessage");
            session.removeAttribute("toastType");
    %>
    <script>
        showToast("<%= toastMessage %>", "<%= toastType %>");
    </script>
    <% } %>
</body>
</html>