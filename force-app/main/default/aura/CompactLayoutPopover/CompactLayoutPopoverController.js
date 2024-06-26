({
	doInit : function(component, event, helper){
		helper.storePopoverSizeAndHide(component, event, helper);
	},

    showHidePopover : function(component, event, helper){
        var isHovered = component.get("v.isHovered");
        if(isHovered){
            helper.showModal(component, event, helper);
        }else{
            helper.hideModal(component, event, helper);
        }
    },

    positionPopover : function(component, event, helper){
        var modalShown = component.get("v.modalShown");
        if(modalShown){
    		helper.positionPopover(component, event, helper);
    	}
    },

    setPopoverHovered : function(component, event, helper){
    	component.set("v.popoverHovered", true);
    },

    setPopoverUnhovered : function(component, event, helper){
    	component.set("v.popoverHovered", false);
    }
    
	
})