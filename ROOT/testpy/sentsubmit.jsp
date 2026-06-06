<%@ page import="java.io.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.servlet.*" %>
<%@ page import= "java.net.URLDecoder" %>


<%
    request.setCharacterEncoding("UTF-8");

    String lab = request.getParameter("lablist");
    String rightid = request.getParameter("rightid");
    String doctorchoos= request.getParameter("doctorchoos");
    String appointdate = request.getParameter("appointdate");
    String choosdate= request.getParameter("choosdate");
    String diac= URLDecoder.decode(request.getParameter("diac"),"UTF-8");
    String note= URLDecoder.decode(request.getParameter("note"),"UTF-8");
    String resu= request.getParameter("resu");
    String per= request.getParameter("per");
    Integer id = (Integer) session.getAttribute("patient_id");
    Integer doctorId  = (Integer) session.getAttribute("user_id");

    
    String main_list = request.getParameter("main_list");
    String main_per = request.getParameter("main_per");
    String main_reason = request.getParameter("main_reason");
    String main_value = request.getParameter("main_value");
    String main_detail = request.getParameter("main_detail");

    String sec_list = request.getParameter("sec_list");
    String sec_per = request.getParameter("sec_per");
    String sec_reason = request.getParameter("sec_reason");
    String sec_value = request.getParameter("sec_value");
    String sec_detail = request.getParameter("sec_detail");


    try {
        String pythonExe = "python";
        String scriptPath = application.getRealPath("./testpy/getsubmit.py");

        ProcessBuilder pb = new ProcessBuilder(
            pythonExe,
            scriptPath,
            lab,
            rightid,
            doctorchoos,
            appointdate,
            choosdate,
            diac,
            note,
            resu,
            per,
            Integer.toString(id),
            Integer.toString(doctorId),

            main_list ,
            main_per ,
            main_reason ,
            main_value ,
            main_detail ,
    
            sec_list ,
            sec_per ,
            sec_reason,
            sec_value,
            sec_detail
        );

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
