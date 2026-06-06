<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*"%>
<%@ include file="WEB-INF/db/connectDB.jsp" %>
<% 
	String errorMessage = "";

	if ("POST".equalsIgnoreCase(request.getMethod())) {
		String username = request.getParameter("docuid");
		String password = request.getParameter("docpass");

		try {
			String sql = "SELECT user_id, username, password_hash, role, title, first_name, last_name, is_active FROM user WHERE username = ?";
			PreparedStatement stmt = con.prepareStatement(sql);
			stmt.setString(1, username);

			ResultSet rs = stmt.executeQuery();

			if (rs.next()) {
			int userId = rs.getInt("user_id");
			String role = rs.getString("role");
			String dbHash = rs.getString("password_hash");
			boolean isActive = rs.getBoolean("is_active");
			
				if (isActive) {
					if (password.equals(dbHash)) {
						String patientId = (String) session.getAttribute("patientId");
						boolean hasPatient = (patientId != null);

						session.setAttribute("user_id", userId);
						session.setAttribute("role", role);

						if (role.equals("doctor")) {
							session.setAttribute("doctorName",
								rs.getString("title") + rs.getString("first_name") + " " + rs.getString("last_name"));
							response.sendRedirect("doctor/main.jsp");
						} else if (role.equals("admin")) {
							session.setAttribute("adminName",
								rs.getString("title") + rs.getString("first_name") + " " + rs.getString("last_name"));
							response.sendRedirect("admin/adminHome.jsp");
						} else if (role.equals("staff")) {
							session.setAttribute("staffName",
								rs.getString("title") + rs.getString("first_name") + " " + rs.getString("last_name"));
							session.setAttribute("firstName", rs.getString("first_name"));
							response.sendRedirect("staff/todayTask.jsp");
						} else if(role.equals("superadmin")) {
							session.setAttribute("superadminName",
								rs.getString("title") + rs.getString("first_name") + " " + rs.getString("last_name"));
							response.sendRedirect("admin/adminHome.jsp");
						}
					} else {
						errorMessage = "รหัสผ่านไม่ถูกต้อง";
					}
				} else {
					errorMessage = "บัญชีผู้ใช้ถูกระงับ";
				}
			} else {
				errorMessage = "ไม่พบชื่อผู้ใช้";
			}
			rs.close();
			stmt.close();
			con.close();

		} catch (Exception e) {
			e.printStackTrace(); 
			errorMessage = e.getClass().getName() + " : " + e.getMessage();
		}

	}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>เข้าสู่ระบบ</title>
<link rel="stylesheet" href="index.css">
<link rel="stylesheet" href="layout.css">
</head>
<body>
	<div id="container">
		<div id="loginDiv">
			<h2 id="indexheader">
				ระบบทำนายสถานที่เก็บสิ่งส่งตรวจที่เหมาะสม (บ้านหรือโรงพยาบาล)<br>
				โดยใช้ Machine Learning
			</h2>

			<div id="loginForm">
				<form method="post">
					<label for="docuid">ชื่อผู้ใช้:</label> <input type="text"
						id="docuid" name="docuid" required><br> <label
						for="docpass">รหัสผ่าน:</label> <input type="password"
						id="docpass" name="docpass" required><br>
					<button id="docloginbtn" type="submit">เข้าสู่ระบบ</button>
				</form>

				<div id="error" style="color: red;">
					<%=errorMessage%>
				</div>
			</div>
		</div>
	</div>
</body>
</html>
