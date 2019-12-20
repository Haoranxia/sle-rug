window.onload = function() {
    document.getElementById("hasSoldHouse").addEventListener("change", checkhasSoldHouse);
    document.getElementById("sellingPrice").addEventListener("change", updatevalueResidue);
    document.getElementById("privateDebt").addEventListener("change", updatevalueResidue);
}

function checkhasSoldHouse() {
    var hasSoldHouse = document.getElementById("hasSoldHouse");
    var ifhasSoldHouse = document.getElementById("ifhasSoldHouse");

    if (hasSoldHouse.checked == true) {
         ifhasSoldHouse.style.display = "block";
    }
    else {
         ifhasSoldHouse.style.display = "none"; 
    }
}

function updatevalueResidue() {
    var valueResidue = document.getElementById("valueResidue");
    
    var sellingPrice = document.getElementById("sellingPrice");
    
    var privateDebt = document.getElementById("privateDebt");
    
    valueResidue.innerHTML = sellingPrice - privateDebt;
}

