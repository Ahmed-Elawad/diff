({
    addTabNumbers: function(component, event, helper) {
        
        var tabNames = [];
        var initTabNum = 0;
        if(component.get('v.censusRequired'))tabNames.push('CensusLabel');
        if(component.get('v.medInvReq'))tabNames.push('medInvReqLabel');
        if(component.get('v.benefitSummReq'))tabNames.push('benefitSummReqLabel');//BenefitSummary
        //if(component.get('v.hlthInsSummReqd'))tabNames.push('hlthInsSummReqdLabel');//Benefit Summary
         if(component.get('v.hlthInsRenwReqd'))tabNames.push('hlthInsRenwReqdLabel');
        if(component.get('v.claimsReportRequired'))tabNames.push('claimsReportRequiredLabel');
        if(component.get('v.payrollRegReqd'))tabNames.push('payrollRegReqdLabel');
        	//if(component.get('v.payrollReportReq'))tabNames.push('payrollReportReqLabel');       
          if(component.get('v.misMedReqd'))tabNames.push('misMedReqdLabel');
              
        if(component.get('v.lossRunsReqd'))tabNames.push('lossRunsReqdLabel');
        if(component.get('v.wcRtNPrcReqd'))tabNames.push('WCpricingLabel');
         if(component.get('v.misWCReqd'))tabNames.push('misWCReqdLabel');
        if(component.get('v.wcDecReqd'))tabNames.push('wcDecReqdLabel'); 
        if(component.get('v.suiReqd'))tabNames.push('suiReqdLabel');
       
        
     //if(component.get('v.misMedReqd') && !component.get('v.isCommunityUser'))tabNames.push('misHSFReqdLabel');
        if(component.get('v.hlthInvReqd'))tabNames.push('hlthInvReqdLabel');
          if(component.get('v.AddntlDocsRqd'))tabNames.push('AddntlDocsRqdLabel'); 	
         if(component.get('v.wcReqd'))tabNames.push('wcReqdLabel');	//Workers' Comp Classes and Wages
        
        if(tabNames.length>0){
            var uploadTabs = component.get('v.uploadTabs');
            tabNames.forEach(function (item, index) {
                initTabNum++;
                //Add the tab to uploadTabs list for Save and Next between Docs
                let tablabel = component.get(`v.`+item);
                if(tablabel=='Benefit Summary'){
                    if(item=='benefitSummReqLabel')
                        tablabel='BenefitSummary';
                    
                    if(item=='hlthInsSummReqdLabel')
                        tablabel='Benefit Summary';
                }
                uploadTabs.push(tablabel);
                console.log('item, index', item, index, tablabel);
                // component.set(`v.`+item, initTabNum+'.'+component.get(`v.`+item));
            });
            component.set('v.uploadTabs',uploadTabs);
        }
    },
    
    getOnBoardingDocs: function(component, event, helper){
        console.log('Enetered into getPEOOnboardingDocs');
        let getPEOOnboardingDocs = component.get('c.getPEOOnboardingDocs');
        
        getPEOOnboardingDocs.setParams({
            recordId: component.get('v.checklist.Id')
        });
        
        getPEOOnboardingDocs.setCallback(this, function(res) { 
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
            }
            let data = res.getReturnValue();
            console.log('OnBoardingDocs: ', JSON.stringify(data));              
            const tabNamesMap = {
                 CensusLabel: "Census",
                medInvReqLabel: "Medical Invoice",
                benefitSummReqLabel: "Benefit Summary",  
                 hlthInsRenwReqdLabel: "Health Insurance Renewal",
                 claimsReportRequiredLabel: "Claims Report",
                //payrollReportReqLabel: "Payroll Report",               
                hlthInvReqdLabel: "Health Invoice",
                hlthInsSummReqdLabel: "Health Insurance Summary",
                wcReqdLabel: "WC Classes and Wages",
                misMedReqdLabel: "Misc Files - Medical",
                AddntlDocsRqdLabel: "Additional Misc Documents",
                lossRunsReqdLabel: "Loss Runs",
                wcDecReqdLabel: "WC Declarations Page/PEO Current Rate",
                //misHSFReqdLabel: "HSF Census",
                suiReqdLabel: "SUI Rate Forms",
                WCpricingLabel: "WC Rates and Pricing",
                misWCReqdLabel: "Misc Files - Workers' Comp",
                payrollRegReqdLabel: "Payroll Register"                
            };
            
            var doclists=[];
            for(var key in tabNamesMap){  
                console.log('Tab Name: ' + key);
                component.set(`v.icon`+key, "utility:stop");
                component.set(`v.ast`+key, false);
                var fndrow = data.filter(function (el){
                    return  el.Name==tabNamesMap[key];
                });
                if(fndrow[0]!=undefined)
                {
                    console.log('updatedrow 1 - ' + fndrow[0] );
                    let tablabel=component.get(`v.`+key);
                    
                    if(tablabel=='Benefit Summary'){
                            if(key=='benefitSummReqLabel')
                                tablabel='BenefitSummary';
                            
                            if(key=='hlthInsSummReqdLabel')
                                tablabel='Benefit Summary';
                        }
                    
                    let updatedrow = fndrow[0].TabLabel=tablabel;                       
                   doclists.push(fndrow[0]);
                    
                    if(fndrow[0].PEO_Doc_Required__c=='Needed'){                                                 
                        component.set(`v.ast`+key, true);
                        //component.set(`v.ast`+key, "utility:frozen");
                    }
                    
                    if(fndrow[0].Status__c==undefined || fndrow[0].Status__c==null || fndrow[0].Status__c=='Purged'){
                        component.set(`v.icon`+key, "utility:stop");
                    }
                    else
                    {
                        component.set(`v.icon`+key, "utility:success");
                        //component.set('v.iconwcReqdLabel',"utility:success"); 
                    }                        
                }
            } // for loop   
            console.log('docs' + JSON.stringify(doclists));
            component.set('v.OnboardingChecklists', doclists);
            component.set('v.init', true);
        })
        $A.enqueueAction(getPEOOnboardingDocs);
        component.set('v.isLoading', false); 
    },

    sendSaveCompleteChatter : function(component, event, helper){
        console.log('checklistId'+ component.get("v.checklist.Id"));
        console.log('isTraditional'+ component.get("v.isTraditional"));
        var action = component.get("c.postSaveAndCompleteChatter");
        action.setParams({
            checkListId : component.get("v.checklist.Id"),
            isTraditional : component.get("v.isTraditional")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('response.getReturnValue updatesendpostchatter'+response.getReturnValue());
            if(state === "SUCCESS"){
                console.log("Chatter Posted"+response.getReturnValue());
            }else{
                console.log('errorrrrrrrrr');
            }


            console.log('Inside sendCommunityFormsTabUpdate');
            let tabNavigateEVt = component.getEvent('communityFormsTabNavigate');
            tabNavigateEVt.setParams({
                direction: 1,
                skipToVerificationScreen: 1
            }); // this needs to go to the page after the submit screen
            tabNavigateEVt.fire();   
        });
        $A.enqueueAction(action);
    },
    showUserMsg: function(cmp, err) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: err.t,
            message: err.m,
            type: err.ty
        });
        toastEvent.fire(); 
    }
})