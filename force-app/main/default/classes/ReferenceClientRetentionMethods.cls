/** Methods for working on the Reference Client Retention object

 * 
 * History
 * -------
   03/29/2023 Carrie Marciano       Created
   04/18/2023 Carrie Marciano		added creation of Touchpoint off of reference client retention record, moved isUpdate to class, added contact update to sync with case 
   05/09/2023 Carrie Marciano		added update of Parent Prospect Client on reference client retention record	
   05/09/2023 Carrie Marciano		added update of Parent Prospect Client on reference client retention record, comment out Touchpoint, clean up error messages, ensure ownerId set when no acct/contact found	
   05/31/2023 Carrie Marciano		added auto population of Primary Concern Type 1 when Current Step is set to Client Unresponsive
   06/13/2023 Carrie Marciano       post-imp fixes - over writing process notes, creating cases on exception refs, not finding br-clt# due to lowercase
   08/02/2023 Carrie Marciano		added logic for POD Model - multiple recordtypes, current step automation, send to resolution team automation, Email Analytics refObj creation
   10/11/2023 Carrie Marciano		added logic for Email Analytics records to take precedence over other record types when closing duplicate
   12/26/2023 Ahmed Elawad			Added logic into getCase to assign retention notes and retention team comments values into case description. SFDC-24385
   1/22/2024  Carrie Marciano		Added logic to create case on RCR that previously didnt have account populated, when account gets populated.
   5/22/2024  Jermaine Stukes		APR0162327 Added additional Email Analytic logic
  */

public without sharing class ReferenceClientRetentionMethods implements TriggerInterfaceC {
	public static Boolean SKIP_TRIGGER=false;
    public static String acctQuery;
    private static Map<Id,Contact> acctToContactMap = new Map<Id,Contact>();
    private static Map<Id,Case> acctToOpenCaseMap = new Map<Id,Case>();
    private static Map<Id,Case> acctToCaseMap = new Map<Id,Case>();
    private static Schema.RecordTypeInfo caseCRrt = RecordTypeHelper.getRecordType('Service Support Client Retention', 'Case'); 
    private static Schema.RecordTypeInfo triageRtInfo = RecordTypeHelper.getRecordType('Reference Client Retention', 'Reference_Client_Retention__c');
    private static Schema.RecordTypeInfo resoRtInfo = RecordTypeHelper.getRecordType('Client Retention - Resolution Team', 'Reference_Client_Retention__c');
    private static Schema.RecordTypeInfo emailRtInfo = RecordTypeHelper.getRecordType('Client Retention - Email Analytics', 'Reference_Client_Retention__c');			
    private static Id rcdTypeId = caseCRrt.getRecordTypeId();
    
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete){ 	
    	if (isBefore) {
            System.debug('ReferenceClientRetentionMethods.handleTrigger isBefore');
            if (Trigger.isInsert){
            	handleRCRBeforeInsert((Reference_Client_Retention__c[])recs);    
            } 
            else if(Trigger.isUpdate){
                handleRCRBeforeUpdate((Reference_Client_Retention__c[])recs, (Map<Id,Reference_Client_Retention__c>)oldMap);
            }
      	}
        else if(isAfter){
            System.debug('ReferenceClientRetentionMethods.handleTrigger isAfter');
            if (Trigger.isInsert){
            	handleRCRAfterInsert((Reference_Client_Retention__c[])recs, (Map<Id,Reference_Client_Retention__c>)oldMap);                  
            } 
            else if(Trigger.isUpdate){
                handleRCRAfterUpdate((Reference_Client_Retention__c[])recs, (Map<Id,Reference_Client_Retention__c>)oldMap);
            }
        }
    } // handleTrigger
    
    public static String RR_QUEUE_ID=Label.ClientRetentionRRQueue;
    public static String RR_ClientRetention_ID=Label.ClientRetentionResolutionQueue;
    public static String EXCEPT_QUEUE_ID=Label.ClientRetentionExceptionQueue;
    
    public static void handleRCRBeforeInsert(Reference_Client_Retention__c[] recs){
        System.debug('handleRCRBefore enter');
        Map<String,Account> brCltAcctMap = new Map<String,Account>();
        Map<Integer,Account> bISIDAcctMap = new Map<Integer,Account>();
        
        Account[] brcltAccts = new Account[]{};    
        Account[] bisidAccts = new Account[]{};
        String[] searchBrCltset = new String[]{};
        Integer[] searchBISIDset = new Integer[]{};
        List<String> acctsToCheck = new List<String>();    
        Map<Id,Case> acctCaseMap = new Map<Id,Case>();
  		Reference_Client_Retention__c[] refToRoundRobin = new Reference_Client_Retention__c[]{};
        for (Reference_Client_Retention__c newRCR : recs){
            if(newRCR.RecordTypeId == emailRtInfo.recordtypeid){
                //APR0162327
                newRCR.OwnerId = RR_ClientRetention_ID;
            }
            if(newRCR.Prospect_Client_Name__c != null){
            	acctsToCheck.add(newRCR.Prospect_Client_Name__c);    
            }else{
                if(newRCR.RecordTypeId == emailRtInfo.recordtypeid){
                    //APR0162327 Update if no Acct
                    newRCR.OwnerId = RR_ClientRetention_ID;
                    newRCR.Current_Step__c = 'New';
                }else{
                    newRCR.OwnerId = RR_QUEUE_ID;
                    newRCR.Current_Step__c = 'New';
                }
            }
            if (String.isNotBlank(newRCR.Branch_Client_Number__c)){   // best case is we have Branch-Client# 
                newRCR.Branch_Client_Number__c = newRCR.Branch_Client_Number__c.toUpperCase();
                searchBrCltset.add(newRCR.Branch_Client_Number__c);
                //System.debug('handleRCRBefore Branch Client Number added to searchBrCltset size: '+searchBrCltset.Size());
            }
            else if (newRCR.BISID__c != null){   // second best case is we have BIS ID  
                searchBISIDset.add(Integer.valueOf(newRCR.BISID__c));
                //System.debug('handleRCRBefore BIS Id added to searchBISIDset size: '+searchBISIDset.Size());
            } 
        }
               
        if(!searchBrCltset.isEmpty()){
            String query = getAcctQuery();
        	query += ' where AccountNumber in :searchBrCltset';
            System.debug('handleRCRBefore searchBrCltset query='+query);
            brcltAccts = Database.query(query);
            for(Account brcltAcct : brcltAccts){
                brCltAcctMap.put(brcltAcct.AccountNumber, brcltAcct);
            }
        } //searchBrCltset not empty
        
        if(!searchBISIDset.isEmpty()){
            String query = getAcctQuery();
        	query += ' where Bis_ID__c in :searchBISIDset';
            System.debug('handleRCRBefore searchBISIDset query='+query);
            bisidAccts = Database.query(query);
            for(Account bisidAcct : bisidAccts){
                bISIDAcctMap.put(Integer.valueOf(bisidAcct.Bis_ID__c), bisidAcct);
            }
        } //searchBISIDset not empty
        
        Case[] crCases = new Case[]{};
        // search for open cases with recordtype Service Support Client Retention associated with accounts on newly inserted reference object
        crCases = [Select Id, CaseNumber, AccountId, Origin, Origin__c, Current_Step__c, OwnerId, RecordTypeId, Status, ParentId, CreatedDate, ClosedDate, 
                   IsClosedOnCreate, isClosed from Case where AccountId in :acctsToCheck and RecordTypeId = :rcdTypeId and ClosedDate = null];    
        for(Case crCase : crCases){
            //List<String> closeSteps = Label.CaseCurrentClostSteps.split(',');
            //if(!closeSteps.contains(crCase.Current_Step__c)){
                acctCaseMap.put(crCase.AccountId, crCase);
            //}
        } // for 
        // insert all recs - update the record with Account if found, leave blank if no account
        for (Reference_Client_Retention__c newRCR : recs){ 
            List<String> messages = new List<String>();
            Case existingCase = (acctCaseMap.keySet().contains(newRCR.Prospect_Client_Name__c) != null ? acctCaseMap.get(newRCR.Prospect_Client_Name__c) : null);
            if(existingCase != null && newRCR.Prospect_Client_Name__c != null){
                // APR0162327 Update
                if(newRCR.RecordTypeId ==  emailRtInfo.recordtypeid){
                    if(existingCase.Origin == 'Email Analytics'){
                        //messages.add('EMAIL ANALYTICS');
                        newRCR.OwnerId =  existingCase.OwnerId; 
                        newRCR.Current_Step__c = 'Closed - Duplicate';
                        
                    }else if(existingCase.Origin == 'Risk Model File'){
                        //Verify current step
                        if(existingCase.Current_Step__c == 'New'){
                            //messages.add('RISK MODEL NEW');
                            newRCR.OwnerId =  RR_ClientRetention_ID;
                            newRCR.Current_Step__c = 'New';
                            refToRoundRobin.add(newRCR);
                        }else{
                            //messages.add('RISK MODEL NOT NEW');
                            newRCR.OwnerId =  existingCase.OwnerId; 
                            newRCR.Current_Step__c = 'Closed - Duplicate';
                        }
                    }
                }
            }
            
            if(newRCR.Case__c == null){
                if(newRCR.RecordTypeId == emailRtInfo.recordtypeid){
                    newRCR.Current_Step__c = (newRCR.Current_Step__c != null ? newRCR.Current_Step__c : 'New'); 
                    messages.add('Reference Client Retention created by Email Analytics');
                	system.debug('handleRCRBefore newRCR.Case__c == null, ref created before case - Email Analytics');    
                }
                else{ 
                    messages.add('Reference Client Retention created by Risk Model');
                    system.debug('handleRCRBefore newRCR.Case__c == null, ref created before case - Triage');
                    newRCR.RecordTypeId = triageRtInfo.recordtypeid;
                    
                    if(brCltAcctMap.Size() > 0){
                        newRCR.Branch_Client_Number__c = newRCR.Branch_Client_Number__c.toUpperCase();
                        //system.debug('handleRCRBefore newRCR.Branch_Client_Number__c: '+newRCR.Branch_Client_Number__c);
                        Account fAcct = (brCltAcctMap.keySet().contains(newRCR.Branch_Client_Number__c) != null ? brCltAcctMap.get(newRCR.Branch_Client_Number__c) : null);                   
                        if(fAcct != null){
                           newRCR.Prospect_Client_Name__c = fAcct.Id;
                           newRCR.Parent_Prospect_Client_Name__c = (fAcct.ParentId != null ? fAcct.ParentId : null);
                           newRCR.Paychex_Payroll_Specialist__c = (fAcct.Paychex_Payroll_Specialist__c != null ? fAcct.Paychex_Payroll_Specialist__c : null); 
                           newRCR.OwnerId = RR_QUEUE_ID;  
                           newRCR.Current_Step__c = 'New'; 
                        } 
                        else{
                            newRCR.OwnerId = EXCEPT_QUEUE_ID;
                            newRCR.Current_Step__c = 'New';
                            messages.add('No matching account found in Salesforce for Br-Clt#');
                            system.debug('handleRCRBefore No matching account found in Salesforce');
                        } // fAcct != null    
                    }
                    else if(bISIDAcctMap.Size() > 0){
                        Account fAcct = (bISIDAcctMap.keySet().contains(Integer.valueOf(newRCR.BISID__c)) != null ? bISIDAcctMap.get(Integer.valueOf(newRCR.BISID__c)) : null);
                        //system.debug('handleRCRBefore bISIDAcctMap fAcct: '+fAcct.Id);
                        if(fAcct != null){
                           newRCR.Prospect_Client_Name__c = fAcct.Id;
                           newRCR.Parent_Prospect_Client_Name__c = (fAcct.ParentId != null ? fAcct.ParentId : null);
                           newRCR.Paychex_Payroll_Specialist__c = (fAcct.Paychex_Payroll_Specialist__c != null ? fAcct.Paychex_Payroll_Specialist__c : null);  
                           newRCR.OwnerId = RR_QUEUE_ID; 
                           newRCR.Current_Step__c = 'New'; 
                        } 
                        else{
                            newRCR.OwnerId = EXCEPT_QUEUE_ID;
                            newRCR.Current_Step__c = 'New';
                            messages.add('No matching account found in Salesforce for BISId');
                            system.debug('handleRCRBefore No matching account found in Salesforce');
                        } // fAcct != null
                    }
                    else{
                        newRCR.OwnerId = EXCEPT_QUEUE_ID;
                        newRCR.Current_Step__c = 'New';
                        messages.add('No matching account found in Salesforce for Br-Clt# or BISId');
                        system.debug('handleRCRBefore No matching account found in Salesforce');
                    } // !foundAccts.isEmpty  
                    
                    refToRoundRobin.add(newRCR);
                } //newRCR.RecordTypeId == emailRtInfo.recordtypeid
        	} 
            else{
                messages.add('Reference Client Retention created by Case');
                system.debug('handleRCRBefore newRCR.Case__c != null, ref created after case');
            }// newRCR.Case__c == null 
            String msg = !messages.isEmpty() ? String.join(messages,'\n') : null;
            addToNotes(newRCR, msg, true); 
            system.debug('handleRCRBefore after addToNotes');
            if(newRCR.OwnerId == RR_ClientRetention_ID){
                refToRoundRobin.add(newRCR);
            }              
        } //for
        if(!refToRoundRobin.isEmpty()){
            System.debug('handleRCRBefore call to RoundRobin.prepareGenericRoundRobin');
            RoundRobin.prepareGenericRoundRobin(refToRoundRobin,null);
         }
         
    } // handleRCRBeforeInsert
    
    public static String getAcctQuery(){
    	if (acctQuery == null) {
            acctQuery = 'Select Id, Name, AccountNumber, ParentId, Bis_ID__c, Paychex_CAID__c, Lost_Date__c, Paychex_Payroll_Specialist__c, Paychex_Payroll_Specialist__r.ReportsToId From Account ';
        }
        System.debug('getAcctQuery acctQuery='+acctQuery);
        return acctQuery;
    } //getAcctQuery
    
    public static void handleRCRAfterInsert(Reference_Client_Retention__c[] recs, Map<Id,Reference_Client_Retention__c> oldMap){
    	System.debug('ReferenceClientRetentionMethods - handleRCRAfterInsert enter');
        Contact[] ctctsToCheck = new Contact[]{}; 
        Id[] acctsToCheck = new Id[]{}; 
        Map<Id, Reference_Client_Retention__c> rcrUpdateMap = new Map<Id, Reference_Client_Retention__c>(); 
        List<id> refids = new List<id>();
        
        Schema.RecordTypeInfo ctctRT = RecordTypeHelper.getRecordType('2008-09 Support Contact Record Type', 'Contact');
        Id rcdTypeId=ctctRT.getRecordTypeId();
            
        for (Reference_Client_Retention__c newRetentionRec : recs) {
        	Reference_Client_Retention__c oldRCR = (oldMap != null ? oldMap.get(newRetentionRec.Id) : null);
            if (oldRCR == null && String.isNotBlank(newRetentionRec.Prospect_Client_Name__c)){
                // get contact data to find matches in Salesforce OR create new contact
                if(String.isNotBlank(newRetentionRec.Contact_Name__c)){
                    StringHelper.parseFullName(newRetentionRec.Contact_Name__c);
                    Contact ctct = new Contact(AccountId=newRetentionRec.Prospect_Client_Name__c, FirstName=StringHelper.firstName, LastName=StringHelper.lastName, Email=newRetentionRec.Contact_Email__c, Phone=newRetentionRec.Contact_Phone_Number__c, Sales_Contact__c=False, RecordTypeId=rcdTypeId );
                    ctctsToCheck.add(ctct);  
                } // if insert has acctId has Contact Name
                // get list of accounts to see if an open case exists
                if(String.isBlank(newRetentionRec.Case__c)){
                    acctsToCheck.add(newRetentionRec.Prospect_Client_Name__c);  
                }// if insert and has acctId no Case
            }
        }
     	
        System.debug('handleRCRAfterInsert ctctsToCheck: '+ctctsToCheck.size());        
        if (!ctctsToCheck.isEmpty()) {
        	getContacts(ctctsToCheck);  
        }
        else{
            system.debug('handleRCRAfterInsert No Contact info available');    
        } // !ctctsToCheck.isEmpty()
        
        System.debug('handleRCRAfterInsert acctsToCheck: '+acctsToCheck.size());
        if(!acctsToCheck.isEmpty()){
        	getCases(acctsToCheck, recs);  
        }
        else{
            system.debug('handleRCRAfterInsert No Accounts to check for cases');    
        } // !acctsToCheck.isEmpty()
        
        for (Reference_Client_Retention__c newRetentionRec : recs) {
            Reference_Client_Retention__c updateRCR = new Reference_Client_Retention__c(Id=newRetentionRec.Id, ProcessNotes__c=newRetentionRec.ProcessNotes__c);
            String msg = '';            
            //system.debug('handleRCRAfterInsert acctToContactMap: '+acctToContactMap.size());	
 
            if (acctToContactMap.size() > 0){
                Contact fCtct = (acctToContactMap.keySet().contains(newRetentionRec.Prospect_Client_Name__c) != null ? acctToContactMap.get(newRetentionRec.Prospect_Client_Name__c) : null);
                if(fCtct != null){                          
                    updateRCR.Prospect_Client_Contact__c=fCtct.Id;
                    msg += '\nUpdate record with contact found in Salesforce or created';  	
                    system.debug('handleRCRAfterInsert updateRCR.Prospect_Client_Contact__c: '+updateRCR.Prospect_Client_Contact__c); 
                } 
                else{
                    msg += '\nNo matching contact found in Salesforce or created';  
                    system.debug('handleRCRAfterInsert No matching contact found in Salesforce or created');
                } // fCtct != null    
            }
            else{
                    msg += '\nNo matching account/contact found in Salesforce or created';  
                    system.debug('handleRCRAfterInsert No matching account/contact found in Salesforce or created');
            } //acctToContactMap.size()
            
            if(acctToCaseMap.size() > 0){
                Case fCase = (acctToCaseMap.keySet().contains(newRetentionRec.Prospect_Client_Name__c) != null ? acctToCaseMap.get(newRetentionRec.Prospect_Client_Name__c) : null);
                if (fCase != null){
                    updateRCR.Case__c=fCase.Id;
                    //if case was created as Closed-Duplicate need to set owner of reference client retention to case owner and set current step to closed
                    if (fCase.Status == 'Closed - Duplicate'){
                    	updateRCR.OwnerId = fCase.OwnerId;
                        updateRCR.Current_Step__c = 'Closed - Duplicate';
                    }
                    /* Touchpoint is on hold for CRT
                    else{
                        refids.add(newRetentionRec.Id);
                    } */   
                } else{
                    msg += '\nNo case created';  
                    system.debug('handleRCRAfterInsert No case created');    
                } // fCase != null
            }
            else{
                    msg += '\nNo case created';  
                    system.debug('handleRCRAfterInsert No case created');
            }// acctToCaseMap.size()
            
            addToNotes(updateRCR,msg, true);
            rcrUpdateMap.put(updateRCR.Id, updateRCR);
        } //for
        
        system.debug('handleRCRAfterInsert rcrUpdateMap: '+rcrUpdateMap.size());
        if(!rcrUpdateMap.isEmpty()){
            SKIP_TRIGGER=True;
            DmlHelper.performDML2(rcrUpdateMap.values(), DmlHelper.DML_UPDATE, 'ReferenceClientRetentionMethods', 'handleRCRAfterInsert', 'Update Reference Client Retention Record', false); 
            system.debug('handleRCRAfterInsert after update recs');
            SKIP_TRIGGER=False;
        } //!rcrUpdateMap.isEmpty
        
        /* Touchpoint is on hold for CRT
        if(!refids.isEmpty() && Label.ClientRetentionCreateCAR == 'True'){
            createCARs(refids);
            System.debug('handleRCRAfterInsert after createCARs');
        } */
                
    } //handleRCRAfterInsert
    
    public static void handleRCRBeforeUpdate(Reference_Client_Retention__c[] recs, Map<Id,Reference_Client_Retention__c> oldMap){
        System.debug('handleRCRBeforeUpdate enter');
        Id[] acctsToCheck = new Id[]{};
        Id[] currentStepUpdate = new Id[]{};    
        Account[] accts = new Account[]{};    
		Map<Id,Account> acctMap = new Map<Id,Account>();
        Reference_Client_Retention__c[] refToRoundRobin = new Reference_Client_Retention__c[]{};
        //List<String> stepDefaultConcernList = label.ClientRetentionStepDefaultPrimaryConcern.split(',');
                
        // get reference records where prospect client name has changed, to grab parent prospect client OR where current step changed
        for (Reference_Client_Retention__c newRetentionRec : recs){
            Reference_Client_Retention__c oldRec = (oldMap != null ? oldMap.get(newRetentionRec.Id) : null);
            if(newRetentionRec.OwnerId == RR_ClientRetention_ID){
                refToRoundRobin.add(newRetentionRec);
            }
            if(newRetentionRec.Prospect_Client_Name__c != null && newRetentionRec.Prospect_Client_Name__c != oldRec.Prospect_Client_Name__c){
            	acctsToCheck.add(newRetentionRec.Prospect_Client_Name__c);    
            } 
            //if (newRetentionRec.Current_Step__c != oldnewRetentionRec.Current_Step__c && stepDefaultConcernList.contains(newRetentionRec.Current_Step__c)){
            System.debug('handleRCRBeforeUpdate newRetentionRec.Current_Step__c: '+newRetentionRec.Current_Step__c+' oldRec.Current_Step__c: '+oldRec.Current_Step__c);
            if (newRetentionRec.Current_Step__c != oldRec.Current_Step__c){    
                currentStepUpdate.add(newRetentionRec.Id);
            }
        } //for
        
        System.debug('handleRCRBeforeUpdate acctsToCheck: '+acctsToCheck.size());
        if(!acctsToCheck.isEmpty()){
        	String query = getAcctQuery();
        	query += ' where Id in :acctsToCheck and ParentId != null';
            System.debug('handleRCRBeforeUpdate acctsToCheck query='+query);
            accts = Database.query(query);
            for(Account acct : accts){
                acctMap.put(acct.Id, acct);
            } 
            getCases(acctsToCheck, recs);
        }

        for (Reference_Client_Retention__c updRCR : recs){   
            String msg = '';
            Reference_Client_Retention__c prevRec = (oldMap != null ? oldMap.get(updRCR.Id) : null);
            
            // check for account and/or parent account updates
            if(!acctMap.isEmpty()){
            	Account fAcct = (acctMap.keySet().contains(updRCR.Prospect_Client_Name__c) != null ? acctMap.get(updRCR.Prospect_Client_Name__c) : null);                   
            	if(fAcct != null){
                    updRCR.Parent_Prospect_Client_Name__c = (fAcct.parentId != null ? fAcct.parentId : null);                   
                    msg += '\nUpdate record with Parent Prospect Client'; 
                    System.debug('handleRCRBeforeUpdate updated Parent_Prospect_Client_Name__c '+updRCR.Parent_Prospect_Client_Name__c);    
            	} // fAcct != null     
            } // !acctMap.isEmpty
            
            if(acctToCaseMap.size() > 0){
                Case fCase = (acctToCaseMap.keySet().contains(updRCR.Prospect_Client_Name__c) != null ? acctToCaseMap.get(updRCR.Prospect_Client_Name__c) : null);
                if (fCase != null){
                    updRCR.Case__c=fCase.Id;
                    //if case was created as Closed-Duplicate need to set owner of reference client retention to case owner and set current step to closed
                    if (fCase.Status == 'Closed - Duplicate'){
                    	updRCR.OwnerId = fCase.OwnerId;
                        updRCR.Current_Step__c = 'Closed - Duplicate';
                    }
                    msg += '\nprospect-client was updated, case was created and RCR case field populated';
                    system.debug('handleRCRBeforeUpdate prospect-client was updated, case was created and RCR case field populated'); 
                    /* Touchpoint is on hold for CRT
                    else{
                        refids.add(rec.Id);
                    } */   
                } else{
                    msg += '\nNo case created';  
                    system.debug('handleRCRBeforeUpdate No case created');    
                } // fCase != null
            }
            else{
                    msg += '\nNo case created';  
                    system.debug('handleRCRBeforeUpdate No case created');
            }// acctToCaseMap.size()
            
            if (!currentStepUpdate.isEmpty() && currentStepUpdate.contains(updRCR.Id)){
                System.debug('handleRCRBeforeUpdate updRCR.RecordTypeId: '+updRCR.RecordTypeId);
                Schema.RecordTypeInfo updRCRRtInfo = RecordTypeHelper.getRecordTypeById(updRCR.RecordTypeId, 'Reference_Client_Retention__c');
                
                System.debug('handleRCRBeforeUpdate updRCRRtInfo.name: '+updRCRRtInfo.getName());
                System.debug('handleRCRBeforeUpdate updRCR.Current_Step__c: '+updRCR.Current_Step__c);
                // update primary concern if current step requires default
                ClientRet_Primary_Concern_Settings__mdt pConcernMD = getPrimaryConcernMetadata(updRCRRtInfo.name, updRCR.Current_Step__c);
                if(pConcernMD != null){
                	updRCR.Primary_Concern_Type_1__c = (pConcernMD.Primary_Concern_Type_1_Default__c != null ? pConcernMD.Primary_Concern_Type_1_Default__c : null);
                	msg += '\nUpdate record with default Primary Concern Type 1'; 
                	system.debug('handleRCRBeforeUpdate update Primary Concern Type 1, Current Step: '+updRCR.Current_Step__c+' Primary_Concern_Type_1__c: '+updRCR.Primary_Concern_Type_1__c);    
                } // pConcernMD != null
                
                // transfer record to Resolution team
                if(updRCR.Current_Step__c == 'Transfer to Resolution Team' && updRCR.Current_Step__c != prevRec.Current_Step__c && updRCRRtInfo.recordtypeid != resoRtInfo.recordtypeid){
                	updRCR.RecordTypeId = resoRtInfo.recordtypeid;
                    updRCR.OwnerId = RR_ClientRetention_ID;
                    updRCR.Transfer_to_Resolution_Date__c = Datetime.now();
                    updRCR.Transfer_to_Resolution_Team__c = UserInfo.getName();
                    refToRoundRobin.add(updRCR);
                    msg += '\nTransferring record to Resolution Team - set recordtype, owner to ClientRetentionResolutionQueue, Date/time and Running User who updated Current Step';
                    system.debug('handleRCRBeforeUpdate update Current Step set to Transfer to Resolution Team recordtype: '+updRCR.RecordTypeId+' owner: '+updRCR.OwnerId);
                } // updRCR.Current_Step__c == 'Transfer to Resolution Team' 
            } // !currentStepUpdate.isEmpty
            addToNotes(updRCR, msg, true);
        } //for
        if(!refToRoundRobin.isEmpty()){
            System.debug('handleRCRBefore call to RoundRobin.prepareGenericRoundRobin');
            RoundRobin.prepareGenericRoundRobin(refToRoundRobin,null);
        }
        
    } //handleRCRBeforeUpdate
    
   public static void handleRCRAfterUpdate(Reference_Client_Retention__c[] recs, Map<Id,Reference_Client_Retention__c> oldMap){
    	System.debug('handleRCRAfterUpdate enter');
        Map<Id,Case> caseUpdateMap = new Map<Id,Case>();
        List<String> statusList = label.Client_Retention_Status.split(',');
        
        for(Reference_Client_Retention__c uRCR : recs){
            Reference_Client_Retention__c oldRCR = (oldMap != null ? oldMap.get(uRCR.Id) : null); 
            Case updateCase = new Case();
            Boolean updated = False;
            System.debug('handleRCRAfterUpdate uRCR: '+uRCR.Case__c+' '+uRCR.Current_Step__c+' '+oldRCR.Current_Step__c+' '+uRCR.Prospect_Client_Name__c+' '+uRCR.Prospect_Client_Contact__c);
			//look for ref updates that need to update related case
            if(uRCR.Case__c != null){
            	updateCase.Id = uRCR.Case__c;
                if(uRCR.Current_Step__c != null && uRCR.Current_Step__c != oldRCR.Current_Step__c){
                    updateCase.Current_Step__c = uRCR.Current_Step__c;
                    updated = True;
                    if (statusList.contains(updateCase.Current_Step__c)){
                        updateCase.Status = 'Closed';
                    }
                    //system.debug('handleRCRAfterUpdate update Case Current Step old: '+oldRCR.Current_Step__c+' new: '+updateCase.Current_Step__c);
                }
                if(uRCR.Prospect_Client_Name__c != null && uRCR.Prospect_Client_Name__c != oldRCR.Prospect_Client_Name__c){
                    updateCase.AccountId = uRCR.Prospect_Client_Name__c;
                    updateCase.Client_Number__c = uRCR.Prospect_Client_Number__c.substring(uRCR.Prospect_Client_Number__c.indexOf('-') + 1);
                    try {
                        updateCase.Branch_ID__c = Decimal.valueof(uRCR.Prospect_Client_Number__c.substring(0, uRCR.Prospect_Client_Number__c.indexOf('-')));
                    }catch(Exception e) {
                        System.debug('Branch Id on RCR record was not a number');
                    }
                    updated = True;
                    //system.debug('handleRCRAfterUpdate update Case Account old: '+oldRCR.Prospect_Client_Name__c+' new: '+updateCase.AccountId);
                }
                if(uRCR.OwnerId != null && uRCR.OwnerId != oldRCR.OwnerId){
                    updateCase.OwnerId = uRCR.OwnerId;
                    updated = True;
                    //system.debug('handleRCRAfterUpdate update Case Owner old: '+oldRCR.OwnerId+' new: '+updateCase.OwnerId);
                }
                if(uRCR.Case_Type__c == 'Email Analytics'){
                    updateCase.OwnerId = uRCR.OwnerId;
                    updated = True;
                    //system.debug('handleRCRAfterUpdate update Case Owner old: '+oldRCR.OwnerId+' new: '+updateCase.OwnerId);
                }
                if(uRCR.Prospect_Client_Contact__c != null && uRCR.Prospect_Client_Contact__c != oldRCR.Prospect_Client_Contact__c){
                    updateCase.ContactId = uRCR.Prospect_Client_Contact__c;
                    updated = True;
                    //system.debug('handleRCRAfterUpdate update Case Contact old: '+oldRCR.Prospect_Client_Contact__c+' new: '+updateCase.ContactId);
                }
                Boolean retentionNotesHaveChanged = uRCR.retention_notes__c != null && (uRCR.retention_notes__c !=oldRCR.retention_notes__c);
                Boolean resolutionCommentsHaveChanged = uRCR.Resolution_Team_Comments__c != null && (uRCR.Resolution_Team_Comments__c != oldRCR.Resolution_Team_Comments__c);
                if (retentionNotesHaveChanged || resolutionCommentsHaveChanged) {
                    updateCase.Description = mergeStringsUpToLength(uRCR.Retention_Notes__c, uRCR.Resolution_Team_Comments__c, 32000);
                    updated = true;
                }
            }
            if(updated){
                caseUpdateMap.put(updateCase.Id, updateCase);
            } 
                    
        } //for
		
        system.debug('handleRCRAfterUpdate Cases to be updated:'+caseUpdateMap.size());
        if (!caseUpdateMap.isEmpty()){
        	DmlHelper.performDML2(caseUpdateMap.values(), DmlHelper.DML_UPDATE, 'ReferenceClientRetentionMethods', 'handleRCRAfterUpdate', 'Update Case from Reference Client Retention', false); 
            system.debug('handleRCRAfterUpdate after update cases');     
        } //!caseUpdateMap.isEmpty
            
    } //handleRCRAfterUpdate
    
    private static ClientRet_Primary_Concern_Settings__mdt getPrimaryConcernMetadata(String recordTypeName, string currentStep){
        System.debug('getPrimaryConcernMetadata begin');   
        ClientRet_Primary_Concern_Settings__mdt returnVal = null;
        List<ClientRet_Primary_Concern_Settings__mdt> primaryConcernSettings = queryPrimaryConcernMetadata(recordTypeName, currentStep);
        if(!primaryConcernSettings.isEmpty()){
        	returnVal = primaryConcernSettings[0];
        }
		System.debug('getPrimaryConcernMetadata returnVal: '+returnVal);
        return returnVal;
    } // getPrimaryConcernMetadata

    public static List<ClientRet_Primary_Concern_Settings__mdt> queryPrimaryConcernMetadata(String recordTypeName, string currentStep){
        System.debug('queryPrimaryConcernMetadata begin');  
        return [
            SELECT Id, Label, Current_Step_Value__c, RecordType_Name__c, Primary_Concern_Type_1_Default__c
            FROM ClientRet_Primary_Concern_Settings__mdt
            WHERE Current_Step_Value__c = :currentStep AND RecordType_Name__c = :recordTypeName
        ];
    } // queryPrimaryConcernMetadata
    
    private static void getContacts(Contact[] ctctsToCheck) {
        System.debug('getContacts enter');
        Contact[] ctctToInsert = new Contact[]{};    
        Id[] foundCtctIds = new Id[]{};
        List<Contact> foundCtcts = new List<Contact>();   
            
    	DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(ctctsToCheck); 
        System.debug('getContacts DuplicateHelper results='+results.size());
        for (Integer cnt=0; cnt<ctctsToCheck.size(); cnt++) {
            //System.debug('getContacts dupeContactChecker cnt='+cnt);
            Contact ctct = ctctsToCheck[cnt];
            //System.debug('getContacts dupeContactChecker ctct='+ctct);
            DuplicateHelper.DupeResult result = results[cnt];
            //System.debug('getContacts dupeContactChecker result='+result.ctctIds.Size());  
            if (!result.ctctIds.isEmpty()) {
                foundCtctIds.addAll(result.ctctIds);
                System.debug('getContacts foundCtctIds: '+foundCtctIds.size());
            }
            else{
                ctctToInsert.add(ctct);
                System.debug('getContacts ctctToInsert: '+ctctToInsert.size());
            }
        } // for
        
        // need to query for AccountId of found contacts because its not returned with DuplicateHelper Results
        // add to map of accountId and contact record - contains all contacts to be matched with a Reference Client Retention record
        if(!foundCtctIds.isEmpty()){           
            foundCtcts = [Select Id, AccountId from Contact where Id in :foundCtctIds]; 
            //System.debug('getContacts foundCtcts: '+foundCtcts);
            if(!foundCtcts.isEmpty()){
                for(Contact fctct : foundCtcts){
                    acctToContactMap.put(fctct.AccountId, fctct);
                    //System.debug('getContacts building acctToContactMap Account: '+fctct.AccountId+' Contact: '+fctct.Id);
                }
            }
        }
        
        // after insert new contacts
        // add to map of accountId and contact record - contains all contacts to be matched with a Reference Client Retention record
        if(!ctctToInsert.isEmpty()){
            DmlHelper.performDML2(ctctToInsert, DmlHelper.DML_INSERT, 'ReferenceClientRetentionMethods', 'handleRCRAfterInsert', 'Insert new Contacts', true); 
            System.debug('getContacts after insert contacts ctctToInsert: '+ctctToInsert);
            for (Contact ctct : ctctToInsert){
                acctToContactMap.put(ctct.AccountId, ctct);
            } //for                
        } //!ctctToInsert.isEmpty(    
    } // getContacts
    
    private static void getCases(Id[] acctsToCheck, Reference_Client_Retention__c[] recs){
    	System.debug('getCases enter');    
        Case[] crCases = new Case[]{};
        Case[] casesToInsert = new Case[]{};
        //List<Case> casesToUpdate = new List<Case>();
        List<Id> existingCaseIds = new List<Id>();
        List<Reference_Client_Retention__c> existingRCRs = new List<Reference_Client_Retention__c>();
        List<Reference_Client_Retention__c> existingRCRsToUpdate = new List<Reference_Client_Retention__c>();
        Map<Id,Reference_Client_Retention__c> existingRcrMap = new Map<Id,Reference_Client_Retention__c>();        
        // search for open cases with recordtype Service Support Client Retention associated with accounts on newly inserted reference object
        crCases = [Select Id, CaseNumber, AccountId, Origin, Origin__c, Current_Step__c, OwnerId, RecordTypeId, Status, ParentId, CreatedDate, ClosedDate, 
                   IsClosedOnCreate, isClosed from Case where AccountId in :acctsToCheck and RecordTypeId = :rcdTypeId and ClosedDate = null];    
        //existingRCR = [Select Id from Reference_Client_Retention__c where ]
        for(Case crCase : crCases){
            List<String> closeSteps = Label.CaseCurrentCloseSteps.split(',');
            if(!closeSteps.contains(crCase.Current_Step__c)){
                acctToOpenCaseMap.put(crCase.AccountId, crCase);
                existingCaseIds.add(crCase.Id);
            }
        } // for  
        if(!existingCaseIds.isEmpty()){
            existingRCRs = [Select Id, Current_Step__c, Case__c from Reference_Client_Retention__c where Case__c in:existingCaseIds];
            for(Reference_Client_Retention__c existingRec : existingRCRs){
                existingRcrMap.put(existingRec.Case__c, existingRec);
            }
        }
        
        for (Reference_Client_Retention__c newRetentionRec : recs) {
            Case newCase = new Case();
            //system.debug('acctsToCheck rec to create case for: '+newRetentionRec.id+' newRetentionRec.Prospect_Client_Name__c '+newRetentionRec.Prospect_Client_Name__c);
            //see if a contact was found for newRetentionRec.Prospect_Client_Name__c in getContacts acctToContactMap
            Contact existingCaseContact = (acctToContactMap.size() > 0 && acctToContactMap.keySet().contains(newRetentionRec.Prospect_Client_Name__c) != null ? acctToContactMap.get(newRetentionRec.Prospect_Client_Name__c) : null);
            if(acctToOpenCaseMap.size() > 0){     
                Case existingCase = (acctToOpenCaseMap.keySet().contains(newRetentionRec.Prospect_Client_Name__c) != null ? acctToOpenCaseMap.get(newRetentionRec.Prospect_Client_Name__c) : null);
                if(existingCase != null && newRetentionRec.Prospect_Client_Name__c != null){    //if acct & open case - create case set to closed duplicate, set owner to open case owner, send chatter to open case owner OR Email Analytics cases remain open
                    newCase.AccountId = newRetentionRec.Prospect_Client_Name__c;
                    newCase.ContactId = (existingCaseContact != null && existingCaseContact.Id != null ? existingCaseContact.Id : null);
                    newCase.RecordTypeId = rcdTypeId;    
                    newCase.Priority = 'Low';
                    newCase.Origin = (newRetentionRec.Case_Type__c != null && newRetentionRec.Case_Type__c == 'Email Analytics' ? 'Email Analytics' : 'Risk Model File');
                    //Origin__c value is used to prevent object relationships from creating a second refObj if the Case is manually created first
                    newCase.Origin__c = 'Reference Client Retention';
                    newCase.Subject = Label.ClientRetentionCaseSubject;
                    // APR0162327 Update
                    if(existingCase.Origin == 'Email Analytics'){
                        newCase.OwnerId = existingCase.OwnerId;  
                        newCase.Status = 'Closed - Duplicate';
                        newCase.Current_Step__c = 'Closed - Duplicate';
                    }else if(existingCase.Origin == 'Risk Model File'){
                        //Verify current step
                        if(existingCase.Current_Step__c == 'New'){
                            //newCase.OwnerId = RR_QUEUE_ID;
                            newCase.Current_Step__c = 'New';
                            //existingCase.Status = 'Closed - Duplicate';
                            //existingCase.Current_Step__c = 'Closed - Duplicate';
                            //casesToUpdate.add(existingCase);
                            if(existingRcrMap.keySet().contains(existingCase.Id)){
                                Reference_Client_Retention__c existingRcr = existingRcrMap.get(existingCase.Id);
                                existingRcr.Current_Step__c = 'Closed - Duplicate';
                                existingRCRsToUpdate.add(existingRcr);
                            } 
                        }else{
                            newCase.OwnerId = existingCase.OwnerId;  
                            newCase.Status = 'Closed - Duplicate';
                            newCase.Current_Step__c = 'Closed - Duplicate';
                        }
                    }
                    else{
                        newCase.OwnerId = existingCase.OwnerId;   
                        newCase.Status = 'Closed - Duplicate';
                        newCase.Current_Step__c = 'Closed - Duplicate';
                    }
                    
                    // if New refCliRet is Email Analytics it should remain open unless the open case found is also Email Analytics, then it will close-duplicate like normal
                    // APR0162327 Update
                    /*if(newRetentionRec.RecordTypeId == emailRtInfo.recordtypeid && existingCase.Origin != 'Email Analytics'){
//newCase.Status = 'New';
//newCase.Current_Step__c = newRetentionRec.Current_Step__c;
//need a notification to EA owner that there is an open case already being worked
} else{
newCase.OwnerId = existingCase.OwnerId;   
newCase.Status = 'Closed - Duplicate';
newCase.Current_Step__c = 'Closed - Duplicate';
}*/
                    // SFDC-24385: add relavent comments so they get picked up by upstream
                    if (newRetentionRec.Prospect_Client_Number__c != null ) {
                        newCase.Client_Number__c = newRetentionRec.Prospect_Client_Number__c.substring(newRetentionRec.Prospect_Client_Number__c.indexOf('-') + 1);
                        try {
                            newCase.Branch_ID__c = Decimal.valueof(newRetentionRec.Prospect_Client_Number__c.substring(0, newRetentionRec.Prospect_Client_Number__c.indexOf('-')));
                        }catch(Exception e) {
                            System.debug('getCases Branch Id on RCR record was not a number');
                        }
                    }
                    newCase.Description = mergeStringsUpToLength(newRetentionRec.Retention_Notes__c, newRetentionRec.Resolution_Team_Comments__c, 32000);
                    casesToInsert.add(newCase);
                } 
                else if(existingCase == null && newRetentionRec.Prospect_Client_Name__c != null){     //if acct & no open case - create case, set owner to rec owner
                    newCase.AccountId = newRetentionRec.Prospect_Client_Name__c;
                    newCase.OwnerId = newRetentionRec.OwnerId;
                    newCase.ContactId = (existingCaseContact != null && existingCaseContact.Id != null ? existingCaseContact.Id : null);
                    newCase.RecordTypeId = rcdTypeId;    
                    newCase.Priority = 'Low';
                    newCase.Status = 'New';
                    newCase.Current_Step__c = newRetentionRec.Current_Step__c;
                    newCase.Origin = (newRetentionRec.Case_Type__c != null && newRetentionRec.Case_Type__c == 'Email Analytics' ? 'Email Analytics' : 'Risk Model File');
                    //Origin__c value is used to prevent object relationships from creating a second refObj if the Case is manually created first
                    newCase.Origin__c = 'Reference Client Retention';
                    newCase.Subject = Label.ClientRetentionCaseSubject;
                    // SFDC-24385: add relavent comments so they get picked up by upstream
                    if (newRetentionRec.Prospect_Client_Number__c != null ) {
                        newCase.Client_Number__c = newRetentionRec.Prospect_Client_Number__c.substring(newRetentionRec.Prospect_Client_Number__c.indexOf('-') + 1);
                        try {
                            newCase.Branch_ID__c = Decimal.valueof(newRetentionRec.Prospect_Client_Number__c.substring(0, newRetentionRec.Prospect_Client_Number__c.indexOf('-')));
                        }catch(Exception e) {
                            System.debug('getCases Branch Id on RCR record was not a number');
                        }
                    }
                    newCase.Description = mergeStringsUpToLength(newRetentionRec.Retention_Notes__c, newRetentionRec.Resolution_Team_Comments__c, 32000);
                    casesToInsert.add(newCase);
                } 
                else {      //if no acct - do not create case, ref owner will be exception queue                   
                    system.debug('getCases acctToOpenCaseMap.size() > 0 No Account Info to find or create case with, owner is Exception Queue');
                }
            }
            else if (newRetentionRec.Prospect_Client_Name__c != null){     //if acct & no open case - create case, set owner to rec owner
                newCase.AccountId = newRetentionRec.Prospect_Client_Name__c;
                newCase.OwnerId = newRetentionRec.OwnerId;
                newCase.ContactId = (existingCaseContact != null && existingCaseContact.Id != null ? existingCaseContact.Id : null);
                newCase.RecordTypeId = rcdTypeId;    
                newCase.Priority = 'Low';
                newCase.Status = 'New';
                newCase.Current_Step__c = newRetentionRec.Current_Step__c;
                newCase.Origin = (newRetentionRec.Case_Type__c != null && newRetentionRec.Case_Type__c == 'Email Analytics' ? 'Email Analytics' : 'Risk Model File');
                //Origin__c value is used to prevent object relationships from creating a second refObj if the Case is manually created first
                newCase.Origin__c = 'Reference Client Retention';
                newCase.Subject = Label.ClientRetentionCaseSubject;
                // SFDC-24385: add relavent comments so they get picked up by upstream
                if (newRetentionRec.Prospect_Client_Number__c != null ) {
                    newCase.Client_Number__c = newRetentionRec.Prospect_Client_Number__c.substring(newRetentionRec.Prospect_Client_Number__c.indexOf('-') + 1);
                    try {
                        newCase.Branch_ID__c = Decimal.valueof(newRetentionRec.Prospect_Client_Number__c.substring(0, newRetentionRec.Prospect_Client_Number__c.indexOf('-')));
                    }catch(Exception e) {
                        System.debug('getCases Branch Id on RCR record was not a number');
                    }
                }
                newCase.Description = mergeStringsUpToLength(newRetentionRec.Retention_Notes__c, newRetentionRec.Resolution_Team_Comments__c, 32000);
                casesToInsert.add(newCase);
            }
            else {      //if no acct - do not create case, ref owner will be exception queue
                system.debug('getCases No Account Info to find or create case with, owner is Exception Queue');
            } 
        } // for
        
        // after insert new cases
        // add to map of accountId and case record - contains all cases to be matched with a Reference Client Retention record
        /*if(!casesToUpdate.isEmpty()){
            Update casesToUpdate;
            //DmlHelper.performDML2(casesToInsert, DmlHelper.DML_UPDATE, 'ReferenceClientRetentionMethods', 'handleRCRAfterInsert', 'Update new Cases', true); 
        }*/
        if(!existingRCRsToUpdate.isEmpty()){
            Update existingRCRsToUpdate;
            //DmlHelper.performDML2(existingRCRsToUpdate, DmlHelper.DML_UPDATE, 'Reference_Client_Retention__c', 'handleRCRAfterInsert', 'Update existing client retention records', true);
        }
        if(!casesToInsert.isEmpty()){
            DmlHelper.performDML2(casesToInsert, DmlHelper.DML_INSERT, 'ReferenceClientRetentionMethods', 'handleRCRAfterInsert', 'Insert new Cases', true); 
            System.debug('getCases after insert cases casesToInsert: '+casesToInsert);
            for (Case rcrCase : casesToInsert){
                acctToCaseMap.put(rcrCase.AccountId, rcrCase);
            } //for      
            
            list<id> userids = new list<id>();
            list<id> caseids = new list<id>();
       		
            if(Label.ClientRetentionClosedChatter == 'True'){
            	// closed duplicate chatterpost
                for (Case rcCase : casesToInsert){
                    If (rcCase.status == 'Closed - Duplicate'){
                        userids.add(rcCase.OwnerId);
                        String postText = 'Another record for this client has been received, please continue to work with the client to ensure all concerns are addressed.';
                        ChatterMentionPost.createChatterMentionPost(rcCase.Id, userids, new String[]{postText}, true, false);
                    }
                    else{
                        caseids.add(rcCase.Id);
                    }
                    userids.clear();
                } //for
                
                ChatterMentionPost.postBatchFeedElements(); 
                System.debug('getCases after ChatterMentionPost for Closed - Duplicate Cases');
            } // label.ClientRetentionClosedChatter
        } //!casesToInsert.isEmpty
                
    } // getCases
    
    /* Touchpoint is on hold for CRT
    private static void createCARs(Id [] refids) {
        System.debug('createCARs enter');
        Cadence_Assignment_Record__c[] newCars = new Cadence_Assignment_Record__c[]{}; 
        list<Case> foundCases = new list<Case>(); 
        list<Reference_Client_Retention__c> foundRefs = new list<Reference_Client_Retention__c>(); 
    	//query for case fields
        if(!refids.isEmpty()){          
            for(Id refid : refids){
                //foundCases = [Select Id, AccountId, Account.Name, ContactId, OwnerId from Case where Id in :caseids]; 
                foundRefs = [Select Id, Prospect_Client_Name__c, Prospect_Client_Name__r.Name, Prospect_Client_Contact__c, OwnerId, Case__c from Reference_Client_Retention__c where Id in :refids];
                system.debug('createCARs get case fields');
            }
            
            if(!foundRefs.isEmpty()){
                // get list of cadences
            	Cadence__c[] cadences = getCadences();
            	system.debug('createCARs cadences: '+cadences.size());
                // create a CAR for the ref
                for(Reference_Client_Retention__c fRef : foundRefs){
                    // reference client retention record owner has to be a user, not a queue
                    if(fRef.OwnerId != null && ((String)fRef.OwnerId).startsWith('005')){
                    	system.debug('createCARs fRef.Account.Name: '+fRef.Prospect_Client_Name__r.Name);
                    	system.debug('createCARs fRef.Contact.Name : '+fRef.Prospect_Client_Contact__c);
                   		system.debug('createCARs cadences[0].Id: '+cadences[0].Id);
                    	system.debug('createCARs fRef.Case__c: '+fRef.Case__c);
                    	system.debug('createCARs fRef.OwnerId : '+fRef.OwnerId ); 
                        Cadence_Assignment_Record__c newCar = new Cadence_Assignment_Record__c(Name=fRef.Prospect_Client_Name__r.Name, Cadence__c=cadences[0].Id
                                                                 , Status__c='Open', Case_Lookup__c=fRef.Case__c, Cadence_Owner__c=fRef.OwnerId
                                                                 , ContactId__c=fRef.Prospect_Client_Contact__c, TargetObjectId__c=fRef.Id
                                                                 , CadenceObject__c=(fRef.Prospect_Client_Contact__c != null ? fRef.Prospect_Client_Contact__c : fRef.Prospect_Client_Name__c)); 
                        newCars.add(newCar);
                    }
                    else{
                        system.debug('createCARs reference record not owned by user, no CAR created');
                    } //fRef.OwnerId
                } // for
            } // !foundRefs.isEmpty
            
            CadenceHelper.SKIP_TRIGGERS=false;
            DmlHelper.performDML2(newCars, DmlHelper.DML_INSERT, 'ReferenceClientRetentionMethods', 'createCARs', 'Insert new CARs', false);
        	system.debug('createCARs after insert CARs foundCases: '+ foundCases.size() +' newCars: '+ newCars.size());    
            
        } // !caseids.isEmpty    
    } // createCARs
    
    public static Cadence__c[] availCadences = null;
    public static Cadence__c[] getCadences() {
        String[] CRT_Cadence_Names = Label.ClientRetentionCadenceName.split(',');
        if(availCadences == null){
        	availCadences = [Select Id, Name, Cadence_Type__c, TargetType__c From Cadence__c Where Active__c=true and Name in :CRT_Cadence_Names];  
            system.debug('getCadences availCadences: '+availCadences);
        }
        
   		return availCadences;
   	} // getCadences
    */
    
    public static final Integer PROCESS_NOTES_SIZE = Reference_Client_Retention__c.ProcessNotes__c.getDescribe().getLength();
    
    public static String mergeStringsUpToLength(String val1, String val2, Integer maxLength) {
        // edge case
        if ((val1 == null && val2 == null) || (maxLength == null || maxLength <= 0)) {
            return '';
        }
        
        String returnString = '';
        Integer val1Size = val1 != null ? val1.length() : 0;
        Integer val2Size = val2 != null ? val2.length() : 0;
        
        // val 1 takes priority
        if (val1Size > maxLength) {
            returnString += val1.substring(0, maxLength);
            return returnString;
        } else {
            returnString += val1;
        }
        
        // do not truncate val2: 
        // '\n' is counted as 1 characters
        if (val2Size != 0 && (returnString.length() + val2Size <= maxLength + 1) ){
            returnString += '\n' + val2;
        }
        
        return returnString;
    }

    public static void addToNotes(Reference_Client_Retention__c obj, String notesToAdd, Boolean addTimeStamp) {
      system.debug('addToNotes notesToAdd: '+notesToAdd); 
      StringHelper.addNotesToField(obj, 'ProcessNotes__c', PROCESS_NOTES_SIZE, notesToAdd, addTimeStamp);
   } // addToNotes  
}