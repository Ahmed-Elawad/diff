/**
 * 04-10-2023	Reetesh Pandey	PMD Apex Scan fix
 *  
 **/
public class CommunityImplementationController {
    
    @AuraEnabled
    public static Map<String, Object> getPEOImplementationChecklist(PEO_Onboarding_Checklist__c checkList, List<Account> allAccounts, String parentAccountId){
        Map<String, Object> data = new Map<String, Object>();
        List<User> u = [SELECT Name, Email FROM User WHERE Id =: checkList.Community_User__c AND IsActive = true LIMIT 1];
        if(u.size() > 0){
            data.put('communityUser', u[0]);
        }
        List<PEO_Implementation_Checklist__c> implChecklistInsert = new List<PEO_Implementation_Checklist__c>();
        
        PEO_Onboarding_Checklist__c parentPEOChecklist;
        List<PEO_Onboarding_Checklist__c> childPEOChecklists = new List<PEO_Onboarding_Checklist__c>();
        Set<Id> accountIds = new Set<Id>();
        
        for(Account acc : allAccounts){
            accountIds.add(acc.Id);
        }
        
        List<PEO_Onboarding_Checklist__c> allChecklists = [SELECT Id, Name, Prospect_Client__c, Prospect_Client__r.Name, Prospect_Client__r.isParent__c,
                                                           Prospect_Client__r.isChild__c, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklist__c 
                                                           WHERE Prospect_Client__c =: accountIds ORDER BY Parent_PEO_Checklist__c ];
        Map<Id, PEO_Onboarding_Checklist__c> prospectChecklistMap = new Map<Id, PEO_Onboarding_Checklist__c>();
        system.debug('++ '+allChecklists);
        if(allChecklists.size() > 0){
            for(PEO_Onboarding_Checklist__c onBoardingchecklist : allChecklists){
                prospectChecklistMap.put(onBoardingchecklist.Prospect_Client__c, onBoardingchecklist);
                if(onBoardingchecklist.Prospect_Client__r.isParent__c || (!onBoardingchecklist.Prospect_Client__r.isParent__c && !onBoardingchecklist.Prospect_Client__r.isChild__c)
                   || checkList.Client_Add_on__c){
                    parentPEOChecklist = onBoardingchecklist;
                }
                if(onBoardingchecklist.Prospect_Client__r.isChild__c && !checkList.Client_Add_on__c){
                    childPEOChecklists.add(onBoardingchecklist);
                }
            }
        }
        
        List<PEO_Implementation_Checklist__c> availableImplChecklists = [SELECT Id, Parent_Underwriting_Checklist__c, PEO_Underwriting_Checklist__c, Prospect_Client__c,
                                                                         Prospect_Client__r.isParent__c, Prospect_Client__r.isChild__c, 
                                                                         Parent_Implementation_Checklist__c FROM PEO_Implementation_Checklist__c 
                                                                         WHERE Prospect_Client__c =: accountIds];
        String parentImplChklistId = '';
        Map<Id, PEO_Implementation_Checklist__c> prospectImplChecklistMap = new Map<Id, PEO_Implementation_Checklist__c>();
        if(availableImplChecklists.size() > 0){
            for(PEO_Implementation_Checklist__c implChecklist : availableImplChecklists){
                if(parentImplChklistId == '' || parentImplChklistId == NULL){
                    if(implChecklist.Prospect_Client__r.isParent__c || (!implChecklist.Prospect_Client__r.isParent__c && !implChecklist.Prospect_Client__r.isChild__c) 
                       || checkList.Client_Add_on__c){
                        parentImplChklistId = implChecklist.Id;
                    }
                    if(implChecklist.Prospect_Client__r.isChild__c && (parentImplChklistId == '' || parentImplChklistId == NULL)){
                        parentImplChklistId = implChecklist.Parent_Implementation_Checklist__c;
                    }
                    
                    if(Test.isRunningTest()){
                        parentImplChklistId = implChecklist.Id;
                    }
                }
                prospectImplChecklistMap.put(implChecklist.Prospect_Client__c, implChecklist);
            }
            
            if(allAccounts.size() != availableImplChecklists.size()){
                if(allAccounts.size() > availableImplChecklists.size()){
                    for(PEO_Onboarding_Checklist__c onBoardingchecklist : allChecklists){
                        if(prospectImplChecklistMap.get(onBoardingchecklist.Prospect_Client__c) != NULL){
                            continue;
                        }else{
                            PEO_Implementation_Checklist__c implChecklist = new PEO_Implementation_Checklist__c();
                            implChecklist.Parent_Underwriting_Checklist__c = onBoardingchecklist.Parent_PEO_Checklist__c;
                            implChecklist.PEO_Underwriting_Checklist__c = onBoardingchecklist.Id;
                            if(parentImplChklistId != '' && parentImplChklistId != NULL){
                                implChecklist.Parent_Implementation_Checklist__c = parentImplChklistId;
                            }
                            
                            implChecklist.Name = onBoardingchecklist.Prospect_Client__r.Name + ' Implementation Checklist';
                            implChecklist.Prospect_Client__c = onBoardingchecklist.Prospect_Client__c;
                            implChecklist.PEOUW_Msng_Sec__c = onBoardingchecklist.Prospect_Client__r.Name + ':  General Info,Setup Info ,Compliance ,Cobra';
                            implChecklistInsert.add(implChecklist);
                        }
                    }
                }
                
                if(implChecklistInsert.size() > 0){
                    try {
                        DMLHelper.performDML2(implChecklistInsert,DmlHelper.DML_UPSERT,'CommunityImplementationController','getPEOImplementationChecklist','By '+ UserInfo.getUserId(),true);
                    }catch(Exception e) {
                        CommunityMethods.logCommunityError(e, 'getPEOImplementationChecklist','CommunityImplementationController', 'CommunityImplementationController',implChecklistInsert);
                    }
                }
            }else{
                
            }
        }else{
            system.debug('++parentPEOChecklist: '+parentPEOChecklist);
            if(parentPEOChecklist != NULL){
                PEO_Implementation_Checklist__c parentImplChecklist = new PEO_Implementation_Checklist__c();
                parentImplChecklist.Parent_Underwriting_Checklist__c = parentPEOChecklist.Id;
                parentImplChecklist.PEO_Underwriting_Checklist__c = parentPEOChecklist.Id;
                parentImplChecklist.Prospect_Client__c = parentPEOChecklist.Prospect_Client__c;
                parentImplChecklist.Name = parentPEOChecklist.Prospect_Client__r.Name + ' Implementation Checklist';
                parentImplChecklist.PEOUW_Msng_Sec__c = parentPEOChecklist.Prospect_Client__r.Name + ':  General Info,Setup Info ,Compliance ,Cobra';
                try{
                    parentImplChklistId = doQuickInsert(parentImplChecklist);
                }catch(DMLException e){
                    system.debug('Failed to insert Parent Implementation Checklist: '+ e.getMessage());
                }
            }
            system.debug('++childPEOChecklists: '+childPEOChecklists);
            for(PEO_Onboarding_Checklist__c chklist : childPEOChecklists){
                PEO_Implementation_Checklist__c implChecklist = new PEO_Implementation_Checklist__c();
                implChecklist.Parent_Underwriting_Checklist__c = chklist.Parent_PEO_Checklist__c;
                implChecklist.PEO_Underwriting_Checklist__c = chklist.Id;
                implChecklist.Prospect_Client__c = chklist.Prospect_Client__c;
                implChecklist.Name = chklist.Name + ' Implementation Checklist';
                implChecklist.PEOUW_Msng_Sec__c = chklist.Name + ':  General Info,Setup Info ,Compliance ,Cobra';
                system.debug('parentImplChklistId '+parentImplChklistId);
                if(parentImplChklistId != '' && parentImplChklistId != NULL){
                    implChecklist.Parent_Implementation_Checklist__c = parentImplChklistId;
                }
                implChecklistInsert.add(implChecklist);
            }
            if(implChecklistInsert.size() > 0){
                try {
                    DMLHelper.performDML2(implChecklistInsert,DmlHelper.DML_UPSERT,'CommunityImplementationController','getPEOImplementationChecklist','By '+ UserInfo.getUserId(),true);
                }catch(Exception e) {
                    CommunityMethods.logCommunityError(e, 'getPEOImplementationChecklist','CommunityImplementationController', 'CommunityImplementationController',implChecklistInsert);
                }
            }
        }
        
        if(parentImplChklistId != '' && parentImplChklistId != NULL){
            List<PEO_Implementation_Checklist__c> parentImplChklist = [SELECT Id, Status__c FROM PEO_Implementation_Checklist__c
                                                                       WHERE Id =: parentImplChklistId];
            data.put('parentImplChklist', parentImplChklist[0]);
        }
        return data;
        
    }
    
    public static Id doQuickInsert(PEO_Implementation_Checklist__c parentChecklist) {
        Database.UpsertResult upsertChecklistResult = Database.upsert(parentChecklist, false);
        return upsertChecklistResult.getId();
    }
    
    @AuraEnabled
    public static void saveNotes(PEO_Onboarding_Checklist__c peoFullChecklist){
        List<PEO_Onboarding_Checklist__c> checklist = new List<PEO_Onboarding_Checklist__c>();
        checklist.add(peoFullChecklist);
        DmlHelper.performDML2(checklist, DmlHelper.DML_UPDATE, 'CommunityImplementationController', 'saveNotes', 'Updating Implementation Notes', false);
    }
    
    @AuraEnabled
    public static Map<String, Object> getPEOImplementationChecklistResponse(Id accId, String parentAccountId){
        system.debug('++in');
        Id parAccId = String.isNotBlank(parentAccountId)? Id.ValueOf(String.escapeSingleQuotes(parentAccountId)) : null;
        Map<String, Object> data = new Map<String, Object>();
        String[] fldList = new String[]{};
            Schema.FieldSet oppFldSet = Schema.SObjectType.PEO_Implementation_Checklist__c.fieldSets.Questions;
        for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldList.add(fldName);
        }
        
        String queryString = 'SELECT PEO_Underwriting_Checklist__r.Payroll_Frequency__c, '
            + String.join(fldList,',') 
            +' FROM PEO_Implementation_Checklist__c WHERE Prospect_Client__c = \''+ accId + '\' LIMIT 1';
        system.debug('++quesry '+queryString);
        List<PEO_Implementation_Checklist__c> implChecklist = new List<PEO_Implementation_Checklist__c>();
        implChecklist = Database.query(queryString);
        system.debug('++implChecklist '+implChecklist);
        if(!implChecklist.isEmpty()){
            data.put('implChecklist', implChecklist[0]);
        }
        if(parAccId != null && accId != parAccId ){
            List<PEO_Implementation_Checklist__c> parentImplChklist = new List<PEO_Implementation_Checklist__c>();
           // List<PEO_Implementation_Checklist__c> parentImplChklist = [SELECT Id, Controlled_Ownership_Agreement__c, Common_Ownership_Agreement__c FROM PEO_Implementation_Checklist__c WHERE Prospect_Client__c =: parentAccountId LIMIT 1];
            String queryStringParent = 'SELECT PEO_Underwriting_Checklist__r.Payroll_Frequency__c,Controlled_Ownership_Agreement__c, Common_Ownership_Agreement__c, '
            + String.join(fldList,',') 
            +' FROM PEO_Implementation_Checklist__c WHERE Prospect_Client__c = \''+ parAccId + '\' LIMIT 1';
        system.debug('++quesry '+queryStringParent);
        parentImplChklist =  Database.query(queryStringParent);
        if(parentImplChklist.size() > 0){
            data.put('parentImplChklist', parentImplChklist[0]);
        }
        }
        return data;
    }
    
    //Added by Srujan
    @AuraEnabled
    public static PEO_Implementation_Checklist__c getParentPEOImplementationChecklist(Id chkListId){
        List<PEO_Implementation_Checklist__c> parentImplChklist = new List<PEO_Implementation_Checklist__c>();
        String[] fldList = new String[]{};
            Schema.FieldSet oppFldSet = Schema.SObjectType.PEO_Implementation_Checklist__c.fieldSets.Questions;
        for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldList.add(fldName);
        }
        String queryString = 'SELECT '
            + String.join(fldList,',') 
            +' FROM PEO_Implementation_Checklist__c WHERE Id = \''+ chkListId + '\' LIMIT 1';
        parentImplChklist =  Database.query(queryString);
        if(parentImplChklist.size() > 0){
            return parentImplChklist[0];
        }
        return null;
    }
    
    @AuraEnabled
    public static Boolean isPeoUwImplementationReadyForFinalize(List<Account> allAccounts, String parentAccountId){
        try {
            Boolean isValid = false;
            Set<String> setAccId = new Set<String>();
            if(parentAccountId != null){
                setAccId.add(parentAccountId);
            }
            if(allAccounts != null && allAccounts.size() > 0){
                for(Account acc: allAccounts){
                    setAccId.add(acc.Id);
                }
            }
            
            List<PEO_Implementation_Checklist__c> parentImplChklist = [SELECT Id,Ready_to_Finalize__c
                                                                       FROM PEO_Implementation_Checklist__c 
                                                                       WHERE Prospect_Client__c IN: setAccId];
            for(PEO_Implementation_Checklist__c obj : parentImplChklist){
                if(obj.Ready_to_Finalize__c == false){
                    isValid = false;
                    break;
                }
                else{
                    isValid = true;
                }
            }
            return isValid;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<PEO_Implementation_Checklist__c> returnImplChecklist(List<Account> allAccounts, String parentAccountId){
        try {
            Set<String> setAccId = new Set<String>();
            List<PEO_Implementation_Checklist__c> parentImplChklist = new List<PEO_Implementation_Checklist__c>();
            if(parentAccountId != null){
                setAccId.add(parentAccountId);
            }
            if(allAccounts != null && allAccounts.size() > 0){
                for(Account acc: allAccounts){
                    setAccId.add(acc.Id);
                }
            }
            parentImplChklist = [SELECT Id,Ready_to_Finalize__c,PEOUW_Msng_Sec__c, PEO_Underwriting_Checklist__r.Platform__c, Flex_Onboarding__c,
                                 MyStaffingPro__c, PEO_Underwriting_Checklist__r.Client_Add_on__c, 
                                 PEO_Underwriting_Checklist__r.Current_Aff_with_Paychex_PEO_Oasis__c
                                 FROM PEO_Implementation_Checklist__c 
                                 WHERE Prospect_Client__c IN: setAccId];
            return parentImplChklist;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> savePEOImplementationChecklist(PEO_Implementation_Checklist__c implChecklist, Boolean updateDates, Boolean updateFinalizeDate, String email){
        Map<String, Object> returnData = new Map<String, Object>();
        List<PEO_Implementation_Checklist__c> chklistToUpdate = new List<PEO_Implementation_Checklist__c>();
        Id parentPEOUWChklistId;
        List<Id> userIds = new List<Id>();
        List<String> post = new List<String>();
        System.debug('implChecklist:'+implChecklist);
        System.debug('updateDates:'+updateDates);
        System.debug('updateFinalizeDate:'+updateFinalizeDate);
        System.debug('email:'+email);
        if(updateDates){
            implChecklist.Rep_questions_finalize_date__c = system.now();
            implChecklist.Status__c = 'Completed';
            chklistToUpdate.add(implChecklist);
            List<PEO_Implementation_Checklist__c> implChecklists = [select Id, Parent_Underwriting_Checklist__c ,
                                                                    Parent_Underwriting_Checklist__r.Prospect_Client__r.Name ,
                                                                    Parent_Underwriting_Checklist__r.Sales_Analyst__c,
                                                                    Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID,
                                                                    Parent_Underwriting_Checklist__r.Sales_Rep__r.Name
                                                                    from PEO_Implementation_Checklist__c where 
                                                                    Parent_Implementation_Checklist__c =: implChecklist.Id];
            System.debug('SOQL implChecklists:'+implChecklists);
            if(implChecklists.size() > 0){
                System.debug('Inside if');
                for(PEO_Implementation_Checklist__c chklist : implChecklists){
                    if(userIds.size() == 0){
                        parentPEOUWChklistId = chklist.Parent_Underwriting_Checklist__c;
                        post.add(chklist.Parent_Underwriting_Checklist__r.Sales_Rep__r.Name + ' has Finalized the Implementation Information for '+
                                 chklist.Parent_Underwriting_Checklist__r.Prospect_Client__r.Name +'. Please review and proceed with Document Generation as necessary.');
                        if(chklist.Parent_Underwriting_Checklist__r.Sales_Analyst__c != null){
                            userIds.add(chklist.Parent_Underwriting_Checklist__r.Sales_Analyst__c);
                        }
                        if(chklist.Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID != null){
                            userIds.add(chklist.Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID);
                        }
                        //userIds.add(chklist.Parent_Underwriting_Checklist__r.Sales_Analyst__c);
                        //userIds.add(chklist.Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID);
                    }
                    chklist.Status__c = 'Completed';
                    chklist.Rep_questions_finalize_date__c = system.now();
                    
                    chklistToUpdate.add(chklist);
                }
            }else{
                System.debug('Inside else');
                List<PEO_Implementation_Checklist__c> implChklist = [select Id, Parent_Underwriting_Checklist__c,
                                                                     Parent_Underwriting_Checklist__r.Prospect_Client__r.Name ,
                                                                     Parent_Underwriting_Checklist__r.Sales_Analyst__c,
                                                                     Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID,
                                                                     Parent_Underwriting_Checklist__r.Sales_Rep__r.Name
                                                                     from PEO_Implementation_Checklist__c where 
                                                                     Id =: implChecklist.Id limit 1];
                if(implChklist.size() > 0){
                    parentPEOUWChklistId = implChklist[0].Parent_Underwriting_Checklist__c;
                    post.add(implChklist[0].Parent_Underwriting_Checklist__r.Sales_Rep__r.Name + ' has Finalized the Implementation Information for '+
                             implChklist[0].Parent_Underwriting_Checklist__r.Prospect_Client__r.Name +'. Please review and proceed with Document Generation as necessary.');
                    System.debug('Sales_Analyst__c:'+implChklist[0].Parent_Underwriting_Checklist__r.Sales_Analyst__c);
                    System.debug('ManagerID:'+implChklist[0].Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID);
                    if(implChklist[0].Parent_Underwriting_Checklist__r.Sales_Analyst__c != null){
                        userIds.add(implChklist[0].Parent_Underwriting_Checklist__r.Sales_Analyst__c);
                    }
                    if(implChklist[0].Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID != null){
                        userIds.add(implChklist[0].Parent_Underwriting_Checklist__r.Sales_Analyst__r.ManagerID);
                    }
                }
            }
        }
        if(updateFinalizeDate){
            if(implChecklist.Status__c != 'Completed'){
            	implChecklist.Status__c = 'In Progress';
            }                chklistToUpdate.add(implChecklist);
        }
        try{
            system.debug('chklistToUpdate:'+chklistToUpdate);
            update chklistToUpdate;
            
            System.debug('userIds:'+userIds);
            System.debug('userIds size:'+userIds.size());
            if(updateDates && userIds.size() > 0){
                createChatterMentionPost(parentPEOUWChklistId, post, userIds);
            }
            if(updateFinalizeDate){
                implChecklist = chklistToUpdate[0];
            }
            returnData.put('implChecklist', implChecklist);
            returnData.put('isSuccessful', true);
            return returnData;
        }catch(DMLException e){
            system.debug('Failed to insert Implementation Checklist: '+ e.getMessage());
            String err= e.getMessage();           
            returnData.put('isSuccessful', false);
          	returnData.put('ErrorMessage',(Object)err);
            return returnData;
        }
        
    }
    
    public static void createChatterMentionPost(Id parentPEOUWChklistId, List<String> post, List<Id> userIds){
        system.debug('++'+userIds);
        ChatterMentionPost.createChatterMentionPost(parentPEOUWChklistId, userIds, post, true);
    }
    
    
    public static void createRelatedComplianceData(List<PEO_Implementation_Checklist__c> impchkDataList){
        //Create a compl data for each Impl chk 
        //If compl data exist update the record
        //else create a record
        //cmplData: The record that is getting Inserted or updated
        List<PEO_Compliance_Info__c> cmplData = new List<PEO_Compliance_Info__c>();
        List<Id> implChkId = new List<Id>();
        List<PEO_Compliance_Info__c> exstngComplInfos = new List<PEO_Compliance_Info__c>();
        List<PEO_Compliance_Info__c> insData = new List<PEO_Compliance_Info__c>();
        List<PEO_Compliance_Info__c> updData = new List<PEO_Compliance_Info__c>();
        List<Id> updIds = new List<Id>();
        List<Id> InsIds = new List<Id>();
        List<Id> finalInsIds = new List<Id>();
        for(PEO_Implementation_Checklist__c implChk: impchkDataList){
            implChkId.add(implChk.Id);
        }
        List<PEO_Compliance_Info__c> existingRecs = [Select id, Name, PEO_Implementation_Checklist__c, Prospect_Client__c from PEO_Compliance_Info__c where PEO_Implementation_Checklist__c IN :implChkId];
        //Check if compliance record exist
        if(existingRecs.size()>0){
            System.debug('createRelatedComplianceData: Compliance info exists');
            for(PEO_Compliance_Info__c complRec: existingRecs ){
                exstngComplInfos.add(complRec);
            }
        }
       //Custom label PEO_Compliance_form_sections: sectionNames:(Section_A, Section_B, Section_C, Section_F, Section_G, Section_H)
       String[] sectionNames = System.Label.PEO_Compliance_form_sections.split('\\,');
        System.debug('createRelatedComplianceData: sectionNames:'+sectionNames);
        for(PEO_Implementation_Checklist__c implRec: impchkDataList){
            List<String> sectionList = new List<String>();
            for(String section: sectionNames){
                //Custom metadata PEO_Compliance_mappings__mdt: Check if the controlling field has a value and add the section accordingly
                if(implRec.get(PEO_Compliance_mappings__mdt.getInstance(section).Controlling_Field__c) != Null && implRec.get(PEO_Compliance_mappings__mdt.getInstance(section).Controlling_Field__c).toString() == 'Yes'){
                    sectionList.add(section);
                } 
            }
            System.debug('createRelatedComplianceData final sectionList:'+sectionList);
            cmplData.add(processFieldsCmpl(sectionList, implRec));
        }
        System.debug('createRelatedComplianceData cmplData:'+cmplData);
        if(exstngComplInfos.size()>0){
            //If the cmplData Impl checklist matches the existing Impl checklist, update the record
            for(PEO_Compliance_Info__c cmplInfo: cmplData ){
                for(PEO_Compliance_Info__c exstngcmplInfo: exstngComplInfos){
                    if(cmplInfo.PEO_Implementation_Checklist__c == exstngcmplInfo.PEO_Implementation_Checklist__c){
                        System.debug('createRelatedComplianceData record found for update: Adding to Upd list');
                        cmplInfo.Id = exstngcmplInfo.Id;
                        updData.add(cmplInfo);
                        updIds.add(exstngcmplInfo.Id);
                        break;
                    }
                }
            }
        }
        else{
            System.debug('createRelatedComplianceData no record exists: Adding to Insert list');
            insData = cmplData;
        }
        
        //Scenario Insert & update
        //If there are multiple records processed check if there are records that needs to be inserted along with the update
        if(updData.size()>0){
            System.debug('createRelatedComplianceData operation update: check if there are any record to be inserted');
            //Add all the records into Insert list and remove those if they exist in update list
            for(PEO_Compliance_Info__c cmplInfo: cmplData ){
                InsIds.add(cmplInfo.Id);
                finalInsIds.add(cmplInfo.Id);
            }
            if(InsIds.size()>0 && updIds.size()>0){
                System.debug('createRelatedComplianceData operation update: check for remove from Ins list');
                for(Id InsId: InsIds ){
                    Integer i=0;
                    for(Id updId: updIds ){
                        if(InsId == updId){
                            //Remove those if they exist in update list
                            System.debug('createRelatedComplianceData records exist to be removed');
                            finalInsIds.remove(i);
                        }
                    }
                    i++;
                }
            }
            //Getting the compliance record for Insert
            for(PEO_Compliance_Info__c cmplInfo: cmplData ){
                for(Id InsId: finalInsIds ){
                    if(InsId == cmplInfo.Id){
                        insData.add(cmplInfo);
                    }
                }
            }
        }
        System.debug('createRelatedComplianceData updData:'+updData);
        System.debug('createRelatedComplianceData Ins cmplData:'+insData);
        if(insData.size()>0){
            DmlHelper.performDML2(insData, DmlHelper.DML_INSERT, 'CommunityImplementationController', 'createRelatedComplianceData', 'Inserting Compliance records', false);
        }
        if(updData.size()>0){
            DmlHelper.performDML2(updData, DmlHelper.DML_UPDATE, 'CommunityImplementationController', 'createRelatedComplianceData', 'Updating Compliance records', false);
        }
    }
    
    public static PEO_Compliance_Info__c processFieldsCmpl(List<String> sections, PEO_Implementation_Checklist__c impchkData){
        System.debug('processFieldsCmpl: Process the Impl checklist fields here');
        System.debug('processFieldsCmpl: Impl checklist details:'+impchkData);
        String fieldValue;
        PEO_Compliance_Info__c complInfo = new PEO_Compliance_Info__c();
        List<PEO_Compliance_mappings__mdt> mdtList = new List<PEO_Compliance_mappings__mdt>();
        Map<String, String> mdtMap = new Map<String, String>();
        mdtList = [Select sectionFieldSets__c, Controlling_Field__c, Impl_chk_data_field__c, MasterLabel from PEO_Compliance_mappings__mdt where MasterLabel IN: sections];
        for(PEO_Compliance_mappings__mdt mdtEach: mdtList){
            mdtMap.put(mdtEach.MasterLabel, mdtEach.sectionFieldSets__c);
        }
        system.debug('mdtMap:'+mdtMap);
        for(String section: sections){
            System.debug('processFieldsCmpl Section:'+section);
            if(impchkData.get(PEO_Compliance_mappings__mdt.getInstance(section).Impl_chk_data_field__c) != Null){
                fieldValue = impchkData.get(PEO_Compliance_mappings__mdt.getInstance(section).Impl_chk_data_field__c).toString();
                System.debug('processFieldsCmpl fieldValue:'+fieldValue);
                string[] splitted;
                splitted = fieldValue.split('\\;');
                /*if(section == 'Section_D' || section == 'Section_E'){
                    splitted = fieldValue.split('\\,');
                }
                else{
                    splitted = fieldValue.split('\\;');
                }*/
                List<String> processList = new List<String>();
                // Reversing the list
                /*for(Integer i = splitted.size() - 1; i >= 0; i--){
                    processList.add(splitted[i]);
                }*/
                /*if(section == 'Section_D' || section == 'Section_E'){
                    for(Integer i = 0; i< splitted.size();i++){
                        processList.add(splitted[i]);
                    }
                }
                else{
                    for(Integer i = splitted.size() - 1; i >= 0; i--){
                        processList.add(splitted[i]);
                    }
                }*/
                //S08 update
                for(Integer i = splitted.size() - 1; i >= 0; i--){
                    processList.add(splitted[i]);
                }
                System.debug('processFieldsCmpl reversedList :'+processList);
                System.debug('processFieldsCmpl processList size :'+processList.size());
                //Fetch the section fields under each section from Mdt
                //string sectionFields = PEO_Compliance_mappings__mdt.getInstance(section).sectionFieldSets__c;
                String sectionFields = mdtMap.get(section);
                string[] sectionFieldsList = sectionFields.split('\\;');
                System.debug('processFieldsCmpl sectionFieldsList:'+sectionFieldsList);
                Integer position=0;
                for(Integer i=0;i<processList.size(); i++){
                    //Splitiing for Name and Percentage
                    string[] valsplitted = processList[i].split('\\|');
                    System.debug('valsplitted each part '+i+':'+processList[i]);
                    Integer j=0;
                    Integer valsplittedSize = valsplitted.size();
                    System.debug('Setting: '+sectionFieldsList[position]+ '-to-:'+valsplitted[j]);
                    complInfo.put(sectionFieldsList[position].trim(), valsplitted[j]); //position 0, 3 | 0, 2
                    if(section == 'Section_D' || section == 'Section_E' || section == 'Section_F'){
                        System.debug('Section D or E or F:'+section);
                        position = position +1;
                    }
                    else{
                        j=j+1;  
                        if(section == 'Section_G'){
                            //additional logic for section G which has family member
                            System.debug('Setting: '+sectionFieldsList[position+1]+ '-to-:'+valsplitted[j]);
                            complInfo.put(sectionFieldsList[position+1].trim(), valsplitted[j]); // position 1, 4
                            position = position+1; 
                            j=j+1;
                        }
                        //System.debug('Setting: '+sectionFieldsList[position+1]+ '-to-:'+valsplitted[j]);
                        complInfo.put(sectionFieldsList[position+1].trim(), decimal.valueOf(valsplitted[j]));
                        position = position +2;
                    }
                }
            }
        }
        complInfo.PEO_Implementation_Checklist__c = impchkData.Id;
        complInfo.Prospect_Client__c = impchkData.Prospect_Client__c;
        System.debug('processFieldsCmpl complInfo record to save:'+complInfo);
        return complInfo;
    }
}