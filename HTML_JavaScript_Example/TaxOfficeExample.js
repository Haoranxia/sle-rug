
window.onload = function() {
	document.getElementById("sellingPrice").addEventListener("change", updateValueResidue);
	document.getElementById("privateDebt").addEventListener("change", updateValueResidue);
	document.getElementById("hasBoughtHouse").addEventListener("change", checkHasBoughtHouse);
}


function updateValueResidue() {
	var sellingPrice = document.getElementById("sellingPrice");
	var privateDebt = document.getElementById("privateDebt");
	var valueResidue = document.getElementById("valueResidue");
	valueResidue.value = sellingPrice.value - privateDebt.value;
	valueResidue.innerHTML = valueResidue.value;
}

function checkHasBoughtHouse() {
	var hasBoughtHouse = document.getElementById("hasBoughtHouse");
	var ifHasBoughtHouse = document.getElementById("ifHasBoughtHouse");
	
	if (hasBoughtHouse.checked == true) {
		ifHasBoughtHouse.style.display = "block";
	}
	else {
		ifHasBoughtHouse.style.display = "none";
	}
	
}
