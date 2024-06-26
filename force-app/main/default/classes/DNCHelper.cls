/* 
   DNC related methods
   
  History
  -------
  05/26/2017 Jermaine Stukes    Created 
  02/05/2018 Jacob Hinds        Adding case status sync
  09/17/2018 Jacob Hinds        commenting out old dnc record sync code, pointing to new queueable job instead.
  01/08/2018 Dan Carmen         Modified to add some more flexibility 
  03/15/2019 Jacob Hinds        adding Comments_and_follow_up__c to case status sync
  06/28/2019 Dan Carmen         Add consent to text logic from the process builders
  01/25/2023 Dan Carmen         Change to TriggerInterfaceC, update API
  01/25/2024 Dan Carmen         Removed an unneeded methods, increment API

 */

public with sharing class DNCHelper implements TriggerInterfaceC {
   // to help with recursion
   public static Boolean DNC_CHECKED=false;
  
   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('DNCHelper', p_recs, oldMap, isBefore, isAfter, null, null);
      System.debug('DNCHelper.handleTrigger recs='+(recs != null ? recs.size() : -1));
      if (recs == null || recs.isEmpty()) {
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      
      if (isBefore) {
         if (objType == Lead.sObjectType) {
            checkLeadsBefore((Lead[])recs, (Map<Id,Lead>)oldMap);
         } else if (objType == Contact.sObjectType) {
            checkContactsBefore((Contact[])recs, (Map<Id,Contact>)oldMap);
         } else if (objType == Account.sObjectType) {
            checkAccountsBefore((Account[])recs, (Map<Id,Account>)oldMap);
         }
      } else if (isAfter) {
         //OBJECTS_RAN_SET.add(objTypeName);
         SObject[] recsToProcess = new SObject[]{};
         // only get the records we haven't already processed
         for (SObject rec : recs) {
            //if (!ALREADY_RAN_SET.contains(rec.Id)) {
               recsToProcess.add(rec);
            //   ALREADY_RAN_SET.add(rec.Id);
            //}
         }
         System.debug('DNCHelper.handleTrigger objTypeName='+TriggerMethods.objectTypeName +' recsToProcess='+recsToProcess.size());
   
         if (!recsToProcess.isEmpty()) {
            if (objType == Lead.sObjectType) {
               checkLeads((Lead[])recs, (Map<Id,Lead>)oldMap);
            } else if (objType == Contact.sObjectType) {
               checkContacts((Contact[])recs, (Map<Id,Contact>)oldMap);
            } else if (objType == Case.sObjectType) {
               
            }
            
         } // if (!recsToProcess.isEmpty
      } // if (recs != null
   } // handleTrigger

   public static void checkLeadsBefore(Lead[] leads, Map<Id,Lead> oldMap) {
      checkConsentBefore(leads,oldMap);
      checkDNCandEmailOpt(leads,oldMap,'DoNotCall', 'Do_Not_Call_Date__c', 'Do_Not_Call_Submitter__c'
                  ,'HasOptedOutOfEmail', 'Email_Opt_Out_Date__c', 'Email_Opt_Out_Submitter__c');
   } // checkLeadsBefore

   public static void checkConsentBefore(SObject[] recs, Map<Id,SObject> oldMap) {
      UserHelper.setRunningUserAttributes();
      System.debug('checkConsentBefore recs='+recs.size()+' oldMap='+(oldMap != null ? oldMap.size() : -1)+' isLeadLoader='+UserHelper.runningUserIsLeadLoader);
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);

         // did the mobile phone field change
         Boolean hasMobile = (rec.get('MobilePhone') != null);
         Boolean mobileChanged = ((rec.get('MobilePhone') != null && oldRec == null) 
                                   || (oldRec != null && rec.get('MobilePhone') != oldRec.get('MobilePhone')));
         // did the consent to text field change?
         Boolean consentToText = (rec.get('Consent_to_Text__c') != null ? (Boolean)rec.get('Consent_to_Text__c') : false);
         Boolean consentToTextPrev = (oldRec != null && oldRec.get('Consent_to_Text__c') != null ? (Boolean)oldRec.get('Consent_to_Text__c') : false);
         System.debug('checkContactsBefore consent new='+consentToText+' consent prev='+consentToTextPrev);
         Boolean consentChanged = ((consentToText && oldRec == null)  || (consentToText != consentToTextPrev));
             //    || (oldRec != null && rec.get('Consent_to_Text__c') != oldRec.get('Consent_to_Text__c')));
         Boolean consentReasonChanged = ((rec.get('Consent_to_Text_reason__c') != null && oldRec == null)
                                           || (oldRec != null && rec.get('Consent_to_Text_reason__c') != oldRec.get('Consent_to_Text_reason__c')));

         System.debug('checkContactsBefore rec='+(String)rec.get('LastName')+' consentToText='+consentToText+' hasMobile='+hasMobile+' mobileChanged='+mobileChanged+' consentChanged='+consentChanged+' consentReasonChanged='+consentReasonChanged);
   
         if (consentToText && mobileChanged && oldRec != null && !consentChanged && !UserHelper.runningUserIsLeadLoader) {
            System.debug('checkConsentBefore changing based on mobileChanged');
            // if the mobile phone itself changes then uncheck consent to text
            // Process Builder: b
            rec.put('Consent_to_Text_Date__c',DateTime.now());
            rec.put('Consent_to_Text_reason__c','Mobile Phone change');
            rec.put('Consent_to_Text__c',false);
         } else if (consentToText && mobileChanged && consentChanged && !UserHelper.runningUserIsLeadLoader) {
            System.debug('checkConsentBefore changing based on mobileChanged and consentChanged');
            // if the mobile phone itself changes with the consent to text being set at the same time
            // Process Builder: c
            rec.put('Consent_to_Text_Date__c',DateTime.now());
            rec.put('Consent_to_Text_reason__c','User change');
         } else if (!UserHelper.runningUserIsLeadLoader && consentChanged && !consentReasonChanged) {
            System.debug('checkConsentBefore user changed consent');
            // if the consent to text changes based on user action
            // Process builder: e
            rec.put('Consent_to_Text_Date__c',DateTime.now());
            rec.put('Consent_to_Text_reason__c','User change');
         } else if (UserHelper.runningUserIsLeadLoader
                          && (consentChanged || (consentToText && (oldRec == null || mobileChanged)))) {
            System.debug('checkConsentBefore web lead changed consent');
            // if the running user is lead loader (& marketo) update the consent to text date  
            // if the consent changes or the consent is set and the mobile changes
            // Process builder: f
            rec.put('Consent_to_Text_Date__c',DateTime.now());
            rec.put('Consent_to_Text_reason__c','Web Lead change');
         }

      } // for (Lead ld : leads
   } // checkConsentBefore

   public static void checkLeads(Lead[] leads, Map<Id,Lead> oldMap) {
      System.debug('checkLeads leads='+leads.size());
      DNCQueueable dncQueue = new DNCQueueable();
      Reference_Do_Not_Contact__c[] newRefDNCs = new Reference_Do_Not_Contact__c[]{};
      for (Lead ld : leads) {
         System.debug('checkLeads ld='+ld.LastName);
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         if ((oldLd == null && !ld.DoNotCall && !ld.HasOptedOutOfEmail && (ld.Phone != null || ld.MobilePhone != null) && ld.Email != null)
                || (oldLd != null && (oldLd.Phone != ld.Phone || oldLd.MobilePhone != ld.MobilePhone) && (oldLd.Email != ld.Email))) {
            dncQueue.addToQueue('checkBoth','Lead/Contact', null, ld.Id, null);
         } else if ((oldLd == null && !ld.DoNotCall &&(ld.Phone != null || ld.MobilePhone != null))
                || (oldLd != null && (oldLd.Phone != ld.Phone || oldLd.MobilePhone != ld.MobilePhone))) {
            dncQueue.addToQueue('checkPhone','Lead/Contact', null, ld.Id, null);
         } else if ((oldLd == null && !ld.HasOptedOutOfEmail && ld.Email != null)
                || (oldLd != null && oldLd.Email != ld.Email)) {
            dncQueue.addToQueue('checkEmail','Lead/Contact', null, ld.Id, null);
         }

         // create a Reference record on changes
         // Process Builder: a,d,g       
         Boolean consentToTextChanged = ((ld.Consent_to_Text__c && oldLd == null) || (oldLd != null && ld.Consent_to_Text__c != oldLd.Consent_to_Text__c));
         Boolean consentReasonChanged = ((String.isNotBlank(ld.Consent_to_Text_reason__c) && oldLd == null)
                                           || (oldLd != null && ld.Consent_to_Text_reason__c != oldLd.Consent_to_Text_reason__c));
         Boolean consentDateChanged = ((ld.Consent_to_Text_Date__c != null && oldLd == null) 
                                           || (oldLd != null && ld.Consent_to_Text_Date__c != oldLd.Consent_to_Text_Date__c));  
         if (consentToTextChanged || consentReasonChanged || consentDateChanged) {
            // create a reference Do Not Contact Request
            logDoNotContactRequest(null,ld, newRefDNCs);
         }
         
      } // for (Lead ld
      DmlHelper.performDML2(newRefDNCs, DmlHelper.DML_INSERT, 'DNCHelper', 'checkLeads', 'Save Reference DNC Requests', true);
      dncQueue.checkLaunchQueuable();
   } // checkLeads
   
   public static void logDoNotContactRequest(Contact ctct, Lead ld, Reference_Do_Not_Contact__c[] newRefDNCs) {
      // make sure we don't exceed the field length
      String recName = (ctct != null ? ctct.FirstName+' '+ctct.LastName : ld.FirstName+' '+ld.LastName).left(80);
      Reference_Do_Not_Contact__c refDNC = new Reference_Do_Not_Contact__c(Name=recName);
      refDNC.Consent_to_Text_Date__c = (ctct != null ? ctct.Consent_to_Text_Date__c : ld.Consent_to_Text_Date__c);
      refDNC.Consent_to_Text_Phone__c = (ctct != null ? ctct.MobilePhone : ld.MobilePhone);
      refDNC.Consent_to_Text_Submitter__c = (ctct != null ? ctct.LastModifiedById : ld.LastModifiedById);
      refDNC.Consent_to_Text__c = (ctct != null ? ctct.Consent_to_Text__c : ld.Consent_to_Text__c);
      refDNC.Consent_to_Text_reason__c = (ctct != null ? ctct.Consent_to_Text_reason__c : ld.Consent_to_Text_reason__c);
      if (ctct != null) {
         refDNC.Contact__c = ctct.Id;
      } else if (ld != null) {
         refDNC.Lead__c = ld.Id;
      }
      newRefDNCs.add(refDNC);
   } // logDoNotContactRequest

   public static void checkAccountsBefore(Account[] accts, Map<Id,Account> oldMap) {
      // TODO - on change of dnc/email out out, update the related contacts
      checkDNCandEmailOpt(accts,oldMap,'Do_Not_Call__c', 'Do_Not_Call_Date__c', 'Do_Not_Call_Submitter__c'
                    ,'Email_Opt_Out__c', 'Email_Opt_Out_Date__c', 'Email_Opt_Out_Submitter__c');
   } // checkAccountsBefore
   
   public static void checkContactsBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
      checkConsentBefore(ctcts,oldMap);
      // TODO - on insert of a contact, see if its related account has dnc/email opt out
      checkDNCandEmailOpt(ctcts,oldMap,'DoNotCall', 'DNC_Date__c', 'DNCSubmitter__c'
                ,'HasOptedOutOfEmail','Email_Opt_Out_Date__c', 'Email_Opt_Out_Submitter__c');
   } // checkContactsBefore
   
   // Account  Do_Not_Call__c, Do_Not_Call_Date__c, Do_Not_Call_Submitter__c
   //          Email_Opt_Out__c, Email_Opt_Out_Date__c, Email_Opt_Out_Submitter__c
   // Lead DoNotCall, Do_Not_Call_Date__c, Do_Not_Call_Submitter__c
   //      HasOptedOutOfEmail, Email_Opt_Out_Date__c, Email_Opt_Out_Submitter__c
   // Contact DoNotCall, DNC_Date__c, DNCSubmitter__c
   //         HasOptedOutOfEmail,Email_Opt_Out_Date__c, Email_Opt_Out_Submitter__c
   public static void checkDNCandEmailOpt(SObject[] recs, Map<Id,SObject> oldMap
                           ,String dncFld, String dncDateFld, String dncSubmitterFld
                           ,String emailOptFld, String emailDateFld, String emailSubmitterFld) {
      User runningUser = UserHelper.getRunningUser();

      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         Boolean dnc = (Boolean)rec.get(dncFld);
         Boolean emailOpt = (Boolean)rec.get(emailOptFld);
         System.debug('checkDNCandEmailOpt dnc='+dnc+' emailOpt='+emailOpt);
         if (dnc && (oldRec == null || (rec.get(dncFld) != oldRec.get(dncFld)))) {
            // if the Do Not Call is set
            // Workflows capture DNC Date & Submitter, Acct: capture DNC Date & Submitter, Capture DNC Date & Submitter
            rec.put(dncDateFld,Date.today());
            rec.put(dncSubmitterFld,runningUser.Name.left(80)); // make sure the name isn't too long
         }
         if (emailOpt && (oldRec == null || (rec.get(emailOptFld) != oldRec.get(emailOptFld)))) {
            // if the email opt out is set
            // Workflows: Capture Email Opt-Out Date & Submitter, Acct: capture EmailOptOut Date & Submitter,  • Capture Email Opt-Out Date & Submitter
            rec.put(emailDateFld,Date.today());
            rec.put(emailSubmitterFld,runningUser.Name.left(80)); // make sure the name isn't too long
         }
      } // for (SObject rec : recs
   } // checkDNCandEmailOpt
   
   public static void checkContacts(Contact[] ctcts, Map<Id,Contact> oldMap) {
      System.debug('checkLeads ctcts='+ctcts.size());
      DNCQueueable dncQueue = new DNCQueueable();
      Reference_Do_Not_Contact__c[] newRefDNCs = new Reference_Do_Not_Contact__c[]{};
      for (Contact ctct : ctcts) {
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         if ((oldCtct == null && !ctct.DoNotCall && !ctct.HasOptedOutOfEmail && (ctct.Phone != null || ctct.MobilePhone != null || ctct.OtherPhone != null) && ctct.Email != null)
                || (oldCtct != null && (oldCtct.Phone != ctct.Phone || oldCtct.MobilePhone != ctct.MobilePhone || oldCtct.OtherPhone != ctct.OtherPhone) 
                            && (oldCtct.Email != ctct.Email))) {
            dncQueue.addToQueue('checkBoth','Lead/Contact', null, ctct.Id, null);
         } else if ((oldCtct == null && !ctct.DoNotCall &&(ctct.Phone != null || ctct.MobilePhone != null || ctct.OtherPhone != null))
                || (oldCtct != null && (oldCtct.Phone != ctct.Phone || oldCtct.MobilePhone != ctct.MobilePhone || oldCtct.OtherPhone != ctct.OtherPhone))) {
            dncQueue.addToQueue('checkPhone','Lead/Contact', null, ctct.Id, null);
         } else if ((oldCtct == null && !ctct.HasOptedOutOfEmail && ctct.Email != null)
                || (oldCtct != null && oldCtct.Email != ctct.Email)) {
            dncQueue.addToQueue('checkEmail','Lead/Contact', null, ctct.Id, null);
         }
         
         // create a Reference record on changes
         // Process Builder: a,d,g       
         Boolean consentToTextChanged = ((ctct.Consent_to_Text__c && oldCtct == null) || (oldCtct != null && ctct.Consent_to_Text__c != oldCtct.Consent_to_Text__c));
         Boolean consentReasonChanged = ((String.isNotBlank(ctct.Consent_to_Text_reason__c) && oldCtct == null)
                                           || (oldCtct != null && ctct.Consent_to_Text_reason__c != oldCtct.Consent_to_Text_reason__c));
         Boolean consentDateChanged = ((ctct.Consent_to_Text_Date__c != null && oldCtct == null) 
                                           || (oldCtct != null && ctct.Consent_to_Text_Date__c != oldCtct.Consent_to_Text_Date__c));  
         if (consentToTextChanged || consentReasonChanged || consentDateChanged) {
            // create a reference Do Not Contact Request
            logDoNotContactRequest(ctct, null, newRefDNCs);
         }
      } // for (Contact ctct
      DmlHelper.performDML2(newRefDNCs, DmlHelper.DML_INSERT, 'DNCHelper', 'checkContacts', 'Save Reference DNC Requests', true);
      dncQueue.checkLaunchQueuable();
   } // checkContacts
   
    //used to prevent test classes from breaking.  skip the step to uncheck records if no matches are found
    public static Boolean skipUncheck = true;
    
    public static final Set<String> DNCSubjects = new Set<String>{'Do Not Contact Request Form','FW: Do Not Contact Request Form','Do Not Call Request - Contact','Email Opt-Out Request'};

    public static Boolean isDNCsubject(String subj)
    {   
        if(subj !=null && subj.contains('Do Not Contact Request for'))
        {
            subj = 'Do Not Contact Request Form';
        }
        return (subj !=null && DNCSubjects.contains(subj));
    } //isDNCSubject   
    /*
    //DNC Request started from case
    public static void CreateCaseDNCRecords(List<Id> caseIdList)
    {
      
        // call batch from here, not in trigger
        Apex_Batch_Control__c apexCS = Apex_Batch_Control__c.getInstance('CaseDNCBatch');
        if ((caseIdList.size() > CaseDNCBatch.BATCH_SIZE)||(apexCS != NULL && apexCS.Active__c))
        {  Id acID = [SELECT Id FROM ApexClass WHERE NamespacePrefix = null AND Name = 'CaseDNCBatch' Limit 1].Id;//'01p70000000TntUAAS'
          boolean jobScheduled = FALSE;
          //check if there are 5 active batch jobs
          list<AsyncApexJob> asyncJobList = [SELECT ApexClassID
                             FROM AsyncApexJob 
                            WHERE JobType='BatchApex' 
                            AND (Status = 'Processing' 
                            OR Status = 'Preparing'
                            OR Status = 'Queued')];
      if(!asyncJobList.isEmpty()){
        For(AsyncApexJob a: asyncJobList){
          if (a.ApexClassId == acId){
            jobScheduled = TRUE;
          }   
        }
      }
      If(!jobScheduled){
        if (asyncJobList.size() < 5){//5 is maximum nuber of concurrent batch job limit.
              CaseDNCBatch kaseBatch = new CaseDNCBatch();
                kaseBatch.caseIdList = new List<Id>();          
                kaseBatch.caseIdList.addAll(caseIdList);           
                ID kaseBatchID = Database.executeBatch(kaseBatch);     
        }
      }                      
        }
        else
        {
            List<Case> casesToProcess = [select Id,description from Case where Id in :caseIdList]; 
            ProcessDNCCases(casesToProcess);
        }
        //List of DNC cases to be processed
       



    }//CreateCaseDNCRecords*/
    
   //Process Cases
   public static void ProcessDNCCases(List<Case> casesDNC) {
      System.debug('ProcessDNCCases casesDNC='+casesDNC.size());
      List<Case> casesToProcess = new List<Case>();
      List<Reference_Do_Not_Contact__c> dncList = new List<Reference_Do_Not_Contact__c>();
      for (Case kase: casesDNC) {   
         Reference_Do_Not_Contact__c caseDoNotContact = new Reference_Do_Not_Contact__c();
         ID caseId;
         boolean dncTelephone;
         boolean dncEmail;    
         String submitter;
         String dncComments;
         string temp_Phone;
         string branchNum;
         string clientNum;
         string branchClientNum;
         string dncName;
         Boolean entirecompany = false;
            if (!(kase.description.length() == 0 || kase.description == null))
            {   
                string descrip = kase.description.replaceAll('\n', '<br>');
                descrip += '<br>';
                // do this for Prospects and Clients
                caseDoNotContact.CaseID__c = kase.Id;
                caseDoNotContact.CaseSubmittedRequest__c = true;
                //Grab DNC Types
                
                if (descrip.indexOfIgnoreCase('entirecompany') > 0)
                {   entirecompany = (findInput(descrip,'entirecompany: ') == 'True' ? true : false); } 
                if (descrip.indexOfIgnoreCase('comments') > 0)
                {   caseDoNotContact.comments__c = findInput(descrip,'comments: '); } 
                
                if(entirecompany)
                {
                    if (descrip.indexOfIgnoreCase('donotcall') > 0)
                    {   
                        string dncCallValue = findInput(descrip, 'donotcall: ');
                        caseDoNotContact.Do_Not_Call_Client_Level__c = (dncCallValue == 'Do Not Call' ? true : false); 
                        dncTelephone = (dncCallValue == 'Do Not Call' ? true : false); 
                    }
                    if (descrip.indexOfIgnoreCase('emailoptout') > 0)
                    {   
                        string dncEmailValue = findInput(descrip, 'emailoptout: ');
                        caseDoNotContact.Email_Opt_Out_Client_Level__c = (dncEmailValue == 'Email Opt-out\\Unsubscribe' ? true : false); 
                        dncEmail = (dncEmailValue == 'Email Opt-out\\Unsubscribe' ? true : false); 
                    }
                }
                else
                {
                    if (descrip.indexOfIgnoreCase('donotcall') > 0)
                    {   
                        string dncCallValue = findInput(descrip, 'donotcall: ');
                        caseDoNotContact.Do_Not_Call_Contact_Level__c = (dncCallValue == 'Do Not Call' ? true : false); 
                        dncTelephone = (dncCallValue == 'Do Not Call' ? true : false); 
                    }
                    if (descrip.indexOfIgnoreCase('emailoptout') > 0)
                    {   
                        string dncEmailValue = findInput(descrip, 'emailoptout: ');
                        caseDoNotContact.Email_Opt_Out_Contact_Level__c = (dncEmailValue == 'Email Opt-out\\Unsubscribe' ? true : false); 
                        dncEmail = (dncEmailValue == 'Email Opt-out\\Unsubscribe' ? true : false); 
                    }
                }
                if (descrip.indexOfIgnoreCase('phone') > 0)
                { temp_Phone = findInput(descrip, 'phone: ');    }
                if (temp_Phone != null)   
                {   caseDoNotContact.Contact_Phone__c = Utilities.removeExtraChars(temp_Phone, '0123456789'); }               
                if (descrip.indexOfIgnoreCase('email') > 0)
                {   caseDoNotContact.Contact_Email__c = findInput(descrip,'email: '); }
                if (descrip.indexOfIgnoreCase('submitter') > 0)
                {   caseDoNotContact.Requestor__c = findInput(descrip,'submitter: ');    }
                if (descrip.indexOfIgnoreCase('branchnum') > 0)
                {   branchNum = findInput(descrip,'branchnum: ');    }
                if (descrip.indexOfIgnoreCase('clientnum') > 0)
                {   
                    clientNum = findInput(descrip,'clientnum: ');    
                    clientNum = Utilities.removeExtraChars(clientNum,'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ');
                }
                if ((branchNum != null && branchNum.length() > 0) || (clientNum != null && clientNum.length() > 0))
                {   
                    branchClientNum = mergeBranchClient(branchNum, clientNum);   
                    branchClientNum = branchClientNum.removeStart('0');
                    caseDoNotContact.Branch_Client_Num__c = branchClientNum;
                }   
                if(dncTelephone && dncEmail)
                {
                    caseDoNotContact.Do_Not_Email__c = true;
                    caseDoNotContact.Do_Not_Call__c = true;
                    dncName = 'Do Not Call/Email Opt Out Requested';
                }
                else if(dncTelephone && !dncEmail)
                {
                    caseDoNotContact.Do_Not_Call__c = true;
                    dncName = 'Do Not Call Requested';
                }
                else if(!dncTelephone && dncEmail)
                {
                    dncName = 'Email Opt Out Requested';
                    caseDoNotContact.Do_Not_Email__c = true;
                }
                caseDoNotContact.Name = dncName;
                System.debug('ProcessDNCCases caseDoNotContact='+caseDoNotContact);
                dncList.add(caseDoNotContact);
            }
            //casesParsed.add(dncWrap); // prospect or client
        } // for kase
        
        System.debug('ProcessDNCCases dncList='+dncList.size());
        if(!dncList.isEmpty())
        {insert dncList;}
    } // ProcessDNCCases
    
    /* find value in case description and trim it */
    private static String findInput (String descrp, String parameter)
    {   
        String ans;             
        if (descrp.indexOfIgnoreCase(parameter) > -1)
        {   ans = descrp.substringBetween(parameter, '<br>');         
         if (ans != Null && ans.length() > 0 )
         {   ans = ans.trim();   }
        }       
        return ans;
    } // findInput
    
    // concatenate branchno and clientno for accountnumber
    private static String mergeBranchClient(String branch, String client) 
    {   String brclno = '';
     if (branch != null && branch.length() > 0)
     {   brclno = Utilities.removeLeadingZero(branch);   }
     brclno = (brclno.length() == 0 ? client : brclno + '-' + client);      
     brclno = brclno.trim();
     brclno = brclno.toUpperCase();
     return brclno;
    } //mergeBranchClient  
/*

    /* create Case comment for Client or Prospect dnc case  */
    private static Casecomment createComment (Id caseId, Contact ct, Boolean flagDNC, Boolean flagEOO)
    {   
        Casecomment comment = new Casecomment();
        comment.ParentId = caseId;
        comment.CommentBody = '';
        
        if (!flagDNC && !flagEOO)
        {   comment.CommentBody = '\rContact Not Updated';   }
        if (flagDNC)
        {   comment.CommentBody = comment.CommentBody + '\rDo Not Call set';    }
        if (flagEOO)
        {   comment.CommentBody = comment.CommentBody + '\rEmail Opt Out set';  }
        comment.CommentBody = comment.CommentBody + '\rContact name - ' + ct.Name;
        comment.CommentBody = comment.CommentBody + '\rContact id - ' + ct.Id;
        return comment;     
    } // createComment
    
   public static void handleDNC(List<Id>caseIds){
      System.debug('handleDNC caseIds='+caseIds.size());
      //store case ids in lists to do different things with them based on what is filled on the case
      Case[] leadContactCall = new Case[]{};
      //Id[] accountCall = new Id[]{};
      //Id[] refCtctsCall = new Id[]{};
      //Id[] refAcctsCall = new Id[]{};
      Case[] leadContactEmail = new Case[]{};
      Case[] leadContactText = new Case[]{};
      Case[] cases = [SELECT Sub_Type__c,AccountId,Referral_Contact__c,Referral_Account__c,Expiration_Date__c,
              Lead__c,Lead__r.FirstName,Lead__r.LastName,Lead__r.Phone,Lead__r.MobilePhone,Lead__r.Email,
              ContactId,Contact.FirstName,Contact.LastName,Contact.Phone,Contact.MobilePhone,Contact.OtherPhone,Contact.Email
              FROM Case WHERE Id in:caseIds];
      Map<String,Date> expirationByPhone = new Map<String,Date>();
      DNCQueueable dncJob = new DNCQueueable();
      for (Case c: cases){
         if(c.Sub_Type__c == 'Do Not Call'){
            if(c.Lead__c!=null || c.ContactId!=null){
               leadContactCall.add(c);
            } else if(c.AccountId!=null){
               if(c.Expiration_Date__c != null){
                  expirationByPhone.put(c.AccountId,c.Expiration_Date__c);
               }
               //accountCall.add(c.AccountId);
               dncJob.addToQueue('Call','Account', null, c.AccountId, expirationByPhone);
            }/*
          else if(c.Referral_Contact__c!=null){
            refCtctsCall.add(c.Referral_Contact__c);
          }
          else if(c.Referral_Account__c!=null){
            refAcctsCall.add(c.Referral_Account__c);
          }*/
         }//if Do Not Call
         else if(c.Sub_Type__c == 'Email Opt Out'){
            if(c.Lead__c!=null && c.Lead__r.Email!=null){
               leadContactEmail.add(c);
            } else if(c.ContactId!=null && c.Contact.Email!=null){
               leadContactEmail.add(c);
            }
         }//else if Email Opt Out
         else if(c.Sub_Type__c == 'Text Opt Out'){
            if(c.Lead__c!=null || c.ContactId!=null){
               leadContactText.add(c);
            }
         }//else if Text Opt Out
      }//for(case c
      
      if(!leadContactCall.isEmpty()){
         system.debug('handleDNC leadContactCall: '+leadContactCall.size());
         setLeadContactDNC(dncJob, leadContactCall,'Call');
      }
      //if(!accountCall.isEmpty()){
      //  system.debug('handleDNC accountCall: '+accountCall);
        //CHANGE ME
      //  DNCQueueable dncJob = new DNCQueueable('Call','Account',null,accountCall,expirationByPhone);
      //    ID jobID = System.enqueueJob(dncJob);
      //}
      /* TO DO, Ref Contact + Ref Account Do Not Call
      if(!refCtctsCall.isEmpty()){
        system.debug('handleDNC refCtctsCall: '+refCtctsCall);
      }
      if(!refAcctsCall.isEmpty()){
        system.debug('handleDNC refAcctsCall: '+refAcctsCall);
        DNCQueueable dncJob = new DNCQueueable('Call','Referral Account',null,refAcctsCall);
          ID jobID = System.enqueueJob(dncJob);
      }*/
      if(!leadContactText.isEmpty()){
        system.debug('handleDNC leadContactText: '+leadContactText.size());
        setLeadContactDNC(dncJob, leadContactText,'Text');
      }
      if(!leadContactEmail.isEmpty()){
        system.debug('handleDNC leadContactEmail: '+leadContactEmail.size());
        setLeadContactDNC(dncJob, leadContactEmail,'Email');
      }

      dncJob.checkLaunchQueuable();
    }//handleDNC
    
    public static void setLeadContactDNC(DNCQueueable dncJob, List<Case>cases,String operation){
      //store a set of phones to find
      Set<String> phoneNumbers = new Set<String>();
      Set<String> emails = new Set<String>();
      Map<String,Date> expirationByPhone = new Map<String,Date>();
      system.debug('setLeadContactDoNotCall cases: '+cases+' operation: '+operation);
      for(Case c: cases){
        if(operation=='Call' || operation =='Text'){
          if(c.Lead__c != null && String.IsNotBlank(c.Lead__r.Phone)){
            phoneNumbers.add(c.Lead__r.Phone);
            if(operation == 'Call' && c.Expiration_Date__c != null){
              expirationByPhone.put(c.Lead__r.Phone,c.Expiration_Date__c);
            }
          }
          if(c.Lead__c != null && String.IsNotBlank(c.Lead__r.MobilePhone)){
            phoneNumbers.add(c.Lead__r.MobilePhone);
            if(operation == 'Call' && c.Expiration_Date__c != null){
              expirationByPhone.put(c.Lead__r.MobilePhone,c.Expiration_Date__c);
            }
          }
          if(c.ContactId != null && String.IsNotBlank(c.Contact.Phone)){
            phoneNumbers.add(c.Contact.Phone);
            if(operation == 'Call' && c.Expiration_Date__c != null){
              expirationByPhone.put(c.Contact.Phone,c.Expiration_Date__c);
            }
          }
          if(c.ContactId != null && String.IsNotBlank(c.Contact.MobilePhone)){
            phoneNumbers.add(c.Contact.MobilePhone);
            if(operation == 'Call' && c.Expiration_Date__c != null){
              expirationByPhone.put(c.Contact.MobilePhone,c.Expiration_Date__c);
            }
          }
          if(c.ContactId != null && String.IsNotBlank(c.Contact.OtherPhone)){
            phoneNumbers.add(c.Contact.OtherPhone);
            if(operation == 'Call' && c.Expiration_Date__c != null){
              expirationByPhone.put(c.Contact.OtherPhone,c.Expiration_Date__c);
            }
          }
        }//call or text
        else if(operation=='Email'){
          if(c.Lead__c != null && String.IsNotBlank(c.Lead__r.Email)){
            emails.add(c.Lead__r.Email);
          }
          if(c.ContactId != null && String.IsNotBlank(c.Contact.Email)){
            emails.add(c.Contact.Email);
          }
        }
        
      }//for(Case c
      system.debug('setLeadContactDoNotCall Phone Numbers to Search: '+phoneNumbers);
      system.debug('setLeadContactDoNotCall expirationByPhone: '+expirationByPhone);
      system.debug('setLeadContactDoNotCall emails: '+emails);
      //build strings to use in sosl of all the phone numbers+emails found
      string phoneSearchString = buildSearchString(phoneNumbers);
      string emailSearchString = buildSearchString(emails);
        
      if(!String.isBlank(phoneSearchString)){
         // addToQueue(String p_operation, String p_objectType, string p_searchString, Id p_searchId, Map<String,Date>p_expirationByPhoneMap)
         dncJob.addToQueue(operation,'Lead/Contact',phoneSearchString,null,expirationByPhone);
         //    ID jobID = System.enqueueJob(dncJob);
         system.debug('setLeadContactDoNotCall queueing job with phone search string: '+phoneSearchString);
      }
      if(!String.isBlank(emailSearchString)){
         system.debug('setLeadContactDoNotCall queueing job with email search string: '+emailSearchString);
         dncJob.addToQueue(operation,'Lead/Contact',emailSearchString,null,expirationByPhone);
      }
    
   } //setLeadContactDNC
    
   public static void handleDNCSharepointContactLevel(List<Reference_Do_Not_Contact__c>refs,String operation){
      System.debug('handleDNCSharepointContactLevel refs='+refs.size()+' operation='+operation);
      //store a set of phones to find
      Set<String> phoneNumbers = new Set<String>();
      Set<String> emails = new Set<String>();
      for(Reference_Do_Not_Contact__c ref: refs){
         if(operation=='Call' || operation =='Both'){
            if(String.IsNotBlank(ref.Contact_Phone__c)){
               phoneNumbers.add(ref.Contact_Phone__c);
            }
         }//call or both
         if(operation=='Email' || operation =='Both'){
            if(String.IsNotBlank(ref.Contact_Email__c)){
               emails.add(ref.Contact_Email__c);
            }
         }
      } //for(Reference_Do_Not_Contact__c ref
      system.debug('handleDNCSharepoint Phone Numbers to Search: '+phoneNumbers+' Emails to Search: '+emails);
      //build strings to use in sosl of all the phone numbers+emails found
      string phoneSearchString = buildSearchString(phoneNumbers);
      string emailSearchString = buildSearchString(emails);
    
      DNCQueueable dncJob = new DNCQueueable();

      if (String.isNotBlank(phoneSearchString)){
         dncJob.addToQueue('Call','Lead/Contact',phoneSearchString,null,null);
         //    ID jobID = System.enqueueJob(dncJob);
         system.debug('handleDNCSharepointContactLevel queueing job with phone search string: '+phoneSearchString);
      }
      if (String.isNotBlank(emailSearchString)){
         dncJob.addToQueue('Email','Lead/Contact',emailSearchString,null,null);
         //    ID jobID = System.enqueueJob(dncJob);
         system.debug('handleDNCSharepointContactLevel queueing job with email search string: '+emailSearchString);
      }
      dncJob.checkLaunchQueuable();
   } // handleDNCSharepointContactLevel
    
   public static void handleDNCSharepointClientLevel(Map<String,String>operationByCltNbr){
      
      System.debug('handleDNCSharepointClientLevel operationByCltNbr='+operationByCltNbr);

      DNCQueueable dncJob = new DNCQueueable();

      for(Account acct:[SELECT Id,AccountNumber FROM Account WHERE AccountNumber in:operationByCltNbr.keySet()]){
         System.debug('handleDNCSharepointClientLevel acct='+acct);
         String operation = operationByCltNbr.get(acct.AccountNumber);
         if(operation!=null && operation == 'Call'){
           System.debug('handleDNCSharepointClientLevel operation call');
           dncJob.addToQueue('Call','Account',null,acct.Id,null);
         }
        else if(operation!=null && operation == 'Email'){
           System.debug('handleDNCSharepointClientLevel operation email');
           dncJob.addToQueue('Email','Account',null,acct.Id,null);
        }
        else if(operation!=null && operation == 'Both'){
           System.debug('handleDNCSharepointClientLevel operation both');
           dncJob.addToQueue('Call','Account',null,acct.Id,null);
           dncJob.addToQueue('Email','Account',null,acct.Id,null);
        }
      } // for(Account acct
      dncJob.checkLaunchQueuable();
      
   } // handleDNCSharepointClientLevel
    
   public static String buildSearchString(Set<String> stringList){
      String searchString='';
      for(String str : stringList){
         if(String.isBlank(searchString)){
            searchString = '("'+str+'")';
         } else{
            searchString += ' OR ("'+str+'")';
         }  
      }//for(String phoneNumber
      return searchString;
   } // buildSearchString
    
} // class DNCHelper