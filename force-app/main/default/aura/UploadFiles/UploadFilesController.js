({
    setupUpload : function(component, event, helper){  
        console.table({
            isMedPrequal: component.get('v.isMedPrequal'),
            benefitSummReq: component.get('v.benefitSummReq'),
            medInvReq: component.get('v.medInvReq'),
            //payrollReportReq: component.get('v.payrollReportReq'),
            censusRequired: component.get('v.censusRequired'),
            claimsReportRequired: component.get('v.claimsReportRequired'),
            hlthInsRenwReqd: component.get('v.hlthInsRenwReqd'),
            hlthInsSummReqd: component.get('v.hlthInsSummReqd'),
            hlthInvReqd: component.get('v.hlthInvReqd'),
            lossRunsReqd: component.get('v.lossRunsReqd'),
            payrollRegReqd: component.get('v.payrollRegReqd'),
            suiReqd: component.get('v.suiReqd'),
            wcDecReqd: component.get('v.wcDecReqd'),
            wcReqd: component.get('v.isMedPrequal'),
            wcRtNPrcReqd: component.get('v.wcRtNPrcReqd'),
            misMedReqd: component.get('v.misMedReqd'),
            misWCReqd: component.get('v.misWCReqd'),
            AddntlDocsRqd: component.get('v.AddntlDocsRqd'),
            uploadParentPEOChecklist: component.get('v.uploadParentPEOChecklist'),
            wcClsNWgsReqd: component.get('v.wcClsNWgsReqd'),
            PEOChecklist: component.get('v.PEOChecklist')
        });
        //debugger;
        var checkList = component.get("v.checklist");
        if(checkList){
            var WCPath = checkList.Workers_Comp_Underwriting_Path_Type__c;
            var medPath = checkList.Medical_Underwriting_Path_Type__c;
            var isTraditional = true;
            if(WCPath){
                WCPath = WCPath.toLowerCase();
                isTraditional = WCPath.includes('traditional');
            }
            if(medPath){
                medPath = medPath.toLowerCase();
                isTraditional = medPath.includes('traditional');
            }
            
            component.set("v.isTraditional", isTraditional);
			if((checkList.CS_CM_Medical_UW_Status__c=='More Info Needed'
               	&& checkList.Medical_Quick_Quote_Eligibility__c	=='Full Underwriting Required')
              || (checkList.CS_CM_WC_UW_Status__c=='More Info Needed'
               	&& checkList.Workers_Comp_Quick_Quote_Eligibility__c =='Full Underwriting Required')){
                 component.set("v.disableCensus", false);                
            }
            else if((component.get("v.disableMedicalUpload") || component.get("v.disableFilesUpload")
                     || component.get("v.checklist.HSF_Submission_Status__c") == 'SUCCESS') 
                    && checkList.Medical_Quick_Quote_Eligibility__c != 'Full Underwriting Required'){
                component.set("v.disableCensus", true);   
            }
        }
        console.log(component.get('v.wcReqd'));
        console.log(component.get('v.isCommunityUser'));
        helper.getOnBoardingDocs(component, event, helper);
        helper.addTabNumbers(component, event, helper);
        if(component.get('v.currentAccount.NAICS_Code__c') != null && component.get('v.hasBenchmarkPermission') && component.get('v.currentAccount.ShippingPostalCode')  != null && component.get('v.checklist.display_Benchmark_tab__c') == true && component.get('v.currentAccount.SalesParent__c') == null){
            component.set('v.benchMarkTabRequired', true);
            console.log('Upload files setting benchMarkTabRequired true');
        }
    },  
    
    HelpMeData:function(component, event, helper) {
    },
    handleFocus:function(cmp, event, helper) {
        console.log('focus');
        let Nextchevron=true;
           
        var UploadDocsList = cmp.get('v.OnboardingChecklists');
        UploadDocsList.forEach((doc) => {
            if(doc.PEO_Doc_Required__c=='Needed' && (doc.Status__c==undefined || doc.Status__c==null)){
                              Nextchevron=false;
                    }
         });
        console.log('Docs not Required?: ' + Nextchevron );
        cmp.set("v.requiredDocsUploaded", Nextchevron );
    },
 
    showTitle:function(component, event, helper) {
        component.set("v.showButtonTitle",true);
    },
    hideTitle:function(component, event, helper) {
        component.set("v.showButtonTitle",false);
    },
    handleCustomCmpEvent:function(component, event, helper) {	
        		var AllDocList = component.get('v.OnboardingChecklists');
        //console.log('docs:' +  JSON.stringify(AllDocList));
        		var documentName=event.getParam("documentName");
        		var actiontype=event.getParam("actiontype");	
        		var attscount=event.getParam("numofattachments");
        console.log('documentName',documentName);
       var doclabel = documentName.replace('icon','');
       var labelval= component.get(`v.`+doclabel);
        console.log('doclabel', labelval); 
        
        if(labelval=='Benefit Summary'){
            if(documentName=='iconbenefitSummReqLabel')
                labelval='BenefitSummary';
            
            if(documentName=='iconhlthInsSummReqdLabel')
                labelval='Benefit Summary';
        }
        
         var fndrow = AllDocList.filter(function (el)
                        {
                        	return  el.TabLabel==labelval;
                        }
                    );
        console.log('fndrow:', fndrow[0].Name); 
           
        if(actiontype=='Add'){
            component.set(`v.`+documentName, "utility:success");
            fndrow[0].Status__c='success';
        }
        else if(actiontype=='Delete' && attscount<=1){
           	component.set(`v.`+documentName, "utility:stop");
            fndrow[0].Status__c=null;
        }
       // helper.getOnBoardingDocs(component, event, helper);
    },
    docListChanged : function(cmp, e, helper){
        let Nextchevron=true;
           
        var UploadDocsList = cmp.get('v.OnboardingChecklists');
        UploadDocsList.forEach((doc) => {
            if(doc.PEO_Doc_Required__c=='Needed' && (doc.Status__c==undefined || doc.Status__c==null)){
                              Nextchevron=false;
                    }
         });
          console.log('Docs not Required?: ' + Nextchevron );
          cmp.set("v.requiredDocsUploaded", Nextchevron );
    },
    sendCommunityFormsTabUpdate: function(cmp, e, helper) {
        try {
           
            helper.sendSaveCompleteChatter(cmp, e, helper);
            
        }catch(err){
            console.error(err);
        }
    }
})