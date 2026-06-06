<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.Date, java.time.*" %>
<%
    Integer patientId = (Integer) session.getAttribute("patient_id");
    boolean hasPatient = (patientId != null);
    String role = (String) session.getAttribute("role");
%>
<div class="navbarlist">
	<div id="name-app">
        <p>ระบบทำนายสถานที่ตรวจสุขภาพ ที่เหมาะสมด้วยMachine learning</p>
	</div>
	<div class="line"></div>
    <% if ("doctor".equals(role)) {%>
        <% if (!hasPatient) { %>
            <div class="menu-item"> 
                <div class="menu <%= "main".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('main.jsp')">
                    เลือกคนไข้
                </div>
                <div class="menu <%= "patient".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('patient.jsp')">
                    ข้อมูลคนไข้
                </div>

                <div class="menu <%= "dashboard".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('dashboard.jsp')">
                    Dashboard
                </div>
            </div>
        <% } else { %>
            <div class="menu-item">
                <div class="menu <%= "patientData".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('patientData.jsp')">
                    ประวัติคนไข้
                </div>
                
                <div class="menu <%= "med".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('medExamination.jsp')">
                    ซักประวัติคนไข้
                </div>

                <div class="menu <%= "predict".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('predict.jsp')">
                    เลือกรายการตรวจแล็บและทำนายสถานที่ตรวจสุขภาพ
                </div>

                <div class="menu <%= "prescription".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('prescription.jsp')">
                    ใบสั่งยา
                </div>
            </div>
        <% } %>
    <% } else if ("staff".equals(role)){ %>
        <div class="menu-item">
            <div class="menu <%= "todayTask".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                onclick="gotoPage('todayTask.jsp')">
                งานตรวจคนไข้ที่ยังไม่ได้ตรวจ
            </div>

            <div class="menu <%= "calendarStaff".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                onclick="gotoPage('calendarStaff.jsp')">
                ปฏิทินนัดตรวจคนไข้
            </div>
            
            <div class="menu <%= "finishedTask".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                onclick="gotoPage('finishedTask.jsp')">
                งานตรวจคนไข้ที่ตรวจแล้ว
            </div>
        </div>
    <% } else if ("admin".equals(role)){ %>
            <div class="menu-item">
                <div class="menu <%= "adminHome".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('adminHome.jsp')">
                    หน้าแรก
                </div>

                <div class="menu <%= "doctor".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('doctorTable.jsp')">
                    รายชื่อหมอ
                </div>

                <div class="menu <%= "patient".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('patientTable.jsp')">
                    รายชื่อคนไข้
                </div>

                <div class="menu <%= "med".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('medExaminationTable.jsp')">
                    ประวัติการซักประวัติคนไข้
                </div>

                <div class="menu <%= "predict".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('predictTable.jsp')">
                    ประวัติการทำนายสถานที่ตรวจสุขภาพ
                </div>

                <div class="menu <%= "prescription".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('prescriptionTable.jsp')">
                    ประวัติใบสั่งยา
                </div>
            </div>
    <% } else if ("superadmin".equals(role)){ %>
            <div class="menu-item">
                <div class="menu <%= "adminHome".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('adminHome.jsp')">
                    หน้าแรก
                </div>

                <div class="menu <%= "doctor".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('doctorTable.jsp')">
                    รายชื่อหมอ
                </div>

                <div class="menu <%= "patient".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('patientTable.jsp')">
                    รายชื่อคนไข้
                </div>

                <div class="menu <%= "admin".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('adminTable.jsp')">
                    รายชื่อแอดมิน
                </div>

                <div class="menu <%= "med".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('medExaminationTable.jsp')">
                    ประวัติการซักประวัติคนไข้
                </div>

                <div class="menu <%= "predict".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('predictTable.jsp')">
                    ประวัติการทำนายสถานที่ตรวจสุขภาพ
                </div>

                <div class="menu <%= "prescription".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('prescriptionTable.jsp')">
                    ประวัติใบสั่งยา
                </div>

                <div class="menu <%= "prescription".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    onclick="gotoPage('model.jsp')">
                    พัฒนาโมเดล
                </div>
            </div>    
    <% } %>

	<div class="line" id="line2"></div>
	<div id="profilecontainer">
		<div class="profile-section" onclick="toggleLogoutMenu()">
			<div id="roleDisplay">
                <% if ("doctor".equals(role)) { %>
                    <span style="color: blue; align-items: center;">DOCTOR</span>
                <% } else if ("admin".equals(role)) { %>
                    <span style="color: red; align-items: center;">ADMIN</span>
                <% } else if ("staff".equals(role)) { %>
                    <span style="color: darkgoldenrod; align-items: center;">STAFF</span>
                <% } else if ("superadmin".equals(role)) { %>
                    <span style="color: purple; align-items: center;">SUPER</br>ADMIN</span>
                <% } %>
			</div>
            <%
                String username = "";

                if ("doctor".equals(role)) {
                    username = (String) session.getAttribute("doctorName");
                } else if ("admin".equals(role)) {
                    username = (String) session.getAttribute("adminName");
                } else if ("staff".equals(role)) {
                    username = (String) session.getAttribute("staffName");
                } else if ("superadmin".equals(role)) {
                    username = (String) session.getAttribute("superadminName");
                }
            %>

            <div id="username">
                <%= username %>
            </div>

			<div id="arrowIcon">
				<svg xmlns="http://www.w3.org/2000/svg" fill="none"
					viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"
					class="size-6" width="20" height="20" preserveAspectRatio="none">
                    <path stroke-linecap="round" stroke-linejoin="round"
						d="m8.25 4.5 7.5 7.5-7.5 7.5" />
                </svg>
			</div>
		</div>
		<div id="logoutMenu">
			<div id="logoutBtn">
				<svg xmlns="http://www.w3.org/2000/svg" fill="none"
					viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"
					width="20" id="logoutIcon">
					<path stroke-linecap="round" stroke-linejoin="round"
						d="M8.25 9V5.25A2.25 2.25 0 0 1 10.5 3h6a2.25 2.25 0 0 1 2.25 2.25v13.5A2.25 2.25 0 0 1 16.5 21h-6a2.25 2.25 0 0 1-2.25-2.25V15m-3 0-3-3m0 0 3-3m-3 3H15" />
				</svg>
				<button onclick="gotoPage('../logout.jsp')" style="color: black;">ออกจากระบบ</button>
			</div>
		</div>
	</div>
</div>
