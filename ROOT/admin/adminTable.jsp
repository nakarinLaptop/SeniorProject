<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
    Integer userId = (Integer) session.getAttribute("user_id");
    if (userId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

	String errorMessage = null;
	String toastMsg  = (String) session.getAttribute("toastMessage");
    String toastType = (String) session.getAttribute("toastType");
    if (toastMsg != null) {
        session.removeAttribute("toastMessage");
        session.removeAttribute("toastType");
    }

	// add, edit, delete , restore
	if ("POST".equalsIgnoreCase(request.getMethod())) {
		request.setCharacterEncoding("UTF-8");
		String action    = request.getParameter("action");
		String editIdStr = request.getParameter("edit_id");

		if (con == null) {
			session.setAttribute("toastMessage", "ไม่สามารถเชื่อมต่อฐานข้อมูลได้");
			session.setAttribute("toastType", "error");
			response.sendRedirect("doctorTable.jsp");
			return;
		}

		if ("add".equals(action)) {
			String newUsername   = request.getParameter("new_username");
			String newPassword   = request.getParameter("new_password");
			String newTitle      = request.getParameter("new_title");
			String newFirstName  = request.getParameter("new_first_name");
			String newLastName   = request.getParameter("new_last_name");
	
			try {
				String insertSql = "INSERT INTO user "
					+ "(username, password_hash, title, first_name, last_name , role ) "
					+ "VALUES (?,?,?,?,?, 'admin')";
				PreparedStatement insStmt = con.prepareStatement(insertSql);
				insStmt.setString(1, newUsername   != null ? newUsername.trim()   : "");
				insStmt.setString(2, newPassword   != null ? newPassword.trim()   : "");
				insStmt.setString(3, newTitle      != null ? newTitle.trim()      : "");
				insStmt.setString(4, newFirstName  != null ? newFirstName.trim()  : "");
				insStmt.setString(5, newLastName   != null ? newLastName.trim()   : "");				
				insStmt.executeUpdate();
				insStmt.close();
				session.setAttribute("toastMessage", "เพิ่มผู้ดูแลระบบเรียบร้อย");
				session.setAttribute("toastType", "success");
			} catch (java.sql.SQLIntegrityConstraintViolationException dupEx) {
				session.setAttribute("toastMessage", "username ซ้ำ");
				session.setAttribute("toastType", "error");
			} catch (Exception ex) {
				String exMsg = ex.getMessage() != null ? ex.getMessage() : "";
				if (exMsg.contains("Duplicate entry") || exMsg.contains("duplicate key")) {
					session.setAttribute("toastMessage", "username ซ้ำ");
				} else {
					session.setAttribute("toastMessage", "เพิ่มผู้ดูแลระบบไม่สำเร็จ: " + exMsg);
				}
				session.setAttribute("toastType", "error");
			}
		} else if ("restore".equals(action)) {
			String restoreIdStr = request.getParameter("restore_id");
			try {
				int restoreId = Integer.parseInt(restoreIdStr);
				PreparedStatement restStmt = con.prepareStatement(
					"UPDATE user SET is_active = 1 WHERE user_id = ? AND role = 'admin'");
				restStmt.setInt(1, restoreId);
				int rows = restStmt.executeUpdate();
				restStmt.close();
				if (rows == 0) {
					session.setAttribute("toastMessage", "ไม่พบข้อมูลผู้ดูแลระบบที่ต้องการกู้คืน");
					session.setAttribute("toastType", "error");
				} else {
					session.setAttribute("toastMessage", "กู้คืนผู้ดูแลระบบเรียบร้อย");
					session.setAttribute("toastType", "success");
				}
			} catch (Exception ex) {
				ex.printStackTrace();
				session.setAttribute("toastMessage", "กู้คืนผู้ดูแลระบบไม่สำเร็จ: " + ex.getMessage());
				session.setAttribute("toastType", "error");
			}
			response.sendRedirect("adminTable.jsp");
			return;
		} else if ("delete".equals(action)) {
			String delIdStr = request.getParameter("delete_id");
			try {
				int delId = Integer.parseInt(delIdStr);
				String deleteSql = "UPDATE user SET is_active = 0 WHERE user_id = ? AND role = 'admin'";
				PreparedStatement delStmt = con.prepareStatement(deleteSql);
				delStmt.setInt(1, delId);
				int rows = delStmt.executeUpdate();
				delStmt.close();
				if (rows == 0) {
					session.setAttribute("toastMessage", "ไม่พบข้อมูลผู้ดูแลระบบที่ต้องการลบ (ID: " + delId + ")");
					session.setAttribute("toastType", "error");
				} else {
					session.setAttribute("toastMessage", "ลบผู้ดูแลระบบเรียบร้อย");
					session.setAttribute("toastType", "success");
				}
			} catch (Exception ex) {
				ex.printStackTrace();
				session.setAttribute("toastMessage", "ลบแพทย์ไม่สำเร็จ: " + ex.getMessage());
				session.setAttribute("toastType", "error");
			}
			response.sendRedirect("adminTable.jsp");
			return;
		} else if (editIdStr != null && !editIdStr.isEmpty()) {
			String editUsername    = request.getParameter("edit_username");
			String editPassword    = request.getParameter("edit_password");
			String editFirst       = request.getParameter("edit_first_name");
			String editLast        = request.getParameter("edit_last_name");
			String editTitle       = request.getParameter("edit_title");
			try {
				int editId = Integer.parseInt(editIdStr);
				String updateSql = "UPDATE user SET first_name=?, last_name=?, title=?, "
					+ "username=?, password_hash=? , role='admin' WHERE user_id=?";
				PreparedStatement upStmt = con.prepareStatement(updateSql);
				upStmt.setString(1, editFirst       != null ? editFirst.trim()       : "");
				upStmt.setString(2, editLast        != null ? editLast.trim()        : "");
				upStmt.setString(3, editTitle       != null ? editTitle.trim()       : "");
				upStmt.setString(4, editUsername    != null ? editUsername.trim()    : "");
				upStmt.setString(5, editPassword    != null ? editPassword.trim()    : "");
				upStmt.setInt(6, editId);
				int rows = upStmt.executeUpdate();
				upStmt.close();
				if (rows == 0) {
					session.setAttribute("toastMessage", "ไม่พบข้อมูลผู้ดูแลระบบที่ต้องการแก้ไข (ID: " + editId + ")");
					session.setAttribute("toastType", "error");
				} else {
					session.setAttribute("toastMessage", "แก้ไขข้อมูลเรียบร้อย");
					session.setAttribute("toastType", "success");
				}
			} catch (Exception ex) {
				ex.printStackTrace();
				session.setAttribute("toastMessage", "แก้ไขข้อมูลไม่สำเร็จ: " + ex.getMessage());
				session.setAttribute("toastType", "error");
				response.sendRedirect("adminTable.jsp");
				return;
			}
		}
		response.sendRedirect("adminTable.jsp");
		return;
	}


	// load deleted admins for restore dialog
	List<Map<String, String>> deletedAdmins = new ArrayList<>();
	try {
		String delSql = " SELECT user_id, CONCAT(title, ' ', first_name, ' ', last_name) AS admin_name, " +
						" CONCAT('A', LPAD(user_id, 3, '0')) AS admin_code " +
			 			" FROM user WHERE role = 'admin' AND is_active = 0 ORDER BY user_id";
		PreparedStatement delStmt = con.prepareStatement(delSql);
		ResultSet delRs = delStmt.executeQuery();
		while (delRs.next()) {
			Map<String, String> d = new HashMap<>();
			d.put("id",   delRs.getString("user_id"));
			d.put("name", delRs.getString("admin_name"));
			d.put("code", delRs.getString("admin_code"));

			deletedAdmins.add(d);
		}
		delRs.close();
		delStmt.close();
	} catch (Exception e) {
		e.printStackTrace();
	}

    // table
	List<Map<String, String>> admins = new ArrayList<>();
	try{
        String sql =
            "SELECT u.user_id, u.username, u.title, u.first_name, u.last_name, "
            + "CONCAT('A', LPAD(u.user_id, 3, '0')) AS admin_code "
            + "FROM `user` u WHERE u.role = 'admin' AND u.is_active = 1 ORDER BY u.user_id";
        PreparedStatement stmt = con.prepareStatement(sql);
        ResultSet rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, String> d = new HashMap<>();
            d.put("id",                 rs.getString("user_id"));
            d.put("username",           rs.getString("username"));
            d.put("admin_code",         rs.getString("admin_code"));
            d.put("title",              rs.getString("title"));
            d.put("first_name",         rs.getString("first_name"));
            d.put("last_name",          rs.getString("last_name"));
            admins.add(d);
        }
        rs.close();
        stmt.close();
	} catch (Exception e) {
		e.printStackTrace();
		errorMessage = "ไม่สามารถโหลดข้อมูลผู้ดูแลระบบได้: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
<link rel="stylesheet" href="../admin_css/patient.css">
<link rel="stylesheet" href="../layout.css">
</head>

<body>
	<%
	request.setAttribute("activePage", "admin");
	request.setAttribute("pageTitle", "รายชื่อผู้ดูแลระบบ");
	%>
	<jsp:include page="../include/navbar.jsp" />
	<jsp:include page="../include/header.jsp" />

	<div class="content" id="adminPage">
		<div id="addAdminContainer" style="display:flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
			<h2>รายชื่อผู้ดูแลระบบ</h2>
			<div>
				<button class="search-btn" onclick="openAddDialog()">เพิ่มผู้ดูแลระบบ</button>
				<button class="search-btn" onclick="openRestoreAdminDialog()">กู้คืนผู้ดูแลระบบที่ถูกลบ</button>
			</div>
		</div>

		<div class="search-container">
			<div class="search-box"><input type="text" id="searchCode"       placeholder="ค้นหารหัสผู้ดูแลระบบ..."></div>
			<div class="search-box"><input type="text" id="searchTitle"      placeholder="ค้นหาคำนำหน้า..."></div>
			<div class="search-box"><input type="text" id="searchFirstName"  placeholder="ค้นหาชื่อ..."></div>
			<div class="search-box"><input type="text" id="searchLastName"   placeholder="ค้นหานามสกุล..."></div>
			<div class="search-box search-box-btn"><button onclick="filterAdmins()" class="search-btn">ค้นหา</button></div>
		</div>

		<table id="adminTable">
			<thead>
				<tr>
					<th class="col-hidden">ID</th>
					<th>รหัสผู้ดูแลระบบ</th>
					<th>คำนำหน้า</th>
					<th>ชื่อ</th>
					<th>นามสกุล</th>
					<th>แก้ไข</th>
				</tr>
			</thead>
			<tbody>
			</tbody>
		</table>

		<div class="pagination" id="pagination"></div>
	</div>

	<%-- Add Admin Dialog --%>
	<div id="addAdminDialog" class="dialogBG" style="display:none;">
		<div class="dialogContent">
			<h3>เพิ่มข้อมูลผู้ดูแลระบบ</h3>
				<form method="post" action="adminTable.jsp" onsubmit="return validateEditForm()">
				<input type="hidden" name="action" value="add">
				<table class="edit-form-table">
					<tr>
						<td class="label-cell">คำนำหน้า</td>
						<td class="input-cell">
						<select name="new_title">
							<option value="นาย">นาย</option>
							<option value="นาง">นาง</option>
							<option value="นางสาว">นางสาว</option>
						</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">ชื่อ</td>
						<td class="input-cell">
							<input type="text" name="new_first_name" required>
						</td>
					</tr>
					<tr>
						<td class="label-cell">นามสกุล</td>
						<td class="input-cell">
							<input type="text" name="new_last_name" required>
						</td>
					</tr>
					<tr>
						<td class="label-cell">ชื่อผู้ใช้</td>
						<td class="input-cell">
							<input type="text" name="new_username" required autocomplete="off">
						</td>
					</tr>
					<tr>
						<td class="label-cell">รหัสผ่าน</td>
						<td class="input-cell">
							<input type="password" name="new_password" required autocomplete="new-password">
						</td>
					</tr>
				</table>
				<div class="dialogActions">
					<button type="button" class="search-btn btn-secondary"
						onclick="closeAddDialog()">ยกเลิก</button>
					<button type="submit" class="search-btn">บันทึก</button>
				</div>
			</form>
		</div>
	</div>

	<%-- Restore Admin Dialog --%>
	<div id="restoreAdminDialog" class="dialogBG" style="display:none;">
		<div class="dialogContent">
			<h3>รายชื่อผู้ดูแลระบบที่ไม่ได้ใช้งาน</h3>
			<div class="docList">
				<% if (deletedAdmins.isEmpty()) { %>
					<p>ไม่มีผู้ดูแลระบบที่ถูกลบ</p>
				<% } else { %>
					<ul id="restoreAdminList">
						<% for (Map<String, String> d : deletedAdmins) { %>
							<li data-id="<%= d.get("id") %>" onclick="selectRestoreAdmin(this)">
								<%= d.get("code") %> - <%= d.get("name") %>
							</li>
						<% } %>
					</ul>
				<% } %>
			</div>
			<div class="dialogActions">
				<button type="button" class="search-btn btn-secondary" onclick="closeRestoreAdminDialog()">ยกเลิก</button>
				<button type="button" class="search-btn" onclick="confirmRestoreAdmin()">กู้คืนผู้ดูแลระบบ</button>
			</div>
		</div>
	</div>

	<%-- Edit Admin Dialog --%>
	<div id="editAdminDialog" class="dialogBG" style="display:none;">
		<div class="dialogContent">
			<h3>แก้ไขข้อมูลผู้ดูแลระบบ</h3>
			<form method="post" action="adminTable.jsp" onsubmit="return validateEditForm()">
				<input type="hidden" id="editAdminId" name="edit_id">
				<table class="edit-form-table">
					<tr>
						<td class="label-cell">คำนำหน้า</td>
						<td class="input-cell">
						<select id="editAdminTitle" name="edit_title">
							<option value="นาย">นาย</option>
							<option value="นาง">นาง</option>
							<option value="นางสาว">นางสาว</option>					
						</select>
						</td>
					</tr>
					<tr>
						<td class="label-cell">ชื่อ</td>
						<td class="input-cell">
							<input type="text" id="editAdminFirstName" name="edit_first_name">
						</td>
					</tr>
					<tr>
						<td class="label-cell">นามสกุล</td>
						<td class="input-cell">
							<input type="text" id="editAdminLastName" name="edit_last_name">
						</td>
					</tr>
					<tr>
						<td class="label-cell">ชื่อผู้ใช้</td>
						<td class="input-cell">
							<input type="text" id="editAdminUsername" name="edit_username">
						</td>
					</tr>
					<tr>
						<td class="label-cell">รหัสผ่านใหม่</td>
						<td class="input-cell">
							<input type="password" id="editAdminPassword" name="edit_password" autocomplete="new-password">
						</td>
					</tr>
					<tr>
						<td class="label-cell">ยืนยันรหัสผ่าน</td>
						<td class="input-cell">
							<input type="password" id="editAdminPasswordConfirm" autocomplete="new-password">
						</td>
					</tr>
				</table>
				<div class="dialogActions">
					<button type="button" class="search-btn btn-danger" onclick="deleteAdmin()" style="background-color: red;">ลบผู้ดูแลระบบ</button>
					<button type="button" class="search-btn btn-secondary"
						onclick="closeEditDialog()">ยกเลิก</button>
					<button type="submit" class="search-btn">บันทึก</button>
				</div>
			</form>
		</div>
	</div>

	<script>
	const adminsData = [
		<% for (Map<String, String> d : admins) { %>
		{
			id:                 "<%= d.get("id") %>",
			username:           "<%= d.get("username") %>",
			admin_code:        "<%= d.get("admin_code") %>",
			title:              "<%= d.get("title") %>",
			first_name:         "<%= d.get("first_name") %>",
			last_name:          "<%= d.get("last_name") %>"
		},
		<% } %>
	];
	</script>
	<%-- Hidden Delete Form --%>
	<form id="deleteAdminForm" method="post" action="adminTable.jsp" style="display:none;">
		<input type="hidden" name="action" value="delete">
		<input type="hidden" id="deleteAdminId" name="delete_id">
	</form>

	<%-- Hidden Restore Form --%>
	<form id="restoreAdminForm" method="post" action="adminTable.jsp" style="display:none;">
		<input type="hidden" name="action" value="restore">
		<input type="hidden" id="restoreAdminId" name="restore_id">
	</form>

	<script src="../admin_js/adminTable.js"></script>
	<script src="../script.js"></script>
	<jsp:include page="../include/toast.jsp" />
	<% if (toastMsg != null) { %>
	<script>document.addEventListener("DOMContentLoaded", function(){ showToast("<%= toastMsg.replace("\"", "&quot;") %>", "<%= toastType %>"); });</script>
	<% } %>
</body>
</html>
