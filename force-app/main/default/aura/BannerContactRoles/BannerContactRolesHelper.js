({
	setPrimaryContact : function(component, event, helper) {
		var contactRoles = component.get("v.contactRoles");
		if(!!contactRoles){
			for(var i = 0; i < contactRoles.length; i++){
				if(contactRoles[i].IsPrimary){
					var id = contactRoles[i].ContactId;
                    console.log('contactRoles[i].ContactId' + contactRoles[i].ContactId);
					var name = contactRoles[i].Contact.Name;
					var DNC = contactRoles[i].Contact.DoNotCall; 
                    var EmailOpt = contactRoles[i].Contact.HasOptedOutOfEmail; 
					var mobilePhone = '';
					var phone = '';
                    var home = '';
                    var other=''; 
					var account = '';
					var title = '';
					var address = '';
					var email = '';
console.log("DNC" + DNC); 

					if(!!contactRoles[i].Contact.Phone){
						phone = contactRoles[i].Contact.Phone;
					}
                    if(!!contactRoles[i].Contact.HomePhone){
						home = contactRoles[i].Contact.HomePhone;
					}
                    if(!!contactRoles[i].Contact.OtherPhone){
                        other = contactRoles[i].Contact.OtherPhone; 
                    }
					if(!!contactRoles[i].Contact.Email){
						email = contactRoles[i].Contact.Email;
                        console.log('found email: '+email);
					}

					if(!!contactRoles[i].Contact.MobilePhone){
						mobilePhone = contactRoles[i].Contact.MobilePhone;
					}
					if(!!contactRoles[i].Contact.Account){
						account = contactRoles[i].Contact.Account;
					}

					if(!!contactRoles[i].Contact.Title){
						title = contactRoles[i].Contact.Title;
					}

					if(!!contactRoles[i].Contact.MailingAddress){
						address = contactRoles[i].Contact.MailingAddress;
					}
                    console.log("Other: "+other ); 	
                    component.set("v.primaryContact", {Id: id, Name: name, Phone: phone, HomePhone: home, OtherPhone: other, Account: account, Title: title, MobilePhone: mobilePhone, MailingAddress: address, Email: email, DoNotCall: DNC, HasOptedOutOfEmail: EmailOpt});
					component.set("v.primaryPhone", {label: "Mobile", phoneNumber: phone, phoneType: 'Mobile'});
		
                    break;

				}
			}
		}
	},

	navigateToContact : function(component, event, helper) {
		var primaryContact = component.get("v.primaryContact");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": primaryContact.Id,
        });
        navEvt.fire();
	},


})