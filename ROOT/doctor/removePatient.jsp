<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    session.removeAttribute("patient_id");
    session.removeAttribute("patientCode");
    session.removeAttribute("patientName");
    session.removeAttribute("patientBirthDate");

    response.sendRedirect("main.jsp");
%>
