({
	init : function(component, event, helper) {
		component.set('v.columns', [
            {label: 'Name', fieldName: 'name', type: 'text'},
            {label: 'Email', fieldName: 'email', type: 'email'},
            {label: 'Admin CPA', fieldName: 'adminCPA', type: 'boolean'},
            {label:'Status',fieldName:'status',type:'text'}
        ]);
        
        helper.fetchReferralCons(component, event);
        helper.checkAccessPerm(component, event, helper);

       
	}
})