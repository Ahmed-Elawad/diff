 function numbersonly(e){
	var key;
	var keychar;
	if (window.event) {
		key = window.event.keyCode;
	}
	else if (e) {
		key = e.which;
	}
	else {
		return true;
	}
	keychar = String.fromCharCode(key);

	// control keys
	if ((key==null) || (key==0) || (key==8) || (key==9) || (key==13) || (key==27) ){
		return true;
	}
	// numbers
	else if ((("0123456789").indexOf(keychar) > -1)){
		return true;  
	}
	else {
		return false;
	}
} 
		
function validatePhone(pvId){
	var phone = document.getElementById(pvId); 
	var reg1 = /^(1\s|1|)?((\(\d{3}\))|\d{3})(\-|\s)?(\d{3})(\-|\s)?(\d{4})$/; 
	var reg2 = /^(1\s|1|)?((\(\d{3}\))|\d{3})(\.|\s)?(\d{3})(\.|\s)?(\d{4})$/;
	if(phone.value.match(reg1) || phone.value.match(reg2) ){ 
		console.log(phone.value);
		return true; 
	} 
	else { 
		console.log(phone.value+'not valid');
		alert('Please enter a valid 10 digit Phone #');
		phone.value = ''; 
		return false; 
	} 
}