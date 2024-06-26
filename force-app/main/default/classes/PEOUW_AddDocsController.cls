/* 
* Controller for the Add Documents component
*
* History
* -------
* 05/22/2023    Jidesh   	Created
*/

public without sharing class PEOUW_AddDocsController {
    
    @AuraEnabled
    public static PEO_Onboarding_Checklist__c getPEOOnboardingChecklist(Id accountId,PEO_Onboarding_Checklist__c oldChecklist,String formName) {
        
        PEO_Onboarding_Checklist__c checkList = CommunityMethods.getPEOOnboardingChecklist(accountId, oldChecklist, formName, 'PEOUW_AddDocsController');
        
        List<PEO_Onboarding_Document__c> existingDocs = new List<PEO_Onboarding_Document__c>();
        Map<String, PEO_Onboarding_Document__c> mapExistingDocs = new Map<String, PEO_Onboarding_Document__c>();
        existingDocs = [SELECT Id, Name FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c =: checkList.Id];
        for(PEO_Onboarding_Document__c extDoc : existingDocs){
            mapExistingDocs.put(extDoc.Name, extDoc);
        }
        
        List<PEO_Onboarding_Document__c> docs = new List<PEO_Onboarding_Document__c>();
        System.debug(checkList);
        if(checkList.Additional_Misc_Documents_Required__c){
            if(mapExistingDocs.get('Additional Misc Documents') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Additional Misc Documents', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Other'));
            }
        }
        if(checkList.Benefit_Summaries_Required__c){
            if(mapExistingDocs.get('Benefit Summary') == null && mapExistingDocs.get('Benefit Summaries') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Benefit Summary', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Benefit Summary'));
            }
        }
        if(checkList.CensusRequired__c){
            if(mapExistingDocs.get('Census') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Census', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Census'));
            }
        }
        if(checkList.Claims_Report_required__c){
            if(mapExistingDocs.get('Claims Report') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Claims Report', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Claims Report'));
            }
        }
        if(checkList.Health_Insurance_Renewal_required__c){
            if(mapExistingDocs.get('Health Insurance Renewal') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Health Insurance Renewal', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Health Insurance Renewal'));
            }
        }
      /*  if(checkList.Health_Insurance_Summary_required__c){
            if(mapExistingDocs.get('Health Insurance Summary') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Health Insurance Summary', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Health Insurance Summary'));
            }
        }*/
        if(checkList.Health_Invoice_required__c){
            if(mapExistingDocs.get('Health Invoice') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Health Invoice', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Health Invoice'));
            }
        }
        if(checkList.Loss_Runs_required__c){
            if(mapExistingDocs.get('Loss Runs') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Loss Runs', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='WC Loss Runs'));
            }
        }
        if(checkList.Medical_Invoice_Required__c){
            if(mapExistingDocs.get('Medical Invoice') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Medical Invoice', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Medical Invoice'));
            }
        }
        if(checkList.Miscellaneous_Docs_Required__c){
            if(mapExistingDocs.get('Misc Files - Medical') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Misc Files - Medical', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Misc Files - Medical'));
            }
        }
        if(checkList.Miscellaneous_Docs_Required_WC__c){
            if(mapExistingDocs.get('Misc Files - Workers\' Comp') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Misc Files - Workers\' Comp', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Misc Files - Workers\' Comp'));
            }
        }
        if(checkList.Payroll_Register_Required__c){
            if(mapExistingDocs.get('Payroll Register') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Payroll Register', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Payroll Register'));
            }
        }
        /*if(checkList.Payroll_Report_Required__c){
            if(mapExistingDocs.get('Payroll Report') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='Payroll Report', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='Payroll Report'));
            }
        }*/
        if(checkList.SUI_Required__c){
            if(mapExistingDocs.get('SUI Rate Forms') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='SUI Rate Forms', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='SUI Rate Forms'));
            }
        }
        if(checkList.WCClassesWages_Required__c){
            if(mapExistingDocs.get('WC Classes and Wages') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='WC Classes and Wages', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='WC Classes and Wages'));
            }
        }
        if(checkList.WC_Declarations_Required__c){
            if(mapExistingDocs.get('WC Declarations Page/PEO Current Rate') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='WC Declarations Page/PEO Current Rate', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='WC Declarations Page/PEO Current Rate'));
            }
        }
        if(checkList.WC_RatesAndPricing_Required__c){
            if(mapExistingDocs.get('WC Rates and Pricing') == null){
                docs.add(new PEO_Onboarding_Document__c(Name='WC Rates and Pricing', PEO_Onboarding_Checklist__c=checkList.Id, Routing_Name__c='WC Rates and Pricing'));
            }
        }
        if(docs.size() > 0){
            try {
                DMLHelper.performDML2(docs,DmlHelper.DML_UPSERT,'PEOUW_AddDocsController','getPEOOnboardingChecklist','By '+ UserInfo.getUserId(),true);
            }catch(Exception e) {
                CommunityMethods.logCommunityError(e, 'getPEOOnboardingChecklist','PEOUW_AddDocsController', 'PEOUW_AddDocsController',docs);
            }
        }
        return checkList;
    }   
}