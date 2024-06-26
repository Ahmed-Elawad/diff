({
    navToNextStage: function(component, event, helper) {
        try{
            event.preventDefault();
            let tabNavigateEVt = component.getEvent('communityFormsTabNavigate');
            tabNavigateEVt.setParam('direction', 1);
            tabNavigateEVt.fire();  
        }catch(e) {
            console.log(e)
        }
    },
    
    addTabNumbers: function(component, event, helper) {
        
        var tabNames = [];
        var initTabNum = 0;
        tabNames.push('WCLabel');
        if(component.get('v.noIndustryFound')!= true){
            tabNames.push('IndustryTabLabel');
        }
      //  if(component.get('v.showCovidQuestionnaire'))tabNames.push('covidLabel');
        tabNames.push('FileUploadLabel');
        if(component.get('v.Account.NAICS_Code__c')){
            tabNames.push('BenchmarkLabel');
        }
        if(tabNames.length>0){
            tabNames.forEach(function (item, index) {
                initTabNum++;
                console.log(item, index);
                component.set(`v.`+item, initTabNum+'.'+component.get(`v.`+item));
            });
        }
    },
    
    checkPermissions : function(cmp, e, helper){
        console.log('Inside WC checkPermissions');
        console.log('CLabel:'+$A.get("$Label.c.PEOUWBenchmarkPermission"));
        console.log('Checklist rep:'+cmp.get('v.Checklist.Sales_Rep__c'));
        let permissionCheck = cmp.get('c.checkBLSPermissions');
        permissionCheck.setParams({
            userId:cmp.get('v.Checklist.Sales_Rep__c'),
            benchMarkPermission: $A.get("$Label.c.PEOUWBenchmarkPermission")
        });
        
        // on response we need to reject if there's an error
        // otherwise if the viewed tab is for a parent account
        // set the medical questionnaire as the updated
        // medical questionnaire value.
        permissionCheck.setCallback(this, function(res) {
            console.log('Set callback');
            if (res.getState() !== 'SUCCESS') {
                console.error(res.getError());
                //reject(res.getError());
                return;
            }
            var hasPermissions = res.getReturnValue();
            console.log('hasPermissions:'+hasPermissions);
            cmp.set('v.hasBenchmarkPermission',hasPermissions);
        })
        $A.enqueueAction(permissionCheck);
    }, 
})