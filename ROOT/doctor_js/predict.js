function openTab(evt, labName) {
  var i, tabcontent, tablinks;

  tabcontent = document.getElementsByClassName("checkbox-group");
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = "none";
  }

  if (evt !== null) {
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
      tablinks[i].className = tablinks[i].className.replace(" active", "");
    }
    evt.currentTarget.className += " active";
  }

  document.getElementById(labName).style.display = "flex";
}
document.addEventListener("DOMContentLoaded", function () {
  document.getElementById("tabChem").style.display = "flex";

  document.querySelectorAll('input[type="checkbox"]').forEach(cb => {
    cb.addEventListener('change', updateSelected);
  });

  updateSelected();
  
});


function resetCheckbox() {
  const activeTab = Array.from(document.querySelectorAll('.tab-content'))
    .find(tab => tab.style.display !== "none");
  if (activeTab) {
    const checkboxes = activeTab.querySelectorAll('input[type="checkbox"]');
    checkboxes.forEach(cb => cb.checked = false);
  }

  document.getElementById('result').innerHTML = 'ยังไม่ได้เลือก Lab';
}
function updateSelected() {
    selectedLabs = [];
    document.querySelectorAll('input[type="checkbox"]').forEach(cb => {
        if(cb.checked) selectedLabs.push(cb.value);
    });
    console.log("selectedLabs =", selectedLabs);

    const resultDiv = document.getElementById("result");
    if(resultDiv){
        resultDiv.innerText = selectedLabs.length ? selectedLabs.join("\n") : "ยังไม่ได้เลือก Lab";
    }
}
function openLabSelection() {
    document.getElementById("lablistbox").style.display = "block";
    document.getElementById("selectedUnit1").style.display = "none";
}
function closeLabSelection() {
    document.getElementById("selectedUnit1").style.display = "grid";
    document.getElementById("lablistbox").style.display = "none";
    //ใส่ผลการทำนาย
}
function predict() {
  document.getElementById("selectedUnit2").style.display = "grid";
  document.getElementById("lablistbox").style.display = "none";
}
function backtoselectlab() {
  document.getElementById("selectedUnit2").style.display = "none";
  document.getElementById("lablistbox").style.display = "block";
}