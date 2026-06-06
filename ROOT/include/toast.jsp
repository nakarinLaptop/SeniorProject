<div id="toast" class="toast"></div>

<style>
.toast{
    position: fixed;
    top: 70px;
    right: 20px;
    border: 1px solid #333;
    background-color: white;
    color: black;
    padding: 12px 20px;
    border-radius: 6px;
    opacity: 0;
    pointer-events: none;
    transition: .5s;
    z-index: 9999;
}
.toast.show{ opacity: 1; } 
</style>

<script>
function showToast(msg, type){
    const toast = document.getElementById("toast");
    if (!toast) {
        console.error("Toast element not found");
        return;
    }
    toast.textContent = msg;
    toast.classList.add("show");
    
    if(type === "success"){
        toast.style.borderColor = "green";
    } else if(type === "error"){
        toast.style.borderColor = "red";
    } else {
        toast.style.borderColor = "black";
    }
    
    setTimeout(()=>{
        toast.classList.remove("show");
    }, 10000);
}
</script>

<%
String toastMsg = (String) session.getAttribute("patientError");
if (toastMsg != null) {
    session.removeAttribute("patientError");
}
%>

<script>
<% if (toastMsg != null) { %>
    showToast("<%= toastMsg %>");
<% } %>
</script>
