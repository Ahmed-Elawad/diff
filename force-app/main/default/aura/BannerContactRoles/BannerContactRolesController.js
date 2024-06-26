({
	setPrimaryContact : function(component, event, helper) {
		helper.setPrimaryContact(component, event, helper);
	},

	navigateToContact : function(component, event, helper) {
		helper.navigateToContact(component, event, helper);
	},

	showModal : function(component, event, helper) {
        var hoverText = component.find("hover-text").getElement();
        component.set("v.hoverBaseElement", hoverText);
        component.set("v.showPopover", true);
	},
    
	hideModal : function(component, event, helper) {
        component.set("v.showPopover", false);
	},

	handleShowPopover : function(component, event, helper) {
        component.find('overlayLib').showCustomPopover({
            body: "Popovers are positioned relative to a reference element",
            referenceSelector: ".mypopover.hyperlink-text",
            cssClass: "popoverclass,slds-nubbin_right-top,no-pointer,cBannerContactRoles"
        }).then(function (overlay) {
            setTimeout(function(){ 
                //close the popover after 3 seconds
                overlay.close(); 
            }, 2000);
        });
    }

})