({
	doInit : function(component, event, helper) {
        console.log('Circular progress Controller');
        console.log('medPart progress:'+component.get('v.medPart'));
		helper.doInit(component, event, helper) ;
	}
})