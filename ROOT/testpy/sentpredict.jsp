<%@ page import="java.io.*" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.servlet.*" %>

<%
    String lab = request.getParameter("lab");
    String right = request.getParameter("right");
    Integer id = (Integer) session.getAttribute("patient_id");
    try {
        String pythonExe = "python";
        String scriptPath = application.getRealPath("./testpy/predict2.py");

        ProcessBuilder pb = new ProcessBuilder(pythonExe, scriptPath, lab, Integer.toString(id), right);
        pb.redirectErrorStream(true);
        Process process = pb.start();

        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        StringBuilder output = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            output.append(line);
        }
        process.waitFor();

        out.print(output.toString());
    } catch (Exception e) {
        out.print("{\"error\":\"" + e.getMessage() + "\"}");
    }
%>
