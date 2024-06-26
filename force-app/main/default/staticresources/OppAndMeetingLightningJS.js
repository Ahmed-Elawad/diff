function requiredFieldsPopulated(){
	var requiredFields = getElementsByClassName('required-opp-meeting-input');
	var fieldsAreValid = true;

	for(var i = 0; i < requiredFields.length; i++){
		console.dir(requiredFields[i]);
		console.dir(requiredFields[i].value)
		if(!requiredFields[i].value){
			fieldsAreValid = false;
			if(!requiredFields[i].className.includes('form-element-error')){
				requiredFields[i].className += ' form-element-error';
			}
		}else{
			if(requiredFields[i].className.includes('form-element-error')){
				requiredFields[i].className = requiredFields[i].className.replace('form-element-error', '');
			}
		}
	}

	if(fieldsAreValid){
		buttonsEnabled(false);
		document.getElementById('statusSpinner').style.visibility='visible';
	}else{
		toastr.error('You must populate all required fields');
	}
	console.log('The fields are valid: ' + fieldsAreValid);
	return fieldsAreValid;

}
