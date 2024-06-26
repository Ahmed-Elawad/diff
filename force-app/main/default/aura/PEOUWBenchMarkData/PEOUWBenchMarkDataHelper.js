({
    helperFunctionAsPromise : function(component, event, helper, helperFunction) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(component, event, helper, resolve, reject);
        }));
    },
    //resolve(true);
    buildDatainSF : function(component, event, helper, resolve, reject) {
        //debugger;
        console.log('helper buildDatainSF');
        var chk = component.get("v.PEOChecklist");
        var chkaccount = component.get("v.currentAccount");
        console.log('buildDatainSF Naics:'+chkaccount.NAICS_Code__c);
        console.log('Naics length:'+chkaccount.NAICS_Code__c.length);
        let benchMarkValues = component.get('c.checkIfBenchmarkValuesExist');
        
        benchMarkValues.setParams({
            account:chkaccount,
            checklist: chk
        });
        
        benchMarkValues.setCallback(this, function(res) {
            //debugger;
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
                component.set('v.averageWages','Not Available');
                component.set('v.medPart','Not Available');
                component.set('v.turnOverrate','Not Available');
                component.set('v.surveyYear','Not Available');	
                let t = 'Error',
                    m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                    ty = 'Error';
                reject({t: t, m: m, ty: ty});
            }
            else{
                let data = res.getReturnValue();
                console.log('buildDatainSF Data from BLS Object:');
                console.log(data);
                if(data == false){
                    console.log(res.getError());
                    console.log('Show error toast');
                    console.log('Set values to Not Available');
                    component.set('v.averageWages','Not Available');
                    component.set('v.medPart','Not Available');
                    component.set('v.turnOverrate','Not Available');
                    component.set('v.surveyYear','Not Available');	 
                    let t = 'Error',
                        m = 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                        ty = 'Error';
                    reject({t: t, m: m, ty: ty});
                }
                resolve(true);
            }
        })
        $A.enqueueAction(benchMarkValues);
    },
    
    fetchDataFromSF : function(component, event, helper) {
        console.log('helper fetchDataFromSF');
        var chk = component.get("v.PEOChecklist");
        
        let benchMarkValues = component.get('c.retrieveBenchmarkValues');
        
        benchMarkValues.setParams({
            checklist: chk
        });
        
        benchMarkValues.setCallback(this, function(res) {
            //debugger;
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }
            let data = res.getReturnValue();
            console.log('Data from BLS Object:');
            console.log(data);
            for (var key in data) {
                console.log('key'+key);
                console.log('value'+data[key]);
                var value = data[key];
                if(key == 'avgWage'){
                    console.log('key Match');
                    component.set('v.averageWages',value.toString().replace(/\D/g, '').replace(/\B(?=(\d{3})+(?!\d))/g, ','));
                }
                if(key == 'medPart'){
                    component.set('v.medPart',value.toString());
                    //component.set('v.medPart','105');
                }
                if(key == 'turnOver'){
                    component.set('v.turnOverrate',value.toString());
                    //component.set('v.medPart','105');
                }
                if(key == 'avgWageYear'){
                    component.set('v.surveyYear',value);
                }
            }
            console.log('averageWages'+component.get('v.averageWages'));
        })
        $A.enqueueAction(benchMarkValues);
    },
    
    handleError: function(data) {
        var event = $A.get("e.force:showToast");
        event.setParams({
            title: data.t,
            message: data.m,
            type: data.ty
        });
        event.fire();
        
        if (data.broke) $A.get("e.force:closeQuickAction").fire();
    },
    
    refreshCmp: function (component, event, helper){
        console.log('Refreshing component');
        //$A.get('e.force:refreshView').fire();
        if(component.get('v.refreshCounter') == 5){
            console.log('End of wait, Show toast');
            let dets = {ty: 'warning', t: 'No data received', m:  'Looks like BLS system is not available at the moment. Please try again after sometime or Contact your system administrator'};
            this.showUserMsg(null, dets);
            component.set('v.medPart','0');
            component.set('v.turnOverrate','0');
            component.set('v.averageWages','0');
        }
        else{
            var a = component.get('c.fetchBenchmarkValues');
            $A.enqueueAction(a);
        }
    },
    
    showUserMsg: function(cmp, err) {
        console.log('Shpuld show msg')
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: err.t,
            message: err.m,
            type: err.ty
        });
        toastEvent.fire(); 
    },
    
    
})