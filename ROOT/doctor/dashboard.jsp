<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.time.*, java.time.format.*" %>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
    Integer doctorId = (Integer) session.getAttribute("user_id");
    if (doctorId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

	String daysParam = request.getParameter("days");
	String dateParam = request.getParameter("date");
	PreparedStatement stmt = null;
	ResultSet rs = null;
	// for chart
	if (daysParam != null) {
		int days = 7;
		try {
			days = Integer.parseInt(daysParam);
		} catch (Exception e) {
			days = 7;
		}

		List<String>  labels       = new ArrayList<>();
		List<Integer> homeData     = new ArrayList<>();
		List<Integer> hospitalData = new ArrayList<>();

		try {
			LocalDate today = LocalDate.now();

			for (int i = days - 1; i >= 0; i--) {
				LocalDate targetDate = today.minusDays(i);
				String dateStr = targetDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
				String label   = targetDate.format(DateTimeFormatter.ofPattern("dd/MM"));

				labels.add(label);

				stmt = con.prepareStatement(
					"SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = ? AND predict_result = 'home' AND doctor_id = ?");
				stmt.setString(1, dateStr);
				stmt.setInt(2, doctorId);
				rs = stmt.executeQuery();
				homeData.add(rs.next() ? rs.getInt(1) : 0);
				rs.close();
				stmt.close();

				stmt = con.prepareStatement(
					"SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = ? AND predict_result = 'hospital' AND doctor_id = ?");
				stmt.setString(1, dateStr);
				stmt.setInt(2, doctorId);
				rs = stmt.executeQuery();
				hospitalData.add(rs.next() ? rs.getInt(1) : 0);
				rs.close();
				stmt.close();
			}
		} catch (Exception e) {
			response.setContentType("application/json; charset=UTF-8");
			out.print("{\"error\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
			return;
		}

		StringBuilder sb = new StringBuilder("{\"labels\":[");
		for (int i = 0; i < labels.size(); i++) {
			if (i > 0) sb.append(",");
			sb.append("\"").append(labels.get(i)).append("\"");
		}
		sb.append("],\"home\":[");
		for (int i = 0; i < homeData.size(); i++) {
			if (i > 0) sb.append(",");
			sb.append(homeData.get(i));
		}
		sb.append("],\"hospital\":[");
		for (int i = 0; i < hospitalData.size(); i++) {
			if (i > 0) sb.append(",");
			sb.append(hospitalData.get(i));
		}
		sb.append("]}");

		response.setContentType("application/json; charset=UTF-8");
		out.print(sb.toString());
		return;
	}
	// for stat
	if (dateParam != null) {
		int    totalPredict  = 0;
		int    homeCount     = 0;
		int    hospitalCount = 0;
		int    agreeCount    = 0;
		int    disagreeCount = 0;
		double agreeRate     = 0;

		try {
			stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = ? AND doctor_id = ?");
			stmt.setString(1, dateParam);
			stmt.setInt(2, doctorId);
			rs = stmt.executeQuery();
			if (rs.next()) totalPredict = rs.getInt(1);
			rs.close(); stmt.close();

			stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = ? AND predict_result = 'home' AND doctor_id = ?");
			stmt.setString(1, dateParam);
			stmt.setInt(2, doctorId);
			rs = stmt.executeQuery();
			if (rs.next()) homeCount = rs.getInt(1);
			rs.close(); stmt.close();

			stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = ? AND predict_result = 'hospital' AND doctor_id = ?");
			stmt.setString(1, dateParam);
			stmt.setInt(2, doctorId);
			rs = stmt.executeQuery();
			if (rs.next()) hospitalCount = rs.getInt(1);
			rs.close(); stmt.close();

			stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = ? AND predict_result = doctor_selected AND doctor_id = ?");
			stmt.setString(1, dateParam);
			stmt.setInt(2, doctorId);
			rs = stmt.executeQuery();
			if (rs.next()) agreeCount = rs.getInt(1);
			rs.close(); stmt.close();

			stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = ? AND predict_result != doctor_selected AND doctor_id = ?");
			stmt.setString(1, dateParam);
			stmt.setInt(2, doctorId);
			rs = stmt.executeQuery();
			if (rs.next()) disagreeCount = rs.getInt(1);
			rs.close(); stmt.close();

			if (totalPredict > 0) {
				agreeRate = Math.round((double) agreeCount / totalPredict * 10000) / 100.0;
			}

		} catch (Exception e) {
			response.setContentType("application/json; charset=UTF-8");
			out.print("{\"error\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
			return;
		}

		response.setContentType("application/json; charset=UTF-8");
		out.print("{\"totalPredict\":"  + totalPredict  +
				  ",\"homeCount\":"     + homeCount     +
				  ",\"hospitalCount\":" + hospitalCount +
				  ",\"agreeCount\":"    + agreeCount    +
				  ",\"disagreeCount\":" + disagreeCount +
				  ",\"agreeRate\":"     + agreeRate     + "}");
		return;
	}
	// วันที่ปัจจุบัน
	String todayDate  = new java.text.SimpleDateFormat("dd/MM/yyyy", java.util.Locale.US).format(new java.util.Date());
	String serverDate = new java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(new java.util.Date());

	// สถิติการทำนายของวันนี้
	int    totalPredict  = 0;
	int    homeCount     = 0;
	int    hospitalCount = 0;
	int    agreeCount    = 0;
	int    disagreeCount = 0;
	double agreeRate     = 0;

	try {
		stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = CURDATE() AND doctor_id = ?");
		stmt.setInt(1, doctorId);
		rs = stmt.executeQuery();
		if (rs.next()) totalPredict = rs.getInt(1);
		rs.close(); stmt.close();

		stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = CURDATE() AND predict_result = 'home' AND doctor_id = ?");
		stmt.setInt(1, doctorId);
		rs = stmt.executeQuery();
		if (rs.next()) homeCount = rs.getInt(1);
		rs.close(); stmt.close();

		stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = CURDATE() AND predict_result = 'hospital' AND doctor_id = ?");
		stmt.setInt(1, doctorId);
		rs = stmt.executeQuery();
		if (rs.next()) hospitalCount = rs.getInt(1);
		rs.close(); stmt.close();

		stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = CURDATE() AND predict_result = doctor_selected AND doctor_id = ?");
		stmt.setInt(1, doctorId);
		rs = stmt.executeQuery();
		if (rs.next()) agreeCount = rs.getInt(1);
		rs.close(); stmt.close();

		stmt = con.prepareStatement("SELECT COUNT(*) FROM prediction WHERE DATE(created_at) = CURDATE() AND predict_result != doctor_selected AND doctor_id = ?");
		stmt.setInt(1, doctorId);
		rs = stmt.executeQuery();
		if (rs.next()) disagreeCount = rs.getInt(1);
		rs.close(); stmt.close();

		if (totalPredict > 0) {
			agreeRate = Math.round((double) agreeCount / totalPredict * 10000) / 100.0;
		}

	} catch (Exception e) {
		out.println("Database Error: " + e.getMessage());
	}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
    <link rel="stylesheet" href="../doctor_css/dashboard.css">
    <link rel="stylesheet" href="../layout.css">
</head>
<body>
	<%
	    request.setAttribute("activePage", "dashboard");
	    request.setAttribute("pageTitle", "Dashboard");
	%>
	<jsp:include page="../include/navbar.jsp" />
	<jsp:include page="../include/header.jsp" />

	<script>const SERVER_DATE = "<%= serverDate %>";</script>

    <div class="content" id="dashboardPage">
        <div class="dashboard">
            <!-- สถิติ -->
            <div class="statsContainer">
                <h2>สถิติข้อมูลการทำนายสถานที่ตรวจสุขภาพ - วันที่ <%= todayDate %></h2>
                <div class="stat">
                    <div class="stat-card">
                        <h4>ระบบทำนายทั้งหมด</h4>
                        <div class="stat-wrapper">
                            <span class="stat-value" id="stat_total_predict"><%= totalPredict %></span>
                            <span class="stat-unit">ครั้ง</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <h4>ระบบแนะนำตรวจที่บ้าน</h4>
                        <div class="stat-wrapper">
                            <span class="stat-value" id="stat_home"><%= homeCount %></span>
                            <span class="stat-unit">ครั้ง</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <h4>ระบบแนะนำตรวจที่โรงพยาบาล</h4>
                        <div class="stat-wrapper">
                            <span class="stat-value" id="stat_hospital"><%= hospitalCount %></span>
                            <span class="stat-unit">ครั้ง</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <h4>หมอเห็นด้วยกับระบบ</h4>
                        <div class="stat-wrapper">
                            <span class="stat-value" id="stat_agree"><%= agreeCount %></span>
                            <span class="stat-unit">ครั้ง</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <h4>หมอไม่เห็นด้วยกับระบบ</h4>
                        <div class="stat-wrapper">
                            <span class="stat-value" id="stat_disagree"><%= disagreeCount %></span>
                            <span class="stat-unit">ครั้ง</span>
                        </div>
                    </div>

                    <div class="stat-card">
                        <h4>อัตราการเห็นด้วยกับระบบ</h4>
                        <div class="stat-wrapper">
                            <span class="stat-value" id="stat_agree_rate"><%= String.format("%.2f", agreeRate) %></span>
                            <span class="stat-unit">%</span>
                        </div>
                    </div>
                </div>
            </div>
            <!-- graph -->
            <div class="chart-section">
                <div class="chart-header">
                    <h3>จำนวนการตรวจบ้าน และ โรงพยาบาล</h3>
                    <div class="chart-filter">
                        <button onclick="changeRange('7')">7 วัน</button>
                        <button onclick="changeRange('14')">14 วัน</button>
                        <button onclick="changeRange('30')">30 วัน</button>
                    </div>
                </div>

                <div class="chart-container">
                    <canvas id="homeHospitalLineChart"></canvas>
                </div>
            </div>

            <!-- ปฏิทิน -->
            <div class="calendar">
                <div class="calendar-header">
                    <button id="prevMonth">&lt;</button>
                    <span id="monthYear"></span>
                    <button id="nextMonth">&gt;</button>
                </div>
                <div class="calendar-grid"></div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="../doctor_js/dashboard.js"></script>     
    <script src="../script.js"></script>     
    <jsp:include page="../include/toast.jsp" /> 
</body>
</html>