
<%@ page import="java.sql.*, java.util.*, java.time.*, java.servlet.*"%>
<%@ include file="../WEB-INF/db/connectDB.jsp" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.servlet.*" %>

<% 
    String errorMessage = null;
    String toastMsg  = (String) session.getAttribute("toastMessage");
    String toastType = (String) session.getAttribute("toastType");
    if (toastMsg != null) {
        session.removeAttribute("toastMessage");
        session.removeAttribute("toastType");
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ระบบทำนายสถานที่ตรวจสุขภาพ</title>
    <link rel="stylesheet" href="../layout.css">
    <style>
        .content{
            overflow-y: scroll;
        }
        .model{
            border: 0.5px rgb(149, 149, 149) solid; 
            border-radius: 10px; 
            box-shadow: 50px;
            margin-top: 10px;
            padding: 10px; 
            padding-left: 20px;
            padding-right: 20px;
        }
        button{
            padding: 10px; 
            font-size: large;
            color: azure;
            background-color:black;
            border-radius: 10px; 
            cursor: pointer;
        }
        div{
            font-size: large;
        }

    </style>
    <script>
        let all = [];
        let used = [];

        function changemodel(name){
            let params = new URLSearchParams({
                'name' : name,
            });
            if(used[1] == name){
                alert("โมเดลนี้กำลังใช้งาน")
            }else{
                document.getElementById("sucses").style.display = "block"
                document.getElementById("norm").style.display = "none"
                fetch("./changemo.jsp?"+params.toString())
                    .then(response => response.text())
                    .then(data => {
                        console.log("Raw Response:", data);
                        alert(data)
                        location.reload();
                    })
                .catch(error => console.error("Error:", error));
            }
        }

        function  createmodel(){
            document.getElementById("sucses").style.display = "block"
            document.getElementById("norm").style.display = "none"
            fetch("./createmodel.jsp?")
                    .then(response => response.text())
                    .then(data => {
                        console.log("Raw Response:", data);
                        alert(data)
                        location.reload();
                    })
            .catch(error => console.error("Error:", error));
        }

        fetch("./getmodel.jsp?")
                .then(response => response.json())
                .then(data => {
                console.log("Raw Response:", data);
                all = data.all ; 
                used = data.cur ; 
                let used_name = document.getElementById('used')
                let all_list = document.getElementById('all')
                let one = 0 ;
                let two = 0 ; 
                let three = 0 ;
                if(data.cur[3] != 0){
                    one = (data.cur[4]*100)/data.cur[3]
                }
                if(data.cur[7] != 0){
                    two = (data.cur[5]*100)/data.cur[7]
                }
                if(data.cur[8] != 0){
                    three = (data.cur[6]*100)/data.cur[8]
                }

                used_name.innerHTML = 
                '<div style="display: flex; flex-direction: row; align-items: center;  gap: 40px;">' + 
                '<h1 style="padding: 20px; border: 0.5px rgb(149, 149, 149) solid; border-radius: 10px;" id="used_name">'+ data.cur[1] +'</h1>' +
                '<div>วันที่เริ่มใช้งาน : '+ data.cur[2] +'</div>' +
                '</div>' +
                '<div>' +
                '<div style="display: flex; flex-direction: row; align-items: center;  gap: 30px;">' +
                    '<div>ทำนายไปเเล้ว : '+ data.cur[3] +' รายการ</div>' +
                    '<div>ทำนายถูก : '+ one +' %</div>' +
                    '<div>อัตตราการทำนายบเมื่อเป็นที่บ้าน : '+ two +' %</div>'+
                    '<div>อัตตราการทำนายบเมื่อเป็นที่โรงพยาบาล : '+ three +' %</div>' +
                '</div>' +
                '</div>' 

                all.forEach(element => {
                    one = 0
                    two = 0
                    three = 0
                    if(element[3] != 0){
                        one = (element[4]*100)/element[3]
                    }
                    if(element[7] != 0){
                        two = (element[5]*100)/element[7]
                    }
                    if(element[8] != 0){
                        three = (element[6]*100)/element[8]
                    }
                    all_list.innerHTML += 
                    '<div class="model" id="">' +
                    '<div style="display: flex; flex-direction: row; align-items: center;  gap: 40px;">' + 
                    '<h1 style="padding: 20px; border: 0.5px rgb(149, 149, 149) solid; border-radius: 10px;" id="">'+ element[1] +'</h1>' +
                    '<div>สร้างเมื่อ : '+ element[2] +'</div>' +
                    '</div>' +
                    '<div>' +
                    '<div style="display: flex; flex-direction: row; align-items: center;  gap: 30px;">' +
                        '<div>ทำนายไปเเล้ว : '+ element[3] +' รายการ</div>' +
                        '<div>ทำนายถูก : '+ one +' %</div>' +
                        '<div>อัตตราการทำนายบเมื่อเป็นที่บ้าน : '+ two +' %</div>'+
                        '<div>อัตตราการทำนายบเมื่อเป็นที่โรงพยาบาล : '+ three +' %</div>' +
                    '</div>' +
                    '</div>' +
                    '<div style="display: flex; justify-content: end;">' +
                    '<button style="ali" onclick = changemodel("'+ element[1] +'")>ใช้โมเดลนี้</button>' +
                    '</div>' +
                    '</div>' 
                });
            })
            .catch(error => console.error("Error:", error));
    </script>
</head>
<body>
    <%
	request.setAttribute("activePage", "model");
	request.setAttribute("pageTitle", "จัดการโมเดล");
	%>
	<jsp:include page="../include/navbar.jsp" />
	<jsp:include page="../include/header.jsp" />

    <div class="content">

        <div id="sucses" style="display: none;">
            <div style="display: flex; justify-content: center; align-items: center; font-size: 50px; color: #333;">
                รอสักครู่
            </div>
        </div>
        <div id="norm" style="display: block;">
            <h1>โมเดลที่ใช้งานอยู่</h1>
            <div class="model" id="used">
            
            </div>
            <div class="" style="display:flex ; flex-direction:row ; align-items: center; gap: 20px; margin-top: 40px;">
                <h1>โมเดลทั้งหมด</h1>
                <button onclick="createmodel()" >อัปเดตโมเดล</button>
            </div>
            <div id="all">

            </div>
        </div>
    </div>
    <script>
        console.log(name)
    </script>
    <jsp:include page="../include/toast.jsp" />
</body>
</html>