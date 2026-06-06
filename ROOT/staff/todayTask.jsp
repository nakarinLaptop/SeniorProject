<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.io.File, java.time.*" %>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%!
    // ฟังก์ชันช่วยในการแปลงค่าเป็น JSON string
    private String jsonStr(String val) {
        if (val == null) return "null";
        return "\"" + val.replace("\\", "\\\\")
                         .replace("\"", "\\\"")
                         .replace("\n", "\\n")
                         .replace("\r", "\\r") + "\"";
    }

    // ฟังก์ชันช่วยสำหรับ HTML attribute value escape
    private String attrEscape(Object val) {
        if (val == null) return "";
        return String.valueOf(val)
            .replace("&", "&amp;")
            .replace("\"", "&quot;")
            .replace("<", "&lt;")
            .replace(">", "&gt;");
    }
%>
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

    if ("saveAppointmentStatus".equals(request.getParameter("action"))) {
        request.setCharacterEncoding("UTF-8");

        String[] predictionIds = request.getParameterValues("predictionId");
        String[] appointmentStatuses = request.getParameterValues("appointmentStatus");
        String[] appointmentDatetimes = request.getParameterValues("appointmentDatetime");
        String[] appointmentNotes = request.getParameterValues("appointmentNote");

        boolean dataMissing = (predictionIds == null || appointmentStatuses == null || appointmentDatetimes == null);
        boolean lengthMismatch = (!dataMissing &&
            (predictionIds.length != appointmentStatuses.length || predictionIds.length != appointmentDatetimes.length));

        if (dataMissing || lengthMismatch) {
            session.setAttribute("toastMessage", "ข้อมูลไม่ครบ กรุณาลองใหม่");
            session.setAttribute("toastType", "error");
            response.sendRedirect("todayTask.jsp");
            return;
        }

        LocalDate today = LocalDate.now();
        for (int j = 0; j < appointmentStatuses.length; j++) {
            if ("completed".equals(appointmentStatuses[j])) {
                String datetimeStr = appointmentDatetimes[j];
                if (datetimeStr == null || datetimeStr.isEmpty()) {
                    session.setAttribute("toastMessage", "กรุณาเลือกวันที่นัดตรวจ");
                    session.setAttribute("toastType", "error");
                    response.sendRedirect("todayTask.jsp");
                    return;
                }
                try {
                    LocalDate appointDate = LocalDate.parse(datetimeStr.substring(0, 10));
                    if (appointDate.isBefore(today)) {
                        session.setAttribute("toastMessage", "ไม่สามารถนัดวันที่ผ่านมาแล้วได้");
                        session.setAttribute("toastType", "error");
                        response.sendRedirect("todayTask.jsp");
                        return;
                    }
                } catch (Exception ignored) {}
            }
        }

        // ตรวจสอบโควต้านัดตรวจเคสที่ "completed"
        Map<String, Integer> newCompletedByDate = new HashMap<>();
        int newCompletedCount = 0;
        for (int j = 0; j < appointmentStatuses.length; j++) {
            if ("completed".equals(appointmentStatuses[j])) {
                String idValue = predictionIds[j];
                String datetimeStr = appointmentDatetimes[j];
                if (idValue != null && !idValue.isEmpty() && datetimeStr != null && !datetimeStr.trim().isEmpty()) {
                    String datePart = datetimeStr.trim().length() >= 10 ? datetimeStr.trim().substring(0, 10) : datetimeStr.trim();
                    newCompletedByDate.put(datePart, newCompletedByDate.getOrDefault(datePart, 0) + 1);
                    newCompletedCount++;
                }
            }
        }
        // ถ้ามีเคสที่เปลี่ยนเป็น "completed" ให้ตรวจสอบโควต้า
        if (newCompletedCount > 0) {
            int quotaAmount = -1;
            PreparedStatement quotaStmt = null;
            ResultSet quotaRs = null;
            try {
                String quotaSql = "SELECT amount FROM quota ORDER BY idquota ASC LIMIT 1";
                quotaStmt = con.prepareStatement(quotaSql);
                quotaRs = quotaStmt.executeQuery();
                if (quotaRs.next()) {
                    quotaAmount = quotaRs.getInt("amount");
                }

                // check each date if it exceed quota
                if (quotaAmount >= 0) {
                    for (Map.Entry<String, Integer> entry : newCompletedByDate.entrySet()) {
                        String dateKey = entry.getKey();
                        int newCountForDate = entry.getValue();

                        String completedCountSql = "SELECT COUNT(*) AS cnt FROM prediction " +
                                                   "WHERE appointment_status = 'completed' " +
                                                   "AND DATE(staff_appointment_date) = ?";
                        PreparedStatement countStmt = null;
                        ResultSet countRs = null;
                        int existingCount = 0;
                        try {
                            countStmt = con.prepareStatement(completedCountSql);
                            countStmt.setDate(1, java.sql.Date.valueOf(LocalDate.parse(dateKey)));
                            countRs = countStmt.executeQuery();
                            if (countRs.next()) {
                                existingCount = countRs.getInt("cnt");
                            }
                        } finally {
                            if (countRs != null) try { countRs.close(); } catch (Exception ignored) {}
                            if (countStmt != null) try { countStmt.close(); } catch (Exception ignored) {}
                        }

                        if ((existingCount + newCountForDate) > quotaAmount) {
                            session.setAttribute("toastMessage", "เกินโควต้าสำหรับวันที่ " + dateKey + " (โควต้า " + quotaAmount + ")");
                            session.setAttribute("toastType", "error");
                            response.sendRedirect("todayTask.jsp");
                            return;
                        }
                    }
                }
            } catch (Exception e) {
                session.setAttribute("toastMessage", "บันทึกไม่สำเร็จ: " + e.getMessage());
                session.setAttribute("toastType", "error");
                response.sendRedirect("todayTask.jsp");
                return;
            } finally {
                if (quotaRs != null) try { quotaRs.close(); } catch (Exception ignored) {}
                if (quotaStmt != null) try { quotaStmt.close(); } catch (Exception ignored) {}
            }
        }

        // ตรวจสอบวันที่นัดตรวจไม่ให้เลยวันนัดจริง
        for (int j = 0; j < appointmentStatuses.length; j++) {
            if ("completed".equals(appointmentStatuses[j])) {
                String idValue       = predictionIds[j];
                String datetimeValue = appointmentDatetimes[j];
                if (idValue == null || idValue.isEmpty() || datetimeValue == null || datetimeValue.trim().isEmpty()) continue;
                PreparedStatement apptStmt = null;
                ResultSet apptRs = null;
                try {
                    String trimmed  = datetimeValue.trim();
                    String datePart = trimmed.length() >= 10 ? trimmed.substring(0, 10) : trimmed;
                    LocalDate staffDate = LocalDate.parse(datePart);

                    apptStmt = con.prepareStatement(
                        "SELECT appointment_date FROM prediction WHERE id = ?");
                    apptStmt.setInt(1, Integer.parseInt(idValue));
                    apptRs = apptStmt.executeQuery();
                    if (apptRs.next()) {
                        java.sql.Date apptDate = apptRs.getDate("appointment_date");
                        if (apptDate != null && !staffDate.isBefore(apptDate.toLocalDate())) {
                            session.setAttribute("toastMessage", "เลยวันนัด: วันที่ตรวจต้องก่อนวันที่ต้องส่งตรวจ (" + apptDate + ")");
                            session.setAttribute("toastType", "error");
                            response.sendRedirect("todayTask.jsp");
                            return;
                        }
                    }
                } catch (Exception e) {
                    session.setAttribute("toastMessage", "ตรวจสอบวันที่ไม่สำเร็จ: " + e.getMessage());
                    session.setAttribute("toastType", "error");
                    response.sendRedirect("todayTask.jsp");
                    return;
                } finally {
                    if (apptRs != null) try { apptRs.close(); } catch (Exception ignored) {}
                    if (apptStmt != null) try { apptStmt.close(); } catch (Exception ignored) {}
                }
            }
        }

        int successCount = 0;
        try {
            con.setAutoCommit(false);

            String updateSql = "UPDATE prediction SET appointment_status = ?, staff_appointment_date = ?, staff_appointment_note = ? WHERE id = ?";
            PreparedStatement updateStmt = con.prepareStatement(updateSql);

            for (int i = 0; i < predictionIds.length; i++) {
                String idValue = predictionIds[i];
                String statusValue = appointmentStatuses[i];
                String datetimeValue = appointmentDatetimes[i];
                String noteValue = (appointmentNotes != null && i < appointmentNotes.length) ? appointmentNotes[i] : "";

                if (idValue == null || idValue.isEmpty() || statusValue == null || statusValue.isEmpty()) {
                    continue;
                }

                updateStmt.setString(1, statusValue);
                if ("completed".equals(statusValue) && datetimeValue != null && !datetimeValue.isEmpty()) {
                    String trimmed = datetimeValue.trim();

                    String normalized = trimmed.replace("T", " ");
                    if (trimmed.length() == 10) {
                        normalized = trimmed + " 12:00:00";
                    } else if (normalized.length() == 16) {
                        normalized += ":00";
                    }
                    updateStmt.setTimestamp(2, Timestamp.valueOf(normalized));
                } else {
                    updateStmt.setNull(2, Types.TIMESTAMP);
                }
                updateStmt.setString(3, noteValue != null ? noteValue : "");
                updateStmt.setInt(4, Integer.parseInt(idValue));

                int rowsAffected = updateStmt.executeUpdate();
                if (rowsAffected > 0) {
                    successCount++;
                }
            }

            updateStmt.close();
            con.commit();
            session.setAttribute("toastMessage", "บันทึก " + successCount + " เคส สำเร็จ");
            session.setAttribute("toastType", "success");
        } catch (Exception e) {
            try {
                con.rollback();
            } catch (Exception ignored) {
            }

            session.setAttribute("toastMessage", "เกิดข้อผิดพลาด: " + e.getMessage());
            session.setAttribute("toastType", "error");
        }

        response.sendRedirect("todayTask.jsp");
        return;
    }

    List<Map<String, Object>> predictions = new ArrayList<>();
    List<Map<String, Object>> homePredictions = new ArrayList<>();
    List<Map<String, Object>> hospitalPredictions = new ArrayList<>();
    List<Map<String, Object>> patientInfo = new ArrayList<>();

    int totalCases = 0;
    int homeCases = 0;
    String errorMessage = "";


    Map<LocalDate, Integer> dayCountMap = new HashMap<>();
    LocalDate calToday = LocalDate.now();
    YearMonth calCurrentMonth = YearMonth.from(calToday);
    String calMonthParam = request.getParameter("month");
    try {
        if (calMonthParam != null && !calMonthParam.trim().isEmpty()) {
            calCurrentMonth = YearMonth.parse(calMonthParam);
        }
    } catch (Exception ignored) {}

    // Load pending appointment cases
    PreparedStatement stmt = null;
    ResultSet rs = null;
    try {
        // Auto-update if pending pass appointment date to unreachable
        PreparedStatement markStmt = null;
        try {
            String markUnreachableSql = "UPDATE prediction " +
                "SET appointment_status = 'unreachable' " +
                "WHERE appointment_status = 'pending' " +
                "AND appointment_date IS NOT NULL " +
                "AND appointment_date <= CURDATE()";
            markStmt = con.prepareStatement(markUnreachableSql);
            markStmt.executeUpdate();
        } catch (Exception ignored) {
        } finally {
            if (markStmt != null) try { markStmt.close(); } catch (Exception ignored) {}
        }

        String sql = "SELECT p.id, p.doctor_id, " +
                     "p.doctor_selected, p.appointment_status, p.created_at, p.appointment_date, " +
                     "p.staff_appointment_note, pt.phone_num, " +
                     "p.lab_list, " +
                     "DATEDIFF(p.appointment_date, CURDATE()) AS days_left, " +
                     "pt.patient_id, pt.title, pt.first_name, pt.last_name, " +
                     "pt.gender, pt.phone_num, pt.marriage_status, pt.birth_date, pt.icd10, pt.occupation, " +
                     "CONCAT(pt.sub_district, ' ', pt.district, ' ', pt.province) AS address, " +
                     "CONCAT('P', LPAD(pt.patient_id, 6, '0')) AS patient_code " +
                     "FROM prediction p " +
                     "JOIN patient pt ON p.patient_id = pt.patient_id " +
                     "WHERE p.appointment_status = 'pending' " +
                     "ORDER BY CASE WHEN p.appointment_date IS NULL THEN 1 ELSE 0 END ASC, p.appointment_date ASC, p.doctor_selected ASC, p.confident DESC";

        stmt = con.prepareStatement(sql);
        rs = stmt.executeQuery();

        while (rs.next()) {
            Map<String, Object> row = new HashMap<>();
            row.put("id", rs.getInt("id"));
            row.put("patient_id", rs.getInt("patient_id"));
            row.put("patient_code", rs.getString("patient_code"));
            row.put("patient_name", rs.getString("title") + rs.getString("first_name") + " " + rs.getString("last_name"));
            row.put("fullname", rs.getString("title") + " " + rs.getString("first_name") + " " + rs.getString("last_name"));
            row.put("doctor_selected", rs.getString("doctor_selected"));
            row.put("created_at", rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toString() : "");
            row.put("appointment_date", rs.getDate("appointment_date") != null ? rs.getDate("appointment_date").toString() : "");
            row.put("staff_appointment_note", rs.getString("staff_appointment_note") != null ? rs.getString("staff_appointment_note") : "");
            row.put("gender", rs.getString("gender"));
            row.put("phone_num", rs.getString("phone_num"));
            row.put("marriage_status", rs.getString("marriage_status"));
            row.put("birth_date", rs.getDate("birth_date") != null ? rs.getDate("birth_date").toString() : "");
            row.put("icd10", rs.getString("icd10"));
            row.put("occupation", rs.getString("occupation"));
            row.put("address", rs.getString("address"));
            row.put("phone_num", rs.getString("phone_num"));
            row.put("lab_list", rs.getString("lab_list") != null ? rs.getString("lab_list") : "");
            int daysLeft = rs.getInt("days_left");
            Integer daysLeftValue = rs.wasNull() ? null : Integer.valueOf(daysLeft);
            String timeLeft;
            if (daysLeftValue == null) {
                timeLeft = "-";
            } else {
                int safeDays = Math.max(daysLeftValue, 0);
                timeLeft = safeDays + "วัน";
            }
            row.put("time_left", timeLeft);

            predictions.add(row);
            totalCases++;

            String doctorSelected = rs.getString("doctor_selected");
            if ("home".equals(doctorSelected)) {
                homePredictions.add(row);
                homeCases++;
            } 
        }

        // Load day-count map for calendar
        LocalDate calStart = calCurrentMonth.atDay(1);
        LocalDate calEnd   = calCurrentMonth.atEndOfMonth();
        PreparedStatement calStmt = con.prepareStatement(
            "SELECT DATE(staff_appointment_date) AS appoint_day, COUNT(*) AS cnt " +
            "FROM prediction " +
            "WHERE appointment_status = 'completed' " +
            "AND staff_appointment_date IS NOT NULL " +
            "AND DATE(staff_appointment_date) BETWEEN ? AND ? " +
            "GROUP BY DATE(staff_appointment_date)");
        calStmt.setDate(1, java.sql.Date.valueOf(calStart));
        calStmt.setDate(2, java.sql.Date.valueOf(calEnd));
        ResultSet calRs = calStmt.executeQuery();
        while (calRs.next()) {
            java.sql.Date dt = calRs.getDate("appoint_day");
            if (dt != null) dayCountMap.put(dt.toLocalDate(), calRs.getInt("cnt"));
        }
        calRs.close();
        calStmt.close();

    } catch (Exception e) {
        e.printStackTrace();
        errorMessage = "Error: " + e.getMessage();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignored) {}
        if (stmt != null) try { stmt.close(); } catch (Exception ignored) {}
        if (con != null) try { con.close(); } catch (Exception ignored) {}
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
	<link rel="stylesheet" href="../staff_css/todayTask.css">
    <link rel="stylesheet" href="../layout.css">
</head>
<body>
    <%
        request.setAttribute("activePage", "todayTask");
        request.setAttribute("pageTitle", "งานตรวจคนไข้ที่ยังไม่ได้ตรวจ");
    %>
    <jsp:include page="../include/navbar.jsp" />
    <jsp:include page="../include/header.jsp" />

	<div class="content" id="mainPage">      
        <% if (!errorMessage.isEmpty()) { %>
            <div class="error-message">
                <b>เกิดข้อผิดพลาดในการดึงข้อมูล:</b><%= errorMessage %>
            </div>
        <% } %>
        
		<div id="todayTaskDiv">
			<div id="todayTask">
                <%-- left panel --%>
                <div id="leftPanel">
                    <div class="mini-cal-header">
                        <a class="mini-cal-nav" href="todayTask.jsp?month=<%= calCurrentMonth.minusMonths(1) %>">&lt;</a>
                        <div class="mini-cal-month-title"><%= calCurrentMonth.getMonthValue() %>/<%= calCurrentMonth.getYear() %></div>
                        <a class="mini-cal-nav" href="todayTask.jsp?month=<%= calCurrentMonth.plusMonths(1) %>">&gt;</a>
                    </div>
                    <div class="mini-cal-grid">
                        <% String[] calDayNames = {"จ","อ","พ","พฤ","ศ","ส","อา"};
                           for (String dn : calDayNames) { %>
                            <div class="mini-cal-day-name"><%= dn %></div>
                        <% } %>
                        <% int calFirstDayOffset = calCurrentMonth.atDay(1).getDayOfWeek().getValue() - 1;
                           for (int i = 0; i < calFirstDayOffset; i++) { %>
                            <div class="mini-cal-day mini-cal-empty"></div>
                        <% } %>
                        <% int calDaysInMonth = calCurrentMonth.lengthOfMonth();
                           for (int d = 1; d <= calDaysInMonth; d++) {
                               LocalDate day = calCurrentMonth.atDay(d);
                               Integer cnt = dayCountMap.get(day);
                               boolean isCalToday = day.equals(calToday); %>
                            <div class="mini-cal-day <%= isCalToday ? "mini-cal-today" : "" %>">
                                <span class="mini-cal-day-num"><%= d %></span>
                                <% if (cnt != null && cnt > 0) { %>
                                    <span class="mini-cal-day-cnt"><%= cnt %></span>
                                <% } %>
                            </div>
                        <% } %>
                    </div>

                    <div id="patientDetailPanel">
                        <div id="patientInfoDiv">
                            <h3>ข้อมูลคนไข้</h3>
                            <p>
                                <div id="patientCode">รหัสคนไข้ : </div>
                                <div id="patientName">ชื่อ นามสกุล : </div>
                                <div id="patientGender">เพศ : </div>
                                <div id="patientAge">อายุ : </div>
                                <div id="patientAddress">ที่อยู่ :</div>
                                <div id="patientMarriageStatus">สถานะการแต่งงาน :</div>
                                <div id="patientOccupation">อาชีพ :</div>
                                <div id="patientICD10">โรคประจำตัว :</div>
                                <div id="patientPhoneNum">เบอร์โทรศัพท์ :</div>
                                <div id="patientLabList">รายการแล็บที่ต้องตรวจ :</div>
                            </p>
                        </div>
                    </div>
                </div>

                <%-- right panel --%>
				<div id="homeCase">
                    <div class="case-title">รายชื่อคนไข้ที่มีคำสั่งตรวจที่บ้าน เรียงตามเวลาที่เหลือก่อนนัดตรวจ</div>
                    <div id="homeCaseList">
					<%
                        List<Map<String, Object>> displayPredictions = homePredictions.isEmpty() ? predictions : homePredictions;
						int homeIndex = 1;
                        if (displayPredictions.isEmpty()) {
					%>
						<div class="case-row">ไม่มีเคสตรวจที่บ้าน</div>
					<%
						} else {
                            for (Map<String, Object> pred : displayPredictions) {
					%>
                       <div class="case-row"
                            data-pred-id="<%= pred.get("id") %>"
                            data-patient-code="<%= attrEscape(pred.get("patient_code")) %>"
                            data-fullname="<%= attrEscape(pred.get("fullname")) %>"
                            data-patient-name="<%= attrEscape(pred.get("patient_name")) %>"
                            data-gender="<%= attrEscape(pred.get("gender")) %>"
                            data-phone-num="<%= attrEscape(pred.get("phone_num")) %>"
                            data-marriage-status="<%= attrEscape(pred.get("marriage_status")) %>"
                            data-birth-date="<%= attrEscape(pred.get("birth_date")) %>"
                            data-icd10="<%= attrEscape(pred.get("icd10")) %>"
                            data-occupation="<%= attrEscape(pred.get("occupation")) %>"
                            data-address="<%= attrEscape(pred.get("address")) %>"
                            data-appointment-date="<%= attrEscape(pred.get("appointment_date")) %>"
                            data-staff-appointment-note="<%= attrEscape(pred.get("staff_appointment_note")) %>"
                            data-lab-list="<%= attrEscape(pred.get("lab_list")) %>"
                            onclick="loadCaseDetail(this)">
                        <span class="case-time-left">เหลือเวลา: <%= pred.get("time_left") %></span> |
						<span class="case-index"><%= homeIndex %>.</span>
						<span class="case-name"><%= pred.get("patient_name") %></span>
                        
                        <input type="datetime-local" class="search-input appointment-datetime" placeholder="เลือกวันที่..." style="display:none;">
                        <select class="status-select" data-pred-id="<%= pred.get("id") %>">
							<option value="">-- เลือกสถานะ --</option>
							<option value="completed">นัดตรวจสำเร็จ</option>
                            <option value="changeToHos">เปลี่ยนไปตรวจโรงพยาบาล</option>
							<option value="rejected">คนไข้ปฏิเสธการตรวจ</option>
						</select>
					</div>
					<%
							homeIndex++;
						}
					}
					%>
                    </div>
                    <div id="staffNotePanel">
                        <div class="note-title">บันทึกเพิ่มเติมของ (ไม่บังคับ)</div>
                        <textarea id="staffAppointmentNote" placeholder="พิมพ์บันทึกสำหรับคนไข้ที่เลือก..."></textarea>
                        <div id="saveButtonDiv">
                            <button id="saveBtn" onclick="saveAllStatus()">บันทึก</button>
                        </div>
                    </div>
				</div>

			</div>
		</div>
        <form id="statusForm" action="todayTask.jsp?action=saveAppointmentStatus" method="post" style="display:none;"></form>
    </div>

    <jsp:include page="../include/toast.jsp" />
    <% if (toastMessage != null) { %>
    <script>
        showToast("<%= toastMessage %>", "<%= toastType != null ? toastType : "info" %>");
    </script>
    <% } %>

    <script src="../staff_js/todayTask.js"></script>     
    <script src="../script.js"></script>   
</body>
</html>