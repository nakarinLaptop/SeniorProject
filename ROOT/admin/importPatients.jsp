<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%
    String csvText = request.getParameter("csvText");
    String[] lines = csvText.split("\\r?\\n");
    String insertSql = "INSERT INTO patient "
        + "(first_name, last_name, gender, marriage_status, birth_date, phone_num, "
        + "province, district, sub_district, travel_method, occupation, created_at) "
        + "VALUES (?,?,?,?,?,?,?,?,?,?,?,NOW())";

    PreparedStatement stmt = con.prepareStatement(insertSql);
    for (int i = 1; i < lines.length; i++) {
        String[] cols = lines[i].split(",", -1);

        stmt.setString(1, cols[0].trim());
        stmt.setString(2, cols[1].trim());
        stmt.setString(3, cols[2].trim());
        stmt.setString(4, cols[3].trim());
        if (!cols[4].trim().isEmpty()) {
            stmt.setString(5, cols[4].trim());
        } else {
            stmt.setNull(5, java.sql.Types.DATE);
        }
        stmt.setString(6, cols[5].trim());
        stmt.setString(7, cols[6].trim());
        stmt.setString(8, cols[7].trim());
        stmt.setString(9, cols[8].trim());
        stmt.setString(10, cols[9].trim());
        stmt.setString(11, cols[10].trim());
        stmt.executeUpdate();
    }
    stmt.close();

    session.setAttribute("patientTableToast", "นำเข้าข้อมูลสำเร็จ");
    session.setAttribute("patientTableToastType", "success");
    response.sendRedirect("patientTable.jsp");
%>
