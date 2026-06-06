<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.time.*, java.servlet.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>

<%
    Integer doctorId  = (Integer) session.getAttribute("user_id");
    Integer patientId = (Integer) session.getAttribute("patient_id");
    String doctorName = (String) session.getAttribute("doctorName");

    if (doctorId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    String patientCode = ""; 
    if (patientId != null) {
        patientCode = String.format("P%06d", patientId);
    }

    String message = null;
	String errorMessage = null;

    PreparedStatement stmt = null;
	ResultSet rs = null;

    String diac = " ";
    String sqlhomecount = null ; 
    String sqlhoscount = null ;

    List<Map<String, String>> healthcareRights = new ArrayList<>();
    List<Map<String, String>> predictionHistory = new ArrayList<>();

    try {
        String sqlRights = "SELECT right_name FROM patient WHERE patient_id = ? ;" ;
        stmt = con.prepareStatement(sqlRights);
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();

        while (rs.next()) {
            if ( rs != null) {
                Map<String, String> right = new HashMap<>();
                right.put("right_name", rs.getString("right_name"));
                healthcareRights.add(right);
            }
        }

        String sqldiac = "SELECT interview_text FROM ravitee_doctor.medical_history where patient_id = ? And DATE(created_at) = CURDATE() ;" ;
        stmt = con.prepareStatement(sqldiac);
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();

        while (rs.next()) {
            if ( rs != null) {
                diac = rs.getString("interview_text");
            }else{ 
                diac = " " ;
            }
        }


        String sqlhoscountt = "SELECT COUNT(*) FROM ravitee_doctor.prediction where DATE(created_at) = CURDATE() And doctor_selected = 'hospital' ;" ;
        stmt = con.prepareStatement(sqlhoscountt);
        rs = stmt.executeQuery();

        while (rs.next()) {
            if ( rs != null) {
                sqlhoscount = rs.getString("COUNT(*)");
            }else{
                sqlhoscount = "0" ;
            }
        }

        String sqlhomecountt = "SELECT COUNT(*) FROM ravitee_doctor.prediction where DATE(created_at) = CURDATE() And doctor_selected = 'home' ;" ;
        stmt = con.prepareStatement(sqlhomecountt);
        rs = stmt.executeQuery();

        while (rs.next()) {
            if ( rs != null) {
                sqlhomecount = rs.getString("COUNT(*)");
            }else{
                sqlhomecount = "0" ;
            }
        }
        String sqlPredictionHistory =
            "SELECT pred.id, " +
            "CONCAT(d.title, d.first_name,' ', d.last_name) AS doctor_name, " +
            "DATE_FORMAT(pred.appointment_date, '%Y-%m-%d %H:%i:%s') AS appoint_at,pred.doctor_selected, pred.diagnosis, pred.lab_list, " +
            "DATE_FORMAT(pred.created_at, '%Y-%m-%d %H:%i:%s') AS created_at " +
            "FROM prediction pred " +
            "JOIN `user` d ON pred.doctor_id = d.user_id " +
            "WHERE pred.patient_id = ? " +
            "ORDER BY pred.id DESC";
        stmt = con.prepareStatement(sqlPredictionHistory);
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, String> pred = new HashMap<>();
            pred.put("id", rs.getString("id"));
            pred.put("date", rs.getString("created_at"));
            pred.put("doctor", rs.getString("doctor_name"));
            pred.put("predict_result", rs.getString("doctor_selected"));
            pred.put("doctor_selected", rs.getString("diagnosis"));
            pred.put("confident", rs.getString("lab_list"));
            predictionHistory.add(pred);
        }
        rs.close();
        stmt.close();
    } catch(Exception e){
		e.printStackTrace();
	} finally {
		if (rs != null) try { rs.close(); } catch(Exception ignored){}
		if (stmt != null) try { stmt.close(); } catch(Exception ignored){}
		if (con != null) try { con.close(); } catch(Exception ignored){}
	}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
    <link rel="stylesheet" href="../doctor_css/predict.css">
    <link rel="stylesheet" href="../layout.css">
    <style>
        .popup-container {
          position: relative;
          cursor: pointer;
        }
    
        /* Hidden popup by default */
        .popup-text {
          visibility: hidden;
          width: 160px;
          background-color: #333;
          color: #fff;
          text-align: center;
          border-radius: 6px;
          padding: 8px;
          position: absolute;
          z-index: 1;
          bottom: 125%; /* Position above the element */
          left: 50%;
          transform: translateX(-50%);
          opacity: 0;
          transition: opacity 0.3s;
        }
    
        /* Show popup on hover */
        .popup-container:hover .popup-text {
          visibility: visible;
          opacity: 1;
        }
        
        .dropdown {
            position: relative;
            display: inline-block;
        }

        .dropdown-content {
            display: none;
            position: absolute;
            background-color: #f9f9f9;
            min-width: 160px;
            box-shadow: 0px 8px 16px rgba(0,0,0,0.2);
            padding: 10px;
            z-index: 1;
            max-height: 200px;
            max-width: 50px;
        }

        .dropdown:hover .dropdown-content {
            display: block;
        }

        table {
            border-collapse: collapse;
            border: #333 1px solid;
            border-radius: 10%;
            margin: 1rem;
            margin-top: 1rem;
        }
        tr:hover {background-color: #D6EEEE;}
        th, td {
            padding: 16px;
            text-align: left;
            border: 1px solid #DDD;
        }
      </style>

      <script>

        let show = false ;

        main_list = []
        main_per = []
        main_reason = []
        main_value = []
        main_detail = []

        sec_list = []
        sec_per = []
        sec_reason = []
        sec_value = []
        sec_detail = []

        const lab_price = {"BUN" :40,
            "Creatinine" :40,
            "Electrolyte" :100,
            "Glucose" :40,
            "Lipid profile" :200,
            "CBC" :90,
            "ALT" :40,
            "AST" :40,
            "LDL Cholesterol" :150,
            "HbA1c" :150,
            "Uric acid" :60,
            "Tg Thyroglobulin" :400,
            "CPK" :75,
            "Potassium" :40,
            "Calcium" :50,
            "Magnesium" :50,
            "Phosphorus" :50,
            "Sodium" :40,
            "Liver function" :290,
            "HDL Cholesterol" :100,
            "Triglyceride" :60,
            "Alkaline phosphatase" :249,
            "Albumin" :30,
            "Cholesterol" :60,
            "Troponin I" :260,
            "Glucose NaF" :40,
            "FT4" :150,
            "TSH" :170,
            "FT3" :170,
            "Glucose Strip" :40,
            "NT-pro BNP" :1300,
            "Blood gas analysis" :195,
            "Anti HIV" :120,
            "Lactate" :150,
            "Anti HCV" :300,
            "Anti HBs" :150,
            "HBs Ag" :130,
            "Hemoculture : แขน" :300,
            "Iron" :100,
            "Total Iron-binding capacity(TIBC)" :80,
            "Total Bilirubin" :40,
            "Direct Bilirubin" :40,
            "Globulin" :30,
            "Total protein" :60,
            "Ferritin" :310,
            "Unsaturated Iron-binding capacity(UIBC)" :80,
            "%Iron Saturation" :100,
            "PSA" :300,
            "Blood Group ABO" :40,
            "Rh(D) Typing" :270,
            "X-Matching" :60,
            "ESR" :50,
            "Gamma-GT" :150,
            "Ketone" :150,
            "Vitamin D" :900,
            "AFP" :250,
            "CEA" :280,
            "CA 19-9" :550,
            "hsC-Reactive protein" :250,
            "LDH" :60,
            "Osmolality" :130,
            "Direct Antiglobulin Test" :90,
            "Indirect Antiglobulin Test" :120,
            "Anion Gap" :40,
            "CO2" :40,
            "Chloride" :40,
            "Intact Parathyroid hormone" :210,
            "%CD4" :500,
            "Absolute CD4" :600,
            "CK-MB" :90,
            "RPR" :50,
            "Cyclosporine (CSA)" :1000,
            "Digoxin" :240,
            "Reticulocyte count" :40,
            "ANA" :450,
            "Anti HBc Total" :200,
            "FPSA" :400,
            "Fructosamine" :120,
            "Anti-TPO" :150,
            "Anti-Tg" :400,
            "Hemoglobin Typing" :270,
            "Phenytoin" :300,
            "T3" :150,
            "T4" :150,
            "Tacrolimus" :1000,
            "Anti HAV (IgG)" :500,
            "Anti HAV (IgM)" :200,
            "Anti Hbe" :180,
            "Anti HIV (Rapid Test)" :220,
            "Anti HAV IgM" :500,
            "Anti-Beta-2 glycoprotein 1 IgG" :300,
            "Anti-Beta-2 glycoprotein 1 IgM" :300,
            "Anti-CCP" :480,
            "Anti-Cardiolipin IgG" :240,
            "Anti-Cardiolipin IgM" :250,
            "Anti-La(SS-B)" :400,
            "Anti-Myeloperoxidase" :310,
            "Anti-Proteinase3" :550,
            "Anti-Ro(SS-A)" :400,
            "Anti-Scl 70" :270,
            "Anti-Streptolysin O" :110,
            "Anti-glomerular basement membrane" :750,
            "Anti dsDNA" :210,
            "Anti nRNP" :350,
            "Anti Sm" :270,
            "ARR" :720,
            "Aldosterone" :720,
            "Anti-mitochondria Antibody(AMA)" :300,
            "Beta-CrossLap" :480,
            "CA 125" :550,
            "CA 15-3" :200,
            "Complement C3" :250,
            "Cortisol II" :250,
            "Cystatin C" :330,
            "Direct Renin" :800,
            "Estradiol (E2)" :170,
            "Follicle-stimulating hormone" :135,
            "FTA-ABS (IgG)" :200,
            "FTA-ABS (IgM)" :200,
            "HB" :60,
            "HCT" :60,
            "HBe Ag" :180,
            "HBs Ag (Quantitative)" :600,
            "Helicobacter pylori Ab" :500,
            "Hemoglobin A" :270,
            "Hemoglobin A2" :270,
            "Hemoglobin E" :270,
            "Hemoglobin F" :270,
            "Hemoculture : ขวด" :300,
            "Immunoglobulin IgA" :350,
            "Immunoglobulin IgG" :350,
            "Immunoglobulin IgM" :350,
            "Inclusion bodies test" :40,
            "Lipase" :200,
            "Luteinizing hormone" :190,
            "MCH" :0,
            "MCHC" :0,
            "MCV" :0,
            "Procalcitonin (PCT)" :600,
            "Prolactin" :300,
            "RBC" :0,
            "RDW" :0,
            "Rheumatoid factor" :80,
            "Syphilis(CMIA)" :50,
            "Testosterone" :190,
            "Toxoplasma IgG" :250,
            "Valproic acid" :300,
            "Beta HCG" :160,
            "100 gm OGTT" :300,
            "Vancomycin" :300,
            "SARS-CoV2 IgG Quantitative" :4000,
            "Smooth muscles Ab (ASMA)" :300,
            "Panel-a" :0,
            "Panel-c" :0,
            "Serum Protein Electrophoresis" :350,
            "Valproic acid (Depakin)" :300,
            "Glucose NaF 2hrs" :40,
            "Lipoprotein (a)" :250,
            "SARS-CoV2 IgM Ab" :2200,
            "SARS-CoV2 anti-NP IgG CMIA" :4000,
            "Dengue IgG+IgM" :520,
            "Dengue NS1 Ag" :260,
            "Anti-centromere" :300,
            "G6PD Screening Test" :1100,
            "DNA for Alpha- thalassemia 1 and 2 (Blood)" :800,
            "Renin Activity (PRA):Calculated" :800,
            "Herpes Simplex IgG" :1400,
            "Varicella zoster IgG" :300,
            "Epstein-Barr IgG" :300,
            "Epstein-Barr IgM" :300,
            "CMV IgG" :250,
            "CMV IgM" :250,
            "DCIP" :70,
            "Complement C4 level" :300,
            "Anti-TSHR" :400,
            "Beta 2 Microglobulin" :480,
            "Interleukin 6 (IL-6)" :800,
            "Anti-PLA-2R" :1300,
            "Everolimus" :1100,
            "LE Test" :170,
            "ANA Profile 1" :1280,
            "Vitamin B12 (Cabalamins)" :240,
            "Myophaties 18 Ag (Myositis Profile 18 Ag)" :3350,
            "Erythropoietin level (EPO)" :250,
            "Osmolality (Serum)" :130,
            "Tacrolimus (Prograf)" :1000,
        };


        function showInput(){
            let checkboxes = document.querySelectorAll('input[name="lab"]:checked');
            let lablist = Array.from(checkboxes).map(cb => cb.value);
            let rightselect = document.getElementById('rightselect').value;
            //let predictresult = document.getElementsByName('input[name="doctorchoos"]:checked')
            let doctorchoos = document.querySelector('input[name="doctor_choose"]:checked').value;
            let appointdate = document.getElementById('appointdate').value;
            let choosdate = document.getElementById('choosdate').value;
            let diac = document.getElementById('diac').value;
            let note = document.getElementById('note').value;
            let resu = document.getElementById('hh').value;
            let per = document.getElementById('pp').value;
            let main_l = document.getElementsByClassName('main_l').value ;


            console.log(lablist);
            console.log(rightselect); 
            console.log(doctorchoos);
            console.log(appointdate); 
            console.log(choosdate);
            console.log(diac); 
            console.log(note);
            console.log(resu); 
            console.log(per);
            console.log(main_l);

            let params = new URLSearchParams({
                lablist: lablist,
                rightid: rightselect,
                doctorchoos: doctorchoos,
                appointdate: appointdate,
                choosdate: choosdate,
                diac: diac,
                note: note,
                resu: resu,
                per: per
            });

            console.log(params.toString())

        }


        function printuncheck(){
            const checkboxes = document.querySelectorAll('input[name="lab"]');
            const values = Array.from(checkboxes).map(cb => cb.value);
            console.log(values);
        }

        function resetresult(){
            home_temp = document.getElementById('main_list'); 
            hos_temp = document.getElementById('sec_list'); 
            home_temp.innerHTML = "" ;
            hos_temp.innerHTML = "" ; 
        }

        function showlab(values){
            let tab = document.getElementById('tab'); 
            temp = values[0]
            for(i=0;i<values.length;i+=1){
                console.log(values[i])
                tab.innerHTML +=
                "<tr>" +
                    "<th><input type='checkbox'></th>" +
                    "<th style='color:#333'>" + values[i] + "</th>" +
                    "<th></th>" +
                "</tr>";

            }
        }
        function getresult(values,right){
            let params = new URLSearchParams({
                lab : values,
                right : right
            });

            show = true ;

            fetch("../testpy/sentpredict.jsp?" + params.toString())
                .then(response => response.json())
                .then(data => {
                    console.log("Raw Response:", data);
                    resu = document.getElementById('hh');
                    per = document.getElementById('pp'); 
                    home_temp = document.getElementById('main_list'); 
                    hos_temp = document.getElementById('sec_list'); 
                    main_ti = document.getElementById('main_title'); 
                    sec_ti = document.getElementById('sec_title'); 
                    resupre = document.getElementById('predictionResult'); 

                    resupre.style.display = "block";

                    main_list = data.main_list
                    main_per = data.main_per
                    main_reason = data.main_reason
                    main_detail = data.main_detail
                    main_value = data.main_list

                    sec_list = data.sec_list
                    sec_per = data.sec_per
                    sec_reason = data.sec_reason
                    sec_detail = data.sec_detail
                    sec_value = data.sec_list



                    if (data.home > data.hos) {
                        resu.innerHTML = "สนันสนุนให้ตรวจที่บ้าน</br>ความมั่นใจในการทำนาย : " ;
                        resu.innerHTML += (data.home*100).toFixed(2) ;
                        resu.innerHTML += "%";
                        main_ti.innerHTML = "ปัจจัยที่สนับสนุนให้ตรวจที่บ้าน"
                        sec_ti.innerHTML = "ปัจจัยที่สนับสนุนให้ตรวจที่โรงพยาบาล"
                        resu.value = "home" ;
                        per.value = (data.home*100).toFixed(2) ;

                    }else{
                        resu.innerHTML = "สนันสนุนให้ตรวจที่โรงพยาบาล</br>ความมั่นใจในการทำนาย : " ;
                        resu.innerHTML += (data.hos*100).toFixed(2) ;
                        resu.innerHTML += "%";
                        sec_ti.innerHTML = "ปัจจัยที่สนับสนุนให้ตรวจที่บ้าน"
                        main_ti.innerHTML = "ปัจจัยที่สนับสนุนให้ตรวจที่โรงพยาบาล"
                        resu.value = "hospital" ;
                        per.value = (data.hos*100).toFixed(2) ;
                    }
    
                    for(i=0;i<data.main_list.length;i+=1){     
                        home_temp.innerHTML += 
                        "<tr>" + 
                            "<td class='popup-container '>" + data.main_list[i] + "<div class='popup-text'>" + data.main_list[i] + "</div></td>" +
                            "<td class='popup-container '>" + data.main_detail[i] + "<div class='popup-text'>" + data.main_per[i].toFixed(2) + "%</div></td>" +
                            "<td class='ok popup-container'><span class='check main_r'>" + data.main_reason[i] +
                            "</span></td>" + 
                        "</tr>";
                    }

                    for(i=0;i<data.sec_list
                    .length;i+=1){
                        hos_temp.innerHTML += 
                        "<tr>" +
                            "<td class='popup-container '>" + data.sec_list[i] + "<div class='popup-text'>" + data.sec_list[i] + "</div></td>" +
                            "<td class='popup-container '>" + data.sec_detail[i] + "<div class='popup-text'>" + data.sec_per[i].toFixed(2) + "%</div></td>" +
                            "<td class='ok popup-container'><span class='check sec_r'>" + data.sec_reason[i] +
                            "</span></td>" +
                        "</tr>";
                
                    }
                })
                .catch(error => console.error("Error:", error));

        }

        function openLabSelection() {
            document.getElementById("lablistbox").style.display = "block";
            document.getElementById("selectedUnit1").style.display = "none";
        }

        function closeLabSelection() {
            document.getElementById("selectedUnit1").style.display = "block";
            document.getElementById("lablistbox").style.display = "none";
        }

        function showre(){
            const checkboxes = document.querySelectorAll('input[name="lab"]:checked');
            if(checkboxes.length != 0){
                const values = Array.from(checkboxes).map(cb => cb.value);
                const right = document.getElementById('rightselect').value;
                console.log(document.getElementById('rightselect'))
                resetresult()
                getresult(values,right)
                show = true ;
            }else{
                alert("โปรดเลือกรายการตรวจ")
            }
        }

        function resetlab(){
            let tab = document.getElementById('tab'); 

            tab.innerHTML = `
                    <thead>
                       <tr style="background-color: #007bff; color: #fff;">
                            <th></th>
                            <th style="text-align: center;">รายการตรวจ</th>
                            <th style="text-align: center;">ราคา</th>
                        </tr>
                    </thead>
             `;
        }

        function submitlab(){
            resetlab()
            closeLabSelection() 
            const checkboxes = document.querySelectorAll('input[name="lab"]:checked');
            const values = Array.from(checkboxes).map(cb => cb.value);
            let tab = document.getElementById('tab'); 
            temp = values[0]
            for(i=0;i<values.length;i+=1){

                tab.innerHTML +=
                "<tr>" +
                    "<th style='text-align: center;'><input name = 'cut' value = '"+ values[i] +"' type='checkbox'></th>" +
                    "<th style='color:#333'>" + values[i] + "</th>" +
                    "<th>"+ lab_price[values[i]] +"</th>" + 
                "</tr>";
            }

            tab.innerHTML +=
                "<tr>" +
                    "<th style='text-align: center;'><button onclick='cutlab()'>นำออก</button></th>" +
                    "<th></th>" +
                    "<th></th>" + 
                "</tr>";
        }

        function cutlab() { 
            let checkboxes = document.querySelectorAll('input[name="lab"]:checked');
            let cutbox = document.querySelectorAll('input[name="cut"]:checked');
            let cutvalue = Array.from(cutbox).map(cb => cb.value);
            checkboxes.forEach(cb => {
                if (cutvalue.includes(cb.value)) {
                    cb.checked = false;
                }
             });
            submitlab()
        }

        function getlab(list){

            let checkboxes = document.querySelectorAll('input[name="lab"]:checked');   
            checkboxes.forEach(e => {
                e.checked = false ; 
            });
            

            let lab_list = list.split(",");

            console.log(lab_list)

            checkboxes = document.querySelectorAll('input[name="lab"]');   
            checkboxes.forEach(cb => {
                if (lab_list.includes(cb.value)) {
                    cb.checked = true;
                }
            });
            submitlab()
            closePredictionHistory()
        }

        function submitappoint() {

            let checkboxes = document.querySelectorAll('input[name="lab"]:checked');
            let lablist = Array.from(checkboxes).map(cb => cb.value);
            let rightselect = document.getElementById('rightselect').value;
            //let predictresult = document.getElementsByName('input[name="doctorchoos"]:checked')
            let doctorchoos = document.querySelector('input[name="doctor_choose"]:checked').value
            let appointdate = document.getElementById('appointdate').value
            let choosdate = document.getElementById('choosdate').value
            let diac = document.getElementById('diac').value
            let note = document.getElementById('note').value
            let resu = document.getElementById('hh').value
            let per = document.getElementById('pp').value
            if (!note) {
                note = " ";
            }
            if (!diac){
                diac= " ";
            }



            let params = new URLSearchParams({
                lablist: lablist,
                rightid: rightselect,
                doctorchoos: doctorchoos,
                appointdate: appointdate,
                choosdate: choosdate,
                diac: diac,
                note: note,
                resu: resu,
                per: per,
                main_list : main_list,
                main_per : main_per,
                main_reason :  main_reason,
                main_value:  main_value,
                main_detail:   main_detail ,
                sec_list:   sec_list,
                sec_per:     sec_per,
                sec_reason :  sec_reason,
                sec_value : sec_value,
                sec_detail :  sec_detail

            });

            if(lablist.length == 0){
                alert('โปรดเลือกรายการตรวจ');
            }else{
                console.log(rightselect)
                document.getElementById("selectedUnit1").style.display = "none";
                document.getElementById("sucses").style.display = "block";
                fetch("../testpy/sentsubmit.jsp", {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded"
                },
                body: params.toString()
                }).then(response => response.text())
                .then(data => {
                    console.log(data)
                    alert('บันทึกสำเร็จ');
                    location.href = "http://d.fnnovation.com/doctor/prescription.jsp"
                });
            }
            
        }

        function showPredictionHistory() {
            const primaryContent = document.getElementById("content1") || document.querySelector("body > .content");
            const historyContent = document.getElementById("content2");
            const section = document.getElementById("predictionHistorySection");
            if (!section) {
                return;
            }

            if (primaryContent) {
                primaryContent.style.display = "none";
            }
            if (historyContent) {
                historyContent.style.display = "block";
            }

            section.style.display = "block";
            section.scrollIntoView({ behavior: "smooth", block: "start" });
        }

        function closePredictionHistory() {
            const primaryContent = document.getElementById("content1") || document.querySelector("body > .content");
            const historyContent = document.getElementById("content2");
            const section = document.getElementById("predictionHistorySection");
            if (!section) {
                return;
            }

            section.style.display = "none";
            if (historyContent) {
                historyContent.style.display = "none";
            }
            if (primaryContent) {
                primaryContent.style.display = "";
            }
        }

        function filterPredictionHistory() {
            const searchDate = (document.getElementById("searchPredictionDate")?.value || "").toLowerCase();
            const searchDoctor = (document.getElementById("searchPredictionDoctor")?.value || "").toLowerCase();
            const searchResult = (document.getElementById("searchPredictionResult")?.value || "").toLowerCase();
            const searchSelected = (document.getElementById("searchPredictionSelected")?.value || "").toLowerCase();

            const rows = document.querySelectorAll("#predictionHistoryBody tr[data-history='true']");
            let hasVisible = false;

            rows.forEach((row) => {
                const dateValue = (row.getAttribute("data-date") || "").toLowerCase();
                const doctorValue = (row.getAttribute("data-doctor") || "").toLowerCase();
                const resultValue = (row.getAttribute("data-result") || "").toLowerCase();
                const selectedValue = (row.getAttribute("data-selected") || "").toLowerCase();

                const isMatch = dateValue.includes(searchDate)
                    && doctorValue.includes(searchDoctor)
                    && resultValue.includes(searchResult)
                    && selectedValue.includes(searchSelected);

                row.style.display = isMatch ? "" : "none";
                if (isMatch) {
                    hasVisible = true;
                }
            });

            const emptyStateRows = document.querySelectorAll("#predictionHistoryBody tr[data-empty='true']");
            emptyStateRows.forEach((row) => {
                row.style.display = hasVisible ? "none" : "";
            });
        }
        </script>
</head>
<body>
	<%
	request.setAttribute("activePage", "predict");
	request.setAttribute("pageTitle", "เลือกรายการตรวจแล็บและทำนายสถานที่เก็บสิ่งส่งตรวจ");
	%>
    <jsp:include page="../include/navbar.jsp" />
    <jsp:include page="../include/header.jsp" />
    
    <div class="content">                                   
        <div id="lablistbox">
            <div class="lablistHeader">
                <button onclick="closeLabSelection()">กลับ</button>
                <h2>รายชื่อแล็บ</h2>
                <button onclick="resetCheckbox()">รีเซ็ตการเลือกแล็บ</button>
            </div>
            
            <div class="tab">
                <button class="tablinks active" onclick="openTab(event, 'tabChem')">งานเคมีคลินิก</button>
                <button class="tablinks" onclick="openTab(event, 'tabHemo')">งานโลหิตวิทยาและจุลทรรศนศาสตร์</button>
                <button class="tablinks" onclick="openTab(event, 'tabImmu')">งานภูมิคุ้มกันวิทยา</button>
                <button class="tablinks" onclick="openTab(event, 'tabBlood')">งานธนาคารเลือด</button>
                <button class="tablinks" onclick="openTab(event, 'tabMicro')">งานจุลชีววิทยา</button>
                <button class="tablinks" onclick="openTab(event, 'tabMole')">งานอนูชีววิทยา</button>
                <button class="tablinks" onclick="openTab(event, 'งานมนุษย์พันธุศาสตร์')">งานมนุษย์พันธุศาสตร์</button>
            </div>
            <div class="tab-content">
                <!-- A. Clinical Chemistry -->
                <div id="tabChem" class="checkbox-group">
                    <div class="lab-sub">
                        <h3>Electrolyte</h3>
                        <label><input type="checkbox" name="lab" value="Sodium"> Sodium</label><br>
                        <label><input type="checkbox" name="lab" value="Potassium"> Potassium</label><br>
                        <label><input type="checkbox" name="lab" value="Chloride"> Chloride</label><br>
                        <label><input type="checkbox" name="lab" value="CO2"> CO2</label><br>
                        <label><input type="checkbox" name="lab" value="Anion Gap"> Anion Gap</label><br>
                    </div>
                    <div class="lab-sub">
                        <h3>Lipid Profile</h3>
                        <label><input type="checkbox" name="lab" value="HDL Cholesterol"> HDL Cholesterol</label><br>
                        <label><input type="checkbox" name="lab" value="LDL Cholesterol"> LDL Cholesterol</label><br>
                        <label><input type="checkbox" name="lab" value="Triglyceride"> Triglyceride</label><br>
                        <label><input type="checkbox" name="lab" value="Cholesterol"> Cholesterol</label><br>
                        <label><input type="checkbox" name="lab" value="Lipoprotein (a)"> Lipoprotein (a)</label><br>
                    </div>
                    <div class="lab-sub">
                        <h3>Panel-a</h3>
                        <label><input type="checkbox" name="lab" value="BUN"> BUN</label><br>
                        <label><input type="checkbox" name="lab" value="Creatinine"> Cre</label><br>
                        <label><input type="checkbox" name="lab"  value="Uric acid"> Uric</label><br>
                    </div>
                    <div class="lab-sub">
                        <h3>Panel-c</h3>
                        <label><input type="checkbox" name="lab" value="Calcium"> Cal</label><br>
                        <label><input type="checkbox" name="lab" value="Phosphorus"> Phos</label><br>
                        <label><input type="checkbox" name="lab" value="Magnesium"> Mg</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Glucose"> Glucose</label><br>
                        <label><input type="checkbox" name="lab" value="Glucose NaF"> Glucose NaF</label><br>
                        <label><input type="checkbox" name="lab" value="Glucose NaF 2hrs"> Glucose NaF 2hrs</label><br>
                        <label><input type="checkbox" name="lab" value="Glucose Strip"> Glucose Strip</label><br>
                    </div>
                    
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="ALT"> ALT</label><br>
                        <label><input type="checkbox" name="lab" value="AST"> AST</label><br>
                        <label><input type="checkbox" name="lab" value="Gamma-GT"> Gamma-GT</label><br>
                        <label><input type="checkbox" name="lab" value="Alkaline phosphatase"> Alkaline phosphatase</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Albumin"> Albumin</label><br>
                        <label><input type="checkbox" name="lab" value="Globulin"> Globulin</label><br>
                        <label><input type="checkbox" name="lab" value="Total protein"> Total protein</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="CPK"> CPK</label><br>
                        <label><input type="checkbox" name="lab" value="CK-MB"> CK-MB</label><br>
                        <label><input type="checkbox" name="lab" value="Troponin I"> Troponin I</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Iron"> Iron</label><br>
                        <label><input type="checkbox" name="lab" value="Ferritin"> Ferritin</label><br>
                        <label><input type="checkbox" name="lab" value="Total Iron-binding capacity(TIBC)"> Total Iron-binding capacity (TIBC)</label><br>
                        <label><input type="checkbox" name="lab" value="Unsaturated Iron-binding capacity(UIBC)"> Unsaturated Iron-binding capacity (UIBC)</label><br>
                        <label><input type="checkbox" name="lab" value="%Iron Saturation">%Iron Saturation</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Total Bilirubin"> Total Bilirubin</label><br>
                        <label><input type="checkbox" name="lab" value="Direct Bilirubin"> Direct Bilirubin</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Vitamin D"> Vitamin D</label><br>
                        <label><input type="checkbox" name="lab" value="Vitamin B12 (Cabalamins)"> Vitamin B12</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="PSA"> PSA</label><br>
                        <label><input type="checkbox" name="lab" value="FPSA"> FPSA</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Beta HCG"> Beta HCG</label><br>
                        <label><input type="checkbox" name="lab" value="AFP"> AFP</label><br>
                        <label><input type="checkbox" name="lab" value="CEA"> CEA</label><br>
                        <label><input type="checkbox" name="lab" value="CA 19-9"> CA 19-9</label><br>
                        <label><input type="checkbox" name="lab" value="CA 125"> CA 125</label><br>
                        <label><input type="checkbox" name="lab" value="CA 15-3"> CA 15-3</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="hsC-Reactive protein"> hsC-Reactive protein (hsCRP)</label><br>
                        <label><input type="checkbox" name="lab" value="Procalcitonin (PCT)"> Procalcitonin (PCT)</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="LDH"> LDH</label><br>
                        <label><input type="checkbox" name="lab" value="Osmolality (Serum)"> Osmolality (Serum)</label><br>
                        <label><input type="checkbox" name="lab" value="Anion Gap"> Anion Gap</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Beta 2 Microglobulin"> Beta 2 Microglobulin</label><br>
                        <label><input type="checkbox" name="lab" value="Beta-crosslaps"> Beta-crosslaps</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Cortisol II"> Cortisol II</label><br>
                        <label><input type="checkbox" name="lab" value="Aldosterone"> Aldosterone</label><br>
                        <label><input type="checkbox" name="lab" value="Erythropoietin level (EPO)"> Erythropoietin level (EPO)</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Estradiol (E2)"> Estradiol (E2)</label><br>
                        <label><input type="checkbox" name="lab" value="Follicle-stimulating hormone"> Follicle-stimulating hormone</label><br>
                        <label><input type="checkbox" name="lab" value="Luteinizing hormone"> Luteinizing hormone</label><br>
                        <label><input type="checkbox" name="lab" value="Prolactin"> Prolactin</label><br>
                        <label><input type="checkbox" name="lab" value="Testosterone"> Testosterone</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Cyclosporine (CSA)"> Cyclosporine (CSA)</label><br>
                        <label><input type="checkbox" name="lab" value="Digoxin"> Digoxin</label><br>
                        <label><input type="checkbox" name="lab" value="Tacrolimus (Prograf)"> Tacrolimus (Prograf)</label><br>
                        <label><input type="checkbox" name="lab" value="Everolimus"> Everolimus</label><br>
                        <label><input type="checkbox" name="lab" value="Vancomycin"> Vancomycin</label><br>
                        <label><input type="checkbox" name="lab" value="Valproic acid"> Valproic acid</label><br>
                        <label><input type="checkbox" name="lab" value="Valproic acid (Depakin)"> Valproic acid (Depakin)</label><br>
                        <label><input type="checkbox" name="lab" value="Phenytoin"> Phenytoin</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Renin Activity (PRA):Calculated"> Renin Activity (PRA): Calculated</label><br>
                        <label><input type="checkbox" name="lab" value="Direct Renin"> Direct Renin</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Liver function"> Liverfunction (รวม panel ของ liver)</label>
                        <label><input type="checkbox" name="lab" value="HbA1c"> HbA1c</label>
                        <label><input type="checkbox" name="lab" value="Lactate"> Lactate</label>
                        <label><input type="checkbox" name="lab" value="Fructosamine"> Fructosamine</label>
                        <label><input type="checkbox" name="lab" value="Intact Parathyroid hormone"> Intact Parathyroid hormone</label>
                        <label><input type="checkbox" name="lab" value="Cystatin C"> Cystatin C</label>
                        <label><input type="checkbox" name="lab" value="Serum Protein Electrophoresis"> Serum Protein Electrophoresis</label>
                    </div>
                </div>

                <!-- B. Hematology and Microscopy -->
                <div id="tabHemo" class="checkbox-group">
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Hemoglobin Typing"> Hemoglobin Typing</label><br>
                        <label><input type="checkbox" name="lab" value="Hemoglobin A"> Hemoglobin A</label><br>
                        <label><input type="checkbox" name="lab" value="Hemoglobin A2"> Hemoglobin A2</label><br>
                        <label><input type="checkbox" name="lab" value="Hemoglobin E"> Hemoglobin E</label><br>
                        <label><input type="checkbox" name="lab" value="Hemoglobin F"> Hemoglobin F</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="RBC"> RBC</label><br>
                        <label><input type="checkbox" name="lab" value="RDW"> RDW</label><br>
                        <label><input type="checkbox" name="lab" value="MCV"> MCV</label><br>
                        <label><input type="checkbox" name="lab" value="MCH"> MCH</label><br>
                        <label><input type="checkbox" name="lab" value="MCHC"> MCHC</label><br>
                        <label><input type="checkbox" name="lab" value="HCT"> HCT</label><br>
                        <label><input type="checkbox" name="lab" value="HB"> HB</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="CBC"> CBC (Complete Blood Count)</label>
                        <label><input type="checkbox" name="lab" value="Reticulocyte count"> Reticulocyte count</label>
                        <label><input type="checkbox" name="lab" value="ESR"> ESR (Erythrocyte Sedimentation Rate)</label>
                        <label><input type="checkbox" name="lab" value="Inclusion bodies test"> Inclusion bodies test</label>
                        <label><input type="checkbox" name="lab" value="G6PD Screening Test"> G6PD Screening Test</label>
                        <label><input type="checkbox" name="lab" value="DCIP"> DCIP</label>
                        <label><input type="checkbox" name="lab" value="LE Test"> LE Test</label>
                    </div>
                </div>

                <!-- C. Immunology -->
                <div id="tabImmu" class="checkbox-group">
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti HIV"> Anti HIV</label><br>
                        <label><input type="checkbox" name="lab" value="Anti HIV (Rapid Test)">  Anti HIV (Rapid Test)</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti HCV"> Anti HCV</label><br>
                        <label><input type="checkbox" name="lab" value="Anti HBs"> Anti HBs</label><br>
                        <label><input type="checkbox" name="lab" value="Anti HBc Total"> Anti HBc Total</label><br>
                        <label><input type="checkbox" name="lab" value="HBs Ag"> HBs Ag</label><br>
                        <label><input type="checkbox" name="lab" value="HBs Ag (Quantitative)"> HBs Ag (Quantitative)</label><br>
                        <label><input type="checkbox" name="lab" value="HBe Ag"> HBe Ag</label><br>
                        <label><input type="checkbox" name="lab" value="Anti Hbe"> Anti Hbe</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="ANA"> ANA</label><br>
                        <label><input type="checkbox" name="lab" value="ANA Profile 1"> ANA Profile 1</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti-TSHR"> Anti-TSHR</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-TPO"> Anti-TPO</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Tg"> Anti-Tg</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="%CD4">%CD4</label><br>
                        <label><input type="checkbox" name="lab" value="Absolute CD4"> Absolute CD4</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Immunoglobulin IgA"> Immunoglobulin IgA</label><br>
                        <label><input type="checkbox" name="lab" value="IgG"> IgG</label><br>
                        <label><input type="checkbox" name="lab" value="IgM"> IgM</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Complement C3"> Complement C3</label><br>
                        <label><input type="checkbox" name="lab" value="Complement C4 level"> Complement C4 level</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti-CCP"> Anti-CCP</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Cardiolipin IgG"> Anti-Cardiolipin IgG/IgM</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti-La(SS-B)"> Anti-La(SS-B)</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Ro(SS-A)"> Anti-Ro(SS-A)</label><br>
                        <label><input type="checkbox" name="lab" value="Anti Sm"> Anti-Sm</label><br>
                        <label><input type="checkbox" name="lab" value="Anti nRNP"> Anti nRNP</label><br>
                        <label><input type="checkbox" name="lab" value="Anti dsDNA"> Anti dsDNA</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-glomerular basement membrane"> Anti-glomerular basement membrane</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Streptolysin O"> Anti-Streptolysin O</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Myeloperoxidase"> Anti-Myeloperoxidase</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Proteinase3"> Anti-Proteinase3</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-centromere"> Anti-centromere</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-PLA-2R"> Anti-PLA-2R</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="SARS-CoV2 IgG Quantitative"> SARS-CoV2 IgG Quantitative</label><br>
                        <label><input type="checkbox" name="lab" value="SARS-CoV2 IgM Ab"> SARS-CoV2 IgM Ab</label><br>
                        <label><input type="checkbox" name="lab" value="SARS-CoV2 anti-NP IgG CMIA"> SARS-CoV2 anti-NP IgG CMIA</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Dengue IgG+IgM"> Dengue IgG+IgM</label><br>
                        <label><input type="checkbox" name="lab" value="Dengue NS1 Ag"> Dengue NS1 Ag</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Epstein-Barr IgG"> Epstein-Barr IgG</label><br>
                        <label><input type="checkbox" name="lab" value="Epstein-Barr IgM"> Epstein-Barr IgM</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="CMV IgG"> CMV IgG</label><br>
                        <label><input type="checkbox" name="lab" value="CMV IgM"> CMV IgM</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="FTA-ABS (IgG)"> FTA-ABS (IgG)</label><br>
                        <label><input type="checkbox" name="lab" value="FTA-ABS (IgM)"> FTA-ABS (IgM)</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti HAV (IgG)"> Anti HAV (IgG)</label><br>
                        <label><input type="checkbox" name="lab" value="Anti HAV (IgM)"> Anti HAV (IgM)</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" id="RheumatoidFactor" value="Rheumatoid factor"> Rheumatoid factor</label>
                        <label><input type="checkbox" name="lab" value="Smooth muscles Ab (ASMA)"> Smooth muscles Ab (ASMA)</label>
                        <label><input type="checkbox" name="lab" value="Anti-mitochondria Antibody(AMA)"> Anti-mitochondria Antibody (AMA)</label>
                        <label><input type="checkbox" name="lab" value="hsC-Reactive protein"> hsC-Reactive protein</label>
                        <label><input type="checkbox" name="lab" value="Interleukin 6 (IL-6)"> Interleukin 6 (IL-6)</label>
                        <label><input type="checkbox" name="lab" value="Anti-Beta-2 glycoprotein 1 IgM"> Anti-Beta-2 glycoprotein 1 IgG/IgM</label>
                        <label><input type="checkbox" name="lab" value="Procalcitonin (PCT)"> Procalcitonin (PCT)</label>
                        <label><input type="checkbox" name="lab" value="Toxoplasma IgG"> Toxoplasma IgG</label>
                        <label><input type="checkbox" name="lab" value="Herpes Simplex IgG"> Herpes Simplex IgG</label>
                        <label><input type="checkbox" name="lab" value="Varicella zoster IgG"> Varicella zoster IgG</label>
                        <label><input type="checkbox" name="lab" value="Beta 2 Microglobulin"> Beta 2 Microglobulin</label>
                    </div>
                </div>

                <!-- D. Blood Bank -->
                <div id="tabBlood" class="checkbox-group">
                    <label><input type="checkbox" name="lab" value="Blood Group ABO"> Blood Group ABO</label>
                    <label><input type="checkbox" name="lab" value="Rh(D) Typing"> Rh(D) Typing</label>
                    <label><input type="checkbox" name="lab" value="X-Matching"> X-Matching (Crossmatching)</label>
                    <label><input type="checkbox" name="lab" value="Direct Antiglobulin Test"> Direct Antiglobulin Test</label>
                    <label><input type="checkbox" name="lab" value="Indirect Antiglobulin Test"> Indirect Antiglobulin Test</label>
                </div>

                <!-- E. Microbiology -->
                <div id="tabMicro" class="checkbox-group">
                    <label><input type="checkbox" name="lab" value="Hemoculture : ขวด"> Hemoculture : ขวด</label>
                    <label><input type="checkbox" name="lab" value="Hemoculture : แขน"> Hemoculture : แขน</label>
                </div>

                <!-- F. Molecular Biology -->
                <div id="tabMole" class="checkbox-group">
                    <label><input type="checkbox" name="lab" value="DNA for Alpha- thalassemia 1 and 2 (Blood)"> DNA for Alpha-thalassemia 1 and 2 (Blood)</label>
                    <label><input type="checkbox" name="lab" value="Myophaties 18 Ag (Myositis Profile 18 Ag)"> Myophaties 18 Ag (Myositis Profile 18 Ag)</label>
                </div>
            </div> 

            <%-- <div id="result"></div> --%>
            <button id="predictButton" onclick="submitlab()">ตกลง</button>
        </div>

        <div id="sucses" style="display: none;">
            <div style="display: flex; justify-content: center; align-items: center; font-size: 50px; color: #333;">
                รอสักครู่
            </div>
        </div>

        <div class="selectedUnit" id="selectedUnit1">
            <div id="SelectUnitTitle">
                <h2 class="section-title">การส่งตรวจภายนอก</h2>
            </div>
            <div id="formSelectUnit">
                <div class="form-grid">
        
                        <div class="form-item">
                            <label>วันที่ส่งตรวจ:</label>
                            <input type="datetime-local" id="choosdate" name="dateTime"
               value="<%= LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")) %>">
                        </div>
        
                        <div class="form-item">
                            <label>แพทย์ผู้ส่งตรวจ:</label>
                            <select>
                                <option>
                                    <%= doctorName %></option>

                            </select>
                        </div>
                        <div class="form-item">
                            
                        </div>

                        <div class="form-item">
                            <label>วันที่ขอตรวจ:</label>
                            <input type="datetime-local" id="appointdate" name="dateTime"  value="<%= LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")) %>">
                            <!--<a style="background-color: #333; color: #fff; padding: 0.5rem; border-radius: 10px; cursor: pointer;">ดูรายการตรวจ</a>-->
                        </div>
        
        
                        <div class="form-item">
                            <label>สิทธิการรักษา:</label>
                            <select id="rightselect">
                                <% for (Map<String, String> right : healthcareRights) { 
                                    if (right.get("right_name") != null) { %>
                                        <option value="<%=right.get("right_name")%>">
                                            <%= right.get("right_name") %>
                                        </option>
                                <%} 
                                } %>
                             
                                <option value="ชำระเงินเอง">
                                    ชำระเงินเอง
                                </option>
                            </select>
                        </div>
        
                        <div class="form-item">
                            
                        </div>


                    </div>
        
                    <div id="botForm">
                        <div class="form-item full" style="display: flex; align-items: start; gap: 10px;">
                            <label for="diac">การวินิจฉัยเบื้องต้น:</label>
                            <textarea cols="50" id="diac"><%= diac %></textarea>
                        </div>
        
                        <div class="form-item full" style="display: flex; align-items: start; gap: 10px;">
                            <label for="note">หมายเหตุ:</label>
                            <textarea cols="50"  id="note"></textarea>
                        </div>
                        
        
                        <div class="" style="display: flex; justify-content: end; gap: 10px; margin-right: 4rem; cursor: pointer;">
                            <button class="btn" onclick="showPredictionHistory()">ประวัติรายการตรวจ</button>
                        </div>
                    
                    </div>
        
                    <div style="display: flex;width: 100%; justify-content: center; margin-top: 50px; gap: 20px;">
                        <div style="width: 40%;">
                            <input id="searchInput" style="width: 100%;" type="text" placeholder="ค้นหา...">
                            <div id="dropdown" style=" max-height: 300px; overflow: scroll; position:absolute; background-color: #fff;"></div>
                        </div>
                        <button style="cursor: pointer;" onclick=openLabSelection()>รายการตรวจ</button>
                    </div>



                    <table id="tab" class="result-table" >
                        <thead>
                            <tr style="background-color: #007bff; color: #fff;">
                                <th></th>
                                <th style="text-align: center;">รายการตรวจ</th>
                                <th style="text-align: center;">ราคา</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <th><input type='checkbox'></th>
                                <th style='color:#333'></th>
                                <th></th>
                            </tr>
                        </tbody>
                    </table>
        
                    <div style="display: flex; flex-flow: row; justify-content: end; align-items: center; margin-right: 1rem; gap: 10px;">
                        <div> 
        
                        </div>
                        <button style="padding: 10px;cursor: pointer;" onclick="showre()">เเสดงการทำนาย</button>
                        <div style="display: flex; flex-flow: column; gap: 1rem; border:1px #DDD solid; border-radius: 10px; padding: 10px;">
                            <div>วันนี้ให้ตรวจที่บ้านเเล้ว : <%= sqlhomecount %> รายการ </div>
                            <div>วันนี้ให้ตรวจที่โรงพยาบาลเเล้ว : <%= sqlhoscount %> รายการ</div>
                        </div>

                    </div>
        
        
                    <div id="predictionResult" style="display:  none; margin-top: 50px; border:1px #DDD solid; border-radius: 10px; padding: 10px;">
                        <div class="result-container" >
                            <h2 class="result-title">ผลการทำนาย</h2>
            
                            <div style="display: flex; flex-direction: column; justify-content: center; align-items: center;">
                                <div class="selected-option popup-container">
                                    <h4 id = 'hh' value=""></h4>
                                    <div id="pp" value="no" style="display: none;"></div>
                                </div>

                            </div>
            
                            <div id="main_title" style="text-align: left; margin-left: 5%;">ปัจจัยสำคัญสำหรับการตรวจครั้งนี้</div>
            
                            <table class="result-table" style="text-align: center;">
                                <thead>
                                    <tr>
                                        <th>รายการ</th>
                                        <th>ผลการประเมิน</th>
                                        <th>เหตุผลรองรับ</th>
                                    </tr>
                                </thead>
                                <tbody id="main_list">

                                </tbody>
                            </table>
            
                                
                            <div id="sec_title" style="text-align: left; margin-left: 5%;">ปัจจัยที่ควรพริจารณาเพิ่ม</div>
            
                            <table class="result-table" style="text-align: center;">
                                <thead>
                                    <tr>
                                        <th>รายการ</th>
                                        <th>ผลการประเมิน</th>
                                        <th>เหตุผลรองรับ</th>
                                    </tr>
                                </thead>
                                <tbody id="sec_list">
                                    
                                </tbody>
                            </table>
                        </div>

                        <div style="margin: 2rem; display: flex; justify-content: center; gap: 10px;">
                            <div style="padding: 1.5rem; border: 1px solid #616161; border-radius: 10px; width: 150px;">
                                <input type="radio" id="doctor_choose" name="doctor_choose" value="home">
                                <label for="option1">ตรวจที่บ้าน</label>
                            </div>
                            <div style="padding: 1.5rem; border: 1px solid #616161; border-radius: 10px; width: 150px;">
                                <input type="radio" id="doctor_choose" checked name="doctor_choose" value="hospital">
                                <label for="option2">ตรวจที่โรงพยาบาล</label>
                            </div>      
                            <button style="cursor: pointer;" onclick="submitappoint()">บันทึก</button>
                        </div>    
                    </div>   
            </div>
        </div>
    </div>
    <div class="content" id="content2" style="display: none;">
        <div class="history-section" id="predictionHistorySection" style="display: none;">
             <div>
                 <button type="button" onclick="closePredictionHistory()">กลับ</button>
             </div>
             <div class="history-header">
                 <h2>ประวัติการทำนายของผู้ป่วยรายนี้</h2>
             </div>

             <div class="search-container">
                 <div class="search-box"><input type="text" id="searchPredictionDate" placeholder="ค้นหาวันที่..."></div>
                 <div class="search-box"><input type="text" id="searchPredictionDoctor" placeholder="ค้นหาแพทย์..."></div>
                 <div class="search-box">
                     <select id="searchPredictionResult">
                         <option value="">สถานที่ตรวจ (ทั้งหมด)</option>
                         <option value="home">home</option>
                         <option value="hospital">hospital</option>
                     </select>
                 </div>
                
                 <div class="search-box">
                     <button type="button" onclick="filterPredictionHistory()">ค้นหา</button>
                 </div>
             </div>

             <div class="history-table-wrapper">
                 <table id="predictionHistoryTable" class="history-table" style="margin-top: 0px;"">
                     <thead>
                         <tr>
                             <th style="position: sticky; top: 0;">วันที่ส่งตรวจ</th>
                             <th style="position: sticky; top: 0;">เเพทย์</th>
                             <th style="position: sticky; top: 0;">ตรวจที่</th>
                             <th style="position: sticky; top: 0;">การวินิจฉัยเบื้องต้น</th>
                             <th style="position: sticky; top: 0;">รายการตรวจ</th>
                             <th style="position: sticky; top: 0;"></th>
                         </tr>
                     </thead>
                     <tbody id="predictionHistoryBody" style="overflow-y: unset;">
                         <% if (predictionHistory.isEmpty()) { %>
                             <tr data-empty="true">
                                 <td colspan="5" style="text-align:center;color:#888;">ไม่พบข้อมูลการทำนาย</td>
                             </tr>
                         <% } else {
                             for (Map<String, String> pred : predictionHistory) {
                                 String rowDate = pred.get("date") != null ? pred.get("date") : "-";
                                 String rowDoctor = pred.get("doctor") != null ? pred.get("doctor") : "-";
                                 String rowResult = pred.get("predict_result") != null ? pred.get("predict_result") : "-";
                                 String rowSelected = pred.get("doctor_selected") != null ? pred.get("doctor_selected") : "-";
                                 String rowConfident = pred.get("confident") != null ? pred.get("confident") : "-";
                         %>
                             <tr data-history="true"
                                 data-date="<%= rowDate %>"
                                 data-doctor="<%= rowDoctor %>"
                                 data-result="<%= rowResult %>"
                                 data-selected="<%= rowSelected %>">
                                 <td><%= rowDate %></td>
                                 <td><%= rowDoctor %></td>
                                 <td><%= rowResult %></td>
                                 <td><%= rowSelected %></td>
                                 <td><%= rowConfident %></td>
                                 <td><button value="<%= rowConfident %>" onclick="getlab(this.value)">เรียกใช้การตรวจนี้</button></td>
                             </tr>
                         <%  }
                            } %>
                         <tr data-empty="true" style="display:none;">
                             <td colspan="5" style="text-align:center;color:#888;">ไม่พบข้อมูลที่ค้นหา</td>
                         </tr>
                     </tbody>
                 </table>
             </div>
         </div>    
</div>
    
    <script src="../doctor_js/predict.js"></script>    
    <script src="../script.js"></script>    
    <script>
        const list = ["Sodium","Potassium","Chloride","CO2","Anion Gap","HDL Cholesterol","LDL Cholesterol","Triglyceride","Cholesterol","Lipoprotein (a)","BUN","Cre","Uric acid","Calcium","Phosphorus","Magnesium","Glucose","Glucose NaF","Glucose NaF 2hrs","Glucose Strip","ALT","AST","Gamma-GT","Alkaline phosphatase","Albumin","Globulin","Total protein","CPK","CK-MB","Troponin I","Calcium","Magnesium","Phosphorus","Iron","Ferritin","Total Iron-binding capacity(TIBC)","Unsaturated Iron-binding capacity(UIBC)","%Iron Saturation","Total Bilirubin","Direct Bilirubin","Vitamin D","Vitamin B12 (Cabalamins)","PSA","FPSA","Beta HCG","AFP","CEA","CA 19-9","CA 125","CA 15-3","hsC-Reactive protein","Procalcitonin (PCT)","LDH","Osmolality (Serum)","Anion Gap","Beta 2 Microglobulin","Beta-crosslaps","Cortisol II","Aldosterone","Erythropoietin level (EPO)","Estradiol (E2)","Follicle-stimulating hormone","Luteinizing hormone","Prolactin","Testosterone","Cyclosporine (CSA)","Digoxin","Tacrolimus (Prograf)","Everolimus","Vancomycin","Valproic acid","Valproic acid (Depakin)","Phenytoin","Renin Activity (PRA):Calculated","Direct Renin","BUN","Creatinine","Liver function","HbA1c","Uric acid","Lactate","Fructosamine","Intact Parathyroid hormone","Cystatin C","Serum Protein Electrophoresis","Hemoglobin Typing","Hemoglobin A","Hemoglobin A2","Hemoglobin E","Hemoglobin F","RBC","RDW","MCV","MCH","MCHC","HCT","HB","CBC","Reticulocyte count","ESR","Inclusion bodies test","G6PD Screening Test","DCIP","LE Test","Anti HIV","Anti HIV (Rapid Test)","Anti HCV","Anti HBs","Anti HBc Total","HBs Ag","HBs Ag (Quantitative)","HBe Ag","Anti Hbe","ANA","ANA Profile 1","Anti-TSHR","Anti-TPO","Anti-Tg","%CD4","Absolute CD4","Immunoglobulin IgA","IgG","IgM","Complement C3","Complement C4 level","Anti-CCP","Anti-Cardiolipin IgG","Anti-La(SS-B)","Anti-Ro(SS-A)","Anti Sm","Anti nRNP","Anti dsDNA","Anti-glomerular basement membrane","Anti-Streptolysin O","Anti-Myeloperoxidase","Anti-Proteinase3","Anti-centromere","Anti-PLA-2R","SARS-CoV2 IgG Quantitative","SARS-CoV2 IgM Ab","SARS-CoV2 anti-NP IgG CMIA","Dengue IgG+IgM","Dengue NS1 Ag","Epstein-Barr IgG","Epstein-Barr IgM","CMV IgG","CMV IgM","FTA-ABS (IgG)","FTA-ABS (IgM)","Anti HAV (IgG)","Anti HAV (IgM)","Rheumatoid factor","Smooth muscles Ab (ASMA)","Anti-mitochondria Antibody(AMA)","hsC-Reactive protein","Interleukin 6 (IL-6)","Anti-Beta-2 glycoprotein 1 IgM","Procalcitonin (PCT)","Toxoplasma IgG","Herpes Simplex IgG","Varicella zoster IgG","Beta 2 Microglobulin","Blood Group ABO","Rh(D) Typing","X-Matching","Direct Antiglobulin Test","Indirect Antiglobulin Test","Hemoculture : ขวด","Hemoculture : แขน","DNA for Alpha- thalassemia 1 and 2 (Blood)","Myophaties 18 Ag (Myositis Profile 18 Ag)"];
        const input = document.getElementById('searchInput');
        const dropdown = document.getElementById('dropdown');
        
        input.addEventListener('input', function() {
            const value = input.value;
            dropdown.innerHTML = ''; // clear previous results

            if (value) {
            const results = list.filter(item => item.toLowerCase().includes(value.toLowerCase()));
            results.forEach(item => {
                const option = document.createElement('div');
                option.textContent = item;
                option.style.padding = '5px';
                option.style.cursor = 'pointer';

                // click to select
                option.addEventListener('click', () => {
                let checkboxes = document.querySelectorAll('input[name="lab"]');   
                checkboxes.forEach(cb => {
                    if (cb.value  === item ) {
                        cb.checked = true;
                    }
                });
                submitlab()
                input.value = item;
                dropdown.innerHTML = '';
                });

                dropdown.appendChild(option);
            });
            }
        });
    </script>
</body>
</html>