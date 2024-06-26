public class CSOProgressBar {
    @AuraEnabled
    public static CSOWrapper getTracking(string recordId){
        CSO_Tracking__c csTracking = [SELECT Id,Opportunity__c,AddEmpsCompleted__c,Contact__c,BankingInfoCompleted__c,BusinessInfoCompleted__c,IsStalled__c,ClientStalledLatest__c,DocsCompleted__c,FirstStepsCompleted__c,RegistrationStart__c,
                                      PayScheduleCompleted__c,DocMSAReceived__c	, PriorPayrollCompleted__c, SubmitCompleted__c, TaxInfoCompleted__c FROM CSO_Tracking__c WHERE Opportunity__c =:recordId];
        CSOWrapper csw = new CSOWrapper();
        csw.AddEmpsCompleted = dateFormat(csTracking.AddEmpsCompleted__c);
        csw.BankingInfoCompleted = dateFormat(csTracking.BankingInfoCompleted__c);
        csw.BusinessInfoCompleted = dateFormat(csTracking.BusinessInfoCompleted__c);
        csw.DocsCompleted = dateFormat(csTracking.DocsCompleted__c);
        csw.FirstStepsCompleted = dateFormat(csTracking.FirstStepsCompleted__c);
        csw.PayScheduleCompleted = dateFormat(csTracking.PayScheduleCompleted__c);
        csw.QuoteSignedDate = dateFormat(csTracking.DocMSAReceived__c);
        csw.PriorPayrollCompleted = dateFormat(csTracking.PriorPayrollCompleted__c);
        csw.SubmitCompleted = dateFormat(csTracking.SubmitCompleted__c);
        csw.TaxInfoCompleted = dateFormat(csTracking.TaxInfoCompleted__c);
        csw.isStalled = csTracking.IsStalled__c;
        csw.latestStallDate = dateFormat(csTracking.ClientStalledLatest__c);
        csw.contactId = csTracking.Contact__c;
        csw.RegistrationStart = dateFormat(csTracking.RegistrationStart__c);
        
        return csw;
    }
    
    public class CSOWrapper{
        @AuraEnabled Public String AddEmpsCompleted{get;set;}
        @AuraEnabled Public String BankingInfoCompleted{get;set;}
        @AuraEnabled Public String BusinessInfoCompleted{get;set;}
        @AuraEnabled Public String DocsCompleted{get;set;}
        @AuraEnabled Public String FirstStepsCompleted{get;set;}
        @AuraEnabled Public String PayScheduleCompleted{get;set;}
        @AuraEnabled Public String PriorPayrollCompleted{get;set;}
        @AuraEnabled Public String SubmitCompleted{get;set;}
        @AuraEnabled Public String TaxInfoCompleted{get;set;}
        @AuraEnabled Public String QuoteSignedDate{get;set;}
        @AuraEnabled Public Boolean isStalled{get;set;}
        @AuraEnabled Public String latestStallDate{get;set;}
        @AuraEnabled Public String contactId{get;set;}
        @AuraEnabled Public String RegistrationStart{get;set;}
        
    }
    
    public static string dateFormat(DateTime dt){
        if(dt!=null){
            String formattedDate = '';
            formattedDate = 'on '+dt.month()+'/'+dt.day()+'/'+dt.year()+' @ '+dt.format('h:mm a');
            return formattedDate;
        }else{
            return ''; 
        }
        
    }
}