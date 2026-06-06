<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, java.time.*" %>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%!
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
    request.setCharacterEncoding("UTF-8");
    Integer staffId = (Integer) session.getAttribute("user_id");
    if (staffId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    String toastMessage = (String) session.getAttribute("toastMessage");
    String toastType    = (String) session.getAttribute("toastType");
    if (toastMessage != null) {
        session.removeAttribute("toastMessage");
        session.removeAttribute("toastType");
    }

    String action = request.getParameter("action");
    // edit note for appointment
    if ("saveNote".equals(action)) {
        String predIdStr = request.getParameter("predId");
        String note      = request.getParameter("note");
        String month     = request.getParameter("month");
        String date      = request.getParameter("date");
        try {
            PreparedStatement ps = con.prepareStatement(
                "UPDATE prediction SET staff_appointment_note = ? WHERE id = ?");
            ps.setString(1, note != null ? note : "");
            ps.setInt(2, Integer.parseInt(predIdStr));
            ps.executeUpdate();
            ps.close();
            session.setAttribute("toastMessage", "บันทึกสำเร็จ");
            session.setAttribute("toastType", "success");
        } catch (Exception e) {
            session.setAttribute("toastMessage", "บันทึกไม่สำเร็จ: " + e.getMessage());
            session.setAttribute("toastType", "error");
        }
        response.sendRedirect("calendarStaff.jsp?month=" + (month != null ? month : "") + "&date=" + (date != null ? date : ""));
        return;
    }
    // cancel appointment
    if ("cancelAppointment".equals(action)) {
        String predIdStr = request.getParameter("predId");
        String month     = request.getParameter("month");
        String date      = request.getParameter("date");
        try {
            PreparedStatement ps = con.prepareStatement(
                "UPDATE prediction SET appointment_status = 'pending', staff_appointment_date = NULL WHERE id = ?");
            ps.setInt(1, Integer.parseInt(predIdStr));
            ps.executeUpdate();
            ps.close();
            session.setAttribute("toastMessage", "ยกเลิกการนัดสำเร็จ");
            session.setAttribute("toastType", "success");
        } catch (Exception e) {
            session.setAttribute("toastMessage", "เกิดข้อผิดพลาด: " + e.getMessage());
            session.setAttribute("toastType", "error");
        }
        response.sendRedirect("calendarStaff.jsp?month=" + (month != null ? month : "") + "&date=" + (date != null ? date : ""));
        return;
    }

    LocalDate today = LocalDate.now();
    LocalDate selectedDate = today;
    YearMonth currentMonth = YearMonth.from(today);

    String monthParam = request.getParameter("month");
    String dateParam = request.getParameter("date");

    try {
        if (monthParam != null && !monthParam.trim().isEmpty()) {
            currentMonth = YearMonth.parse(monthParam);
        }
    } catch (Exception ignored) {
        currentMonth = YearMonth.from(today);
    }

    try {
        if (dateParam != null && !dateParam.trim().isEmpty()) {
            selectedDate = LocalDate.parse(dateParam);
        }
    } catch (Exception ignored) {
        selectedDate = today;
    }

    if (!YearMonth.from(selectedDate).equals(currentMonth)) {
        selectedDate = currentMonth.atDay(1);
    }

    Map<LocalDate, Integer> dayCountMap = new HashMap<>();
    List<Map<String, Object>> selectedDayAppointments = new ArrayList<>();
    String errorMessage = "";

    // data in current month for calendar display and selected day list
    try {
        LocalDate startDate = currentMonth.atDay(1);
        LocalDate endDate = currentMonth.atEndOfMonth();

        String countSql = "SELECT DATE(staff_appointment_date) AS appoint_day, COUNT(*) AS cnt " +
                          "FROM prediction " +
                          "WHERE doctor_selected = 'home' " +
                          "AND staff_appointment_date IS NOT NULL " +
                          "AND DATE(staff_appointment_date) BETWEEN ? AND ? " +
                          "GROUP BY DATE(staff_appointment_date)";
        PreparedStatement countStmt = con.prepareStatement(countSql);
        countStmt.setDate(1, java.sql.Date.valueOf(startDate));
        countStmt.setDate(2, java.sql.Date.valueOf(endDate));
        ResultSet countRs = countStmt.executeQuery();

        while (countRs.next()) {
            java.sql.Date dt = countRs.getDate("appoint_day");
            if (dt != null) {
                dayCountMap.put(dt.toLocalDate(), countRs.getInt("cnt"));
            }
        }
        countRs.close();
        countStmt.close();
        // data for selected patient list and detail
        String listSql = "SELECT p.id, p.patient_id, p.confident, p.staff_appointment_date, p.staff_appointment_note, p.lab_list, " +
                         "p.predict_result, p.doctor_selected, p.created_at, p.appointment_date, " +
                         "pt.title, pt.first_name, pt.last_name, pt.gender, pt.marriage_status, " +
                         "pt.birth_date, pt.icd10, pt.occupation, pt.phone_num, " +
                         "CONCAT(pt.sub_district, ' ', pt.district, ' ', pt.province) AS address, " +
                         "CONCAT('P', LPAD(pt.patient_id, 6, '0')) AS patient_code " +
                         "FROM prediction p " +
                         "JOIN patient pt ON p.patient_id = pt.patient_id " +
                         "WHERE p.doctor_selected = 'home' " +
                         "AND p.staff_appointment_date IS NOT NULL " +
                         "AND DATE(p.staff_appointment_date) = ? " +
                         "ORDER BY p.staff_appointment_date ASC";
        PreparedStatement listStmt = con.prepareStatement(listSql);
        listStmt.setDate(1, java.sql.Date.valueOf(selectedDate));
        ResultSet listRs = listStmt.executeQuery();

        while (listRs.next()) {
            Map<String, Object> row = new HashMap<>();
            row.put("id", listRs.getInt("id"));
            row.put("patient_code", listRs.getString("patient_code"));
            row.put("title", listRs.getString("title"));
            row.put("patient_name", listRs.getString("title") + listRs.getString("first_name") + " " + listRs.getString("last_name"));
            row.put("fullname", listRs.getString("title") + " " + listRs.getString("first_name") + " " + listRs.getString("last_name"));
            row.put("confident", listRs.getDouble("confident"));
            row.put("created_at", listRs.getTimestamp("created_at") != null ? listRs.getTimestamp("created_at").toString() : "");
            row.put("appointment_date", listRs.getDate("appointment_date") != null ? listRs.getDate("appointment_date").toString() : "");
            row.put("gender", listRs.getString("gender"));
            row.put("marriage_status", listRs.getString("marriage_status"));
            row.put("birth_date", listRs.getDate("birth_date") != null ? listRs.getDate("birth_date").toString() : "");
            row.put("icd10", listRs.getString("icd10"));
            row.put("occupation", listRs.getString("occupation"));
            row.put("address", listRs.getString("address"));
            row.put("phone_num", listRs.getString("phone_num"));
            String noteVal = listRs.getString("staff_appointment_note");
            row.put("staff_appointment_note", noteVal != null ? noteVal : "");
            String labVal = listRs.getString("lab_list");
            row.put("lab_list", labVal != null ? labVal : "");
            selectedDayAppointments.add(row);
        }
        listRs.close();
        listStmt.close();

    } catch (Exception e) {
        errorMessage = e.getMessage();
    }

    String[] dayNames = {"จ", "อ", "พ", "พฤ", "ศ", "ส", "อา"};
    int firstDayOffset = currentMonth.atDay(1).getDayOfWeek().getValue() - 1;
    int daysInMonth = currentMonth.lengthOfMonth();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
    <link rel="stylesheet" href="../staff_css/calendarStaff.css">
    <link rel="stylesheet" href="../layout.css">
</head>
<body>
    <%
        request.setAttribute("activePage", "calendarStaff");
        request.setAttribute("pageTitle", "ปฏิทินนัดตรวจคนไข้");
    %>
    <jsp:include page="../include/navbar.jsp" />
    <jsp:include page="../include/header.jsp" />

    <div class="content" id="calendarStaffPage">
        <% if (!errorMessage.isEmpty()) { %>
            <div class="error-message">เกิดข้อผิดพลาด: <%= errorMessage %></div>
        <% } %>

        <div class="calendar-layout">
            <div class="calendar-card">
                <div class="calendar-header">
                    <a class="month-nav" href="calendarStaff.jsp?month=<%= currentMonth.minusMonths(1) %>&date=<%= currentMonth.minusMonths(1).atDay(1) %>">&lt;</a>
                    <div class="month-title"><%= currentMonth.getMonthValue() %>/<%= currentMonth.getYear() %></div>
                    <a class="month-nav" href="calendarStaff.jsp?month=<%= currentMonth.plusMonths(1) %>&date=<%= currentMonth.plusMonths(1).atDay(1) %>">&gt;</a>
                </div>

                <div class="calendar-grid">
                    <% for (String dName : dayNames) { %>
                        <div class="day-name"><%= dName %></div>
                    <% } %>

                    <% for (int i = 0; i < firstDayOffset; i++) { %>
                        <div class="day empty"></div>
                    <% } %>

                    <% for (int d = 1; d <= daysInMonth; d++) {
                        LocalDate day = currentMonth.atDay(d);
                        Integer count = dayCountMap.get(day);
                        boolean isSelected = day.equals(selectedDate);
                        boolean isToday = day.equals(today);
                    %>
                        <a href="calendarStaff.jsp?month=<%= currentMonth %>&date=<%= day %>" class="day <%= isSelected ? "selected" : "" %> <%= isToday ? "today" : "" %>">
                            <span class="day-number"><%= d %></span>
                            <% if (count != null && count > 0) { %>
                                <span class="day-count"><%= count %></span>
                            <% } %>
                        </a>
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

            <div class="list-card">
                <div class="list-title">รายการนัดวันที่ <%= selectedDate %></div>
                <div id="calendarCaseList">
                <% if (selectedDayAppointments.isEmpty()) { %>
                    <div class="case-row">ไม่มีคนไข้นัดในวันนี้</div>
                <% } else {
                    int idx = 1;
                    for (Map<String, Object> row : selectedDayAppointments) {
                %>
                    <div class="case-row"
                         data-pred-id="<%= row.get("id") %>"
                         data-patient-code="<%= attrEscape(row.get("patient_code")) %>"
                         data-fullname="<%= attrEscape(row.get("fullname")) %>"
                         data-patient-name="<%= attrEscape(row.get("patient_name")) %>"
                         data-gender="<%= attrEscape(row.get("gender")) %>"
                         data-marriage-status="<%= attrEscape(row.get("marriage_status")) %>"
                         data-birth-date="<%= attrEscape(row.get("birth_date")) %>"
                         data-icd10="<%= attrEscape(row.get("icd10")) %>"
                         data-occupation="<%= attrEscape(row.get("occupation")) %>"
                         data-address="<%= attrEscape(row.get("address")) %>"
                         data-phone-num="<%= attrEscape(row.get("phone_num")) %>"
                         data-staff-appointment-note="<%= attrEscape(row.get("staff_appointment_note")) %>"
                         data-lab-list="<%= attrEscape(row.get("lab_list")) %>"
                         onclick="loadCaseDetail(this)">
                        <span class="case-index"><%= idx %>.</span>
                        <span class="case-name"><%= row.get("patient_name") %></span>
                        <span class="case-meta">มั่นใจ <%= String.format("%.2f", (Double) row.get("confident")) %>%</span>
                    </div>
                <% idx++; } } %>
                </div>
                <div id="calendarNotePanel">
                    <div class="note-title" id="calendarNoteLabel">บันทึกเพิ่มเติม</div>
                    <textarea id="staffAppointmentNote" rows="10" placeholder="คลิกคนไข้เพื่อดูบันทึก..."></textarea>
                    <div class="note-actions">
                        <button class="btn-note-save" onclick="saveCalendarNote()"> บันทึก</button>
                        <button class="btn-note-cancel" onclick="cancelCalendarAppointment()">ยกเลิกการนัด</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <jsp:include page="../include/toast.jsp" />
    <% if (toastMessage != null) { %>
    <script>
        showToast("<%= toastMessage %>", "<%= toastType != null ? toastType : "info" %>");
    </script>
    <% } %>
    <script src="../staff_js/todayTask.js"></script>
    <script src="../script.js"></script>
    <script>
        const calendarMonthParam = '<%= currentMonth %>';
        const calendarDateParam  = '<%= selectedDate %>';

        function saveCalendarNote() {
            if (!currentSelectedPredId) { showToast('กรุณาเลือกคนไข้ก่อน', 'error'); return; }
            const note = document.getElementById('staffAppointmentNote').value;
            const form = document.createElement('form');
            form.method = 'post';
            form.action = 'calendarStaff.jsp';
            form.acceptCharset = 'UTF-8';
            form.enctype = 'application/x-www-form-urlencoded;charset=UTF-8';
            [['action','saveNote'],['predId', currentSelectedPredId],['note', note],
             ['month', calendarMonthParam],['date', calendarDateParam]].forEach(([n,v]) => {
                const i = document.createElement('input');
                i.type = 'hidden'; i.name = n; i.value = v;
                form.appendChild(i);
            });
            document.body.appendChild(form);
            form.submit();
        }

        function cancelCalendarAppointment() {
            if (!currentSelectedPredId) { showToast('กรุณาเลือกคนไข้ก่อน', 'error'); return; }
            if (!confirm('ยืนยันยกเลิกการนัด?')) return;
            const form = document.createElement('form');
            form.method = 'post';
            form.action = 'calendarStaff.jsp';
            [['action','cancelAppointment'],['predId', currentSelectedPredId],
             ['month', calendarMonthParam],['date', calendarDateParam]].forEach(([n,v]) => {
                const i = document.createElement('input');
                i.type = 'hidden'; i.name = n; i.value = v;
                form.appendChild(i);
            });
            document.body.appendChild(form);
            form.submit();
        }
    </script>   
</body>
</html>