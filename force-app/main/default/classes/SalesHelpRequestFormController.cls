/** Controller extension class for the Sales Help Request Form VF Page
 * 
 * History
 * -------
 * 03/19/2019   Michael Karcz   Created
 * 12/05/2019   Jake Hinds      PEO Routing, Sales Help Custom Permission
   06/30/2020   Dan Carmen      Changes so test will pass.
   08/06/2020   Jake Hinds      Bug fix to find custom setting correctly based on subtype first
   12/21/2020   Jermaine Stukes Reconfigured to work with Lightning Component 
   10/24/2023   Eric Porter     Update for APR0158830 to include Peo Help Request Queue for PEO Virtual sales
   01/10/2024   Eric Porter     Update for APR0163095 to include new default queue for MMS RSR Reps 
   01/24/2024   Eric Porter        Adding the submitter user for SHRC's Chatter Messages. APR0164265
   04/02/2024   Eric Porter        Adding Routing for Users with "Agency" in sales division. APR0167817


*/

public without sharing class SalesHelpRequestFormController  implements TriggerInterfaceC{
    public static User runningUser = UserHelper.getRunningUser();
    public static final String CLASSNAME='SalesHelpRequestFormController';
    
    //Add Trigger Information
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        if (TriggerMethods.didTriggerRun(CLASSNAME,recs,oldMap,isBefore,isAfter,isDelete)) {
            System.debug('handleTrigger trigger ran');
            return;
        }
        SObjectType objType = TriggerMethods.objType;
        //Create List if Sales Help Case(s)
        
        if (isBefore) {
            if (Trigger.isInsert ) {
                handleSHBefore((Case[])recs);
            }
        } else if (isAfter) {
            if (Trigger.isInsert ) {
                handleSHAfter((Case[])recs);
            }
        }
        
    } // handleTrigger
    
    public class ShValidationWrapper{
        @AuraEnabled public Boolean formValid = true;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String urlLink;
    }
    @AuraEnabled
    public static String retrieveSalesHelpRT(){
        String recordTypeId = RecordTypeHelper.getRecordType(Label.Case_Sales_Help_Request_RT,'Case').getRecordTypeId();
        return recordTypeId;
    }
    @AuraEnabled
    public static ShValidationWrapper validateForm(String caseType, String caseSubType){
        System.debug(LoggingLevel.DEBUG, 'Casetype'+caseType+' caseSubType'+caseSubType);
        ShValidationWrapper validateWrapper = new ShValidationWrapper();
        Sales_Help_Request_Case__c salesHelpCS;
        // iterate the queued cases: shrc = case
        System.debug('Starting iteration over SHRQ obj');
        for(Sales_Help_Request_Case__c shrc : Sales_Help_Request_Case__c.getAll().values()){
            // if the case has a type and subtype log a message
            if(shrc.Type__c!=null && shrc.Sub_Type__c!=null){
                system.debug('SalesHelpRequestFormController getCustomSettingTypeSpecific newCase.Type: '+caseType+' shrc.Type__c: '+shrc.Type__c+ 'subType: '+ caseSubType +'shrc.Sub_Type__c: '+shrc.Sub_Type__c);
            }
            
            if(String.IsNotBlank(shrc.Type__c) && caseType==shrc.Type__c){
                if(String.isBlank(shrc.Sub_Type__c)){
                    salesHelpCS = shrc;
                    system.debug('SHCS: '+salesHelpCS);
                }
                else if(shrc.Sub_Type__c == caseSubType){
                    system.debug('SalesHelpRequestFormController getCustomSettingTypeSpecific newCase.Type: '+caseType+' shrc.Type__c: '+shrc.Type__c);
                    salesHelpCS = shrc;
                    break;
              }
             }
        }
        //Create Alert Messages
        if(salesHelpCS != null && String.isNotBlank(salesHelpCS.Alert_Message__c)){
            system.debug('SalesHelpRequestFormController checkShowMessage adding Message'+salesHelpCS.Alert_Message__c);
            validateWrapper.errorMessage = salesHelpCS.Alert_Message__c;
            validateWrapper.urlLink = salesHelpCS.Alert_Message_URL__c;
            String replacementURLString = 'in the link below ';
            if(String.isNotBlank(validateWrapper.errorMessage.subStringBetween('#'))){
                String alertShortText = validateWrapper.errorMessage.subStringBetween('#');
                Integer replaceIndex = validateWrapper.errorMessage.indexOf(alertShortText)-1;//subtract 1 to also include the #
                String textToReplace = validateWrapper.errorMessage.mid(replaceIndex,alertShortText.length()+2);//add 2 to include both #
                    validateWrapper.errorMessage = validateWrapper.errorMessage.replace(textToReplace,replacementURLString);
            }                
            system.debug('SalesHelpRequestFormController alertMessage '+validateWrapper.errorMessage);
        } 
        if(salesHelpCS==null || (salesHelpCS!=null && salesHelpCS.Route_via_Sales_Org__c)){
            // Filtering virtual/nss before routing to field based queues
            System.debug('Made it to routing');
            String runningUserRole = runningUser.UserRole.Name; 
            if(runningUserRole.contains('Virtual') || runningUserRole.contains('VIRTUAL') || runningUserRole.contains('NSS') || runningUserRole.equalsIgnoreCase('Oasis Manager') || runningUserRole.equalsIgnoreCase('Oasis SDR')) {
            //if(runningUser.Sales_Division__c.contains('Virtual') || runningUser.UserRole.Name.contains('NSS')){
                salesHelpCS = Sales_Help_Request_Case__c.getValues('Virtual_NSS');
                //caseType = runningUser.UserRole.Name;
            }
            
            else{
                salesHelpCS = Sales_Help_Request_Case__c.getValues(runningUser.Sales_Division__c);   
            }
            if(salesHelpCS == null){
                System.debug('hit default');
                salesHelpCS = Sales_Help_Request_Case__c.getValues('Default');
            }  
        }
        if (String.IsNotBlank(salesHelpCS.Permission_Needed__c) && !UserHelper.isSystemAdmin(runningUser)){
            Boolean hasPermission = false;
            CustomPermission[] cps = [SELECT DeveloperName FROM CustomPermission WHERE MasterLabel = :salesHelpCS.Permission_Needed__c LIMIT 1];
            system.debug('SalesHelpRequestFormController performRouting cps'+cps);            
            if(cps!=null && !cps.isEmpty()){
                hasPermission = FeatureManagement.checkPermission(cps[0].DeveloperName);
            }
            if(!hasPermission){
                validateWrapper.formValid = false;
                String errorMessage = 'You do not have permission to submit this type of request. Please select a new Request type to submit';
                if(validateWrapper.errorMessage == null){
                    validateWrapper.errorMessage = errorMessage;
                }else{
                   validateWrapper.errorMessage +='\n\n' + errorMessage; 
                }
            }
        }
        return validateWrapper;
    }
    public static Sales_Help_Request_Case__c retrieveSHCS(String caseType, String caseSubType){
        System.debug('STARTING RETRIEVE');
        String runningUserRole = runningUser.UserRole.Name;
        Sales_Help_Request_Case__c salesHelpCS;
        for(Sales_Help_Request_Case__c shrc : Sales_Help_Request_Case__c.getAll().values()){
            System.debug('SALES HELP NAME: '+shrc.Name);
            if(String.IsNotBlank(shrc.Type__c) && caseType==shrc.Type__c){
                if(String.isBlank(shrc.Sub_Type__c)){
                    system.debug('SalesHelpRequestFormController getCustomSettingTypeSpecific newCase.Type: '+caseType+' shrc.Type__c: '+shrc.Type__c);
                    salesHelpCS = shrc;
                }
                else if(shrc.Sub_Type__c == caseSubType){
                    system.debug('SalesHelpRequestFormController getCustomSettingTypeSpecific newCase.Type: '+caseType+' shrc.Type__c: '+shrc.Type__c);
                    salesHelpCS = shrc;
                    break;
                }
            }
        } 
        
        if(salesHelpCS==null || (salesHelpCS!=null && salesHelpCS.Route_via_Sales_Org__c)){
            //Update for APR0158830 to include Peo Help Request Queue for PEO Virtual sales
            if(runningUserRole.contains('PEO Virtual Sales')){
                salesHelpCS = Sales_Help_Request_Case__c.getValues('PEO_Help_Request');
            }else{
            //APR0167817
            if(runningUser.Sales_Division__c.contains('Agency')){
                salesHelpCS = Sales_Help_Request_Case__c.getValues('Agency HNBF');

            }else{

            
            
            //APR0163095
            if(runningUserRole.contains('MMS SALES REP RSR')|| runningUserRole.contains('MMS Region RSR')){
                System.debug('Made it to the RSR Assignment');
                salesHelpCS = Sales_Help_Request_Case__c.getValues('MMS Help Request Queue');
                // if(salesHelpCS == null){
                //     System.debug('Cant find SalesHelpCS with \'MMS Help Request Queue\'');
                // }
                System.debug('salesHelpCS in if :' + salesHelpCS);
            }else{
                            // Filtering virtual/nss before routing to field based queues

                if(runningUserRole.contains('Virtual') || runningUserRole.contains('VIRTUAL') || runningUserRole.contains('NSS') || 
                runningUserRole.equalsIgnoreCase('Oasis Manager') || runningUserRole.equalsIgnoreCase('Oasis SDR') || 
                runningUserRole.toLowerCase().startsWith('sales development rep') || runningUserRole.toLowerCase().startsWith('sales development manager')) {
                 System.debug('virtual nss check passed');   
                 salesHelpCS = Sales_Help_Request_Case__c.getValues('Virtual_NSS');
                }
             else{
                 System.debug('virtual nss check failed');
                 salesHelpCS = Sales_Help_Request_Case__c.getValues(runningUser.Sales_Division__c);   
             }
            }

            
        }
    }
        System.debug('salesHelpCS outside else:' + salesHelpCS);

        }
        if(salesHelpCS == null){
            System.debug('shcs is null!');
            salesHelpCS = Sales_Help_Request_Case__c.getValues('Default');
        }
        return salesHelpCS;
    }
    public static void handleSHBefore(List <Case> caselist){
        //Verify Record Type
        Schema.RecordTypeInfo caseSaleHelp = RecordTypeHelper.getRecordType(Label.Case_Sales_Help_Request_RT, 'Case');
        List<Case> salesHelpCases = new List<Case>();
        for(Case kase : caselist){
            if (kase.RecordTypeId == caseSaleHelp.getRecordTypeId()){
                salesHelpCases.add(kase); 
            }
        }
        if(!salesHelpCases.isEmpty()){
            routeSalesHelpCases(salesHelpCases);
        }
    }
    public static void handleSHAfter(List <Case> caselist){
        //Verify Record Type
        Schema.RecordTypeInfo caseSaleHelp = RecordTypeHelper.getRecordType(Label.Case_Sales_Help_Request_RT, 'Case');
        List<Case> salesHelpCases = new List<Case>();
        for(Case kase : caselist){
            if (kase.RecordTypeId == caseSaleHelp.getRecordTypeId()){
                salesHelpCases.add(kase); 
            }
        }
        if(!salesHelpCases.isEmpty()){
            createChatterMessage(salesHelpCases);
        }
    }
    public static void routeSalesHelpCases(List <Case> caselist){
        System.debug('ROUTING STARTED');
        String runningUserRole = runningUser.UserRole.Name; 
        for(case cs : caseList){
            cs.Subject = cs.Type + ' - ' + cs.Sub_Type__c + ' - ' + runningUser.Sales_Division__c;
            System.debug('CASE SUBJECT: '+cs.Subject);
            cs.Origin = 'Utility Bar';
            Sales_Help_Request_Case__c salesHelpCS = retrieveSHCS(cs.Type, cs.Sub_Type__c);
            if(salesHelpCS!=null && String.isNotBlank(salesHelpCS.User_Id__c)){
                cs.OwnerId = salesHelpCS.User_Id__c;
            }
            else if(salesHelpCS!=null && String.isNotBlank(salesHelpCS.Group_Name__c)){
                //get the queue Id and the chatter group Id
                cs.OwnerId = ([SELECT Id FROM Group WHERE Type = 'Queue' AND Name = :salesHelpCS.Group_Name__c LIMIT 1][0]).Id;
                System.debug('case owner ID: '+cs.OwnerId);
            }
        }
    }
    public static void createChatterMessage(List<Case> CaseList){
        String runningUserRole = runningUser.UserRole.Name; 
        CollaborationGroup chatterGroup;
        for(case cs : caseList){
            Sales_Help_Request_Case__c salesHelpCS = retrieveSHCS(cs.Type, cs.Sub_Type__c);
            String chatterGroupId;
            if(salesHelpCS!=null && String.isNotBlank(salesHelpCS.User_Id__c)){
                chatterGroupId = salesHelpCS.User_Id__c;
            }
            else if(salesHelpCS!=null && String.isNotBlank(salesHelpCS.Group_Name__c)){
                if(!Test.isRunningTest()){
                    chatterGroup = [SELECT Id FROM CollaborationGroup WHERE CollaborationType = 'Public' AND Name = :salesHelpCS.Group_Name__c LIMIT 1];
                    if(chatterGroup!=null){
                        chatterGroupId = chatterGroup.Id;
                    }
                }else{
                    chatterGroupId = '0F9000000000000000';
                }  
            }
            //Create Chatter
            if(chatterGroupId!=null){
                String chatterBody = 'There is a new ' + cs.Sub_Type__c + ' Sales Help Request case! ';
                chatterBody += (cs.Due_Date__c!=null && cs.Due_Date__c == date.today()? 'REQUESTED DUE DATE - TODAY. ':'');
                chatterBody += 'Contact: '+cs.CreatedBy.FirstName+' '+cs.CreatedBy.LastName+'. Description: '+cs.Description;
                //APR0164265 update adding shrc submitter
                Id SubmitterId = cs.CreatedById;
                List<Id> chatterGroupIds = new List<Id> {chatterGroupId, SubmitterId};
                    system.debug('chatterGroupId'+chatterGroupId);
                if(!Test.isRunningTest()){
                ChatterMentionPost.createChatterMentionPost(cs.Id, chatterGroupIds, new String[] {chatterBody}, true, true);
                }
            }
        }
    }
}