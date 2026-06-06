<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.time.*, java.time.format.DateTimeFormatter" %>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>

<%
    Integer patientId = (Integer) session.getAttribute("patient_id");
    boolean hasPatient = (patientId != null);

    String patientCode = (String) session.getAttribute("patientCode");
    String patientName = (String) session.getAttribute("patientName");
	String patientGender = (String) session.getAttribute("patientGender");
	Date birthDate = (Date) session.getAttribute("patientBirthDate");
	String ageText = "-";

	if (birthDate != null) {
    	LocalDate birth = birthDate.toLocalDate();
    	LocalDate today = LocalDate.now();

    	Period p = Period.between(birth, today);

    	int years = p.getYears();
    	int months = p.getMonths();
    	int days = p.getDays();

    	if (years > 0) {
    	    ageText = years + " ปี " + months + " เดือน " + days + " วัน";
    	} else if (months > 0) {
    	    ageText = months + " เดือน " + days + " วัน";
    	} else {
    	    ageText = days + " วัน";
    	}
	}

	String patientError = (String) session.getAttribute("patientError");
	boolean showPatientChangeOnError = (patientError != null && hasPatient);

    String activePage = (String) request.getAttribute("activePage");
    String pageTitle = (String) request.getAttribute("pageTitle");

    String role = (String) session.getAttribute("role");
    boolean isDoctor = "doctor".equals(role);
	boolean isStaff = "staff".equals(role);
	int quotaAmount = -1;
	int quotaId = -1;
	String quotaMessage = null;
	String editorName = null;

	// โหลดค่าโควต้าจริงจากฐานข้อมูล
	try {
		String sqlQuota = "SELECT idquota, amount FROM quota ORDER BY idquota ASC LIMIT 1";
		PreparedStatement stmtQuota = con.prepareStatement(sqlQuota);
		ResultSet rsQuota = stmtQuota.executeQuery();
		if (rsQuota.next()) {
			quotaId = rsQuota.getInt("idquota");
			quotaAmount = rsQuota.getInt("amount");
		}
		rsQuota.close();
		stmtQuota.close();

	} catch (Exception e) {
		e.printStackTrace();
	}

	if (isStaff && "updateQuota".equals(request.getParameter("action"))) {
		String quotaInput = request.getParameter("quotaAmount");
		try {
			int newQuota = Integer.parseInt(quotaInput);
			if (editorName == null || editorName.trim().isEmpty()) {
				editorName = (String) session.getAttribute("firstName");
			}

			if (newQuota < 0) {
				quotaMessage = "โควต้าต้องไม่ติดลบ";
			} else {
				String updateQuotaSql = "UPDATE quota SET amount = ?, edit_name = ? WHERE idquota = ?";
				PreparedStatement updateQuotaStmt = con.prepareStatement(updateQuotaSql);
				updateQuotaStmt.setInt(1, newQuota);
				updateQuotaStmt.setString(2, editorName);
				updateQuotaStmt.setInt(3, quotaId);
				updateQuotaStmt.executeUpdate();
				updateQuotaStmt.close();
				quotaAmount = newQuota;
				String updatedAt = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
				quotaMessage = "บันทึกโควต้าเรียบร้อย " + updatedAt;
			}
		} catch (Exception ex) {
			quotaMessage = "บันทึกโควต้าไม่สำเร็จ";
		}
	}

%>
<div class="header"> 
    <div class="pageTitle" style="<%= !isDoctor ? "width: 100%; max-width: 100%;" : "" %>"><%= pageTitle %></div>
	<div class="patientBlock" style="<%= !isDoctor ? "display: none;" : "" %>">
		<%
		if (hasPatient) {
		%>
			<div id="patientDisplay">
				<div class="patientInfo">
					รหัส:
					<%=patientCode%><br> 
					ชื่อ:
					<%=patientName%><br>
				</div>
				<div class="patientInfo">
					เพศ:
					<%=patientGender%><br>
					อายุ:
					<%=ageText%>
				</div>
				<button type="button" onclick="toggleRemovePatient()">
					ยกเลิกการเลือกคนไข้
				</button>
			</div>
		<%
		}
		%>
	</div>

	<% if (isStaff) { %>
		<div>
			<form method="post" style="display:flex;align-items:center;gap:8px;">
				<input type="hidden" name="action" value="updateQuota">
				<label for="quotaAmountInput">โควต้าการตรวจวันนี้:</label>
				<input
					type="number"
					id="quotaAmountInput"
					name="quotaAmount"
					min="0"
					value="<%= quotaAmount %>"
					style="width:90px;"
				>
				<button type="submit">บันทึก</button>
			</form>
			<% if (quotaMessage != null) { %>
				<div style="font-size:12px;color:#333;margin-top:4px;"><%= quotaMessage %></div>
			<% } %>
		</div>
	<% } %>

</div>
<%-- กล่องยกเลิกการเลือกคนไข้ --%>
<div id="patientRemoveDialog" class="dialogBG" style="display: none;">
	<div class="dialogContent">
		<h3>ยกเลิกการเลือกคนไข้</h3>
		<p>คุณแน่ใจหรือไม่ว่าต้องการยกเลิกการเลือกคนไข้นี้?</p>
		<div class="dialogActions">
			<button type="button" onclick="toggleRemovePatient()">ยกเลิก</button>
			<form action="removePatient.jsp" method="post" style="display: inline;">
				<button type="submit">ยืนยัน</button>
			</form>
		</div>
	</div>
</div>

<script>
function toggleRemovePatient() {
    const box = document.getElementById("patientRemoveDialog");
    box.style.display = (box.style.display === "none") ? "block" : "none";
}
</script>
