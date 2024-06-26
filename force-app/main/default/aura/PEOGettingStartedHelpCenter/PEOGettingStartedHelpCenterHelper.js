({
	getRunningUser : function(component,event) {
		return new Promise(function(resolve, reject) {
            console.log('in promise');
            let getSalesRepApex = component.get('c.getSalesRep');
            
            //getSalesRepApex.setParams();
            getSalesRepApex.setCallback(this, function(res) {
                if (res.getState() != 'SUCCESS' || !res.getReturnValue()) {
                    console.log(res.getError())
                    let t = 'Record Retrieval Error';
                    let m = 'Failed to retrieve Sales Rep. Please contact your sales rep for support.';
                    let ty = 'error';                  
                    reject({
                        t: t,
                        m: m,
                        ty: ty
                    });
                }
                let salesRepJS = res.getReturnValue();
                if(salesRepJS){
                    console.log('salesRep'+salesRepJS.Name);
                    salesRepJS.Name = salesRepJS.FirstName+' '+salesRepJS.LastName;
                	component.set('v.salesRep', salesRepJS);
                }
                
                resolve(true);
            });
            $A.enqueueAction(getSalesRepApex);
        });
	},
    getOpenCases : function(component,event) {
		return new Promise(function(resolve, reject) {
            console.log('in case');
            
            component.set('v.caseColumns', [
            	{label: 'Case Number', fieldName: 'CaseNumber', type: 'text'},
            	{label: 'Date Opened', fieldName: 'CreatedDate', type: 'date'},
                {label: 'Subject', fieldName: 'Subject', type: 'text'},
                {label: 'Description', fieldName: 'Description', type: 'text'},
                {label: 'Status', fieldName: 'Status', type: 'text'}
            ]);
            let getCases = component.get('c.getProspectCases');
            
            //getSalesRepApex.setParams();
            getCases.setCallback(this, function(res) {
                if (res.getState() != 'SUCCESS' || !res.getReturnValue()) {
                    console.log(res.getError())
                    let t = 'Case Retrieval Error';
                    let m = 'Failed to retrieve open cases. Please contact your sales rep for support.';
                    let ty = 'error';                  
                    reject({
                        t: t,
                        m: m,
                        ty: ty
                    });
                }
                let allOpenCases = res.getReturnValue();
                if(allOpenCases.length > 0){
                    console.log('allOpenCases'+allOpenCases.length);
                	component.set('v.openCases', allOpenCases);
                }
                resolve(true);
            });
            $A.enqueueAction(getCases);
        });
	}
})