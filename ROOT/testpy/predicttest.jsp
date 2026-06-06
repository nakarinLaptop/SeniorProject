<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.servlet.*" %>
<%
    Integer doctorId  = (Integer) session.getAttribute("user_id");
    Integer patientId = (Integer) session.getAttribute("patient_id");
    

    if (doctorId == null) {
        response.sendRedirect("../index.jsp");
        return;
    }

    String patientCode = "";
    if (patientId != null) {
        patientCode = String.format("P%06d", patientId);
    }

%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
    <link rel="stylesheet" href="../css/predict.css">
    <link rel="stylesheet" href="../css/layout.css">
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

      </style>
      <script>



        function resetlab(){
            let tab = document.getElementById('tab'); 
            tab.innerHTML = `
                <thead style="background-color: blue; color: #fff;">
                    <tr>
                        <th></th>
                        <th>รายการตรวจ</th>
                        <th>สิ่งส่งตรวจ</th>
                        <th>ราคา</th>
                    </tr>
                </thead>

                `;
        }

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
        function getresult(values,id){
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
                        per.innerHTML = (((data.home).toFixed(2))*100)+"%"   ; 
                    }else{
                        resu.innerHTML = "สนันสนันให้ตรวจที่โรงพยาบาล" ;
                        per.innerHTML = (((data.hos).toFixed(2))*100)+"%" ; 
                    }
    
                    for(i=0;i<data.home_list.length;i+=1){
                        home_temp.innerHTML += 
                        "<tr>" +
                            "<td class='popup-container'>" + data.home_list[i] + "<div class='popup-text'>" + data.home_list[i] + "</div></td>" +
                            "<td class='popup-container'>" + data.home_detail[i] + "<div class='popup-text'>" + data.home_detail[i] + "</div></td>" +
                            "<td class='ok popup-container'><span class='check'>ยังไม่สามารถใช้งานได้" +
                                "<div class='popup-text'>ยังไม่สามารถใช้งานได้</div>" +
                            "</span></td>" +
                        "</tr>";
                    }
                    for(i=0;i<data.hos_list.length;i+=1){
                        hos_temp.innerHTML += 
                        "<tr>" +
                            "<td class='popup-container'>" + data.hos_list[i] + "<div class='popup-text'>" + data.hos_list[i] + "</div></td>" +
                            "<td class='popup-container'>" + data.hos_detail[i] + "<div class='popup-text'>" + data.hos_detail[i] + "</div></td>" +
                            "<td class='ok popup-container'><span class='check'>ยังไม่สามารถใช้งานได้" +
                                "<div class='popup-text'>ยังไม่สามารถใช้งานได้</div>" +
                            "</span></td>" +
                        "</tr>";
                
                    }
                })
                .catch(error => console.error("Error:", error));

        }

        function showre(){
            const checkboxes = document.querySelectorAll('input[name="lab"]:checked');
            const values = Array.from(checkboxes).map(cb => cb.value);
            resetlab()
            resetresult()
            showlab(values)
            getresult(values)
        }

        function callPython(action) {
            
            let el = document.getElementById("index");
            let temp = Number(el.className)
            if(action == 'back' && temp != 0) {
                temp -= 1 
                el.className = temp
            }else if(action == 'next' && temp != 46){
                temp += 1
                el.className = temp
            }else{
                temp = action
                el.className = temp
            }

            console.log(el.className)

            fetch("callPython.jsp?action=" + temp)   // call another JSP/Servlet
                .then(response => response.json())
                .then(data => {
                    console.log("Response JSON:", data);
                    let id = document.getElementById("idItem");
                    id.textContent = "id : " + data.idItem;
                    id.className = data.idItem;
                    document.getElementById("genderItem").textContent = "เพศ : " + data.genderItem;
                    document.getElementById("ageItem").textContent = "อายุ : " + data.ageItem;
                    document.getElementById("addressItem").textContent = "ที่อยู่ : " + data.addressItem;
                    document.getElementById("rightsItem").textContent = "สิทธิ : " + data.rightsItem;
                    document.getElementById("transportItem").textContent = "วิธีการเดินทาง : " + data.transportItem;
                    document.getElementById("statusItem").textContent = "สถานะ : " + data.statusItem;
                    document.getElementById("icd10").textContent = "โรค : " + data.icd10;
                })
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
            

            <%-- <div id="result"></div> --%>
            <button id="predictButton" onclick="predict()">ตกลง</button>
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
                        <label>สถานะใบชันสูตร:</label>
                        <input type="text" placeholder="พิมพ์ชันสูตรแล้ว">
                    </div>

                    <div class="form-item">
                        <label>ประเภทงาน:</label>
                        <input type="text" placeholder="Endocrine">
                    </div>

                    <div class="form-item">
                        <label>หน่วยงานส่งตรวจ:</label>
                        <select>
                            <option>คลินิกเวชศาสตร์นิวเคลียร์</option>
                        </select>
                    </div>

                    <div class="form-item">
                        <label>วันที่ส่งตรวจ:</label>
                        <input type="date">
                        <input type="time">
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
                            <option>นพ.สมชาย ใจดี</option>
                        </select>
                    </div>

                    <div class="form-item">
                        <label>วันที่ขอตรวจ:</label>
                        <input type="date">
                        <input type="time">
                    </div>

                    <div class="form-item">
                        <label>ผู้รับสิ่งส่งตรวจ:</label>
                        <select>
                            <option>นพ.สมชาย ใจดี</option>
                        </select>
                    </div>

                    <div class="form-item">
                        <label>สิทธิการรักษา:</label>
                        <select>
                            <option>ประกันสังคมเครือข่ายกรมการ</option>
                        </select>
                    </div>

                    <div class="form-item">
                        <label>Lab ID:</label>
                        <input type="text" placeholder="12-34-567890">
                    </div>

                    <div class="button-row">
                        <button class="btn">สอบถาม LAB</button>
                        <button class="btn">ประวัติรายการตรวจ</button>
                    </div>
                </div>

                <div id="botForm">
                    <div class="form-item full">
                        <label>การวินิจฉัยเบื้องต้น:</label>
                        <input type="text">
                    </div>

                    <div class="form-item full">
                        <label>หมายเหตุ:</label>
                        <input type="text">
                    </div>

                    <div class="form-item">
                        <button class="btn btn-cancel">ยกเลิกการตรวจ</button>
                    </div>
                </div>

                <div style="display: flex; justify-content: center; margin-top: 50px;"> 
                    <div class="dropdown">
                        <button>เลือก LAB ▼</button>
                        <div class="dropdown-content">
                            <label><input name="lab" type="checkbox" value="BUN"> BUN</label><br>
    <label><input name="lab" type="checkbox" value="Creatinine"> Creatinine</label><br>
    <label><input name="lab" type="checkbox" value="Electrolyte"> Electrolyte</label><br>
    <label><input name="lab" type="checkbox" value="Glucose"> Glucose</label><br>
    <label><input name="lab" type="checkbox" value="Lipid profile"> Lipid profile</label><br>
    <label><input name="lab" type="checkbox" value="CBC"> CBC</label><br>
    <label><input name="lab" type="checkbox" value="ALT"> ALT</label><br>
    <label><input name="lab" type="checkbox" value="AST"> AST</label><br>
    <label><input name="lab" type="checkbox" value="LDL Cholesterol"> LDL Cholesterol</label><br>
    <label><input name="lab" type="checkbox" value="HbA1c"> HbA1c</label><br>
    <label><input name="lab" type="checkbox" value="Uric acid"> Uric acid</label><br>
    <label><input name="lab" type="checkbox" value="Tg Thyroglobulin"> Tg Thyroglobulin</label><br>
    <label><input name="lab" type="checkbox" value="CPK"> CPK</label><br>
    <label><input name="lab" type="checkbox" value="Potassium"> Potassium</label><br>
    <label><input name="lab" type="checkbox" value="Calcium"> Calcium</label><br>
    <label><input name="lab" type="checkbox" value="Magnesium"> Magnesium</label><br>
    <label><input name="lab" type="checkbox" value="Phosphorus"> Phosphorus</label><br>
    <label><input name="lab" type="checkbox" value="Sodium"> Sodium</label><br>
    <label><input name="lab" type="checkbox" value="Liver function"> Liver function</label><br>
    <label><input name="lab" type="checkbox" value="HDL Cholesterol"> HDL Cholesterol</label><br>
    <label><input name="lab" type="checkbox" value="Triglyceride"> Triglyceride</label><br>
    <label><input name="lab" type="checkbox" value="Alkaline phosphatase"> Alkaline phosphatase</label><br>
    <label><input name="lab" type="checkbox" value="Albumin"> Albumin</label><br>
    <label><input name="lab" type="checkbox" value="Cholesterol"> Cholesterol</label><br>
    <label><input name="lab" type="checkbox" value="Troponin I"> Troponin I</label><br>
    <label><input name="lab" type="checkbox" value="Glucose NaF"> Glucose NaF</label><br>
    <label><input name="lab" type="checkbox" value="FT4"> FT4</label><br>
    <label><input name="lab" type="checkbox" value="TSH"> TSH</label><br>
    <label><input name="lab" type="checkbox" value="FT3"> FT3</label><br>
    <label><input name="lab" type="checkbox" value="Glucose Strip"> Glucose Strip</label><br>
    <label><input name="lab" type="checkbox" value="NT-pro BNP"> NT-pro BNP</label><br>
    <label><input name="lab" type="checkbox" value="Blood gas analysis"> Blood gas analysis</label><br>
    <label><input name="lab" type="checkbox" value="Anti HIV"> Anti HIV</label><br>
    <label><input name="lab" type="checkbox" value="Lactate"> Lactate</label><br>
    <label><input name="lab" type="checkbox" value="Anti HCV"> Anti HCV</label><br>
    <label><input name="lab" type="checkbox" value="Anti HBs"> Anti HBs</label><br>
    <label><input name="lab" type="checkbox" value="HBs Ag"> HBs Ag</label><br>
    <label><input name="lab" type="checkbox" value="Hemoculture ขวด"> Hemoculture ขวด</label><br>
    <label><input name="lab" type="checkbox" value="Iron"> Iron</label><br>
    <label><input name="lab" type="checkbox" value="Total Iron-binding capacity(TIBC)"> Total Iron-binding capacity(TIBC)</label><br>
    <label><input name="lab" type="checkbox" value="Total Bilirubin"> Total Bilirubin</label><br>
    <label><input name="lab" type="checkbox" value="Direct Bilirubin"> Direct Bilirubin</label><br>
    <label><input name="lab" type="checkbox" value="Globulin"> Globulin</label><br>
    <label><input name="lab" type="checkbox" value="Total protein"> Total protein</label><br>
    <label><input name="lab" type="checkbox" value="Ferritin"> Ferritin</label><br>
    <label><input name="lab" type="checkbox" value="Unsaturated Iron-binding capacity(UIBC)"> Unsaturated Iron-binding capacity(UIBC)</label><br>
    <label><input name="lab" type="checkbox" value="%Iron Saturation">%Iron Saturation</label><br>
    <label><input name="lab" type="checkbox" value="PSA"> PSA</label><br>
    <label><input name="lab" type="checkbox" value="Blood Group ABO"> Blood Group ABO</label><br>
    <label><input name="lab" type="checkbox" value="Rh(D) Typing"> Rh(D) Typing</label><br>
    <label><input name="lab" type="checkbox" value="X-Matching"> X-Matching</label><br>
    <label><input name="lab" type="checkbox" value="ESR"> ESR</label><br>
    <label><input name="lab" type="checkbox" value="Gamma-GT"> Gamma-GT</label><br>
    <label><input name="lab" type="checkbox" value="Ketone"> Ketone</label><br>
    <label><input name="lab" type="checkbox" value="Vitamin D"> Vitamin D</label><br>
    <label><input name="lab" type="checkbox" value="AFP"> AFP</label><br>
    <label><input name="lab" type="checkbox" value="CEA"> CEA</label><br>
    <label><input name="lab" type="checkbox" value="CA 19-9"> CA 19-9</label><br>
    <label><input name="lab" type="checkbox" value="hsC-Reactive protein"> hsC-Reactive protein</label><br>
    <label><input name="lab" type="checkbox" value="LDH"> LDH</label><br>
    <label><input name="lab" type="checkbox" value="Osmolality"> Osmolality</label><br>
    <label><input name="lab" type="checkbox" value="Direct Antiglobulin Test"> Direct Antiglobulin Test</label><br>
    <label><input name="lab" type="checkbox" value="Indirect Antiglobulin Test"> Indirect Antiglobulin Test</label><br>
    <label><input name="lab" type="checkbox" value="Anion Gap"> Anion Gap</label><br>
    <label><input name="lab" type="checkbox" value="CO2"> CO2</label><br>
    <label><input name="lab" type="checkbox" value="Chloride"> Chloride</label><br>
    <label><input name="lab" type="checkbox" value="Intact Parathyroid hormone"> Intact Parathyroid hormone</label><br>
    <label><input name="lab" type="checkbox" value="%CD4">%CD4</label><br>
    <label><input name="lab" type="checkbox" value="Absolute CD4"> Absolute CD4</label><br>
    <label><input name="lab" type="checkbox" value="CK-MB"> CK-MB</label><br>
    <label><input name="lab" type="checkbox" value="RPR"> RPR</label><br>
    <label><input name="lab" type="checkbox" value="Cyclosporine (CSA)"> Cyclosporine (CSA)</label><br>
    <label><input name="lab" type="checkbox" value="Digoxin"> Digoxin</label><br>
    <label><input name="lab" type="checkbox" value="Reticulocyte count"> Reticulocyte count</label><br>
    <label><input name="lab" type="checkbox" value="ANA"> ANA</label><br>
    <label><input name="lab" type="checkbox" value="Anti HBc Total"> Anti HBc Total</label><br>
    <label><input name="lab" type="checkbox" value="FPSA"> FPSA</label><br>
    <label><input name="lab" type="checkbox" value="Fructosamine"> Fructosamine</label><br>
    <label><input name="lab" type="checkbox" value="Anti-TPO"> Anti-TPO</label><br>
    <label><input name="lab" type="checkbox" value="Anti-Tg"> Anti-Tg</label><br>
    <label><input name="lab" type="checkbox" value="Hemoglobin Typing"> Hemoglobin Typing</label><br>
                        </div>
                    </div>
                </div>
            </div>

            <div style="display: flex; justify-content: center; margin-top: 200px; cursor: pointer; max-height: 50px;">
                <button onclick='showre()''>ดูผลทำนาย</button>

            </div>
            
            <table id="tab" class="result-table" style="text-align: center; margin-top: 50px; gap: 10px; border-collapse: separate; border-spacing: 20px; ">
                <thead style="background-color: blue; color: #fff;">
                    <tr>
                        <th></th>
                        <th>รายการตรวจ</th>
                        <th>สิ่งส่งตรวจ</th>
                        <th>ผลการตรวจ</th>
                    </tr>
                </thead>
                <tbody>
                </tbody>
            </table>

            <div style="margin: 50px; display: flex; justify-content: center; gap: 10px;">
                <label>
                    <input type="radio" name="color" value="red">
                    บ้าน
                </label>
                <label>
                    <input type="radio" name="color" value="red">
                    โรงพยาบาล
                </label>
                <button>บันทึก</button>
            </div>


            <div id="predictionResult" style="display:  none; margin-top: 50px;">
                <div class="result-container" style="overflow: scroll; max-height: 500px;">
                    <h2 class="result-title">สรุปผลการทำนาย</h2>
    
                    <div class="selected-option popup-container">
                        <h4 id = 'hh'></h1>
                        <span id='jj' class="home-icon">
                        </span>
                        <div id="pp" class="popup-text"></div>
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
        
       


        <div id="predictTable">
            <div>
                <h4>ประวัติการทำนาย</h4>
                <table class="patientPageTable" id="labTable">
                    <thead>
                        <tr>
                            <th>วันที่ตรวจ</th>
                            <th>รหัสคนไข้</th>
                            <th>ชื่อคนไข้</th>
                            <th>แพทย์ผู้สั่งตรวจ</th>
                            <th>แล็บที่ตรวจ</th>
                            <th>ดูรายละเอียด</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>2026-01-11 10:30:50</td>
                            <td>P000001</td>
                            <td>นายทดสอบ ระบบ</td>
                            <td>นายสมพล แซ่ชี</td>
                            <td>Sodium, Potassium, Chloride, BUN, Creatinine</td>
                            <td><button onclick="openLabView()">ดูรายละเอียด</button></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    
    <script src="../js/predict.js"></script>    
    <script src="../js/script.js"></script>    
</body>
</html>