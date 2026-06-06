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

    List<Map<String, String>> healthcareRights = new ArrayList<>();

    try {
        String sqlRights = "SELECT right_id,right_name FROM patient_right INNER JOIN healthcare_right USING (right_id) WHERE patient_id = ? " ;
        stmt = con.prepareStatement(sqlRights);
        stmt.setInt(1, patientId);
        rs = stmt.executeQuery();
            
        while (rs.next()) {
            Map<String, String> right = new HashMap<>();
            right.put("right_id", String.valueOf(rs.getInt("right_id")));
            right.put("right_name", rs.getString("right_name"));
            healthcareRights.add(right);
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
            overflow-y: scroll;
            overflow-x: scroll;
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

        function resetresult(){
            home_temp = document.getElementById('home_list'); 
            hos_temp = document.getElementById('hos_list'); 
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
                    "<th></th>" +
                "</tr>";

            }
        }
        function getresult(values){
            let params = new URLSearchParams({
                lab: values
            });

            fetch("../testpy/sentpredict.jsp?" + params.toString())
                .then(response => response.json())
                .then(data => {
                    console.log("Raw Response:", data);
                    resu = document.getElementById('hh');
                    icon = document.getElementById('jj'); 
                    per = document.getElementById('pp'); 
                    home_temp = document.getElementById('home_list'); 
                    hos_temp = document.getElementById('hos_list'); 
                    resupre = document.getElementById('predictionResult'); 

                    resupre.style.display = "block";

                    if (data.home > data.hos) {
                        resu.innerHTML = "สนันสนันให้ตรวจที่บ้าน" ;
                        resu.value = "home" ;
                        per.innerHTML = (((data.home).toFixed(2))*100)+"%"   ; 
                        per.value = (((data.home).toFixed(2))*100) ;
                    }else{
                        resu.innerHTML = "สนันสนันให้ตรวจที่โรงพยาบาล" ;
                        resu.value = "hospital" ;
                        per.innerHTML = (((data.hos).toFixed(2))*100)+"%" ; 
                        per.value = (((data.hos).toFixed(2))*100) ;
                    }
    
                    for(i=0;i<data.home_list.length;i+=1){
                        home_temp.innerHTML += 
                        "<tr>" +
                            "<td class='popup-container'>" + data.home_list[i] + "<div class='popup-text'>" + data.home_list[i] + "</div></td>" +
                            "<td class='popup-container'>" + data.home_detail[i] + "<div class='popup-text'>" + data.home_per[i].toFixed(2) + "%</div></td>" +
                            "<td class='ok popup-container'><span class='check'>ยังไม่สามารถใช้งานได้" +
                                "<div class='popup-text'>ยังไม่สามารถใช้งานได้</div>" +
                            "</span></td>" +
                        "</tr>";
                    }
                    for(i=0;i<data.hos_list.length;i+=1){
                        hos_temp.innerHTML += 
                        "<tr>" +
                            "<td class='popup-container'>" + data.hos_list[i] + "<div class='popup-text'>" + data.hos_list[i] + "</div></td>" +
                            "<td class='popup-container'>" + data.hos_detail[i] + "<div class='popup-text'>" + data.hos_per[i].toFixed(2) + "%</div></td>" +
                            "<td class='ok popup-container'><span class='check'>ยังไม่สามารถใช้งานได้" +
                                "<div class='popup-text'>ยังไม่สามารถใช้งานได้</div>" +
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
            const values = Array.from(checkboxes).map(cb => cb.value);
            resetresult()
            getresult(values)
        }

        function resetlab(){
            let tab = document.getElementById('tab'); 
            tab.innerHTML = `
                    <thead>
                        <tr style="background-color: blue; color: #fff;">
                            <th></th>
                            <th style="text-align: center;">รายการตรวจ</th>
                            <th style="text-align: center;">สิ่งส่งตรวจ</th>
                            <th style="text-align: center;">ราคา</th>
                            <th style="text-align: center;">เบิกได้</th>
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
                console.log(values[i])
                tab.innerHTML +=
                "<tr>" +
                    "<th style='text-align: center;'><input type='checkbox'></th>" +
                    "<th style='color:#333'>" + values[i] + "</th>" +
                    "<th>Clotted blood</th>" + 
                    "<th></th>" +
                    "<th></th>" +
                "</tr>";

            }
        }

        function submitappoint() {
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




            console.log(lablist);
            console.log(rightselect); 
            console.log(doctorchoos);
            console.log(appointdate); 
            console.log(choosdate);
            console.log(diac); 
            console.log(note);
            console.log(resu); 
            console.log(per);

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

            
            fetch("../testpy/sentsubmit.jsp", {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded"
                },
                body: params.toString()
            }).then(response => response.text())
            .then(data => {
                console.log(data)
            });
        }
        </script>
</head>
<body>
	<%
	request.setAttribute("activePage", "predict");
	request.setAttribute("pageTitle", "เลือกรายการตรวจแล็บและทำนายสถานที่ตรวจสุขภาพ");
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
                        <label><input type="checkbox" name="lab" value="Cre"> Cre</label><br>
                        <label><input type="checkbox" name="lab"  value="Uric"> Uric</label><br>
                    </div>
                    <div class="lab-sub">
                        <h3>Panel-c</h3>
                        <label><input type="checkbox" name="lab" value="Cal"> Cal</label><br>
                        <label><input type="checkbox" name="lab" value="Phos"> Phos</label><br>
                        <label><input type="checkbox" name="lab" value="Mg"> Mg</label><br>
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
                        <label><input type="checkbox" name="lab" value="Calcium"> Calcium</label><br>
                        <label><input type="checkbox" name="lab" value="Magnesium"> Magnesium</label><br>
                        <label><input type="checkbox" name="lab" value="Phosphorus"> Phosphorus</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Iron"> Iron</label><br>
                        <label><input type="checkbox" name="lab" value="Ferritin"> Ferritin</label><br>
                        <label><input type="checkbox" name="lab" value="Total Iron-binding capacity (TIBC)"> Total Iron-binding capacity (TIBC)</label><br>
                        <label><input type="checkbox" name="lab" value="Unsaturated Iron-binding capacity (UIBC)"> Unsaturated Iron-binding capacity (UIBC)</label><br>
                        <label><input type="checkbox" name="lab" value="% Iron Saturation">% Iron Saturation</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Total Bilirubin"> Total Bilirubin</label><br>
                        <label><input type="checkbox" name="lab" value="Direct Bilirubin"> Direct Bilirubin</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Vitamin D"> Vitamin D</label><br>
                        <label><input type="checkbox" name="lab" value="Vitamin B12"> Vitamin B12</label><br>
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
                        <label><input type="checkbox" name="lab" value="hsC-Reactive protein (hsCRP)"> hsC-Reactive protein (hsCRP)</label><br>
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
                        <label><input type="checkbox" name="lab" value="Renin Activity (PRA): Calculated"> Renin Activity (PRA): Calculated</label><br>
                        <label><input type="checkbox" name="lab" value="Direct Renin"> Direct Renin</label><br>
                    </div>
                    <label><input type="checkbox" name="lab" value="BUN"> BUN</label>
                    <label><input type="checkbox" name="lab" value="Creatinine"> Creatinine</label>
                    <label><input type="checkbox" name="lab" value="Liver function (รวม panel ของ liver)"> Liverfunction (รวม panel ของ liver)</label>
                    <label><input type="checkbox" name="lab" value="HbA1c"> HbA1c</label>
                    <label><input type="checkbox" name="lab" value="Uric acid"> Uric acid</label>
                    <label><input type="checkbox" name="lab" value="Lactate"> Lactate</label>
                    <label><input type="checkbox" name="lab" value="Fructosamine"> Fructosamine</label>
                    <label><input type="checkbox" name="lab" value="Intact Parathyroid hormone"> Intact Parathyroid hormone</label>
                    <label><input type="checkbox" name="lab" value="Cystatin C"> Cystatin C</label>
                    <label><input type="checkbox" name="lab" value="Serum Protein Electrophoresis"> Serum Protein Electrophoresis</label>
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
                    <label><input type="checkbox" name="lab" value="CBC (Complete Blood Count)"> CBC (Complete Blood Count)</label>
                    <label><input type="checkbox" name="lab" value="Reticulocyte count"> Reticulocyte count</label>
                    <label><input type="checkbox" name="lab" value="ESR (Erythrocyte Sedimentation Rate)"> ESR (Erythrocyte Sedimentation Rate)</label>
                    <label><input type="checkbox" name="lab" value="Inclusion bodies test"> Inclusion bodies test</label>
                    <label><input type="checkbox" name="lab" value="G6PD Screening Test"> G6PD Screening Test</label>
                    <label><input type="checkbox" name="lab" value="DCIP"> DCIP</label>
                    <label><input type="checkbox" name="lab" value="LE Test"> LE Test</label>
                </div>

                <!-- C. Immunology -->
                <div id="tabImmu" class="checkbox-group">
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti HIV"> Anti HIV</label><br>
                        <label><input type="checkbox" name="lab" value="Anti HIV(Rapid Test)">  Anti HIV (Rapid Test)</label><br>
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
                        <label><input type="checkbox" name="lab" value="Anti-Cardiolipin IgG/IgM"> Anti-Cardiolipin IgG/IgM</label><br>
                    </div>
                    <div class="lab-subNoheader">
                        <label><input type="checkbox" name="lab" value="Anti-La(SS-B)"> Anti-La(SS-B)</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Ro(SS-A)"> Anti-Ro(SS-A)</label><br>
                        <label><input type="checkbox" name="lab" value="Anti-Sm"> Anti-Sm</label><br>
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
                    <label><input type="checkbox" name="lab" id="RheumatoidFactor" value="Rheumatoid factor"> Rheumatoid factor</label>
                    <label><input type="checkbox" name="lab" value="Smooth muscles Ab (ASMA)"> Smooth muscles Ab (ASMA)</label>
                    <label><input type="checkbox" name="lab" value="Anti-mitochondria Antibody (AMA)"> Anti-mitochondria Antibody (AMA)</label>
                    <label><input type="checkbox" name="lab" value="hsC-Reactive protein"> hsC-Reactive protein</label>
                    <label><input type="checkbox" name="lab" value="Interleukin 6 (IL-6)"> Interleukin 6 (IL-6)</label>
                    <label><input type="checkbox" name="lab" value="Anti-Beta-2 glycoprotein 1 IgG/IgM"> Anti-Beta-2 glycoprotein 1 IgG/IgM</label>
                    <label><input type="checkbox" name="lab" value="Procalcitonin (PCT)"> Procalcitonin (PCT)</label>
                    <label><input type="checkbox" name="lab" value="Toxoplasma IgG"> Toxoplasma IgG</label>
                    <label><input type="checkbox" name="lab" value="Herpes Simplex IgG"> Herpes Simplex IgG</label>
                    <label><input type="checkbox" name="lab" value="Varicella zoster IgG"> Varicella zoster IgG</label>
                    <label><input type="checkbox" name="lab" value="Beta 2 Microglobulin"> Beta 2 Microglobulin</label>
                </div>

                <!-- D. Blood Bank -->
                <div id="tabBlood" class="checkbox-group">
                    <label><input type="checkbox" name="lab" value="Blood Group ABO"> Blood Group ABO</label>
                    <label><input type="checkbox" name="lab" value="Rh(D) Typing"> Rh(D) Typing</label>
                    <label><input type="checkbox" name="lab" value="X-Matching (Crossmatching)"> X-Matching (Crossmatching)</label>
                    <label><input type="checkbox" name="lab" value="Direct Antiglobulin Test"> Direct Antiglobulin Test</label>
                    <label><input type="checkbox" name="lab" value="Indirect Antiglobulin Test"> Indirect Antiglobulin Test</label>
                </div>

                <!-- E. Microbiology -->
                <div id="tabMicro" class="checkbox-group">
                    <label><input type="checkbox" name="lab" value="Hemoculture ขวด"> Hemoculture ขวด</label>
                    <label><input type="checkbox" name="lab" value="Hemoculture : แขน"> Hemoculture : แขน</label>
                </div>

                <!-- F. Molecular Biology -->
                <div id="tabMole" class="checkbox-group">
                    <label><input type="checkbox" name="lab" value="DNA for Alpha-thalassemia 1 and 2 (Blood)"> DNA for Alpha-thalassemia 1 and 2 (Blood)</label>
                    <label><input type="checkbox" name="lab" value="Myophaties 18 Ag (Myositis Profile 18 Ag)"> Myophaties 18 Ag (Myositis Profile 18 Ag)</label>
                </div>
            </div> 

            <%-- <div id="result"></div> --%>
            <button id="predictButton" onclick="submitlab()">ตกลง</button>
        </div>
        <div class="selectedUnit" id="selectedUnit1">
            <div id="SelectUnitTitle">
                <h2 class="section-title">การส่งตรวจภายนอก</h2>
            </div>
            <div id="formSelectUnit">
                <div class="form-grid">
                        <div class="form-item">
                            <label>หน่วยงานรับตรวจ:</label>
                            <select>
                                <option>Endocrine</option>
                                <option>Cardio Lab</option>
                                <option>Hormone Center</option>
                            </select>
                        </div>
        
                        <div class="form-item">
                            <label>ประเภทงาน:</label>
                            <input type="text" placeholder="Endocrine">
                        </div>
        
                        <div class="form-item">
                            
                        </div>
        
                        <div class="form-item">
                            <label>หน่วยงานส่งตรวจ:</label>
                            <select>
                                <option>คลินิกเวชศาสตร์นิวเคลียร์</option>
                            </select>
                        </div>
        
                        <div class="form-item">
                            <label>วันที่ส่งตรวจ:</label>
                            <input type="datetime-local" id="choosdate" name="dateTime"
               value="<%= LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")) %>">
                        </div>
        
                        <div class="form-item">
                            <label>ผู้ส่งตรวจ:</label>
                            <select>
                                <option>นพ.สมชาย ใจดี</option>
                            </select>
                        </div>
        
                        <div class="form-item">
                            <label>แพทย์ผู้ส่งตรวจ:</label>
                            <select>
                                <option>
                                    <%= doctorName %></option>
                            </select>
                        </div>
        
                        <div class="form-item">
                            <label>วันที่ขอตรวจ:</label>
                            <input type="datetime-local" id="appointdate" name="dateTime">
                            <a style="background-color: #333; color: #fff; padding: 0.5rem; border-radius: 10px; cursor: pointer;">ดูรายการตรวจ</a>
                        </div>
        
                        <div class="form-item">
                            <label>ผู้รับสิ่งส่งตรวจ:</label>
                            <select>
                                <option>นพ.สมชาย ใจดี</option>
                            </select>
                        </div>
        
                        <div class="form-item">
                            <label>สิทธิการรักษา:</label>
                            <select id="rightselect">
                                <% for (Map<String, String> right : healthcareRights) { %>
                                    <option value="<%= right.get("right_id") %>">
                                        <%= right.get("right_name") %>
                                    </option>
                                <% } %>
                            </select>
                        </div>
        
                        <div class="form-item">
                            <label>Lab ID:</label>
                            <input type="text" placeholder="12-34-567890">
                        </div>
        
                    </div>
        
                    <div id="botForm">
                        <div class="form-item full">
                            <label>การวินิจฉัยเบื้องต้น:</label>
                            <input id="diac" type="text">
                        </div>
        
                        <div class="form-item full">
                            <label>หมายเหตุ:</label>
                            <input id="note" type="text">
                        </div>
                        
        
                        <div class="" style="display: flex; justify-content: end; gap: 10px; margin-right: 4rem;">
                            <button class="btn">คืนค่า LAB</button>
                            <button class="btn">ประวัติรายการตรวจ</button>
                        </div>
                        
                        <div style="display: flex; justify-content: end; margin-right: 4rem;">
                            <button class="btn" style="color: red; margin-top: 10px;">ยกเลิกการตรวจ</button>
                        </div>
                    </div>
        
                    <div style="display: flex;width: 100%; justify-content: center; margin-top: 50px; gap: 20px;">
                        <input style="width: 40%;" type="text" placeholder="ค้นหา...">
                        <button onclick=openLabSelection()>รายการตรวจ</button>
                    </div>



                    <table id="tab" class="result-table" >
                        <thead>
                            <tr style="background-color: blue; color: #fff;">
                                <th></th>
                                <th style="text-align: center;">รายการตรวจ</th>
                                <th style="text-align: center;">สิ่งส่งตรวจ</th>
                                <th style="text-align: center;">ราคา</th>
                                <th style="text-align: center;">เบิกได้</th>
                            </tr>
                        </thead>
                        <tbody>
        
                        </tbody>
                    </table>
        
                    <div style="display: flex; flex-flow: row; justify-content: space-between; align-items: center; margin-right: 1rem;">
                        <div> 
        
                        </div>
                        <button style="padding: 10px; max-height: 3rem; cursor: pointer;" onclick="showre()">เเสดงการทำนาย</button>
                        <div style="display: flex; flex-flow: column; gap: 1rem; border:1px #DDD solid; border-radius: 10px; padding: 10px;">
                            <div>ตรวจที่บ้านเเล้ว : 8 รายการ</div>
                            <div>โควต้าตรวจที่บ้านคงเหลือ : 2 รายการ</div>
                            <button style="padding: 10px;">ดูเพิ่มเติม</button>
                        </div>
                    </div>
        
                    <div style="margin: 2rem; display: flex; justify-content: center; gap: 10px;">
                        <div>
                            <input type="radio" id="doctor_choose" name="doctor_choose" value="home">
                            <label style="padding: 1.5rem; border: 1px solid #616161; border-radius: 10px; width: 50px;" for="option1">ตรวจที่บ้าน</label>
                        </div>
                        <div>
                            <input type="radio" id="doctor_choose" name="doctor_choose" value="hospital">
                            <label style="padding: 1.5rem; border: 1px solid #616161; border-radius: 10px; width: 50px;" for="option2">ตรวจที่โรงพยาบาล</label>
                        </div>       
                        <div style="margin-left: 2rem;">
                            <button onclick="submitappoint()">บันทึก</button>
                        </div>         
                    </div>        
        
        
                    <div id="predictionResult" style="display:  none; margin-top: 50px;">
                        <div class="result-container" style="overflow: scroll; max-height: 500px;">
                            <h2 class="result-title">สรุปผลการทำนาย</h2>
            
                            <div class="selected-option popup-container">
                                <h4 id = 'hh' value=""></h1>
                                <span id='jj' class="home-icon">
                                </span>
                                <div id="pp" value="" class="popup-text"></div>
                            </div>
            
                            <div  style="text-align: left; margin-left: 5%;">ปัจจัยที่สนับสนุนให้ตรวจที่บ้าน 🏠</div>
            
                            <table class="result-table" style="text-align: center;">
                                <thead>
                                    <tr>
                                        <th>รายการ</th>
                                        <th>ผลการประเมิน</th>
                                        <th>เหตุผลรองรับ</th>
                                    </tr>
                                </thead>
                                <tbody id="home_list">
                                    
                                </tbody>
                            </table>
            
                                
                            <div  style="text-align: left; margin-left: 5%;">ปัจจัยที่สนับสนุนให้ตรวจที่โรงพยาบาล 🏥</div>
            
                            <table class="result-table" style="text-align: center;">
                                <thead>
                                    <tr>
                                        <th>รายการ</th>
                                        <th>ผลการประเมิน</th>
                                        <th>เหตุผลรองรับ</th>
                                    </tr>
                                </thead>
                                <tbody id="hos_list">
                                    
                                </tbody>
                            </table>
                        </div>
                    </div>
            </div>
        </div>
    </div>
    
    <script src="../doctor_js/predict.js"></script>    
    <script src="../script.js"></script>    
</body>
</html>