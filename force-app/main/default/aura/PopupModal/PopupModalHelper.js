({
	toggleModalDisplay : function(component) {
		var shouldDisplay = component.get("v.isVisible");
		if(shouldDisplay){
			this.openModal(component);
		}else{
			this.closeModal(component);
		}
	},

    closeModal : function(component){    
    	var cmpTarget = component.find('generic-popup-Modalbox');
    	var cmpBack = component.find('generic-popup-Modalbackdrop');
    	$A.util.removeClass(cmpBack,'slds-backdrop--open');
    	$A.util.removeClass(cmpTarget, 'slds-fade-in-open');
    	component.set("v.isVisible", false);
    },

    openModal : function(component) {
	    var cmpTarget = component.find('generic-popup-Modalbox');
   		var cmpBack = component.find('generic-popup-Modalbackdrop');
    	$A.util.addClass(cmpTarget, 'slds-fade-in-open');
    	$A.util.addClass(cmpBack, 'slds-backdrop--open'); 
    	component.set("v.isVisible", true);
    },
})