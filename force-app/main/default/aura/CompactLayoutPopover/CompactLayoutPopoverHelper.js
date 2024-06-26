({
    storePopoverSizeAndHide : function(component, event, helper){
        
        var positioning = component.get("v.positioning");

        if(!positioning){

            var modal = component.find("hover-modal");
            var hoverText = component.get("v.hoverElement");

            var referencePosition = hoverText.getBoundingClientRect();
            var popoverPosition = modal.getElement().getBoundingClientRect();

            var positioning = {
                reference : {
                    w: referencePosition.width,
                    h: referencePosition.height,
                    t: referencePosition.top,
                    b: referencePosition.bottom,
                    l: referencePosition.left,
                    r: referencePosition.right
                },
                popover : {
                    w: popoverPosition.width,
                    h: popoverPosition.height,
                    t: popoverPosition.top,
                    b: popoverPosition.bottom,
                    l: popoverPosition.left,
                    r: popoverPosition.right
                }
            }

            component.set("v.positioning", positioning);


        }else{

            var hoverText = component.get("v.hoverElement");
            var referencePosition = hoverText.getBoundingClientRect();
            if(referencePosition.left != positioning.reference.l || referencePosition.top != positioning.reference.t){
                positioning.reference.w = referencePosition.width;
                positioning.reference.h = referencePosition.height;
                positioning.reference.t = referencePosition.top;
                positioning.reference.b = referencePosition.bottom;
                positioning.reference.l = referencePosition.left;
                positioning.reference.r = referencePosition.right;
            }

            component.set("v.positioning", positioning);
        }


    },

	showModal : function(component, event, helper) {
		var modal = component.find("hover-modal");
        $A.util.removeClass(modal, 'slds-hide');


        var positioning = component.get("v.positioning");

        var modalRight = positioning.reference.l - positioning.popover.w - 25;
        var modalTop = positioning.reference.t - 32;
        modal.getElement().style.left = modalRight + 'px';
        modal.getElement().style.top = modalTop + 'px';


	},
	hideModal : function(component, event, helper) {
        setTimeout(function(){

            var popoverHovered = component.get("v.popoverHovered");
            var isHovered = component.get("v.isHovered");

            if(!isHovered && !popoverHovered){
                var modal = component.find("hover-modal");
                $A.util.addClass(modal, 'slds-hide');
            }else{
                helper.hideModal(component, event, helper);
            }

        }, 100);
	},

    positionPopover : function(component, event, helper){
        var modal = component.find("hover-modal");
        var hoverText = component.get("v.hoverElement");
        var boundingRectangle = hoverText.getBoundingClientRect();
        var w = boundingRectangle.width;
        var h = boundingRectangle.height;
        var t = boundingRectangle.top;
        var l = boundingRectangle.left;
        var r = boundingRectangle.right;

        var modalWidth = modal.getElement().getBoundingClientRect().width;
        
        var modalRight = l - modalWidth - 20;
        var modalLeft = w + l + 20;
        var modalTop = t - 25;
        modal.getElement().style.display = "";
        modal.getElement().style.left = modalRight + 'px';
        modal.getElement().style.top = modalTop + 'px';
        $A.util.removeClass(modal, 'slds-hide');
        var modalWidth = modal.getElement().getBoundingClientRect().width;
        console.log(modalWidth);
    }
})