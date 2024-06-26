/* 
   Methods for working with the onboarding/registration component

   
  History
  -------
  06/01/2022 Harish Lanka      Created
  07/21/2022 Dan Carmen        Capture exception in getTracking
  08/01/2022 Jermaine Stukes   Add DSM and Previous Payroll
  08/30/2022 Jermaine Stukes   Add PACO Feed field
  10/19/2022 Jermaine Stukes   Add attachment logic and add Opportunity to OppPathWrapper
  10/25/2022 Dan Carmen        Additional CSO/Enterprise changes
  11/03/2022 Dan Carmen        Add Contact FlexUEID to the query
  12/14/2022 Dan Carmen        Update dsm emailAddress to email
  02/15/2023 Bindu Madhavi     Add ManagerId to the query
  06/12/2023 Dan Carmen        Remove space in formatAddress
  08/30/2023 Dan Carmen        Add debugging
  11/03/2023 Dan Carmen        Changes for PO Box
  12/15/2023 Dan Carmen        Update existing child trackers to link to parent
  01/22/2024 Dan Carmen        Fix query for tracker to make sure we're getting the children.

*/
public class EZOnboardingRegistration {
    public static final String CLASSNAME='EZOnboardingRegistration';
    
    // used to return the information needed for the opportunityPath component
    public class OppPathWrapper {
        @AuraEnabled public CSO_Tracking__c tracker;
        @AuraEnabled public Onboarding_Tool__c onboarding;
        @AuraEnabled public Account acct;
        @AuraEnabled public Opportunity opp;
        @AuraEnabled public List<Contact> ctcts = new List<Contact>();
        @AuraEnabled public String currentUserId;
        @AuraEnabled public Boolean alwaysShowNewClientBtn=false;
        @AuraEnabled public Boolean hasPrimaryQuote=false;
        @AuraEnabled public Boolean docusignComplete=false;
        @AuraEnabled public Boolean ezComplete=false;
        @AuraEnabled public Boolean oppStageIsWon=false;
        @AuraEnabled public Boolean oppStageIsSold=false;
        @AuraEnabled public Boolean oppStageIsSoldSubmitted=false;
        @AuraEnabled public Boolean signedQuoteRequired=Boolean.valueOf(Label.CSO_Signed_Quote_Required); 
        // is the opp the user entered from the tracker opportunity?
        @AuraEnabled public Boolean isPrimaryOpp=false;
        @AuraEnabled public String primaryQuoteName=null;
        @AuraEnabled public List<QuoteInfo> otherQuotes=new List<QuoteInfo>();
        @AuraEnabled public Boolean csoUser=false;
        @AuraEnabled public Boolean newBillUser=false;
        // the primary quote is a subscription quote
        @AuraEnabled public Boolean quoteIsNewBill=false;
        // does the primary quote say that the subscription was created?
        @AuraEnabled public Boolean subscriptionCreated=false;
        // the name of the package selected on the primary quote (if any)
        @AuraEnabled public String packageName=null;
        @AuraEnabled public String otherProducts=null;
        @AuraEnabled public OppPathWrapper[] childWraps = new OppPathWrapper[]{};
        public Set<Id> childAcctIds = new Set<Id>();
        // the product codes that are relative to the CTT form that are on the quote
        @AuraEnabled public String[] salesSubProds = new String[]{};
        // is the SST form required for the user to fill out? Don't think we'll need this in the component but sending it just in case.
        @AuraEnabled public Boolean sstRequired=true;
        @AuraEnabled public Boolean sstAvailable=false;
        // if the SST form is not required, but they can optionally use it. 
        @AuraEnabled public Boolean showCTTBtn=showCttButton;
        
        @AuraEnabled public Boolean clientRegistered=false;
        @AuraEnabled public Boolean canUpdateClient=false;
    } // class OppPathWrapper
    
    public class QuoteInfo {
       @AuraEnabled public Id quoteId;
       @AuraEnabled public String quoteName;
    } // class QuoteInfo
    
    public static String[] alwaysShowProfs = Label.EZOnboarding_AlwaysShowSetupNewClient.split(',');
    // if we're showing the button, CTT is optional. If we're not showing it, we're going to default CTT (SST) to true on the opp.
    public static Boolean showCttButton = (Label.EZOnboarding_ShowCttBtn == 'True');
    
    // recordId is the Opportunity Id
    @AuraEnabled
    public static OppPathWrapper getRegInfo(String recordId) {
       // get the information to confirm for an enterprise client registration
       OppPathWrapper wrap = new OppPathWrapper();
       wrap.currentUserId = Userinfo.getUserId();
       // get the tracker and the children information (if multi-id)
       if (String.isNotBlank(recordId)) {
          User runningUser = UserHelper.getRunningUser();
          wrap.alwaysShowNewClientBtn = (alwaysShowProfs.contains('All') 
                                            || (runningUser != null && runningUser.Profile != null && alwaysShowProfs.contains(runningUser.Profile.Name)));
          Boolean updateTracker = false;
          wrap.tracker = getTracking(recordId);
          if (wrap.tracker == null) {
             // create a new tracker - need to have a record here in order to set fields in the next method.
             wrap.tracker = new CSO_Tracking__c();
          } else {
             wrap.acct = wrap.tracker.AccountId__r;
          }
          updateTracker = (getOpportunity(recordId, wrap) || updateTracker);
          if (wrap.tracker.Id == null) {
             wrap.acct = wrap.opp.Account;
             // if this is a new record
             Integer trackerNameSize = CSO_Tracking__c.Name.getDescribe().getLength();
             wrap.tracker.Name = wrap.opp.Name.left(trackerNameSize);
             wrap.tracker.AccountId__c = wrap.opp.AccountId;
             wrap.tracker.Opportunity__c = wrap.opp.Id;
             insert wrap.tracker;
             Onboarding_Tool__c newOnboardingRec = CsoMethods.createOnboarding(wrap.tracker);
             insert newOnboardingRec;
             wrap.tracker.Onboarding_Tool__c = newOnboardingRec.Id;
             wrap.tracker.RegistrationStartedBy__c=UserInfo.getUserId();
             updateTracker = true;
          }
          String acctId = wrap.opp.AccountId;
          String quoteId = (wrap.opp != null ? wrap.opp.Primary_Oracle_Quote__c : null);
          Integer childIds = wrap.childAcctIds.size();
          System.debug('getRegInfo quoteId='+quoteId+' childAcctIds='+wrap.childAcctIds.size());
          if (wrap.tracker.IsParentTracker__c != !wrap.childAcctIds.isEmpty()
             || wrap.tracker.NumberOfIds__c != childIds) {
             wrap.tracker.IsParentTracker__c = !wrap.childAcctIds.isEmpty();
             wrap.tracker.NumberOfIds__c = childIds;
             updateTracker=true;
          }
          if (quoteId != null && !wrap.childAcctIds.isEmpty()) {
             String childActQuery = CsoMethods.getQuery(CsoMethods.QUERY_ACCT_MULTI_QUOTE);
             Account[] childAccts = Database.query(childActQuery);
             System.debug('getRegInfo childAccts='+childAccts.size());
             if (!childAccts.isEmpty()) {
                String[] validTypes = getValidChildTypes();
                CSO_Tracking__c[] newTrackers = new CSO_Tracking__c[]{};
                Map<Id,CSO_Tracking__c> updateTrackers = new Map<Id,CSO_Tracking__c>();
                for (Account childAcct : childAccts) {
                   // make sure each child has a tracker
                   CSO_Tracking__c childTracker = null;
                   if (childAcct.CSO_Recs__r.isEmpty()) {
                      // create a new one
                      // default the parent account to the main account, knowing it might change
                      childTracker = new CSO_Tracking__c(AccountId__c=childAcct.Id, Name=childAcct.Name, ParentAccount__c=acctId, ParentTracker__c=wrap.tracker.Id
                                                        ,Environment__c=wrap.tracker.Environment__c, IsOppCso__c=wrap.tracker.IsOppCso__c
                                                        ,IsOppEnterprise__c=wrap.tracker.IsOppEnterprise__c, HasSubscriptionQuote__c=wrap.tracker.HasSubscriptionQuote__c
                                                        ,ProcessNotes__c='Created By getRegInfo');
                      if (!childAcct.Account_Junctions__r.isEmpty() && validTypes.contains(childAcct.Account_Junctions__r[0].Type__c)) {
                         // default the type based on the relationship
                         childTracker.ChildType__c = childAcct.Account_Junctions__r[0].Type__c;
                      }
                      newTrackers.add(childTracker);
                   } else {
                      childTracker = childAcct.CSO_Recs__r[0];
                      // check to make sure it's linked to the parent
                      if (childTracker.ParentAccount__c!=acctId || childTracker.ParentTracker__c!=wrap.tracker.Id || String.isBlank(childTracker.ChildType__c)) {
                         childTracker.ParentAccount__c=acctId;
                         childTracker.ParentTracker__c=wrap.tracker.Id;
                         if (String.isBlank(childTracker.ChildType__c) && !childAcct.Account_Junctions__r.isEmpty() 
                                  && validTypes.contains(childAcct.Account_Junctions__r[0].Type__c)) {
                            childTracker.ChildType__c = childAcct.Account_Junctions__r[0].Type__c;
                         }
                         updateTrackers.put(childTracker.Id, childTracker);
                      }
                   }
                   OppPathWrapper childWrap = new OppPathWrapper();
                   childWrap.tracker = childTracker;
                   childWrap.acct = childAcct;
                   wrap.childWraps.add(childWrap);
                } // for (Account childAcct : childAccts
                 
                if (!newTrackers.isEmpty()) {
                   DmlHelper.performDML2(newTrackers, DmlHelper.DML_INSERT, CLASSNAME, 'getRegInfo', 'Inserting new trackers', true);
                }
                if (!updateTrackers.isEmpty()) {
                   DmlHelper.performDML2(updateTrackers.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'getRegInfo', 'Update trackers', true);
                }
             } // if (!childAccts.isEmpty()
          } // if (quoteId != null
          if (updateTracker) {
             CsoMethods.SKIP_TRIGGERS = true;
             update wrap.tracker;
          }
       } // if (String.isNotBlank(recordId
       
       return wrap;
    } // getRegInfo
    
    @AuraEnabled
    public static OppPathWrapper getOppPathInfo(String recordId) {
       // get the information needed for the opportunityPath component
       OppPathWrapper wrap = new OppPathWrapper();
       wrap.currentUserId = Userinfo.getUserId();
       Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('CsoQueueable');
       Boolean updateTracker = false;
       if(!abc.Active__c){
            wrap.tracker.Opportunity_Eligible__c = false;
            wrap.tracker.OpportunityEligibilityDetail__c = 'Easy Setup Registration is Currently Unavailable. Please Submit via PACO';
            updateTracker = true;
       } else {
          User runningUser = UserHelper.getRunningUser();
          wrap.alwaysShowNewClientBtn = (alwaysShowProfs.contains('All') 
                                            || (runningUser != null && runningUser.Profile != null && alwaysShowProfs.contains(runningUser.Profile.Name)));
          // check for which path the user has permissions
          CsoMethods.checkUserPerms();
          wrap.csoUser = CsoMethods.v_runUserHasPermCso;
          wrap.newBillUser = CsoMethods.v_runUserHasPermEnt;
        
          System.debug('getOppPathInfo recordId='+recordId);
          if (String.isNotBlank(recordId)) {
             wrap.tracker = getTracking(recordId);
             Boolean isCso =  (wrap.tracker.CanUseCSO__c || wrap.tracker.IsOppCso__c);
             System.debug('getOppPathInfo isCso='+isCso);
             if (isCso) {
                // don't change the approver if an exception is already in progress or complete
                if (String.isBlank(wrap.tracker.ExceptionStatus__c)) {
                   updateTracker = (checkExceptionAllowed(wrap.tracker, runningUser) || updateTracker);
                   // set the approver on the tracker record - if the running user is a sales rep
                   updateTracker = (checkApprovers(wrap.tracker, runningUser) || updateTracker);
                }
             }

             wrap.ctcts = getContact(recordId);
             updateTracker = (getOpportunity(recordId, wrap) || updateTracker);
             //checkPrimaryQuote(recordId, wrap);
             wrap.oppStageIsSoldSubmitted = (wrap.opp != null && wrap.opp.Probability >= 90);
             wrap.oppStageIsSold = (!wrap.oppStageIsSoldSubmitted && wrap.opp != null && wrap.opp.Probability >= 80);
             wrap.oppStageIsWon = (!wrap.oppStageIsSoldSubmitted && !wrap.oppStageIsSold && wrap.opp != null && wrap.opp.Probability >= 70);
             wrap.ezComplete = (wrap.oppStageIsWon && wrap.docusignComplete);
             wrap.isPrimaryOpp = (recordId == wrap.tracker.Opportunity__c);
          } // if (String.isNotBlank
          System.debug('getOppPathInfo hasPrimaryQuote='+wrap.hasPrimaryQuote+' docusignComplete='+wrap.docusignComplete+' oppStageIsWon='+wrap.oppStageIsWon+' ezComplete='+wrap.ezComplete);
          System.debug('getOppPathInfo oppStageIsSoldSubmitted='+wrap.oppStageIsSoldSubmitted+' oppStageIsSold='+wrap.oppStageIsSold);
          // this is to handle if the subscription gets started directly out of CPQ (or some other means we don't currently know about)
          if (wrap.opp != null && wrap.tracker != null && wrap.subscriptionCreated) {
             // clear errors if they exist
             if (wrap.tracker.CPQKeysStatusCode__c == '050') {
                wrap.tracker.CPQKeysStatusCode__c = null;
                wrap.tracker.CPQKeysDetail__c = null;
                updateTracker = true;
             }
             if (wrap.tracker.CPQSubStatusCode__c != '200') {
                wrap.tracker.CPQSubStatusCode__c = '200';
                updateTracker = true;
             }
          } // if (wrap.opp != null && wrap.subscriptionCreated

          // start checking when it's registered. Stop checking when the subscription starts
         // if (wrap.tracker.RegistrationStarted__c && wrap.opp != null && wrap.opp.Primary_Oracle_Quote__r != null && wrap.opp.Primary_Oracle_Quote__r.IsSubscriptionQuote__c
         //           && wrap.tracker.CPQSubStatusCode__c != '200' && wrap.opp.Probability >= CsoMethods.probSoldSubmit) {
         //    checkCPQRequired(wrap.tracker,null);
         // }

       } // if(!abc.Active__c
       if (updateTracker) {
          CsoMethods.SKIP_TRIGGERS=true;
          update wrap.tracker;
       }
       return wrap;
    } // getOppPathInfo
    
    public static Boolean checkApprovers(CSO_Tracking__c tracker, User usr) {
       Boolean updateTracker = false;
       // set the approver on the tracker record - if the running user is a sales rep
       Id exceptionApproverId = null;
       Id exceptionApprover2Id = null;
       if ((tracker.CanUseCSO__c || tracker.IsOppCso__c) && usr != null && usr.Job_Name__c==UserHelper.JOB_REP) {
          if (usr.ManagerId != null && usr.Manager.ManagerId != null && usr.Manager.Manager.IsActive) {
             exceptionApproverId = usr.Manager.Manager.Id;
          }
          if (usr.ManagerId != null && usr.Manager.ManagerId != null && usr.Manager.Manager.EasySetupDelegate__c != null) {
             exceptionApprover2Id = usr.Manager.Manager.EasySetupDelegate__c;
          }
          // make sure that if there is an approver, the first one is always filled out.
          // So if the zone manager is not active but the delegated is, the delegated would be in the first approver position
          if (exceptionApproverId == null && exceptionApprover2Id != null) {
             exceptionApproverId = exceptionApprover2Id;
             exceptionApprover2Id = null;
          }
       }
       System.debug('checkApprovers exceptionApprover2Id='+exceptionApprover2Id+' exceptionApprover2Id='+exceptionApprover2Id);
       if (tracker.ExceptionApprover__c != exceptionApproverId || tracker.ExceptionApprover2__c != exceptionApprover2Id) {
          tracker.ExceptionApprover__c = exceptionApproverId;
          tracker.ExceptionApprover2__c = exceptionApprover2Id;
          updateTracker=true;
       }
       return updateTracker;
    } // checkApprovers
    
    public static Boolean checkExceptionAllowed(CSO_Tracking__c tracker, User usr) {
       Boolean changed = false;
       Boolean exceptionAllowed = false;
       Boolean needsApproval = false;
       if (usr != null && tracker != null && String.isNotBlank(tracker.Product_Bundle__c)) {
          System.debug('checkExceptionAllowed Product_Bundle__c='+tracker.Product_Bundle__c);
          for (CsoExceptionSetup__c ces : CsoExceptionSetup__c.getAll().values()) {
             if (ces.Active__c && tracker.Product_Bundle__c == ces.ProductBundle__c) {
                Boolean salesOrgOkay = (String.isBlank(ces.SalesOrgs__c) || (ces.SalesOrgs__c.contains(usr.Sales_Org__c)));
                Boolean salesDivOkay = (String.isBlank(ces.SalesDivisions__c) || (ces.SalesDivisions__c.contains(usr.Sales_Division__c)));
                Boolean zoneOkay = (String.isBlank(ces.SalesDivisions__c) || (ces.SalesDivisions__c.contains(usr.Sales_Division__c)));
                System.debug('checkExceptionAllowed salesOrgOkay='+salesOrgOkay+' salesDivOkay='+salesDivOkay+' zoneOkay='+zoneOkay);
                exceptionAllowed = (salesOrgOkay && salesDivOkay && zoneOkay);
                if (exceptionAllowed) {
                   needsApproval = ces.ApprovalProcess__c;
                   break;
                }
             }
          }
       } // if (usr != null && tracker != null
       if (tracker != null && (tracker.ExceptionAllowed__c != exceptionAllowed || tracker.ExceptionNeedApproval__c != needsApproval)) {
          tracker.ExceptionAllowed__c = exceptionAllowed;
          tracker.ExceptionNeedApproval__c = needsApproval;
          changed = true;
       }
       System.debug('checkExceptionAllowed exceptionAllowed='+exceptionAllowed+' needsApproval='+needsApproval+' changed='+changed);
       return changed;
    } // checkExceptionAllowed
    
    public static Boolean checkContains(String listValue, String checkValue) {
       String[] checkVals = (String.isBlank(listValue) ? new String[]{} : listValue.split(','));
       return (checkVals.isEmpty() || (String.isNotBlank(checkValue) && checkVals.contains(checkValue)));
    } // checkContains
    
    @AuraEnabled
    public static CSO_Tracking__c getTracking(string recordId){
        System.debug('getTracking recordId='+recordId);
        CSO_Tracking__c csTracking = null;
        if (String.isNotBlank(recordId)) {
            Opportunity[] opps = [Select Id, ClientTracking__c from Opportunity where Id=:recordId];
            try {
               Id oppId = (Id)recordId;
               Id[] queryIds = new Id[]{oppId};
               if (!opps.isEmpty()) {
                  // should only be one record
                  queryIds.add(opps[0].ClientTracking__c);
               }
               String query = CsoMethods.getQuery(CsoMethods.QUERY_CSO);
               //query += ' WHERE (Id in :queryIds or Opportunity__c in :queryIds or ParentTracker__r.Opportunity__c in :queryIds) order by CreatedDate desc';
               // if querying by opportunity id, the opp should be tied to the parent tracker, so make sure we're not pulling a child tracker.
               query += ' WHERE (Id in :queryIds or (Opportunity__c in :queryIds and ParentTracker__c = null) or (ParentTracker__r.Opportunity__c in :queryIds)) order by CreatedDate desc';
               CSO_Tracking__c[] trackers = Database.query(query);
               System.debug('getTracking queryIds='+queryIds.size()+' trackers='+trackers.size());
               String[] childErrors = new String[]{};
               for (CSO_Tracking__c tracker : trackers) {
                  if (queryIds.contains(tracker.Id) || (queryIds.contains(tracker.Opportunity__c) && tracker.ParentTracker__c==null)) {
                     // this is the main tracker
                     csTracking = tracker;
                  } else if (tracker.ParentTracker__c != null && queryIds.contains(tracker.ParentTracker__r.Opportunity__c)) {
                     // this is a child tracker
                     // check for registration errors
                     if (String.isNotBlank(tracker.RegistrationStatusCode__c) && tracker.RegistrationStatusCode__c != '200' && String.isNotBlank(tracker.RegistrationDetail__c)) {
                        childErrors.add(tracker.Name+': '+tracker.RegistrationDetail__c);
                     } else if (String.isNotBlank(tracker.OSSKeysStatusCode__c) && tracker.OSSKeysStatusCode__c != '200' && String.isNotBlank(tracker.OSSKeysDetail__c)) {
                        childErrors.add(tracker.Name+': '+tracker.OSSKeysDetail__c);
                     }
                  }
               }
               System.debug('getTracking csTracking='+(csTracking != null)+' childErrors='+childErrors.size());
               csTracking.ChildErrors__c = (!childErrors.isEmpty() ? String.join(childErrors,', ' ) : null);
            } catch (Exception e) {
               System.debug('getTracking exception: '+e.getMessage()+'; '+e.getStackTraceString());
            } // try
        } // if (String.isNotBlank(recordId
        return csTracking;
    } // getTracking
    
    @AuraEnabled
    public static void removeFile(String fileId){
        
        String attachmentType = fileId.startsWith('00P') ? 'Attachment' : 'File';
        if(attachmentType == 'Attachment'){
            Attachment uploadedAttachment = [Select Id from Attachment where Id=:fileId];
            delete uploadedAttachment;
        }else{
            ContentDocument uploadedFile = [Select Id from ContentDocument where Id=:fileId];
            delete uploadedFile;
        }
    }
    @AuraEnabled
    public static void updateUploadedAttId(CSO_Tracking__c tracker, String attType, String attId){
        if(attType == 'quote'){
            tracker.AttachedQuoteId__c = attId;
        }else{
            tracker.AttachedCertificateId__c = attId;
        }
        update tracker;
    }
    @AuraEnabled
    public static ContentVersion retrieveFile(String fileId){
        ContentVersion uploadedFile = [Select Id,ContentDocumentId,FileType,Title,VersionData from ContentVersion where ContentDocumentId=:fileId];
        
        return uploadedFile;
    }
    @AuraEnabled
    public static String saveQuoteAttachment(CSO_Tracking__c cso, String recordId, String fileName, String base64Data, String contentType, String attachType) {
        string attachmentId ='';
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        Attachment attc = new Attachment();
        attc.parentId = recordId;
        attc.Body = EncodingUtil.base64Decode(base64Data);
        attc.Name = fileName;
        attc.ContentType = contentType;
        insert attc;
        system.debug('QUOTE ID: '+attc.Id);
        attachmentId= attc.Id;
        if(attachType == 'Quote'){
            cso.AttachedQuoteId__c = attc.Id;
        }else{
            cso.AttachedCertificateId__c = attc.Id;
        }
        update cso;
        return attachmentId;
    }
    
    /*@AuraEnabled
    public static String updateUploadContent(CSO_Tracking__c cso,Opportunity oppty, String updateType, String fileId, String fileName){
        
        ContentVersion uploadedFile = [Select Id, VersionData, FileExtension from ContentVersion where ContentDocumentId =: fileId];
        String attachmentName = oppty.Primary_Oracle_Quote__r.Name+'_'+ fileName+'_Completed.'+uploadedFile.FileExtension;
        //String decode = EncodingUtil.
        String decodedBody = EncodingUtil.Base64Encode(uploadedFile.VersionData);//EncodingUtil.urlDecode(uploadedFile.VersionData, 'UTF-8');
        attachmentName = attachmentName.replaceFirst('.'+uploadedFile.FileExtension, '');
        Attachment attc = new Attachment();
        attc.parentId = oppty.Id;
        attc.Body = EncodingUtil.base64Decode(decodedBody);
        attc.Name = updateType == 'Signed Quote' ? attachmentName.replace('_Completed_Completed', '_Completed') : fileName;
        attc.ContentType = uploadedFile.FileExtension;
        insert attc;
        cso.SignedQuoteId__c = attc.Id;

        return attc.Id;
        
    }*/
    
    // TODO
    @AuraEnabled
    public static String setException(CSO_Tracking__c cso) {
       return 'Success';
    } // setException
    
    @AuraEnabled
    public static void removeException(CSO_Tracking__c cso){
        if (cso != null) {
            try {
                cso.CsoExceptionList__c = null;
                cso.CsoExceptionDetail__c = null;
                cso.CsoException__c = false;
                cso.ExceptionStatus__c = null;
                cso.ExceptionAcceptRejectDescipt__c = null;
                cso.ExceptionRequestUser__c = null;
                cso.ExceptionNeedApproval__c = false;
                cso.Account_Eligible__c = true;
                cso.Opportunity_Eligible__c = true;
                update cso;
            } catch (Exception e) {
                System.debug('removeException exception: '+e.getMessage());
            }
        } // if (cso != null
    } // removeException 
    
    // the statuses on the quote that indicate the subscription started. Overrides everything on the tracker. 
    public static String[] subCreated = Label.ClientReg_SubscriptCreated.split(',');
    // the sales orgs and parts in the role that are able to use the SST form. 
    public static String[] sstSalesOrgs = Label.ClientReg_SST_SalesOrg.split(',');
    public static String[] sstRoles = Label.ClientReg_SST_Role.split(',');
    // if the owner is one of these profiles they can use the SST form. This is separate from role and profile
    public static String[] sstProfiles = Label.ClientReg_SST_Profile.split(',');
    
    @AuraEnabled
    public static Boolean getOpportunity(string recordId, OppPathWrapper pathWrap){
        Boolean trackerUpdated = false;
        String docusignUser ='DocuSign API User';
        Opportunity opp = [SELECT Id, AccountId, Account.Id, Account.Name, Account.Paychex_CAID__c, Account.CurrentClient__c
                                 ,CloseDate,Employees_Paid_Per_Payroll__c,Frequency__c,Handbook_Contact__c,LeadSource,Multi_ID_Client__c,LeverageSST__c,Name,NonEnglishPaperwork__c,Probability,Promotion__c,Returning_Lost_Client__c
                                 ,OwnerId, Owner.ManagerId, Owner.Manager.Person_ID_Number__c, Owner.Manager.Name, Owner.Manager.Email
                                 ,Owner.Sales_Org__c, Owner.UserRole.Name, Owner.Profile.Name
                                 ,Service_Location__c, StageName
                                 ,Payroll_Current_Prior_Method__c,Primary_Oracle_Quote__c,Primary_Oracle_Quote__r.Name, Primary_Oracle_Quote__r.IsSubscriptionQuote__c
                                 ,Primary_Oracle_Quote__r.Status__c
                                 ,(SELECT Id,Name,ParentId,CreatedById, CreatedBy.Name FROM Attachments)
                                 ,(Select ContentDocument.Id, ContentDocument.Title, ContentDocument.ContentSize from ContentDocumentLinks),ClientRegistrationTestMode__c 
                              FROM Opportunity WHERE Id =:recordId];
        pathWrap.opp = opp;
        pathWrap.primaryQuoteName = (opp.Primary_Oracle_Quote__c != null ? opp.Primary_Oracle_Quote__r.Name : null);
        pathWrap.quoteIsNewBill = (opp.Primary_Oracle_Quote__c != null ? opp.Primary_Oracle_Quote__r.IsSubscriptionQuote__c : false);
        pathWrap.subscriptionCreated = (opp.Primary_Oracle_Quote__c != null && opp.Primary_Oracle_Quote__r.IsSubscriptionQuote__c && String.isNotBlank(opp.Primary_Oracle_Quote__r.Status__c)
                                          && subCreated.contains(opp.Primary_Oracle_Quote__r.Status__c));
        pathWrap.clientRegistered=String.isNotBlank(opp.Account.Paychex_CAID__c);
        pathWrap.canUpdateClient=opp.Account.CurrentClient__c == false;
        
        System.debug('getOpportunity recordId='+recordId+' ClientRegistrationTestMode__c='+opp.ClientRegistrationTestMode__c+' QUOTE_CREATED_BY='+QUOTE_CREATED_BY+' TEST_PRIMARY_QUOTE='+TEST_PRIMARY_QUOTE+' TEST_QUOTE_SIGNED='+TEST_QUOTE_SIGNED);
        System.debug('getOpportunity quoteIsNewBill='+pathWrap.quoteIsNewBill);
        Boolean testMode = opp.ClientRegistrationTestMode__c;
        pathWrap.hasPrimaryQuote = (opp.Primary_Oracle_Quote__c!=null || (opp.ClientRegistrationTestMode__c && TEST_PRIMARY_QUOTE));
        
        // is the opp owner able to use the SST form?
        // check to see if we're opening it up to all.
        Boolean useSST = ((sstSalesOrgs.contains('ALL') && sstRoles.contains('ALL')) || (sstProfiles.contains('ALL')));
        if (!useSST && opp != null && opp.Owner != null) {
           useSST = (opp.Owner.Profile != null && sstProfiles.contains(opp.Owner.Profile.Name));
           if (!useSST && String.isNotBlank(opp.Owner.Sales_Org__c) && sstSalesOrgs.contains(opp.Owner.Sales_Org__c) && opp.Owner.UserRole != null) {
              for (String roleCheck : sstRoles) {
                 if (opp.Owner.UserRole.Name.contains(roleCheck)) {
                    useSST=true;
                    break;
                 }
              }
           }
        } // if (!useSST
        System.debug('getOpportunity useSST='+useSST);
        pathWrap.sstAvailable = useSST;
        
        if (pathWrap.hasPrimaryQuote) {
            // see if it's a signed quote
            Id quoteUserId = getQuoteUserId();
            //User[] checkUsers = [Select Id, Name from User Where IsActive=true and Name=:QUOTE_CREATED_BY limit 1];
            //User checkUser = (!checkUsers.isEmpty() ? checkUsers[0] : null);
            System.debug('getOpportunity quoteName='+opp.Primary_Oracle_Quote__r.Name);
            //List<Attachment> listOfAttachment = new List<Attachment>([SELECT Id,Name,ParentId,CreatedById, CreatedBy.Name FROM Attachment Where ParentId=:recordId]);
            for(Attachment atta : opp.Attachments){
                Boolean startsWithQuote = atta.Name.startsWithIgnoreCase(opp.Primary_Oracle_Quote__r.Name);
                //Boolean createdByOkay = ((checkUser != null && checkUser.Id == atta.CreatedById) || atta.CreatedBy.Name == QUOTE_CREATED_BY);
                Boolean createdByOkay = (quoteUserId != null && quoteUserId == atta.CreatedById);
                Boolean isCompleted = (atta.Name.containsIgnoreCase('Completed'));
                system.debug('getPrimaryQuote attach='+atta.Name+' startsWithQuote='+startsWithQuote+' createdByOkay='+createdByOkay+' isCompleted='+isCompleted+' quoteUserId='+quoteUserId+' CreatedById='+atta.CreatedById+' createdby='+atta.CreatedBy.Name);
//                if(atta.Name.startsWithIgnoreCase(opp.Primary_Oracle_Quote__r.Name) && atta.CreatedBy.Name == QUOTE_CREATED_BY && atta.Name.containsIgnoreCase('Completed')){
                if(startsWithQuote && createdByOkay && isCompleted){
                   system.debug('getPrimaryQuote atta.Name'+atta.Name+' meets attachment criteria');
                   pathWrap.docusignComplete = true;
                   break;
                }
            } // for(Attachment atta : listOfAttachment   
            // for testing purposes
            if (!pathWrap.docusignComplete && opp.ClientRegistrationTestMode__c && TEST_QUOTE_SIGNED) {
               pathWrap.docusignComplete = true;
            }
        } // if(!primaryFound && opp.Primary_Oracle_Quote__c!=null
        
        String[] prodNames = new String[]{};
        // get products and any other quotes
        Map<Id, cafsl__Oracle_Quote__c> quoteMap = CsoMethods.getQuotes(new Id[]{recordId});
        /*
        cafsl__Oracle_Quote__c[] quotes = [Select Id, Name, IsSubscriptionQuote__c
                                                 ,(Select Id, cafsl__Product__r.Name, Prospect_Client__c
                                                         ,cafsl__Product__r.CSO_Required__c
                                                         ,cafsl__Product__r.CSO_Eligible__c, cafsl__Product__r.CSOOnly__c, cafsl__Product__r.UseSST__c
                                                         ,cafsl__Product__r.Is_Package__c
                                                         ,cafsl__Product__r.DoNotDisplay__c
                                                         ,cafsl__Product__r.ProductCode
                                                         ,TestPackage__c, TestProductName__c
                                                     From cafsl__Oracle_Quote_Line_Items1__r)
                                             From cafsl__Oracle_Quote__c
                                            Where cafsl__Opportunity__c = :recordId];
        */
        Boolean hasSubscriptionQuote = false;
        Boolean primaryIsSubscription = false;
        String primaryBundleName = null;
        String[] csoOnlyProds = new String[]{};
        Boolean sstRequired=false;
        Boolean sstOptional=showCttButton;

        for (cafsl__Oracle_Quote__c quote : quoteMap.values()) {
            hasSubscriptionQuote = (hasSubscriptionQuote || quote.IsSubscriptionQuote__c);
            if (quote.Id == opp.Primary_Oracle_Quote__c) {
               primaryIsSubscription = quote.IsSubscriptionQuote__c;
               for (cafsl__Oracle_Quote_Line_Item__c item : quote.cafsl__Oracle_Quote_Line_Items1__r) {
                  // is this line item for the parent opportuntiy?
                  if (item.Prospect_Client__c == opp.AccountId) {
                     String prodName = (String.isNotBlank(item.TestProductName__c) ? item.TestProductName__c 
                                          : (item.cafsl__Product__c != null ? item.cafsl__Product__r.Name : 'Product'+prodNames.size()+1));
                     Boolean isPackage = ((item.cafsl__Product__c != null && item.cafsl__Product__r.Is_Package__c) || item.TestPackage__c);
                     sstRequired = (sstRequired || (String.isNotBlank(item.cafsl__Product__r.UseSST__c) && item.cafsl__Product__r.UseSST__c == 'Required'));
                     sstOptional = (sstOptional || (String.isNotBlank(item.cafsl__Product__r.UseSST__c) && item.cafsl__Product__r.UseSST__c == 'Optional'));
                     System.debug('getOpportunity prodName='+prodName+' isPackage='+isPackage+' sstRequired='+sstRequired+' sstOptional='+sstOptional);
                     if (isPackage) {
                        pathWrap.packageName = prodName;
                        primaryBundleName = prodName;
                        //if (pathWrap.tracker.Product_Bundle__c != prodName) {
                        //   pathWrap.tracker.Product_Bundle__c = prodName;
                        //   trackerUpdated = true;
                        //}
                     } else if (!item.cafsl__Product__r.DoNotDisplay__c) {
                        prodNames.add(prodName);
                     }
                     if (item.cafsl__Product__r.CSOOnly__c) {
                        csoOnlyProds.add(prodName);
                     }
                  } else if (item.Prospect_Client__c != null) {
                     pathWrap.childAcctIds.add(item.Prospect_Client__c);
                  }
                  if (!item.cafsl__Product__r.DoNotDisplay__c) {
                     pathWrap.salesSubProds.add(item.cafsl__Product__r.ProductCode);
                  }
               } // for (cafsl__Oracle_Quote_Line_Item__c item
            } else {
               QuoteInfo qi = new QuoteInfo();
               qi.quoteName=quote.Name;
               qi.quoteId=quote.Id;
               pathWrap.otherQuotes.add(qi);
            } // if (quote.Id !=
        } // for (cafsl__Oracle_Quote__c quote
        pathWrap.sstRequired = sstRequired;
        // only show the button if it's optional and available to the user
        pathWrap.showCTTBtn = (!sstRequired && sstOptional && pathWrap.sstAvailable);
        Boolean leverageSSTValue = (sstRequired);
        if (opp != null && opp.Primary_Oracle_Quote__r.IsSubscriptionQuote__c 
               && ((sstRequired && opp.LeverageSST__c == false)
                    || (!sstRequired && !pathWrap.sstAvailable && opp.LeverageSST__c == true))) {
           // set this so it's passed into the component.
           opp.LeverageSST__c = sstRequired;
           Opportunity updateOpp = new Opportunity(Id=opp.Id, LeverageSST__c=sstRequired);
           OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
           update updateOpp;
        }
        pathWrap.otherProducts = String.join(prodNames,', ');
        if ((pathWrap.tracker.HasSubscriptionQuote__c != hasSubscriptionQuote)
            || (String.isNotBlank(primaryBundleName) && pathWrap.tracker.Product_Bundle__c != primaryBundleName)) {
           pathWrap.tracker.HasSubscriptionQuote__c = hasSubscriptionQuote;
           pathWrap.tracker.Product_Bundle__c = primaryBundleName;
           trackerUpdated = true;
        }
        if (checkCsoOnlyProds(pathWrap.tracker, csoOnlyProds)) {
           trackerUpdated = true;
        }
        System.debug('getOpportunity primaryQuoteName='+pathWrap.primaryQuoteName+' quoteMap='+quoteMap.size()+' otherQuotes='+pathWrap.otherQuotes.size()+' otherProducts='+pathWrap.otherProducts+' trackerUpdated='+trackerUpdated+' primaryBundleName='+primaryBundleName+' Product_Bundle__c='+pathWrap.tracker.Product_Bundle__c);
        return trackerUpdated;
    } // getOpportunity
    
    @AuraEnabled
    public static String updateSSTOption(Id oppId, Boolean curValue) {
       System.debug('updateSSTOption oppId='+oppId+' curValue='+curValue);
       if (oppId != null) {
          Opportunity opp = new Opportunity(Id=oppId, LeverageSST__c=!curValue, SkipTriggers__c=true);
          update opp;
       }
       return 'SUCCESS';
    } // changeSST
    
    public static Boolean checkCsoOnlyProds(CSO_Tracking__c tracker, String[] p_csoOnlyProds) {
       Boolean changed = false;
       String csoOnlyProds = (!p_csoOnlyProds.isEmpty() ? String.join(p_csoOnlyProds,', ') : null);
       System.debug('checkCsoOnlyProds csoOnlyProds='+csoOnlyProds);
       if (tracker.CSOOnlyProds__c != csoOnlyProds) {
           if (csoOnlyProds != null) {
              Schema.DescribeFieldResult dfr = CSO_Tracking__c.CSOOnlyProds__c.getDescribe();
              Integer fldLength = Integer.valueOf(dfr.getLength());
              tracker.CSOOnlyProds__c = csoOnlyProds.left(fldLength); 
           } else {
              tracker.CSOOnlyProds__c = null;
           }
           changed = true;
        }
       return changed;
    } // checkCsoOnlyProds
    
    @AuraEnabled
    public static ResponseWrapper updateAccount(string recordId, String fedId){
        ResponseWrapper res = new ResponseWrapper();
        res.statusCode = 200;
        if (String.isNotBlank(fedId)) {
           if (!Pattern.matches('[0-9]{2}-[0-9]{7}', fedId)) {
              if (fedId.length() >= 9) {
                 fedId = fedId.substring(0,2)+'-'+fedId.substring(2);
              }
           }
           //String fedOk = StringHelper.validateTin(fedId, StringHelper.FEIN);
           //if (String.isNotBlank(fedOk)) {
           //   res.statusCode = 400;
           //   res.message = fedOk;
           //}
        } // if (String.isNotBlank
        Account acc = new Account();
        acc.Id = recordId;
        
        acc.Federal_ID_Number__c = fedId;
        ZipCheckOwner.SKIP_TRIGGERS=true;
        CsoMethods.SKIP_TRIGGERS=true;
        Update acc;
        System.debug('updateAccount res='+res);
        return res;
    } // updateOppAndAccount
    
    @AuraEnabled
    public static void updateOppAndAccount(string recordId,Opportunity oppObject, String street, String city, String postalCode,string country, String State, String updateAccount){
        Update oppObject;
        if(updateAccount == 'No') {
            Account acc = new Account();
            acc.Id = recordId;
            acc.ShippingStreet = street;
            acc.ShippingState = state;
            acc.ShippingCity = city;
            acc.ShippingPostalCode = postalCode;
            acc.ShippingCountry = country;
            ZipCheckOwner.SKIP_TRIGGERS=true;
            Update acc;
        } // if(updateAccount == 'No')
    } // updateOppAndAccount
    
    // TODO - is this allowed, or does this have to be updated on the Oracle CPQ side?
    @AuraEnabled
    public static void setPrimaryQuote(Id trackerId, Id oppId, Id quoteId) {
       System.debug('setPrimaryQuote trackerId='+trackerId+' oppId='+oppId+' quoteId='+quoteId);
       // get the opp and current quote
       Opportunity opp = [Select Id, Name, Primary_Oracle_Quote__c
                                ,Primary_Oracle_Quote__r.Id, Primary_Oracle_Quote__r.IsSubscriptionQuote__c
                                ,Primary_Oracle_Quote__r.cafsl__Syncing__c
                            From Opportunity
                           Where Id=:oppId];
       cafsl__Oracle_Quote__c quoteToMove = [Select Id, IsSubscriptionQuote__c, cafsl__Syncing__c
                                               From cafsl__Oracle_Quote__c
                                              Where Id=:quoteId];
       cafsl__Oracle_Quote__c quote1 = opp.Primary_Oracle_Quote__r;
       quote1.cafsl__Syncing__c = false;
       update quote1;
       quoteToMove.cafsl__Syncing__c = true;
       update quoteToMove;
       opp.Primary_Oracle_Quote__c = quoteToMove.Id;
       update opp;
    } // setPrimaryQuote
    
    public static String QUOTE_CREATED_BY='DocuSign API User';
    
    public static String CACHE_KEY='EZOnboardingRegistrationQuoteUserId';
    
    public static Id getQuoteUserId() {
       Id quoteUserId = (Id)CacheManager.getOrg(CACHE_KEY);
       if (quoteUserId == null) {
           User[] checkUsers = [Select Id, Name from User Where IsActive=true and Name=:QUOTE_CREATED_BY limit 1];
           User checkUser = (!checkUsers.isEmpty() ? checkUsers[0] : null);
           quoteUserId = checkUser != null ? checkUser.Id : null;
           if (quoteUserId != null) {
              CacheManager.putOrg(CACHE_KEY,quoteUserId);
           }
       } // if (quoteUserId == null
       return quoteUserId;
    } // getQuoteUserId
    
    public static Boolean TEST_PRIMARY_QUOTE=true;
    public static Boolean TEST_QUOTE_SIGNED=true;
    
   /* @AuraEnabled
    public static void checkPrimaryQuote(string recordId, OppPathWrapper pathWrap) {
        Opportunity opp = [SELECT Id,Primary_Oracle_Quote__c,Primary_Oracle_Quote__r.Name,Probability,ClientRegistrationTestMode__c FROM Opportunity WHERE Id =:recordId];
        System.debug('getPrimaryQuote recordId'+recordId+' ClientRegistrationTestMode__c='+opp.ClientRegistrationTestMode__c+' QUOTE_CREATED_BY='+QUOTE_CREATED_BY+' TEST_PRIMARY_QUOTE='+TEST_PRIMARY_QUOTE+' TEST_QUOTE_SIGNED='+TEST_QUOTE_SIGNED);
        Boolean testMode = opp.ClientRegistrationTestMode__c;
        pathWrap.hasPrimaryQuote = (opp.Primary_Oracle_Quote__c!=null || (opp.ClientRegistrationTestMode__c && TEST_PRIMARY_QUOTE));

        if (pathWrap.hasPrimaryQuote) {
            // see if it's a signed quote
            Id quoteUserId = getQuoteUserId();
            //User[] checkUsers = [Select Id, Name from User Where IsActive=true and Name=:QUOTE_CREATED_BY limit 1];
            //User checkUser = (!checkUsers.isEmpty() ? checkUsers[0] : null);
            System.debug('getPrimaryQuote quoteName='+opp.Primary_Oracle_Quote__r.Name);
            List<Attachment> listOfAttachment = new List<Attachment>([SELECT Id,Name,ParentId,CreatedById, CreatedBy.Name FROM Attachment Where ParentId=:recordId]);
            for (Attachment atta : listOfAttachment) {
                Boolean startsWithQuote = atta.Name.startsWithIgnoreCase(opp.Primary_Oracle_Quote__r.Name);
                //Boolean createdByOkay = ((checkUser != null && checkUser.Id == atta.CreatedById) || atta.CreatedBy.Name == QUOTE_CREATED_BY);
                Boolean createdByOkay = (quoteUserId != null && quoteUserId == atta.CreatedById);
                Boolean isCompleted = (atta.Name.containsIgnoreCase('Completed'));
                system.debug('getPrimaryQuote attach='+atta.Name+' startsWithQuote='+startsWithQuote+' createdByOkay='+createdByOkay+' isCompleted='+isCompleted+' quoteUserId='+quoteUserId+' CreatedById='+atta.CreatedById+' createdby='+atta.CreatedBy.Name);
//                if(atta.Name.startsWithIgnoreCase(opp.Primary_Oracle_Quote__r.Name) && atta.CreatedBy.Name == QUOTE_CREATED_BY && atta.Name.containsIgnoreCase('Completed')){
                if(startsWithQuote && createdByOkay && isCompleted){
                   system.debug('getPrimaryQuote atta.Name'+atta.Name+' meets attachment criteria');
                   pathWrap.docusignComplete = true;
                   break;
                }
            } // for(Attachment atta : listOfAttachment   
            // for testing purposes
            if (!pathWrap.docusignComplete && opp.ClientRegistrationTestMode__c && TEST_QUOTE_SIGNED) {
               pathWrap.docusignComplete = true;
            }
        } // if(!primaryFound && opp.Primary_Oracle_Quote__c!=null
    } // checkPrimaryQuote*/
    
    @AuraEnabled
    public static String getCurrentUserId(){
        String currentUserId = Userinfo.getUserId();
        return currentUserId;
    } // getCurrentUserId
    
    @AuraEnabled 
    public static List<Contact> getContact(String recordId){
        Opportunity oppObject = [SELECT ID,AccountId From Opportunity Where Id =:recordId ];
        Return [SELECT Id,FirstName,LastName,Email,MobilePhone,Phone,Name,AccountId From Contact Where AccountId =: oppObject.AccountId];
    } // getContact
    
    @AuraEnabled 
    public static Account getAccountData(String recordId){
        String acctQuery = CsoMethods.getQuery(CsoMethods.QUERY_ACCT);
        String acctId = recordId;
        acctQuery += ' Where Id = :acctId';
        Account[] accts = Database.query(acctQuery);
        Account acc = (!accts.isEmpty() ? accts[0] : null);
        return acc;
    } // getAccountData
    
    /** Not sure if this one is used
    @AuraEnabled 
    public static Account getAccount(String recordId){
        Account acc = [SELECT ID,LegalAddress__Street__s,LegalAddress__City__s,LegalAddress__StateCode__s,LegalAddress__PostalCode__s,LegalAddress__CountryCode__s,DBA__c,Name,NumberOfEmployees,Source_of_Business__c,ShippingCity,ShippingState,ShippingPostalCode,ShippingStreet,ShippingCountry,Federal_ID_Number__c,Legal_Name__c,Paychex_CEID__c,Paychex_CAID__c,AccountNumber From Account Where Id =:recordId ];
        Return acc;
    }
    */
    @AuraEnabled 
    public static void updateContact(String recordId, String email, String mobile){
        Contact con = new Contact();
        con.Id = recordId;
        con.Email = email;
        con.MobilePhone = mobile;
        // skip the triggers if we're only updating this basic info
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        Update con;
    } // updateContact

    @AuraEnabled 
    public static ResponseWrapper updateCSO(CSO_Tracking__c cso, String ssn,String isssn, String multiId, String paperwork, String client, String extraction ){
        ResponseWrapper res = new ResponseWrapper();
        res.statusCode = 200;

        system.debug('extraction'+extraction);
        isssn = isssn.remove('Please select');
        multiId = multiId.remove('Please select');
        paperwork = paperwork.remove('Please select');
        client = client.remove('Please select');
        extraction = extraction.remove('Please select');
        
        //CSO_Tracking__c cso = [SELECT ID FROM CSO_Tracking__c WHERE Opportunity__c =:recordId];
        cso.Is_this_a_SSN_Number__c = isssn;
        cso.SSN_Number__c = ssn;
        if (String.isNotBlank(cso.SSN_Number__c)) {
           String ssnResult = StringHelper.validateTin(cso.SSN_Number__c, StringHelper.SSN);
           if (String.isNotBlank(ssnResult)) {
              res.statusCode = 400;
              res.message = ssnResult;
           }
        } // if (String.isNotBlank
        cso.Data_Extraction_Needed__c = extraction;
        cso.Returning_Lost_Client__c = client;
        cso.Client_Require_Non_English_Paperwork__c = paperwork;
        cso.Part_of_a_Multi_ID_Affiliated_ID_s__c = multiId;
        Update cso;
        return res;
    } // updateCSO
    
    public static String REG_CSO='CSO_Registration';
    public static String REG_ENT='Enterprise Registration';
    public static String OSS_KEYS='OSS Keys';
    public static String CPQ_KEYS='CPQ Account Ids';
    public static String CPQ_SUB='CPQ Subscription';
    // https://wiki.paychex.com/pages/viewpage.action?pageId=1365848242#CSOCORDGWSVCEndpoints-ClientRegistrationResource
    
    @AuraEnabled
     public static ResponseWrapper sendCSOData(Opportunity oppObject,string fedIdNumber, string contactId, CSO_Tracking__c csoRec, Boolean isSSN, String dataExtraction, String quoteId, String certId ){
        
        Account acctAddress = getAccountData(oppObject.AccountId);
        Boolean accountValidated = csoRec.ClientDataValidated__c && csoRec.User_Validated__c ? true : false;
        User usObject = [SELECT Id,Email,Person_ID_Number__c,Name,Phone FROM User Where Id =:oppObject.OwnerId];
        String afterblob;
        Blob requestblob;
        
        CSOEligibilityJSON.ClientRegistrationResource2 clientReg2 = new CSOEligibilityJSON.ClientRegistrationResource2();
        clientReg2.bundleList = new Map<String,CSOEligibilityJSON.LineItems[]>();
        clientReg2.additionalLineItems = new CSOEligibilityJSON.LineItems[]{};
        clientReg2.clientResource = new CSOEligibilityJSON.ClientResource();
        clientReg2.userResource = new CSOEligibilityJSON.UserResource();
        clientReg2.misc = new CSOEligibilityJSON.Misc();
        clientReg2.onboardingDataResource = new CSOEligibilityJSON.OnboardingDataResource();
        clientReg2.salesResource = new CSOEligibilityJSON.SalesResource();

        clientReg2.salesResource.quoteFileId = '';
        clientReg2.salesResource.quoteFileCertificateId = '';
        String[] attachList = new String[]{quoteId,certId};
        //Add SSN
        if(oppObject.Primary_Oracle_Quote__c!=NULL){
            List<Attachment> listOfAttachment = new List<Attachment>([SELECT Id,Name,ParentId,CreatedBy.Name,Body FROM Attachment Where ParentId=:oppObject.Id or Id in:attachList]);
            for(Attachment atta : listOfAttachment){
                if((atta.Name.startsWithIgnoreCase(oppObject.Primary_Oracle_Quote__r.Name) && atta.CreatedBy.Name == QUOTE_CREATED_BY && atta.Name.containsIgnoreCase('Completed')) || (atta.Id == quoteId)){
                    System.debug('Attachment: '+atta.Id);
                    blob attachmentBody = atta.Body;
                    afterblob = EncodingUtil.base64Encode(attachmentBody);
                    clientReg2.salesResource.quoteFileId = atta.Id;
                }
                if((atta.Name.startsWithIgnoreCase('Certificate') && atta.CreatedBy.Name == QUOTE_CREATED_BY) || (atta.Id == certId)){
                    clientReg2.salesResource.quoteFileCertificateId = atta.Id;
                }
            }
        }
        
        clientReg2.salesResource.salesRepDetail = new CSOEligibilityJSON.SalesRepDetail();
        clientReg2.salesResource.salesRepDetail.repId = usObject.Person_ID_Number__c;
        clientReg2.salesResource.salesRepDetail.repName = usObject.Name;
        clientReg2.salesResource.salesRepDetail.repEmailAddress = usObject.Email;
        clientReg2.salesResource.salesRepDetail.repPhoneNumber = usObject.Phone;
        
        List<CSOEligibilityJSON.LineItems> listOfLineItems = new List<CSOEligibilityJSON.LineItems>();
        List<CSOEligibilityJSON.LineItems> additionalLineItems = new List<CSOEligibilityJSON.LineItems>();
        
        List<cafsl__Oracle_Quote_Line_Item__c> qLineList = [Select Id,
                                                            cafsl__Oracle_Quote__r.cafsl__Opportunity__c,
                                                            cafsl__Oracle_Quote__r.cafsl__Opportunity__r.CloseDate,
                                                            cafsl__Product__c,cafsl__Product__r.Name,
                                                            cafsl__Product__r.cafsl__Part_Number__c, 
                                                            cafsl__Product__r.CSO_Required__c,    // TODO - use this to identify the bundle for now
                                                            cafsl__Product__r.Is_Package__c,    
                                                            cafsl__Product__r.USS_Enterprise_Code__c 
                                                            from cafsl__Oracle_Quote_Line_Item__c 
                                                            where cafsl__Oracle_Quote__r.cafsl__Opportunity__c =:oppObject.Id 
                                                            and cafsl__Oracle_Quote__r.cafsl__Syncing__c = true 
                                                            and cafsl__Product__r.USS_Enterprise_Code__c!=null];
        // todo - this is temporary until we get the bundle code from CPQ
        System.debug('sendCSOData qLineList='+qLineList.size());
        String bundleName = '';
        for(cafsl__Oracle_Quote_Line_Item__c qline : qLineList) {
           // find the bundle names
           if (qline.cafsl__Product__r.Is_Package__c) {
              bundleName = qline.cafsl__Product__r.USS_Enterprise_Code__c;
              clientReg2.bundleList.put(bundleName, new CSOEligibilityJSON.LineItems[]{});
           }
        } // for(cafsl__Oracle_Quote_Line_Item__c qline
        System.debug('sendCSOData oppId='+oppObject.Id+' bundleName='+bundleName+' qLineList='+qLineList.size());
        for(cafsl__Oracle_Quote_Line_Item__c qline : qLineList) {
            CSOEligibilityJSON.ServiceAvailability sa = new CSOEligibilityJSON.ServiceAvailability();
            sa.serviceStartDate = string.valueOf(date.today());//Must update this to be a real date. Cannot be NULL;
            sa.serviceEndDate = '';
            
            CSOEligibilityJSON.LineItems li = new CSOEligibilityJSON.LineItems();
            li.serviceAvailability = sa;
            li.entProductCode = qline.cafsl__Product__r.USS_Enterprise_Code__c;
            
            listOfLineItems.add(li);
            // to separate the bundle products from non-bundled products
            if (!qline.cafsl__Product__r.Is_Package__c && String.isNotBlank(bundleName)) {
               CSOEligibilityJSON.LineItems[] bundleLines = (clientReg2.bundleList.containsKey(bundleName) ? clientReg2.bundleList.get(bundleName) : new CSOEligibilityJSON.LineItems[]{});
               bundleLines.add(li);
               clientReg2.bundleList.put(bundleName,bundleLines);
            }
            // else if not part of a bundle
            // additionalLineItems.add(li);
        } // for(cafsl__Oracle_Quote_Line_Item__c qline 
        
        Contact con = [SELECT Id,FirstName,LastName,Email,MobilePhone,Phone FROM Contact Where Id =: contactId];
         
        clientReg2.salesResource.sourceOfBusiness = oppObject.LeadSource;
        
        clientReg2.misc.sourceOfBusiness = oppObject.LeadSource;
        clientReg2.misc.doingBusinessAs = acctAddress.DBA__c;
        clientReg2.misc.numberOfEmployees = String.valueOf(acctAddress.NumberOfEmployees);
        
        
        clientReg2.clientResource.tinType = isSSN ? 'SSN' : 'FEIN';
        clientReg2.clientResource.tin = formatFedId(acctAddress.Federal_ID_Number__c);
        clientReg2.clientResource.legalName = formatName(acctAddress.Name);
        clientReg2.clientResource.legalAddress = new CSOEligibilityJSON.LegalAddress();

        AddressWrapper legalStreetWrap = getAddressWrap(acctAddress.LegalAddress__Street__s);
        clientReg2.clientResource.legalAddress.streetAddressOne = formatAddress(legalStreetWrap.addressOne); 
        clientReg2.clientResource.legalAddress.streetAddressTwo = formatAddress(legalStreetWrap.addressTwo);
        clientReg2.clientResource.legalAddress.city = formatName(acctAddress.LegalAddress__City__s);
        clientReg2.clientResource.legalAddress.stateProv = formatState(acctAddress.LegalAddress__StateCode__s);
        clientReg2.clientResource.legalAddress.postalcode = formatPostalCode(acctAddress.LegalAddress__PostalCode__s,acctAddress.LegalAddress__CountryCode__s);
        clientReg2.clientResource.legalAddress.countryCode = formatCountry(acctAddress.LegalAddress__CountryCode__s);
        clientReg2.clientResource.legalAddress.poBoxIndicator = legalStreetWrap.isPoBox;

        clientReg2.salesResource.districtSalesManager = new CSOEligibilityJSON.DSM();
        clientReg2.salesResource.districtSalesManager.name = oppObject.Owner.Manager.Name;
        clientReg2.salesResource.districtSalesManager.id = oppObject.Owner.Manager.Person_ID_Number__c;
        clientReg2.salesResource.districtSalesManager.email = oppObject.Owner.Manager.Email;
                 
        // save this on the CSO record so we know which one was sent
        if (csoRec.Contact__c != contactId) {
            csoRec.Contact__c = contactId;
        } // 
        
        clientReg2.userResource.contactId = '';//blank is Ok per Vishy. No direct mapping in SFDC.
        clientReg2.userResource.email = con.Email;
        clientReg2.userResource.firstName = formatName(con.FirstName); //con.FirstName.replaceAll(',', ' ');
        clientReg2.userResource.lastName = formatName(con.LastName); //con.LastName.replaceAll(',', ' ');
        clientReg2.userResource.telephone = new CSOEligibilityJSON.Telephone();
        StringHelper.parsePhone(con.MobilePhone);
        clientReg2.userResource.telephone.areaCode = StringHelper.phoneArea;
        clientReg2.userResource.telephone.number_Z = StringHelper.phoneTele;
        clientReg2.userResource.telephone.ext = StringHelper.phoneExt;
        clientReg2.userResource.telephone.countryCode = '1';
         
        clientReg2.onboardingDataResource.numberOfEmployees = Integer.valueOf(acctAddress.NumberOfEmployees);
        clientReg2.onboardingDataResource.referral = new CSOEligibilityJSON.BankInfo();
        clientReg2.onboardingDataResource.previousPayrollMethod = oppObject.Payroll_Current_Prior_Method__c;
        clientReg2.onboardingDataResource.dataExtractionNeeded = (String.isNotBlank(dataExtraction) && dataExtraction == 'Yes');
        clientReg2.onboardingDataResource.runEffectiveDate = oppObject.CloseDate;
         
        clientReg2.base64QuoteFile = 'data:application/pdf;base64,' + afterBlob;
        
        ResponseWrapper res = new ResponseWrapper();
        //Create HTTP Request
        if(!accountValidated){
            CsoQueueable csoQue = new CsoQueueable();
            csoQue.addRecsToProcess(acctAddress, csoRec);
            csoQue.processRecs(false);
            system.debug('EZOnboardingRegistration - sendCSOData - recsToProcess: '+csoQue.recsToProcess.size());
            if (!csoQue.recsToProcess.isEmpty()) {
               csoQue.processRecs(false);
            }
        }
        System.debug('sendCSOData after validation ClientDataValidated__c='+csoRec.ClientDataValidated__c+' User_Validated__c='+csoRec.User_Validated__c);
        if(csoRec.ClientDataValidated__c && csoRec.User_Validated__c){
            CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(acctAddress, csoRec);
            HttpRequest request = setupRequest(wrap, REG_CSO);

            request.setBody(json.serialize(clientReg2).replace('number_Z','number'));
            requestblob = request.getBodyAsBlob();
            //EZOnboardingRegistration.addToClientResponse(wrap.cso, 'Registration Request\n'+request.getBody());
            
            system.debug('JSON String: '+request.getBody());
            HTTPResponse response = sendRequest(wrap, request, REG_CSO);
            res = handleRegistrationResponse(response, wrap, REG_CSO, requestblob);
        }else{
            res.statusCode = 400;
            res.message = 'There was an issue validating the client information.  The registration form has not been sent.';
        }
        update csoRec;
        return res;
    } // sendCSOData
    
    public static String REG_CLT_UPDATE='ClientUpdate';
    public static String CLT_VALIDATE='ClientValidate';
    public static String CLT_VALIDATE_ADDR='ClientValidateAddr';
    
    @AuraEnabled
    public static ResponseWrapper validateInfo(Id trackerId, Boolean validClient, Boolean validShipAddr, Boolean validBillAddr) {
       ResponseWrapper res = null;
       Boolean okay = (validClient || validShipAddr || validBillAddr);
       
       CSO_Tracking__c tracker = (okay ? getTracking(trackerId) : null);
       Account acct = (tracker != null ? tracker.AccountId__r : null);
       okay = (acct != null);
       if (!okay) {
          return null;
       }
       // make sure we have the address values
       System.debug('validateInfo 1 trackerId='+trackerId+' validClient='+validClient+' validShipAddr='+validShipAddr+' validBillAddr='+validBillAddr);
       validShipAddr = (validShipAddr && checkShipping(acct,null));
       validBillAddr = (validBillAddr && checkBilling(acct, null));
       System.debug('validateInfo 2 trackerId='+trackerId+' validClient='+validClient+' validShipAddr='+validShipAddr+' validBillAddr='+validBillAddr);
       // make sure it's still okay
       okay = (validClient || validShipAddr || validBillAddr);
       String reqType = (!validClient ? CLT_VALIDATE_ADDR : CLT_VALIDATE);
       CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(acct, tracker);
       wrap.accts.add(acct);
       System.debug('validateInfo okay='+okay+' validClient='+validClient+' validShipAddr='+validShipAddr+' validBillAddr='+validBillAddr);
       if (okay) {
          JSONGenerator gen = buildOicRegRequest(wrap, wrap.acct, wrap.accts, validClient, validShipAddr, validBillAddr);
          HttpRequest req = setupRequest(wrap, reqType);
          if (req != null) {
             req.setBody(gen.getAsString());
             addToValidationRequest(wrap.cso, 'Enterprise Client request:\n'+gen.getAsString());
             HTTPResponse response = sendRequest(wrap, req, reqType);
             res = handleRegistrationResponse(response, wrap, reqType, req.getBodyAsBlob());
          } else {
             res = new ResponseWrapper();
             res.statusCode = (String.isNotBlank(wrap.cso.RegistrationStatusCode__c) ? Integer.valueOf(wrap.cso.RegistrationStatusCode__c) : 400);
          }
       }
       return res;
    } // validateInfo
    
    // check if the address fields are populated. If the oldAcct is passed in, also check if the address changed
    public static Boolean checkShipping(Account acct, Account oldAcct) {
       Boolean hasAddr = (String.isNotBlank(acct.ShippingStreet)
                          && String.isNotBlank(acct.ShippingCity)
                          && String.isNotBlank(acct.ShippingState)
                          && String.isNotBlank(acct.ShippingPostalCode)
                          && String.isNotBlank(acct.ShippingCountry));
       Boolean addrChanged = (oldAcct == null || (oldAcct != null && (acct.ShippingStreet != oldAcct.ShippingStreet
                                              || acct.ShippingCity != oldAcct.ShippingCity
                                              || acct.ShippingState != oldAcct.ShippingState
                                              || acct.ShippingPostalCode != oldAcct.ShippingPostalCode
                                              || acct.ShippingCountry != oldAcct.ShippingCountry
                                             )));
       System.debug('checkShipping hasAddr='+hasAddr+' addrChanged='+addrChanged+' oldAcct='+(oldAcct != null));
       return (hasAddr && addrChanged);
    } // checkShipping
    
    // check if the address fields are populated. If the oldAcct is passed in, also check if the address changed
    public static Boolean checkBilling(Account acct, Account oldAcct) {
       Boolean hasAddr = (String.isNotBlank(acct.BillingStreet)
                          && String.isNotBlank(acct.BillingCity)
                          && String.isNotBlank(acct.BillingState)
                          && String.isNotBlank(acct.BillingPostalCode)
                          && String.isNotBlank(acct.BillingCountry));
       Boolean addrChanged = (oldAcct == null || (oldAcct != null && (acct.BillingStreet != oldAcct.BillingStreet
                                              || acct.BillingCity != oldAcct.BillingCity
                                              || acct.BillingState != oldAcct.BillingState
                                              || acct.BillingPostalCode != oldAcct.BillingPostalCode
                                              || acct.BillingCountry != oldAcct.BillingCountry
                                             )));
       System.debug('checkBilling hasAddr='+hasAddr+' addrChanged='+addrChanged+' oldAcct='+(oldAcct != null));
       return (hasAddr && addrChanged);
    } // checkBilling

    /*
    @AuraEnabled
    public static ResponseWrapper updateLegalInfo(CSO_Tracking__c tracker, Account acct) {
       // what's being passed in is what we want updated, not what's saved in the database.
       // query the db to compare the values
       Account checkAcct = (acct != null && acct.Id != null ? getAccountData(acct.Id) : null);
       System.debug('updateLegalInfo acct='+(acct != null ? acct.Name : 'No acct')+' checkAcct='+(checkAcct != null ? checkAcct.Name : 'No checkAcct'));
       if (checkAcct == null) {
          return null;
       }
       ResponseWrapper res = null;
       Boolean nameChanged = (acct.Name != checkAcct.Name);
       Boolean addrChanged = (acct.LegalAddress__Street__s != checkAcct.LegalAddress__Street__s
                              || acct.LegalAddress__City__s != checkAcct.LegalAddress__City__s
                              || acct.LegalAddress__StateCode__s != checkAcct.LegalAddress__StateCode__s
                              || acct.LegalAddress__PostalCode__s != checkAcct.LegalAddress__PostalCode__s
                              || acct.LegalAddress__CountryCode__s != checkAcct.LegalAddress__CountryCode__s);
       System.debug('updateLegalInfo nameChanged='+nameChanged+' addrChanged='+addrChanged);
       String sendName = (nameChanged ? acct.Name : null);
       String sendStreet = (addrChanged ? acct.LegalAddress__Street__s : null);
       String sendCity = (addrChanged ? acct.LegalAddress__City__s : null);
       String sendState = (addrChanged ? acct.LegalAddress__StateCode__s : null);
       String sendPostal = (addrChanged ? acct.LegalAddress__PostalCode__s : null);
       String sendCountry = (addrChanged ? acct.LegalAddress__CountryCode__s : null);
       CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(checkAcct, tracker);
       HttpRequest req = setupRequest(wrap, REG_CLT_UPDATE, 'PATCH');
       if (req != null) {
          String reqBody = EntRespHelper.getLegalUpdateJson(checkAcct.Paychex_CEID__c, sendName, sendStreet, sendCity, sendState, sendPostal, sendCountry);
          req.setBody(reqBody);
          addToValidationRequest(wrap.cso, 'Legal Update:\n'+reqBody);
          HTTPResponse response = sendRequest(wrap, req, REG_CLT_UPDATE);
          res = handleRegistrationResponse(response, wrap, REG_CLT_UPDATE, req.getBodyAsBlob());
       } else {
          res = new ResponseWrapper();
          res.statusCode = (String.isNotBlank(wrap.cso.RegistrationStatusCode__c) ? Integer.valueOf(wrap.cso.RegistrationStatusCode__c) : 400);
       }
       if (res.statusCode == 200) {
          ZipCheckOwner.SKIP_TRIGGERS=true;
          update acct;
       }
       return res;
    } // updateLegalInfo
    */
    @AuraEnabled
    public static ResponseWrapper handleLegalUpdate(Id trackerId, Boolean nameChanged, Boolean addrChanged) {
       System.debug('handleLegalUpdate nameChanged='+nameChanged+' addrChanged='+addrChanged);
       Boolean okay = (nameChanged || addrChanged);
       ResponseWrapper res = null;
       
       CSO_Tracking__c tracker = (okay ? getTracking(trackerId) : null);
       Account acct = (tracker != null ? tracker.AccountId__r : null);
       okay = (acct != null && String.isNotBlank(acct.Paychex_CEID__c));
       System.debug('handleLegalUpdate okay='+okay+' CEID='+(acct != null ? acct.Paychex_CEID__c : 'NoAcct' ));
       if (okay) {
          String sendName = (nameChanged ? acct.Name : null);
          String sendStreet = (addrChanged ? acct.LegalAddress__Street__s : null);
          String sendCity = (addrChanged ? acct.LegalAddress__City__s : null);
          String sendState = (addrChanged ? acct.LegalAddress__StateCode__s : null);
          String sendPostal = (addrChanged ? acct.LegalAddress__PostalCode__s : null);
          String sendCountry = (addrChanged ? acct.LegalAddress__CountryCode__s : null);
          // make sure we're sending values to update. We don't want to send blank values
          okay = (!nameChanged || (nameChanged && String.isNotBlank(sendName)));
          okay = okay && (!addrChanged || (addrChanged && String.isNotBlank(sendStreet)
                                           && String.isNotBlank(sendCity)
                                           && String.isNotBlank(sendState)
                                           && String.isNotBlank(sendPostal)
                                           && String.isNotBlank(sendCountry)));
          CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(acct, tracker);
          HttpRequest req = setupRequest(wrap, REG_CLT_UPDATE, 'PATCH');
          System.debug('handleLegalUpdate okay='+okay+' before sending the request');
          if (okay && req != null) {
             String reqBody = EntRespHelper.getLegalUpdateJson(acct.Paychex_CEID__c, sendName, sendStreet, sendCity, sendState, sendPostal, sendCountry);
             req.setBody(reqBody);
             addToValidationRequest(wrap.cso, 'Legal Update:\n'+reqBody);
             HTTPResponse response = sendRequest(wrap, req, REG_CLT_UPDATE);
             res = handleRegistrationResponse(response, wrap, REG_CLT_UPDATE, req.getBodyAsBlob());
          } else if (okay) {
             res = new ResponseWrapper();
             res.statusCode = (String.isNotBlank(wrap.cso.RegUpdateStatusCode__c) ? Integer.valueOf(wrap.cso.RegUpdateStatusCode__c) : 400);
          } else {
             res = new ResponseWrapper();
             res.statusCode = 401;
          }
       //if (res.statusCode == 200) {
       //   ZipCheckOwner.SKIP_TRIGGERS=true;
       //   update acct;
       //}
       } // if (okay

       return res;
    } // handleLegalUpdate
    
    public static String testCPQId='83325637';
    
    public static HttpRequest setupRequest(CsoQueueable.AcctCsoWrap wrap, String webServiceName) {
       return setupRequest(wrap,webServiceName,'POST');
    }
       
    public static HttpRequest setupRequest(CsoQueueable.AcctCsoWrap wrap, String webServiceName, String methodType) {
       HttpRequest request = new HttpRequest();
       String env = wrap.cso.Environment__c;
       // if we're in production then we're not using the env variable.
       env = ((String.isBlank(env) || env == CsoMethods.ENV_PROD) ? '' : env);
       System.debug('setupRequest webServiceName='+webServiceName+' env='+env);
       WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting(webServiceName+env);
       if (wss == null) {
          // get the default value if an env specific one isn't found
          wss = WebServicesHelper.getWebSvcSetting(webServiceName);
       }
       StringHelper.addToProcessNotes(wrap.cso,'Setting up request for '+env+' wss='+(wss != null ? wss.Name : webServiceName+' Not Found!'));
       if (wss == null) {
          wrap.setRequestStart(webServiceName);
          wrap.setRequestEnd(webServiceName,'400', 'The webservice is not available');
          return request;
       }
       if (String.isNotBlank(wss.Timeout__c)) {
          try {
             Integer timeout = Integer.valueOf(wss.Timeout__c);
             request.setTimeout(timeout);
          } catch (Exception e) {
             System.debug('Error setting timeout: '+e.getMessage()+'; '+e.getStackTraceString());
          }
       } // if (String.isNotBlank
       System.debug('setupRequest wss='+wss);
       if (wss.NamedCredential__c) {
          if (webServiceName == CPQ_KEYS || webServiceName == CPQ_SUB) {
             // get the oracle transaction id (BS ID)  cafsl__Oracle_Quote__c.cafsl__Transaction_ID__c
             String cpqId = (wrap.cso.Opportunity__r != null && wrap.cso.Opportunity__r.Primary_Oracle_Quote__r != null 
                                 ? wrap.cso.Opportunity__r.Primary_Oracle_Quote__r.cafsl__Transaction_ID__c : null);
             // TODO for testing purposes
             cpqId = (String.isBlank(cpqId) ? testCPQId : cpqId); 
             wrap.cso.CPQTransactionId__c = cpqId;
             String endPoint = String.format(wss.Comment__c,new String[]{cpqId});
             System.debug('setupRequest endPoint='+endPoint);
             request.setEndpoint(endPoint);
         } else {
             request.setEndpoint(wss.Comment__c);
         }
       } else {
          request.setEndpoint(wss.Endpoint__c);
       }
       request.setMethod(methodType);
       if (!Test.isRunningTest() && String.isNotBlank(wss.Certificate__c)) {
          request.setClientCertificateName(wss.Certificate__c);
       }
       request.setHeader('Content-Type', 'application/json');

       // put in this check just in case - once in a while it's not getting populated
       if (String.isBlank(wrap.cso.TrackerUUID__c)) {
          wrap.cso.TrackerUUID__c = System.UUID.randomUUID().toString();
       }
       request.setHeader('x-payx-txid', wrap.cso.TrackerUUID__c);
       request.setHeader('x-payx-cnsmr', 'SFDC');
       request.setHeader('x-payx-bizpn',webServiceName);
       String requestKey = wrap.setRequestStart(webServiceName);
       if (String.isNotBlank(requestKey)) {
          request.setHeader('x-payx-subtxnbr',requestKey);
       }
       return request;
    } // setupRequest
    
    public static HTTPResponse sendRequest(CsoQueueable.AcctCsoWrap wrap, HttpRequest request, String requestType) {
        HTTPResponse response;
        try {
            response = new Http().send(request);
            System.debug('sendRequest after http.send');
            wrap.setRequestEnd(requestType, (response != null ? String.valueOf(response.getStatusCode()) : '-1'), null);
        } catch(Exception e) {
            System.debug('sendRequest Exception Caught: '+e.getMessage());
            //wrap.cso.InitialValidationDetail__c = 'Exception Caught: '+e.getMessage();
            addToCsoResponse(wrap.cso,'Exception Caught: '+e.getMessage());
            wrap.setRequestEnd(requestType, 'FAIL', e.getMessage()+'; '+e.getStackTraceString());
        }
        return response;
    } // sendRequest
    
   // if we get a partial failure (207) with a validated address returned, do we try to automatically resubmit the registration?
   public static Boolean retryOnPartialAddress=(Label.EZOnboarding_AddressRetry == 'Y');
    
   public static ResponseWrapper handleRegistrationResponse(HttpResponse response, CsoQueueable.AcctCsoWrap wrap, String requestType, Blob requestblob) {
      ResponseWrapper res = new ResponseWrapper();
      Boolean retryReg=false;
      Map<Id,CSO_Tracking__c> trackerUpdateMap = new Map<Id,CSO_Tracking__c>();
      if (response !=null) {
         res.statusCode = response.getStatusCode();
         res.message = response.getBody();
         System.debug('handleRegistrationResponse statusCode='+res.statusCode+' requestType='+requestType);
         EntResponse entResp = EntRespHelper.parseResponse(wrap, response.getBody(), requestType);

         wrap.setRequestEnd(requestType, null, entResp.errDesc);
         //wrap.cso.RegistrationDetail__c = entResp.errDesc;
         if (String.isNotBlank(entResp.statusCode)) {
             try {
                res.statusCode = Integer.valueOf(entResp.statusCode);
             } catch (Exception e) {
                System.debug('handleRegistrationResponse e='+e.getMessage()+'; '+e.getStackTraceString());
             }
         }
         // if at least one address is returned as part of this request and we ended in a partial success, resend the registration
         Boolean addressReturned = ((String.isNotBlank(wrap.cso.ValidAddr1__Street__s) && String.isNotBlank(wrap.cso.ValidAddr1__PostalCode__s))
                                    || (String.isNotBlank(wrap.cso.ValidAddr2__Street__s) && String.isNotBlank(wrap.cso.ValidAddr2__PostalCode__s)));
         retryReg = (retryOnPartialAddress && requestType == REG_ENT && res.statusCode == 207 && addressReturned);
         if (retryReg) {
            wrap.cso.RegistrationProcessing__c=true;
            wrap.cso.EntRegTest__c=true;
            StringHelper.addToProcessNotes(wrap.cso,'Status Code 207 returned, retrying reg');
         }
             
         checkFieldChange(wrap.cso,wrap.cso, 'CEID__c', entResp.ceid);
         checkFieldChange(wrap.cso,wrap.cso, 'CAID__c', entResp.caid);
         checkFieldChange(wrap.cso,wrap.cso, 'ClientNumber__c', entResp.cltNbr);
         checkFieldChange(wrap.cso,wrap.cso, 'ResponseGuid__c', entResp.responseId);
         trackerUpdateMap.put(wrap.cso.Id, wrap.cso);
         Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
  
         EntResponse[] acctResps = (!entResp.accts.isEmpty() ? entResp.accts : new EntResponse[]{entResp});
         Account[] checkAccts = (wrap.accts != null && !wrap.accts.isEmpty() ? wrap.accts : new Account[]{wrap.acct});
         CsoQueueable.AcctCsoWrap[] allWraps = new CsoQueueable.AcctCsoWrap[]{wrap};
         if (!wrap.children.isEmpty()) {
            allWraps.addAll(wrap.children);
         }
         System.debug('handleRegistrationResponse acctResps='+acctResps.size()+' allWraps='+allWraps.size());
         Boolean acctFound = false;
         for (EntResponse acctResp : acctResps) {
            CsoQueueable.AcctCsoWrap matchWrap = ((acctResps.size() == 1 && (requestType == REG_CSO || requestType == CLT_VALIDATE 
                                                                             || requestType == CLT_VALIDATE_ADDR)
                                                    ) ? wrap : findWrap(allWraps, acctResp));
            System.debug('handleRegistrationResponse matchWrap='+(matchWrap != null));
            if (matchWrap != null) {
               acctFound = true;
               Boolean isParent = (matchWrap.acct.Id == wrap.acct.Id);
               matchWrap.setRequestEnd(requestType, (res.statusCode != null ? String.valueOf(res.statusCode) : null),null);
               checkFieldChange(matchWrap.cso,matchWrap.cso, 'CEID__c', entResp.ceid);
               checkFieldChange(matchWrap.cso,matchWrap.cso, 'CAID__c', acctResp.caid);
               checkFieldChange(matchWrap.cso,matchWrap.cso, 'ClientNumber__c', acctResp.cltNbr);
               trackerUpdateMap.put(matchWrap.cso.Id, matchWrap.cso);
               checkAccountUpdate(entResp, acctResp, matchWrap.acct, acctUpdateMap, isParent);
            }
         } // for (EntResponse acctResp
         // if we have address information returned, but we can't link directly to an account because the caid 
         // is not returned, try to match directly to the address.
         Boolean hasAddrId = (!wrap.billingIdSet.isEmpty() || !wrap.shippingIdSet.isEmpty());
         System.debug('handleRegistrationResponse acctFound='+acctFound+' hasAddrId='+hasAddrId+' entResp.addrMap='+entResp.addrMap.size()+' acctUpdateMap='+acctUpdateMap.size());
         // double check the address is set.
         if (hasAddrId) {
            for (CsoQueueable.AcctCsoWrap acctWrap : allWraps) {
               if (acctWrap.acct != null && acctWrap.acct.Id != null) {
                  Account updateAcct = (acctUpdateMap.containsKey(acctWrap.acct.Id) ? acctUpdateMap.get(acctWrap.acct.Id) : new Account(Id=acctWrap.acct.Id));
                  checkNonLegalAddr(entResp, null, acctWrap.acct, updateAcct, acctUpdateMap, false);
               }
            }
         } // if (!acctFound
 
          // ACCOUNT_ADDRESS_ID_EXISTS
         //if (res.statusCode == 400) {
            
         //}

         wrap.cso.RegistrationStarted__c = (res.statusCode == 200);
         if (wrap.cso.RegistrationStarted__c && wrap.cso.RegistrationStartedBy__c == null) {
            wrap.cso.RegistrationStartedBy__c = UserInfo.getUserId();
         }
         
         if (!acctUpdateMap.isEmpty()) {
            ZipCheckOwner.SKIP_TRIGGERS=true;
            DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'handleRegistrationResponse', 'Update Accounts', true);
             
         }
         // update the flex ueid on the contact if it's returned
         if (String.isNotBlank(entResp.userGuid) && wrap.cso.Contact__c != null) {
            Contact ctct = new Contact(Id=wrap.cso.Contact__c, FlexUEID__c=entResp.userGuid);
            ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
            ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
            update ctct;
            ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
            ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
         }
         

         if (res.statusCode == 200) {
           //setOppToSold(oppObject);
         } else if(res.statusCode == 503) {
            res.message = 'Easy Setup Registration is Currently Unavailable. Please Submit via PACO';
            wrap.cso.Opportunity_Eligible__c = false;
            wrap.cso.OpportunityEligibilityDetail__c = res.message;
            wrap.cso.RegistrationDetail__c = 'The onboarding service is not available at this time';
         } else {
            wrap.cso.Opportunity_Eligible__c = false;
            wrap.setRequestEnd(requestType, null, entResp.errDesc);
            //wrap.cso.RegistrationDetail__c = entResp.errDesc;
         }
      } else {
         res.statusCode = 400;
         res.message = 'The onboarding service is not available at this time';
         wrap.cso.Opportunity_Eligible__c = false;
         wrap.cso.OpportunityEligibilityDetail__c = res.message;
         wrap.cso.RegistrationDetail__c = 'The onboarding service is not available at this time';
         // TODO - should this be an alert?
         trackerUpdateMap.put(wrap.cso.Id, wrap.cso);
      }
      if (res.statusCode != 200 && String.isBlank(res.message)) {
         res.message = 'Unable to connect to external services';
      }
      addToCsoResponse(wrap.cso,'statusCode='+res.statusCode+' response='+res.message);
      wrap.setRequestEnd(requestType, (res.statusCode != null ? String.valueOf(res.statusCode) : null),null);
      if (requestType == REG_CSO) {
          //Create JSON request file
          FileWrapper[] fileWrapList = new FileWrapper[]{};
          FileWrapper fw = new FileWrapper(new Id[]{wrap.cso.Id}, 'SendCsoData_Request.txt', 'SendCsoData_Request.txt', null, requestblob);
          fileWrapList.add(fw);
          if (!fileWrapList.isEmpty()) {  
              AddFileQueueable afq = new AddFileQueueable(fileWrapList);  
              afq.processRecs();
          }
       } // if (requestType == REG_CSO
       // don't skip the triggers if we're creating an onboarding record
       Boolean createOnboarding = (wrap.cso.RegistrationStarted__c && wrap.cso.Onboarding_Tool__c != null);
       // TODO - not sure if it's skipping the triggers when it shouldn't be.
       CsoMethods.SKIP_TRIGGERS=false; //(!createOnboarding || retryReg);
       DmlHelper.performDML2(trackerUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'handleRegistrationResponse', 'Update CSO Tracking Record', true); 
       CsoMethods.SKIP_TRIGGERS=false;
       return res;
    } // handleRegistrationResponse

    public static CsoQueueable.AcctCsoWrap findWrap(CsoQueueable.AcctCsoWrap[] allWraps, EntResponse acctResp) {
       CsoQueueable.AcctCsoWrap matchWrap = null;
       for (CsoQueueable.AcctCsoWrap wrap : allWraps) {
          if ((String.isNotBlank(acctResp.acctId) && acctResp.acctId == wrap.acct.Id)
              || (String.isNotBlank(acctResp.caid) && acctResp.caid == wrap.acct.Paychex_CAID__c)) {
             matchWrap = wrap;
             break;
          }
       } // for (Account acct : accts
       System.debug('findAcct acctResp acctId='+acctResp.acctId+' caid='+acctResp.caid+' matchWrap='+(matchWrap != null));
       return matchWrap;
    } // findWrap

    public static Account findAcct(Account[] accts, EntResponse acctResp) {
       Account matchAcct = null;
       for (Account acct : accts) {
          if ((String.isNotBlank(acctResp.acctId) && acctResp.acctId == acct.Id)
              || (String.isNotBlank(acctResp.caid) && acctResp.caid == acct.Paychex_CAID__c)) {
             matchAcct = acct;
             break;
          }
       } // for (Account acct : accts
       System.debug('findAcct acctResp acctId='+acctResp.acctId+' caid='+acctResp.caid+' matchAcct='+(matchAcct != null));
       return matchAcct;
    } // findAcct
    
    public static void checkAccountUpdate(EntResponse cltResp, EntResponse acctResp, Account checkAcct, Map<Id,Account> acctUpdateMap, Boolean isParent) {
       System.debug('checkAccountUpdate id='+acctResp.acctId+' cltResp.ceid='+cltResp.ceid+' caid='+acctResp.caid+' billingId='+acctResp.billingId+' shippingId='+acctResp.shippingId+' isParent='+isParent);
       if (checkAcct != null) {
          Account updateAcct = new Account(Id=checkAcct.Id);
           
          Boolean changed = checkFieldChange(checkAcct, updateAcct, 'Paychex_CAID__c', acctResp.caid, true);
          changed = (checkFieldChange(checkAcct, updateAcct, 'Paychex_CEID__c', cltResp.ceid, true) || changed);
          changed = (checkFieldChange(checkAcct, updateAcct, 'EnterpriseAAID__c', cltResp.aaid, true) || changed);
          if (cltResp.legalAddr != null) {
             changed = (checkLegal(checkAcct, updateAcct, cltResp.legalAddr) || changed);
          }
          if (isParent && String.isNotBlank(cltResp.acctName)) {
             changed = (checkFieldChange(checkAcct, updateAcct, 'Name', cltResp.acctName, true) || changed);
          }
           changed = (checkFieldChange(checkAcct, updateAcct, 'EnterpriseClientNumber__c', acctResp.cltNbr, true) || changed);
          if (String.isNotBlank(acctResp.caid)) {
             // if a CAID is returned, mark the account as enterprise client
             changed = (checkFieldChange(checkAcct, updateAcct, 'ClientRegistrationStatus__c', CsoMethods.TYPE_CLIENT, true) || changed);
          }
          changed = checkNonLegalAddr(cltResp, acctResp, checkAcct, updateAcct, acctUpdateMap, changed);
       } // if (checkAcct != null

    } // checkAccountUpdate
    
   public static Boolean checkNonLegalAddr(EntResponse cltResp, EntResponse acctResp, Account checkAcct, Account updateAcct, Map<Id,Account> acctUpdateMap, Boolean changed) {
      System.debug('checkNonLegalAddr cltResp.addrMap='+(cltResp.addrMap.size())+' checkAcct='+(checkAcct != null ? checkAcct.Id : null));
      AddrResp billAddr = ((String.isNotBlank(checkAcct.BillingUUID__c) && acctResp != null && acctResp.addrMap.containsKey(checkAcct.BillingUUID__c)) 
                               ? acctResp.addrMap.get(checkAcct.BillingUUID__c) 
                               : (String.isNotBlank(checkAcct.BillingUUID__c) && cltResp.addrMap.containsKey(checkAcct.BillingUUID__c)
                                  ? cltResp.addrMap.get(checkAcct.BillingUUID__c) : (acctResp != null ? acctResp.billAddr : null)));
      System.debug('checkNonLegalAddr checkAcct.BillingUUID__c='+checkAcct.BillingUUID__c+' billAddr='+(billAddr != null));
      if (billAddr != null) {
         changed = (checkBilling(checkAcct, updateAcct, billAddr) || changed);                     
      }
      AddrResp shipAddr = ((String.isNotBlank(checkAcct.ShippingUUID__c) && acctResp != null && acctResp.addrMap.containsKey(checkAcct.ShippingUUID__c)) 
                               ? acctResp.addrMap.get(checkAcct.ShippingUUID__c) 
                               : (String.isNotBlank(checkAcct.ShippingUUID__c) && cltResp.addrMap.containsKey(checkAcct.ShippingUUID__c)
                                  ? cltResp.addrMap.get(checkAcct.ShippingUUID__c) : (acctResp != null ? acctResp.shipAddr : null)));
                               
      if (shipAddr != null) {
         changed = (checkShipping(checkAcct, updateAcct, shipAddr) || changed);                     
      }
      System.debug('checkNonLegalAddr checkAcct.ShippingUUID__c='+checkAcct.ShippingUUID__c+' shipAddr='+(shipAddr != null)+' changed='+changed);
      if (changed) {
         updateAcct.SkipAddressIdCheck__c=true;
         acctUpdateMap.put(updateAcct.Id, updateAcct);
      }
      return changed;
   } // checkNonLegalAddr
    
    public static Boolean checkLegal(Account checkAcct, Account updateAcct, AddrResp addr) {
       Boolean changed = (checkFieldChange(checkAcct, updateAcct, 'EnterpriseAAID__c', addr.aid, true));
       changed = (checkFieldChange(checkAcct, updateAcct, 'LegalAddress__Street__s', addr.street, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'LegalAddress__City__s', addr.city, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'LegalAddress__StateCode__s', addr.state, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'LegalAddress__PostalCode__s', addr.postal, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'LegalAddress__CountryCode__s', addr.country, true) || changed);
       return changed;
    } // checkLegal

    public static Boolean checkBilling(Account checkAcct, Account updateAcct, AddrResp addr) {
       Boolean changed = (checkFieldChange(checkAcct, updateAcct, 'EnterpriseBillingId__c', addr.aid, true));
       changed = (checkFieldChange(checkAcct, updateAcct, 'BillingUUID__c', addr.aid, true));
       changed = (checkFieldChange(checkAcct, updateAcct, 'BillingStreet', addr.street, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'BillingCity', addr.city, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'BillingState', addr.state, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'BillingPostalCode', addr.postal, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'BillingCountry', addr.country, true) || changed);
       return changed;
    } // checkBilling
    
    public static Boolean checkShipping(Account checkAcct, Account updateAcct, AddrResp addr) {
       Boolean changed = (checkFieldChange(checkAcct, updateAcct, 'EnterpriseShippingId__c', addr.aid, true));
       changed = (checkFieldChange(checkAcct, updateAcct, 'ShippingUUID__c', addr.aid, true));
       changed = (checkFieldChange(checkAcct, updateAcct, 'ShippingStreet', addr.street, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'ShippingCity', addr.city, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'ShippingState', addr.state, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'ShippingPostalCode', addr.postal, true) || changed);
       changed = (checkFieldChange(checkAcct, updateAcct, 'ShippingCountry', addr.country, true) || changed);
       return changed;
    } // checkShipping

    // use the picklist entry to stay dynamic
    public static String[] getValidChildTypes() {
       String[] validTypes = new String[]{};
       Schema.DescribeFieldResult childTypeDesc = CSO_Tracking__c.ChildType__c.getDescribe();	
       List<Schema.PicklistEntry> childTypes = childTypeDesc.getPicklistValues();
   	   for (schema.picklistEntry childType: childTypes) {
          validTypes.add (childType.getvalue()); 
       } //for (schema.picklistEntry childType: childTypes 
       System.debug('getValidChildTypes validTypes='+validTypes);
       return validTypes;
    } // getValidChildTypes

    public static CsoQueueable.AcctCsoWrap getMultiIdWrapper(Id trackerId, Boolean checkReg, Boolean checkNonRegChildren) {
       CsoQueueable.AcctCsoWrap wrap = null;
       // in order to resend part of a multi-id, assuming some records have succeeded, we need to be able to retrieve 
       // the parent record, then filter through the children and find ones that didn't successfully register.
       // if checkNonRegChildren comes in as true, we're not going to check the registration flag on the parent since that's
       // used to retrieve all the children.
       Boolean checkTheReg = (checkNonRegChildren ? false : checkReg);
       Map<Id, CSO_Tracking__c> trackerMap = CsoMethods.getCsoRecs(new Id[]{trackerId},checkTheReg);
       CSO_Tracking__c tracker = trackerMap.get(trackerId);
       if (tracker != null) {
          // only the parent should have a quote attached. 
          String quoteId = (tracker.Opportunity__c != null ? tracker.Opportunity__r.Primary_Oracle_Quote__c : null);
          String queryKey = (quoteId != null ? CsoMethods.QUERY_ACCT_MULTI_QUOTE : CsoMethods.QUERY_ACCT_MULTI);

          String acctId = tracker.AccountId__c;
          Account acct = tracker.AccountId__r;
          wrap = new CsoQueueable.AcctCsoWrap(acct, tracker);
          // always add the acct to the list
          wrap.accts.add(acct);
          // make sure we have a quote before performing the query
          //Account[] queryAccts = (quoteId != null ? Database.query(acctQuery) : new Account[]{});
          String acctQuery = CsoMethods.getQuery(queryKey);
          System.debug('getMultiIdWrapper acctId='+acctId+' quoteId='+quoteId+' trackerId='+trackerId);
          Account[] queryAccts = Database.query(acctQuery);
          System.debug('getMultiIdWrapper queryAccts='+queryAccts.size());
          if (tracker.NumberOfIds__c != queryAccts.size()) {
             tracker.NumberOfIds__c = queryAccts.size();
          }
          if (!queryAccts.isEmpty()) {
             String[] validTypes = getValidChildTypes();
             CSO_Tracking__c[] newTrackers = new CSO_Tracking__c[]{};
             for (Account childAcct : queryAccts) {
                // make sure each child has a tracker
                // these should have already been created previously. Should we assumed they're present?
                CSO_Tracking__c childTracker = (!childAcct.CSO_Recs__r.isEmpty() ? childAcct.CSO_Recs__r[0] : null);
                CsoQueueable.AcctCsoWrap childWrap = new CsoQueueable.AcctCsoWrap(childAcct, childTracker);
                wrap.children.add(childWrap);
             } // for (Account child : queryAccts
             wrap.accts.addAll(queryAccts);
          } // if (!queryAccts.isEmpty

          //HttpRequest req = setupRequest(wrap, REG_ENT);
          //wrap.accts = new Account[]{};
          // TODO have to do additional filtering and checking
          // If coming from a child, the parent should already be registered. They should only be
          // coming from the child if adding an ID to an existing.
          // TODO - what if adding multiple children at once to an existing parent?
          //Account client = acct.SalesParent__c != null ? acct.SalesParent__r : acct;
          //wrap.accts.add(acct);
          // add the children
          //if (acct.isParent__c) {
          //   wrap.accts.addAll(acct.Sales_Parent__r);
          //}
          System.debug('getMultiIdWrapper accts='+wrap.accts.size());
       }
       return wrap;
    } // getMultiIdWrapper
    
    public class ClientGroup {
       public String parentFedId;
       public Id parentAcctId;
       public Id parentTrackerId;
       public CsoQueueable.AcctCsoWrap wrap;
       //public Id[] childTrackerIds = new Id[]{};
       //public Id[] childAcctIds = new Id[]{};
       public CsoQueueable.AcctCsoWrap[] children = new CsoQueueable.AcctCsoWrap[]{};
    } // class ClientGroup
    
    // prepare the request to register a client. If this is a multi-id request, 
    // break it up into combo and multi-id groups. If the combo groups are too large
    // break those up too.
    /*
    public static ClientGroup[] prepareEntRegistrationReq(Id trackerId) {
       
       CsoQueueable.AcctCsoWrap wrap = getMultiIdWrapper(trackerId, true, true);
       // use an array to control the order
       ClientGroup[] groupsToSend = new ClientGroup[]{};
       // use the map so easy to put together
       Map<Id,ClientGroup> groupMapByAcctId = new Map<Id,ClientGroup>();
       // always will have the parent record?
       ClientGroup cg = new ClientGroup();
       cg.parentTrackerId = wrap.cso.Id;
       cg.wrap = wrap;
       groupsToSend.add(cg);
       groupMapByAcctId.put(wrap.acct.Id, cg);
       for (CsoQueueable.AcctCsoWrap child : wrap.children) {
          System.debug('prepareEntRegistrationReq child tracker='+(child.cso != null));
          if (child.cso == null) {
             // shouldn't be null at this point. What should we do if it is?
          }
          if (child.cso != null) {
             System.debug('prepareEntRegistrationReq sameFEIN='+child.cso.IsSameFEIN__c);
             if (child.cso.IsSameFEIN__c) {
                // group with its parent record
                ClientGroup parentCg = groupMapByAcctId.get(child.cso.ParentAccount__c);
                if (parentCg == null) {
                   System.debug('prepareEntRegistrationReq creating new parent for Same FEIN');
                   parentCg = new ClientGroup();
                   groupMapByAcctId.put(child.cso.ParentAccount__c, parentCg);
                   groupsToSend.add(parentCg);
                }
                parentCg.childTrackerIds.add(child.cso.Id);
                parentCg.childAcctIds.add(child.acct.Id);
                parentCg.children.add(child);
             } else {
                // if not a same fein, or is a parent of a relationship, register each child as a separate client
                ClientGroup checkCg = groupMapByAcctId.get(child.acct.Id);
                if (checkCg == null) {
                   System.debug('prepareEntRegistrationReq creating new Group for parent-child');
                   checkCg = new ClientGroup();
                   groupMapByAcctId.put(child.acct.Id, checkCg);
                   checkCg.parentTrackerId = child.cso.Id;
                   checkCg.parentAcctId = child.acct.Id;
                   checkCg.wrap = child;
                   groupsToSend.add(checkCg);
                }
             } // if (child.cso.IsSameFEIN__c
             
          }
       } // for (CsoQueueable.AcctCsoWrap child 

       System.debug('prepareEntRegistrationReq trackerId='+trackerId+' groupsToSend='+groupsToSend.size());
       return groupsToSend;
    } // prepareEntRegistrationReq
    */
    public static ClientGroup[] prepareEntRegistrationReq(Id trackerId) {
       
       CsoQueueable.AcctCsoWrap wrap = getMultiIdWrapper(trackerId, true, true);
       // use an array to control the order
       ClientGroup[] groupsToSend = new ClientGroup[]{};
       // use the map so easy to put together
       Map<Id,ClientGroup> groupMapByAcctId = new Map<Id,ClientGroup>();
       Map<String,ClientGroup> groupMapByFedId = new Map<String,ClientGroup>();
       // always will have the parent record?
       ClientGroup cg = new ClientGroup();
       cg.parentFedId = formatFedId(wrap.cso.AccountId__r.Federal_ID_Number__c);
       cg.parentTrackerId = wrap.cso.Id;
       cg.wrap = wrap;
       groupsToSend.add(cg);
       groupMapByAcctId.put(wrap.acct.Id, cg);
       groupMapByFedId.put(cg.parentFedId, cg);
       for (CsoQueueable.AcctCsoWrap child : wrap.children) {
          System.debug('prepareEntRegistrationReq child tracker='+(child.cso != null));
          if (child.cso == null) {
             // shouldn't be null at this point. What should we do if it is?
          }
          if (child.cso != null && child.acct != null) {
             String childFedId = formatFedId(child.acct.Federal_ID_Number__c);
             if (String.isNotBlank(childFedId)) {
                ClientGroup parentCg = groupMapByFedId.get(childFedId);
                if (parentCg == null) {
                   System.debug('prepareEntRegistrationReq creating new parent for Same FEIN');
                   parentCg = new ClientGroup();
                   parentCg.wrap = child;
                   parentCg.parentFedId = childFedId;
                   groupMapByFedId.put(parentCg.parentFedId, parentCg);
                   groupsToSend.add(parentCg);
                } else {
                   parentCg.children.add(child);
                }
                //parentCg.childTrackerIds.add(child.cso.Id);
                //parentCg.childAcctIds.add(child.acct.Id);

             } else if (String.isBlank(childFedId)) {
                // if no fed id assume a child of the parent
                //cg.childTrackerIds.add(child.cso.Id);
                //cg.childAcctIds.add(child.acct.Id);
                cg.children.add(child);

             }
          } // if (child.cso != null
       } // for (CsoQueueable.AcctCsoWrap child 

       System.debug('prepareEntRegistrationReq trackerId='+trackerId+' groupsToSend='+groupsToSend.size());
       return groupsToSend;
    } // prepareEntRegistrationReq

    // used as an override to trigger the retrieval of the keys
    public static void startOssKeysRequestNow(Id trackerId) {
       System.debug('startOssKeysRequestNow trackerId='+trackerId);
       ClientGroup[] grps = prepareEntRegistrationReq(trackerId);
       EnterpriseRegistration entReg = new EnterpriseRegistration(null,grps);
       EnterpriseRegistration.launchJob(entReg);
    } // startOssKeysRequestNow

    // if they're 
    @AuraEnabled
    public static ResponseWrapper submitOnboarding(Id trackerId) {
       ResponseWrapper res = new ResponseWrapper();
       CSO_Tracking__c tracker = [Select Id, AccountId__c, Contact__c, Opportunity__c
                                        ,RegistrationStartedBy__c, NumberOfIds__c, Onboarding_Tool__c, Product_Bundle__c
                                    From CSO_Tracking__c 
                                   Where Id=:trackerId];
       if (tracker.Onboarding_Tool__c != null) {
          Map<Id,CSO_Tracking__c> onboardTrackerMap = new Map<Id,CSO_Tracking__c>();
          onboardTrackerMap.put(tracker.Onboarding_Tool__c, tracker);
          Id[] acctIds = new Id[]{tracker.AccountId__c};
          Id[] oppIds = new Id[]{tracker.Opportunity__c};
          Id[] trackerIds = new Id[]{tracker.Id};
          CsoMethods.createCaseRefCtt(onboardTrackerMap, acctIds, oppIds, trackerIds); 
       }

       return res;
    } // submitOnboarding
    
    // start the enterprise registration request. 
    // if this is a multi-id, depending on the type of groupings, they will processed separately
    // if we want to process the first record synchronously with this method, processFirst should be true
    @AuraEnabled
    public static ResponseWrapper startEntRegRequestNow(Id trackerId, Boolean processFirst) {
       ResponseWrapper res = null;
       System.debug('startEntRegRequestNow trackerId='+trackerId+' processFirst='+processFirst);
       ClientGroup[] grps = prepareEntRegistrationReq(trackerId);
       EnterpriseRegistration entReg = new EnterpriseRegistration(grps,null);
       // set parent to processing
       grps[0].wrap.cso.RegistrationProcessing__c=true;
       if (processFirst) {
          res = entReg.handleCltReg();
       } else {
          CsoMethods.SKIP_TRIGGERS=true;
          CSO_Tracking__c updateTracker = new CSO_Tracking__c(Id=grps[0].wrap.cso.Id, RegistrationProcessing__c=true);
          update updateTracker;
          res = new ResponseWrapper();
          res.statusCode = 200;
          res.message = 'Client Registration Started';
          EnterpriseRegistration.launchJob(entReg);
       } // if (processFirst
       return res;
    } // startEntRegRequestNow
    
    // for testing only so we can see if the logic works.
    public static String testCEID=null;
    
    public static ResponseWrapper sendEntRegRequest(ClientGroup cltGrp, Boolean validateOnly) {
       // see if any of the group already have a ceid - put that one in the primary position.
       // if nothing has a ceid, and we have a fed id, query for another account with the same fed id that has a ceid.
       
       CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(cltGrp.wrap);
       Boolean allSuccess = (wrap.cso.RegistrationStatusCode__c == '200');
       // if we need to query the accounts to find an existing CEID
       Id[] queryAcctIds = new Id[]{};
       wrap.accts.add(wrap.acct);
       queryAcctIds.add(wrap.acct.Id);
       Boolean hasSalesParent=(wrap.acct.SalesParent__c != null);
       if (wrap.acct.SalesParent__c != null) {
          queryAcctIds.add(wrap.acct.SalesParent__c);
       }
       String fedId=(wrap.acct != null ? wrap.acct.Federal_Id_Number__c : null);
       wrap.ceid=(wrap.acct != null ? wrap.acct.Paychex_CEID__c : null);
       for (CsoQueueable.AcctCsoWrap child : cltGrp.children) {
          allSuccess = (allSuccess && child.cso.RegistrationStatusCode__c == '200');
          fedId = (String.isNotBlank(fedId) ? fedId : child.acct.Federal_Id_Number__c);
          wrap.ceid = (String.isNotBlank(wrap.ceid) ? wrap.ceid : child.acct.Paychex_CEID__c);
          hasSalesParent = (hasSalesParent || child.acct.SalesParent__c != null);
          if (child.acct.SalesParent__c != null) {
             queryAcctIds.add(child.acct.SalesParent__c);
          }
          wrap.accts.add(child.acct); 
          wrap.children.add(child);
       }
       ResponseWrapper res = null;
       if (!allSuccess) {
          if (String.isBlank(wrap.ceid) && String.isNotBlank(fedId) && hasSalesParent) {
             // see if there are any accounts in the family that have the same fed id and have a ceid
             Account[] chkAccts = [Select Id, Paychex_CEID__c, Paychex_CAID__c, Federal_Id_Number__c
                                     from Account
                                    Where Federal_Id_Number__c = :fedId
                                      and Paychex_CEID__c != null
                                      and (Id in :queryAcctIds or SalesParent__c in :queryAcctIds)];
             if (!chkAccts.isEmpty()) {
                wrap.ceid = chkAccts[0].Paychex_CEID__c;
             }
          } // if (String.isBlank(wrap.ceid)
          // just for testing
          testCEID = wrap.ceid;
          JSONGenerator gen = buildOicRegRequest(wrap, wrap.acct, wrap.accts, false, false, false);
          HttpRequest req = setupRequest(wrap, REG_ENT);
          if (req != null) {
             req.setBody(gen.getAsString());
             addToValidationRequest(wrap.cso, 'Enterprise Client request:\n'+gen.getAsString());
             HTTPResponse response = sendRequest(wrap, req, REG_ENT);
             res = handleRegistrationResponse(response, wrap, REG_ENT, req.getBodyAsBlob());
          } else {
             res = new ResponseWrapper();
             res.statusCode = (String.isNotBlank(wrap.cso.RegistrationStatusCode__c) ? Integer.valueOf(wrap.cso.RegistrationStatusCode__c) : 400);
          }
       } else {
          res = new ResponseWrapper();
          res.statusCode = 200;
       }
       return res;
    } // sendEntRegRequest
    
    /*
    // send a single request
    @future (callout=true)
    public static void sendOicRequest(Id trackerId) {
       CsoQueueable.AcctCsoWrap wrap = getMultiIdWrapper(trackerId, true, true);
       if (wrap != null) {
          // if there are children, break out 
          Account client = wrap.acct.SalesParent__c != null ? wrap.acct.SalesParent__r : wrap.acct;
          JSONGenerator gen = buildOicRegRequest(wrap, client, wrap.accts);
          HttpRequest req = setupRequest(wrap, REG_ENT);
          req.setBody(gen.getAsString());
          addToValidationRequest(wrap.cso, 'Enterprise Client request:\n'+gen.getAsString());
          HTTPResponse response = sendRequest(wrap, req, REG_ENT);
          ResponseWrapper res = handleRegistrationResponse(response, wrap, REG_ENT, req.getBodyAsBlob());
       } // if (tracker != null
    } // sendOicRequest
    */
    public static String KEYS_NAME='EntRegOSSKeys';
    
    public static Boolean sendKeysRequest(ClientGroup cltGrp) {
       // TODO - re-retrieve the records since they could have changed
       CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(cltGrp.wrap);
       wrap.accts.add(wrap.acct);
       for (CsoQueueable.AcctCsoWrap child : cltGrp.children) {
          wrap.accts.add(child.acct); 
          wrap.children.add(child);
       }
       wrap.cso.OSSKeysNextAttempt__c = null;
       //wrap.cso.OSSKeysNbrTries__c = (wrap.cso.OSSKeysNbrTries__c == null ? 1 : wrap.cso.OSSKeysNbrTries__c+1);
       HttpRequest req = setupRequest(wrap, OSS_KEYS);
       if (req == null) {
          wrap.cso.OSSKeysNextAttempt__c=null;
       } else {
          String addressJson = EntRespHelper.getAddressKeyJson(wrap.accts);
          HTTPResponse response = null;
          if (String.isBlank(addressJson)) {
             wrap.cso.OSSKeysDetail__c = 'Address Keys Not Found';
          } else {
             req.setBody(addressJson);
             addToValidationRequest(wrap.cso, 'OSS Key request:\n'+addressJson);
             String errorMsg = null;
             try {
                response = sendRequest(wrap, req, OSS_KEYS);
             } catch (Exception e) {
                wrap.cso.OSSKeysDetail__c = e.getMessage();
             }
          }
          System.debug('sendKeysRequest response='+(response != null ? response.getBody() : 'No Response'));
          EntResponse entResp = (response != null ? EntRespHelper.parseResponse(wrap, response.getBody(), OSS_KEYS) : new EntResponse());
          entResp.statusCode = (response != null ? String.valueOf(response.getStatusCode()) : '400');
          addToCsoResponse(wrap.cso,'OSS Keys response statusCode='+(response != null ? response.getStatusCode() : null)+' body='+(response != null ? response.getBody() : ''));

          if (entResp.ossKeysResp != null && entResp.ossKeysResp.client != null && String.isNotBlank(entResp.ossKeysResp.client.ceid)) {
             Account[] accts = [Select Id, Name, Paychex_CEID__c, Paychex_CAID__c, EBSAccountID__c, EBSPartyId__c, OSSAccountID__c, OSSPartyID__c
                                      ,EnterpriseAAID__c, EnterpriseBillingId__c, EnterpriseShippingId__c
                                      ,EBSBillToSiteID__c, EBSShipToSiteID__c, OSSBillToSiteID__c, OSSShipToSiteID__c
                                      ,(Select Id, Account__c, CAID__c, CEID__c, EnterpriseAID__c
                                              ,EBSBillToSiteID__c, EBSShipToSiteID__c, OSSBillToSiteID__c, OSSShipToSiteID__c
                                          From AccountAddresses__r)
                                  From Account
                                 Where Paychex_CEID__c = :entResp.ossKeysResp.client.ceid];
             System.debug('sendKeysRequest entResp.ossKeysResp.client.ceid='+entResp.ossKeysResp.client.ceid+' accts='+accts.size());
             if (!accts.isEmpty()) {
                updateAddressIds(entResp.ossKeysResp, accts, entResp);
             }
          } // if (entResp.ossKeysResp
          if (wrap.cso.OSSKeysStatusCode__c != entResp.statusCode) {
             wrap.cso.OSSKeysStatusCode__c = entResp.statusCode;
          }
          wrap.cso.OSSKeysDetail__c = entResp.errDesc;
          // if we're not successful, check if we need to launch this again
          if (wrap.cso.OSSKeysStatusCode__c != '200') {
             Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(KEYS_NAME);
             if (abc != null && abc.Active__c) {
                Integer maxAttempts = (abc.NbrOfAttempts__c != null ? Integer.valueOf(abc.NbrOfAttempts__c) : 5);
                wrap.cso.OSSKeysMaxTries__c = (wrap.cso.OSSKeysNbrTries__c >= maxAttempts);
                if (!wrap.cso.OSSKeysMaxTries__c) {
                   // use this as an indicator we're going to try again.
                   wrap.cso.OSSKeysNextAttempt__c = Datetime.now();
                }
             } // if (abc != null && abc.Active__c
          } // if (wrap.cso.OSSKeysStatusCode__c
          if (wrap.cso.OSSKeysStatusCode__c == '200' || wrap.cso.OSSKeysMaxTries__c) {
             wrap.cso.RegistrationProcessing__c = false;
          }
       } // if (req == null
       CsoMethods.SKIP_TRIGGERS=true;
       update wrap.cso;
       CsoMethods.SKIP_TRIGGERS=false;

       return (wrap.cso.OSSKeysNextAttempt__c == null);
    } // sendKeysRequest

    public static void updateAddressIds(EntRespHelper.OssIdResponse ossIdResp, Account[] accts, EntResponse entResp) {
       Map<String,Account> acctByCaidMap = new Map<String,Account>();
       Map<String,AccountAddress__c> addrByIdMap = new Map<String,AccountAddress__c>();
       Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
       Map<String,AccountAddress__c> addrUpsertMap = new Map<String,AccountAddress__c>();
       // break apart the accounts and address records by caids (for multi ids)
       for (Account acct : accts) {
          if (String.isNotBlank(acct.Paychex_CAID__c)) {
             acctByCaidMap.put(acct.Paychex_CAID__c, acct);
             for (AccountAddress__c addr : acct.AccountAddresses__r) {
                addrByIdMap.put(addr.EnterpriseAID__c, addr);
             }
          }
       } // for (Account acct : accts
       System.debug('updateAddressIds acctByCaidMap='+acctByCaidMap.size()+' addrByIdMap='+addrByIdMap.size());
       for (EntRespHelper.BillAcctResp billAcct : ossIdResp.billingAccounts) {
          System.debug('updateAddressIds billAcct='+billAcct);
          Account acct = acctByCaidMap.get(billAcct.enterpriseCaid);
          System.debug('updateAddressIds acct='+(acct != null ? acct.Name : 'Not Found')+' errors='+(billAcct.errors != null ? billAcct.errors.size() : -1));
          if (billAcct.errors != null && !billAcct.errors.isEmpty()) {
             // there will probably only be one error returned. Not coded for multiple at the moment.
             for (EntRespHelper.ErrorResp err : billAcct.errors) {
                entResp.errCode = err.errorCode;
                entResp.errDesc = err.errorDescription;
                entResp.statusCode = err.errorCode;
             }
          } else if (acct != null) {
             Boolean acctUpdated = checkFieldChange(acct,acct,'EBSPartyId__c',ossIdResp.client.ebsPartyId);
             acctUpdated = (checkFieldChange(acct,acct,'OSSPartyID__c',ossIdResp.client.ossPartyId) || acctUpdated);
             acctUpdated = (checkFieldChange(acct,acct,'EBSAccountID__c',billAcct.ebsAccountId) || acctUpdated);
             acctUpdated = (checkFieldChange(acct,acct,'OSSAccountID__c',billAcct.ossAccountId) || acctUpdated);
             AccountAddress__c billingAddr = null;
             AccountAddress__c shippingAddr = null;
             if (billAcct.clientAddresses != null) {
                  
                for (EntRespHelper.CltAddrResp addrResp : billAcct.clientAddresses) {
                   AccountAddress__c addr = addrByIdMap.get(addrResp.enterpriseAddressId);
                   if (addr == null) {
                      addr = new AccountAddress__c(EnterpriseAID__c=addrResp.enterpriseAddressId, CAID__c=billAcct.enterpriseCaid, Account__c=acct.Id); 
                   }
                   // default them to the first address found, so we always populate ids if ids are returned to us
                   if (billingAddr == null) {
                      billingAddr = addr;
                      shippingAddr = addr;
                   }
                   Boolean addrChanged = checkFieldChange(addr,addr,'EBSBillToSiteID__c',addrResp.ebsBillToSiteId);
                   addrChanged = (checkFieldChange(addr,addr,'EBSShipToSiteID__c',addrResp.ebsShipToSiteId) || addrChanged);
                   addrChanged = (checkFieldChange(addr,addr,'OSSBillToSiteID__c',addrResp.ossBillToSiteId) || addrChanged);
                   addrChanged = (checkFieldChange(addr,addr,'OSSShipToSiteID__c',addrResp.ossShipToSiteId) || addrChanged);
                   if (addrChanged) {
                      addr.IdsLastRetrieved__c = Datetime.now();
                      addrUpsertMap.put(addr.EnterpriseAID__c, addr);
                   }
                   if (acct.EnterpriseBillingId__c == addr.EnterpriseAID__c) {
                      billingAddr = addr;
                   }
                   if (acct.EnterpriseShippingId__c == addr.EnterpriseAID__c) {
                      shippingAddr = addr;
                   }
                } // for (EntRespHelper.CltAddrResp addrResp
             } // if (billAcct.clientAddresses != null
             System.debug('updateAddressIds billingAddr='+(billingAddr != null)+' shippingAddr='+(shippingAddr != null));
             if (billingAddr != null) {
                acctUpdated = (checkFieldChange(acct,acct,'EBSBillToSiteID__c', billingAddr.EBSBillToSiteID__c) || acctUpdated);
                acctUpdated = (checkFieldChange(acct,acct,'OSSBillToSiteID__c', billingAddr.OSSBillToSiteID__c) || acctUpdated);
             }
             if (shippingAddr != null) {
                acctUpdated = (checkFieldChange(acct,acct,'EBSShipToSiteID__c', shippingAddr.EBSShipToSiteID__c) || acctUpdated);
                acctUpdated = (checkFieldChange(acct,acct,'OSSShipToSiteID__c', shippingAddr.OSSShipToSiteID__c) || acctUpdated);
             }
             if (acctUpdated) {
                acctUpdateMap.put(acct.Id, acct);
             }
             // check to make sure the account has all the ids populated. This will still be an error even if no other error is returned.
             String[] reqFields = checkAcctCpqFlds(acct);
             if (!reqFields.isEmpty()) {
                entResp.errCode = '405';
                entResp.errDesc = 'Missing fields: '+String.join(reqFields,', ');
                entResp.statusCode = '405';
             }
          } // if (acct != null)
       } // for (EntRespHelper.BillAcctResp billAcct
       System.debug('updateAddressIds acctUpdateMap='+acctUpdateMap.size()+' addrUpsertMap='+addrUpsertMap.size());
       if (!acctUpdateMap.isEmpty()) {
          ZipCheckOwner.SKIP_TRIGGERS=true;
          DmlHelper.performDML(acctUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'updateAddressIds', 'updating Accounts', true);
       }
       if (!addrUpsertMap.isEmpty()) {
         DmlHelper.DmlResult dmlResult = DmlHelper.initializeDmlResult(addrUpsertMap.values(), DmlHelper.DML_UPSERT, CLASSNAME, 'updateAddressIds', 'upserting leads');
         Database.UpsertResult[] results = Database.upsert(addrUpsertMap.values(),AccountAddress__c.Fields.EnterpriseAID__c,false);
         DmlHelper.handleUpsertResults(addrUpsertMap.values(), results, dmlResult);
         //ErrorLog.addToDescription(log,'Save Result recs='+dmlResult.nbrRecs+' success='+dmlResult.nbrSuccess);

       }
       
    } // updateAddressIds

    public static Boolean checkFieldChange(SObject checkRec, SObject updateRec, String fieldName, String value) {
       return checkFieldChange(checkRec, updateRec, fieldName, value, false);
    }
    
    public static Boolean checkFieldChange(SObject checkRec, SObject updateRec, String fieldName, String value, Boolean setCheckRecToo) {
       String recValue = (String)updateRec.get(fieldName);
       System.debug('checkFieldChange fieldName='+fieldName+' recValue='+recValue+' value='+value);
       if (String.isNotBlank(value) && recValue != value) {
          updateRec.put(fieldName,value);
          if (setCheckRecToo) {
             checkRec.put(fieldName,value);
          }
          return true;
       }
       return false;
    } // checkFieldChange

    /*
    public static void checkSendCpqKeys(Id[] trackerIds) {
       EnterpriseRegistration entReg = new EnterpriseRegistration(EnterpriseRegistration.MODE_CPQ_KEYS, trackerIds);
       EnterpriseRegistration.launchJob(entReg);
    } // checkSendCpqKeys

    @future (callout=true)
    public static void sendCPQKeys(Id trackerId) {
       sendCPQKeysNow(trackerId);
    } // sendCPQKeys
    */
    public static CsoQueueable.AcctCsoWrap sendCPQKeysNow(Id trackerId) {
       CsoQueueable.AcctCsoWrap wrap = getMultiIdWrapper(trackerId, false, false);
       // only send if subscription quote
       Boolean isSubscriptionQuote = (wrap != null && wrap.cso != null && wrap.cso.Opportunity__c != null && wrap.cso.Opportunity__r.IsPrimaryQuoteSubscription__c);
       System.debug('sendCPQKeysNow trackerId='+trackerId+' isSubscriptionQuote'+isSubscriptionQuote);
       if (isSubscriptionQuote) {
          // make sure we have the fields populated
          if (checkCPQRequired(wrap)) {
             HttpRequest req = setupRequest(wrap, CPQ_KEYS);
             if (req == null) {
                wrap.cso.CPQProcessing__c = false;
             } else {
                 
                String addressJson = buildCPQKeysReq(wrap);
                req.setBody(addressJson);
                addToValidationRequest(wrap.cso, 'Oracle CPQ Keys request:\n'+addressJson);
                HTTPResponse response = sendRequest(wrap, req, CPQ_KEYS);
                // if this is successful, it will move onto submitting the subscription
                System.debug('sendCPQKeysNow wrap.cso.CPQKeysStatusCode__c='+wrap.cso.CPQKeysStatusCode__c);
                if (wrap.cso.CPQSubStatusCode__c != '200') {
                   wrap.cso.CPQProcessing__c = false;
                }
                handleCpqResponse(wrap, CPQ_KEYS, wrap.cso.CPQKeysStatusCode__c, response.getBody());
                // look for getOSSChargeResponse_t in the response to see if there's an error
                addToCsoResponse(wrap.cso,'CPQ Keys response statusCode='+response.getStatusCode()+' body='+response.getBody());
                //wrap.setRequestEnd(CPQ_KEYS, (response != null ? String.valueOf(response.getStatusCode()) : null));
                System.debug('sendCPQKeys response='+response);
             }
          } else {
             // if the required fields fail reset the processing flag
             wrap.cso.CPQProcessing__c = false;
          }
       } else {
          wrap.cso.CPQProcessing__c = false;
          wrap.cso.CPQKeysStatusCode__c = null;
          wrap.cso.CPQKeysDetail__c = null;
       } // if (isSubscriptionQuote
       CsoMethods.SKIP_TRIGGERS=true;
       update wrap.cso;
       CsoMethods.SKIP_TRIGGERS=false;
       return wrap;
    } // sendCPQKeysNow
    
    /*
8/16/2023 9:25:41: CPQ Keys response statusCode=404 body={"type":"HTTP://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html","title":"Resource commerceDocumentsPaychexCommerceProcessTransaction with key 87938657 doesn't exist or is not accessible for current user."}
8/16/2023 9:18:32: CPQ Keys response statusCode=401 body={"error_description":"Incorrect user or password - user could not be logged in.","error_uri":"HTTP://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html","error":"Incorrect user or password - user could not be logged in."}

    */    
    public static void handleCpqResponse(CsoQueueable.AcctCsoWrap wrap, String requestType, String statusCode, String respBody) {
          try {
             JSONParser parser = JSON.createParser(respBody);
             String statusDetail = null;
             while (parser.nextToken() != null) {
                 if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                    string currentName = parser.getText();
                    System.debug('handleCpqResponse currentName='+currentName);
                    parser.nextToken();
                    if (currentName == 'title') {
                       statusDetail = parser.getText();
                       System.debug('error='+statusDetail);
                    } else if (currentName == 'error_description') {
                       statusDetail = parser.getText();
                       System.debug('errDesc='+statusDetail);
                    } else if (currentName == 'createSubscriptionResponse_t' || 
                               currentName == 'subscriptionIntegrationResponse_t') {
                       // if this is not success, then it's an error
                       String result = parser.getText();
                       if (result != 'success') {
                          statusDetail = result;
                          statusCode = '399';
                       }
                    }
                }     
             } // while (parser.nextToken() != null
             wrap.setRequestEnd(requestType, statusCode, statusDetail);
          } catch (Exception e) {
             // this is just as a backup - shouldn't have to use
             System.debug('parseResponse exception='+e.getMessage()+'; '+e.getStackTraceString());
             //if (response.contains('description')) {
             //   resp.errDesc = response.substringBetween('"description":"', '"');
             //}
          }
    } // handleCpqResponse
    
    // TESTING ONLY
    public static Boolean BYPASS_QUOTE_CHECK=false;
    
    public static Boolean checkCPQRequired(CsoQueueable.AcctCsoWrap wrap) {
       return checkCPQRequired(wrap.cso, wrap.accts);
    } // checkCPQRequired
    
    public static Boolean checkCPQRequired(CSO_Tracking__c cso, Account[] accts) {

       System.debug('checkCPQRequired BYPASS_QUOTE_CHECK='+BYPASS_QUOTE_CHECK);
       // clear out the fields
       cso.CPQKeysDetail__c = null;
       cso.CPQKeysStatusCode__c = null;
       String[] errors = new String[]{};
       if (!BYPASS_QUOTE_CHECK) {
          if (cso == null || cso.Opportunity__r == null || cso.Opportunity__r.Primary_Oracle_Quote__c == null 
                   || !cso.Opportunity__r.Primary_Oracle_Quote__r.isSubscriptionQuote__c
                   || String.isBlank(cso.Opportunity__r.Primary_Oracle_Quote__r.cafsl__Transaction_ID__c)
             ) {
             errors.add('Valid Subscription Quote not found');
          } else {
             OracleQuoteStatusOpptyStatus__mdt statusCheck = null;
             if (String.isNotBlank(cso.Opportunity__r.Primary_Oracle_Quote__r.Status__c)) {
                statusCheck = OracleQuoteStatusOpptyStatus__mdt.getInstance(cso.Opportunity__r.Primary_Oracle_Quote__r.Status__c);
             }
             if (statusCheck == null || !statusCheck.OSSSubmitOkay__c) {
                errors.add('The subscription cannot be started in the current Quote status: '+cso.Opportunity__r.Primary_Oracle_Quote__r.Status__c);
             }
          }
       } // if (!BYPASS_QUOTE_CHECK
       if (errors.isEmpty() && accts != null) {
          for (Account acct : accts) {
             // check the account fields
             errors.addAll(checkAcctCpqFlds(acct));
          } // for (Account acct : wrap
       }// if (errors.isEmpty
       Boolean okay = errors.isEmpty();
       if (!okay) {
          Integer fldSize = CSO_Tracking__c.CPQKeysDetail__c.getDescribe().getLength();
          // make sure the field isn't too long
          cso.CPQKeysDetail__c = (String.join(errors,', ')).left(fldSize);
          cso.CPQKeysStatusCode__c = '050';
          StringHelper.addToProcessNotes(cso,'checkCPQRequired failed');
       }
       System.debug('checkCPQRequired okay='+okay+' errors='+errors);
       return okay;
    } // checkCPQRequired
    
    public static String[] checkAcctCpqFlds(Account acct) {
       String[] errors = new String[]{};
       // check the account fields
       for (Schema.FieldSetMember fsm : Schema.SObjectType.Account.fieldSets.CPQSubReqFlds.getFields()) {
          String fldName = fsm.getFieldPath();
          if (acct.get(fldName) == null) {
             errors.add(acct.Name+ ' missing '+fsm.getLabel());
          }
       } // for (Schema.FieldSetMember fsm
       return errors;
    } // checkAcctCpqFlds
    /*
    @future (callout=true)
    public static void sendCPQSub(Id trackerId) {
       sendCPQSubNow(trackerId);
    }
    */
    public static void sendCPQSubNow(Id trackerId) {
       Map<Id, CSO_Tracking__c> trackerMap = CsoMethods.getCsoRecs(new Id[]{trackerId}, false);
       CSO_Tracking__c tracker = trackerMap.get(trackerId);
       // if it's already a success, don't try to send again
       if (tracker != null && tracker.CPQSubStatusCode__c != '200') {
          CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(tracker.AccountId__r, tracker);
          HttpRequest req = setupRequest(wrap, CPQ_SUB);
          String addressJson = buildCPQSubReq(wrap);
          req.setBody(addressJson);
          addToValidationRequest(wrap.cso, 'Oracle CPQ Sub request:\n'+addressJson);
          HTTPResponse response = sendRequest(wrap, req, CPQ_SUB);
          tracker.CPQProcessing__c = false;
          handleCpqResponse(wrap, CPQ_SUB, wrap.cso.CPQSubStatusCode__c, response.getBody());
          addToCsoResponse(tracker,'CPQ Sub response statusCode='+response.getStatusCode()+' body='+response.getBody());
          //wrap.setRequestEnd(CPQ_KEYS, (response != null ? String.valueOf(response.getStatusCode()) : null));
          System.debug('sendCPQKeys response='+response);
          CsoMethods.SKIP_TRIGGERS=true;
          update tracker;
          CsoMethods.SKIP_TRIGGERS=false;
       } // if (tracker != null
    } // sendCPQSub
    /* single id message
{
	"documents": {
		"partyId_t": "100000002144650",
		"accountNumber_t": "100000002146011",
		"billToSiteUseId_t": "100000002146246",
		"shipToAccountId_t": "100000002146011",
		"shipToPartyId_t": "100000002144650",
		"shipToSiteId_t": "100000002145771",
	}
}     
*/
    public static String buildCPQKeysReq(CsoQueueable.AcctCsoWrap wrap) {
       // TODO - have to handle multi-id
       EntRespHelper.CpqKeys cpq = new EntRespHelper.CpqKeys();
       cpq.documents.partyId_t = wrap.acct.OSSPartyID__c;
       cpq.documents.accountNumber_t = wrap.acct.OSSAccountID__c;
       cpq.documents.billToSiteUseId_t = wrap.acct.OSSBillToSiteID__c;
       cpq.documents.shipToAccountId_t = wrap.acct.OSSAccountID__c;
       cpq.documents.shipToPartyId_t = wrap.acct.OSSPartyID__c;
       cpq.documents.shipToSiteId_t = wrap.acct.OSSShipToSiteID__c;
       cpq.documents.SFDCChildAccountData_t=EntRespHelper.getCpqChildren(wrap.accts);
       String output = json.serialize(cpq).replace('number_Z','number');
       System.debug('buildCPQKeysReq output='+output);
       return output;
    } // buildCPQKeysReq
    
    /*
    {
    "criteria":{
        "fields":["bs_id","subscriptionIntegrationResponse_t"]
    }
    }
*/

    public static String buildCPQSubReq(CsoQueueable.AcctCsoWrap wrap) {
       //String output = '{"criteria":{"fields":["bs_id","subscriptionIntegrationResponse_t","createSubscriptionResponse_t"]}}';
       String output = '{"criteria":{"fields":["bs_id","subscriptionIntegrationResponse_t"]}}';
       System.debug('output='+output);
       return output;
    } // buildCPQSubReq
    
    // values for Type on Account Junction: Sales Parent-Child, Related/Common, Combo
    // build the request for enterprise registration to OIC
    public static JSONGenerator buildOicRegRequest(CsoQueueable.AcctCsoWrap wrap, Account client, Account[] accts
                                                  ,Boolean validateClient, Boolean validateShip, Boolean validateBill) {
       Boolean isValidate = (validateClient || validateShip || validateBill);
       System.debug('buildOicRegRequest accts='+accts.size()+' isValidate='+isValidate);
       CSO_Tracking__c tracker = wrap.cso;
       JSONGenerator gen = JSON.createGenerator(true);
       gen.writeStartObject();
       //gen.writeStringField('ceid','');
       //gen.writeStringField('id','');
       String ceid = (String.isNotBlank(client.Paychex_CEID__c) ? client.Paychex_CEID__c : wrap.ceid);
       // if it's not a validate call we always include the client section
       // If it is a validate call, we'll include this section if validating the client section
       //     or there's a CEID
       if (!isValidate || (isValidate && (validateClient || ceid != null))) {
          gen.writeFieldName('client');
          gen.writeStartObject();
          addStringField(gen,'ceid',ceid,false);
          // include this part if it's not a validate call or if it's a validate call for the client info
          if (!isValidate || validateClient) {
             gen.writeFieldName('taxPayerIdentification');
             gen.writeStartObject();
             gen.writeStringField('id',formatFedId(client.Federal_ID_Number__c));
             gen.writeStringField('type','FEIN');  // TODO - choose between FEIN and SSN
             gen.writeEndObject(); // end of taxPayerIdentification
        
             gen.writeFieldName('postalAddresses');
             gen.writeStartArray();
             addAddress(gen,ADDR_LEGAL,client.LegalAddress__Street__s, client.LegalAddress__City__s, client.LegalAddress__StateCode__s, client.LegalAddress__PostalCode__s, client.LegalAddress__CountryCode__s
                     ,'streetAddress1','streetAddress2','poBoxIndicator','city','countrySubdivision','postalCode','iso2CountryCode');
       
             gen.writeEndArray(); // end of postalAddresses array
             gen.writeFieldName('names');
             gen.writeStartObject();
             gen.writeFieldName('primary');
             gen.writeStartObject();
             gen.writeStringField('name',formatName(client.Name));
             gen.writeBooleanField('active', false);
             gen.writeEndObject(); // end of primary
             gen.writeEndObject(); // end of names
          } // if (!isValidate || validateClient
          gen.writeEndObject(); // end of client
       } // if (!validateClient

       if (!isValidate || validateShip || validateBill) {
          gen.writeFieldName('accounts');
          gen.writeStartArray();
          for (Account acct : accts) {
             gen.writeStartObject();
             addStringField(gen,'name',formatName(acct.Name),true);
             addStringField(gen,'enterpriseCaid',acct.Paychex_CAID__c,false);
             gen.writeFieldName('primarySourceSystem');
             gen.writeStartObject();
             gen.writeStringField('id',formatText(acct.Id));
             gen.writeStringField('name','SFDC');
             gen.writeFieldName('effectivity');
             gen.writeStartObject();
             gen.writeBooleanField('active', true);
             gen.writeEndObject();   // end of effectivity

             gen.writeEndObject();   // end of primarySourceSystem
                gen.writeFieldName('postalAddresses');
                gen.writeStartArray();
                setAddress(gen, acct, wrap, validateShip, validateBill);
       
                gen.writeEndArray(); // end of postalAddresses array
             gen.writeEndObject();   // end of 1 account in the accounts array

          } // for (Account acct : accts
        
          gen.writeEndArray();   // end of accounts array
       } // if (!isValidate || validateShip

       gen.writeEndObject();  // end of JSON string
       System.debug('buildOicRegRequest wrap.billingIdSet='+wrap.billingIdSet.size()+' wrap.shippingIdSet='+wrap.shippingIdSet.size());
       System.debug('buildOicRegRequest gen='+gen.getAsString());
       return gen;
    } // buildOicRegRequest
    
    public static void setAddress(JSONGenerator gen, Account acct, CsoQueueable.AcctCsoWrap wrap, Boolean validateShip, Boolean validateBill) {
       Boolean isClient = (wrap.cso.ExistingEnterpriseClient__c);
       Boolean isValidate = (validateShip || validateBill);
       Boolean addrTheSame = areNonLegalTheSame(acct);
       System.debug('setAddress isClient='+isClient+' isValidate='+isValidate+' addrTheSame='+addrTheSame);
       if (addrTheSame) {
          addAddress(gen,wrap,new String[]{ADDR_SHIP,ADDR_BILL},acct.ShippingUUID__c, acct.ShippingStreet, acct.ShippingCity, acct.ShippingState, acct.ShippingPostalCode, acct.ShippingCountry
                    ,'streetAddress1','streetAddress2','poBoxIndicator','city','countrySubdivision','postalCode','iso2CountryCode');
       } else {
          // we have to include at least one address. If the billing isn't used, we have to include the shipping
          Boolean billUsed = false;
          //if (useBilling && String.isBlank(acct.EnterpriseBillingId__c)) {
          if (validateBill || (!isValidate && useBilling && (isClient || String.isBlank(acct.EnterpriseBillingId__c)))) {
             addAddress(gen,wrap,new String[]{ADDR_BILL},acct.BillingUUID__c, acct.BillingStreet, acct.BillingCity, acct.BillingState, acct.BillingPostalCode, acct.BillingCountry
                    ,'streetAddress1','streetAddress2','poBoxIndicator','city','countrySubdivision','postalCode','iso2CountryCode');
             billUsed = true;
          } // if (useBilling
          //if (useShipping && String.isBlank(acct.EnterpriseShippingId__c)) {
          if (validateShip || (!isValidate && useShipping && (!billUsed || isClient || String.isBlank(acct.EnterpriseShippingId__c)))) {
             addAddress(gen,wrap,new String[]{ADDR_SHIP},acct.ShippingUUID__c, acct.ShippingStreet, acct.ShippingCity, acct.ShippingState, acct.ShippingPostalCode, acct.ShippingCountry
                    ,'streetAddress1','streetAddress2','poBoxIndicator','city','countrySubdivision','postalCode','iso2CountryCode');
          } // if (useShipping
       }

    } // setAddress
    
    public static Boolean useShipping=true;
    public static Boolean useBilling=true;
    
    public static Boolean areNonLegalTheSame(Account acct) {
       Boolean areEqual = false;
       // check to see if the are equal, or if only one address is populated. If only one address exists, we'll send that in as both shipping and billing (so we have an id for both) 
       useShipping = (String.isNotBlank(acct.ShippingStreet) && String.isNotBlank(acct.ShippingPostalCode));
       useBilling = (String.isNotBlank(acct.BillingStreet) && String.isNotBlank(acct.BillingPostalCode));
       areEqual = (useShipping && useBilling && ((acct.ShippingStreet == acct.BillingStreet && acct.ShippingPostalCode == acct.BillingPostalCode)
                                                 || (String.isNotBlank(acct.BillingUUID__c) && acct.BillingUUID__c == acct.ShippingUUID__c)));
       return areEqual;
    } // areNonLegalTheSame
    
    public static String ADDR_LEGAL='LEGAL';
    public static String ADDR_BILL='BILLING';
    public static String ADDR_SHIP='SHIPPING';
    
    public static Boolean ALWAYS_USE_POBOX=(Label.EzOnboarding_AlwaysUsePoBox=='Y');
    
    // this is called from an external class
    public static void addAddress(JSONGenerator gen, String addrType, String street, String city, String state, String postal, String country
                                 ,String tagStreet1, String tagStreet2, String tagPoBox, String tagCity, String tagState, String tagPostal, String tagCountry) {
       addAddress(gen, null, (String.isNotBlank(addrType) ? new String[]{addrType} : null), null, street, city, state, postal, country
                                 ,tagStreet1, tagStreet2, tagPoBox, tagCity, tagState, tagPostal, tagCountry);
    } // addAddress

    public static void addAddress(JSONGenerator gen, CsoQueueable.AcctCsoWrap wrap, String[] addrTypes, String idValue, String street, String city, String state, String postal, String country
                                 ,String tagStreet1, String tagStreet2, String tagPoBox, String tagCity, String tagState, String tagPostal, String tagCountry) {
       Boolean isLegal = (addrTypes != null && addrTypes.contains(ADDR_LEGAL));
       System.debug('addAddress street='+street+' city='+city+' state='+state+' postal='+postal);
       if (String.isNotBlank(street) && String.isNotBlank(postal)) {
          if (wrap != null && String.isNotBlank(idValue) && addrTypes != null) {
             if (addrTypes.contains(ADDR_BILL)) {
                wrap.billingIdSet.add(idValue);
             }
             if (addrTypes.contains(ADDR_SHIP)) {
                wrap.shippingIdSet.add(idValue);
             }
          } // if (wrap != null
          gen.writeStartObject();
          AddressWrapper addrWrap = getAddressWrap(street);
          addStringField(gen,'enterpriseAccountAddressId',idValue,false);
          addStringField(gen,tagStreet1,addrWrap.addressOne,true);
          addStringField(gen,tagStreet2,addrWrap.addressTwo,false);
          // TODO - see if addressOne has PO Box in it?
          if (ALWAYS_USE_POBOX || isLegal) {
          gen.writeBooleanField(tagPoBox, addrWrap.isPoBox);
          }
          //addStringField(gen,tagPoBox,addrWrap.isPoBox,false);
          addStringField(gen,tagCity,formatName(city),true);
          addStringField(gen,tagState,formatState(state),true);
          addStringField(gen,tagPostal,formatPostalCode(postal,country),true);
          addStringField(gen,tagCountry,formatCountry(country),true);
          if (addrTypes != null && !addrTypes.isEmpty()) {
             gen.writeFieldName('usages');
             gen.writeStartArray();
             for (String uType : addrTypes) {
                gen.writeStartObject();
                gen.writeStringField('type',uType);
                gen.writeEndObject();
             }
             gen.writeEndArray();
          }               
        
          gen.writeEndObject();
       } // if (String.isNotBlank(street
    } // addAddress
    
    public static void addStringField(JSONGenerator gen, String tagName, String fldValue, Boolean required) {
       if (String.isNotBlank(tagName) && (required || String.isNotBlank(fldValue))) {
           gen.writeStringField(tagName,formatText(fldValue));
       }
    } // addStringField
    
    public class EntResponse {
       public String statusCode;
       public String responseId;
       public String errCode;
       public String errDesc;
       public String acctId;
       public String sourceSystem;
       public String ceid;
       public String caid;
       // legal address id
       public String aaid;
       public String billingId;
       public String shippingId;
       public String acctName;
       public String taxpayId;
       public String taxpayType;
       public String cltNbr;
       public String userGuid;
       public EntResponse[] accts = new EntResponse[]{};
       public Map<String,EntResponse> acctMap = new Map<String,EntResponse>();
       public EntRespHelper.ErrResp[] errs = new EntRespHelper.ErrResp[]{};
       // error by correlation id (if any)
       public Map<String,EntRespHelper.ErrResp> errMap = new Map<String,EntRespHelper.ErrResp>();
       public AddrResp legalAddr;
       public AddrResp billAddr;
       public AddrResp shipAddr;
       public Map<String,AddrResp> addrMap = new Map<String,AddrResp>();
       public EntRespHelper.OssIdResponse ossKeysResp;
       // combine the error codes together.
       public void checkErrors() {
          String[] codes = new String[]{};
          String[] descs = new String[]{};
          for (EntRespHelper.ErrResp err : errs) {
             codes.add(err.errCode);
             descs.add(err.errDesc);
          }
          errCode = String.join(codes,', ');
          errDesc = String.join(descs,', ');
       } // checkErrors
    } // class EntResponse
    
    public class AddrResp {
       // the sf uuid we passed to enterprise
       public String sfId;
       public String ceid;
       public String caid;
       // the enterprise address id returned from enterprise
       public String aid;
       //public String addrType;
       public String errCode;
       public String errDesc;
       public String street;
       public String street2;
       public String city;
       public String state;
       public String postal;
       public String country;
       public Boolean poBox=false;
       public Boolean isLegalAddr=false;
    } // class AddrResp

    // look for the description in the response.
    public static EntResponse parseResponse(String response) {
       return EntRespHelper.parseResponse(response);
    } // parseResponse
    
    public static String formatAddress(String valueToCheck) {
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('[^A-Za-z0-9 ]', '') : '');
       //String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('[^A-Za-z0-9\\&\\/#\\%\\- ]', '') : '');
       return retValue;
    } // formatAddress
    
    public static String formatAddress2(String valueToCheck) {
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('[^A-Za-z0-9 ]', '') : '');
       return retValue;
    } // formatAddress
    
    public static String formatName(String valueToCheck) {
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('[^a-zA-Z0-9-& ]', '') : '');
       return retValue;
    } // formatName
    
    public static String formatFedId(String valueToCheck) {
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('[^0-9.]', '') : '');
       return retValue;
    } // formatFedId
    
    public static String formatState(String valueToCheck) {
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.toUpperCase() : '');
       return retValue;
    } // formatState
    
    public static String formatPostalCode(String valueToCheck) {
       return formatPostalCode(valueToCheck,null);
    }
    public static String formatPostalCode(String valueToCheck, String country) {
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('-','') : '');
       // only send in the 5 digits for postals - if people pass in +4 then it could throw
       // off the address validation.
       if (String.isNotBlank(retValue) && (String.isBlank(country) || country == 'US')) {
          retValue = retValue.left(5);
       }
       return retValue;
    } // formatPostalCode
    
    public static String formatCountry(String valueToCheck) {
       String retValue = 'US';
       if (String.isNotBlank(valueToCheck) && valueToCheck.length() == 2) {
          retValue = valueToCheck;
       }
       return retValue;
    } // formatCountry
    
    public static String formatText(String valueToCheck) {
       // make sure we're not returning a null value
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck : '');
       return retValue;
    } // formatText
    
    /* Not sure if they still need this
    public static void setOppToSold(Opportunity opp) {
       if (opp != null && opp.Probability < 80) {
          opp.StageName = Label.OppStage_Sold;
          opp.Probability = 80;
          update opp;
       }
    } // setOppToSold
    */
    public static void addToCsoResponse(CSO_Tracking__c rec, String msgToAdd) {
       Schema.DescribeFieldResult dfr = CSO_Tracking__c.CsoResponse__c.getDescribe();
       //Integer fldSize = CSO_Tracking__c.CsoResponse__c.getDescribe().getLength();
       StringHelper.addToProcessNotes(rec, dfr, msgToAdd);
    } // addToCsoResponse
    
    public static void addToValidationRequest(CSO_Tracking__c rec, String msgToAdd) {
       Schema.DescribeFieldResult dfr = CSO_Tracking__c.ClientRequest__c.getDescribe();
       StringHelper.addToProcessNotes(rec, dfr, msgToAdd);
    } // addToValidationRequest
    
    @AuraEnabled 
    public static void setLegalToShipping(Account acct){
        System.debug('setLegalToShipping acct='+acct);
        if (acct != null) {
           acct.LegalAddress__Street__s = acct.ShippingStreet;
           acct.LegalAddress__StateCode__s = acct.ShippingState;
           acct.LegalAddress__City__s = acct.ShippingCity;
           acct.LegalAddress__PostalCode__s = acct.ShippingPostalCode;
           acct.LegalAddress__CountryCode__s = (acct.ShippingCountry != null && acct.ShippingCountry.length() == 2 ? acct.ShippingCountry : 'US');
           update acct;
        }
    } // setLegalToShipping
    
    @AuraEnabled 
    public static void updateOpp(Opportunity updateOppty, Boolean isMulti, Boolean returningLost, Boolean NonEnglishPpwrk){
        System.debug('updateOpp updateOppty='+(updateOppty != null));
        if (updateOppty != null) {
           updateOppty.Multi_ID_Client__c = isMulti;
           updateOppty.Returning_Lost_Client__c = returningLost;
           updateOppty.NonEnglishPaperwork__c = NonEnglishPpwrk;
           update updateOppty;
        } // if (updateOppty != null
    } // updateOpp
    
    public class ResponseWrapper{
        @AuraEnabled Public Integer statusCode{get;set;}
        @AuraEnabled Public String message{get;set;}
    } 
    public class AddressWrapper{
        Public String addressOne{get;set;}
        Public String addressTwo{get;set;}
        public Boolean isPoBox=false;
    }
    
    public static String[] poBoxVariations = Label.PO_Box_Variations.toUpperCase().split(',');
    public static AddressWrapper getAddressWrap(String streetValue){
        AddressWrapper aw = new AddressWrapper();
        System.debug('getAddressWrap streetValue='+streetValue);
        if(String.isNotBlank(streetValue) && streetValue.contains('\n')){
            aw.addressOne = formatAddress(streetValue.substringBefore('\n'));
            aw.addressTwo = streetValue.substringAfter('\n');
            aw.addressTwo.remove('\n');
            aw.addressTwo = formatAddress2(aw.addressTwo);
        }else{
            aw.addressOne = formatAddress(streetValue);
            aw.addressTwo = '';
        }
        Boolean isPoBox = false;
        String poBoxRemainder = null;
        if (String.isNotBlank(streetValue)) {
           String checkValue = streetValue.toUpperCase();
           for (String poBox : poBoxVariations) {
              System.debug('getAddressWrap check for: '+poBox);
              if (checkValue.startsWith(poBox)) {
                 isPoBox = true;
                 poBoxRemainder = (checkValue.substring(poBox.length())).trim();
                 break;
              }
           }
        } // if (String.isNotBlank(streetValue
        aw.isPoBox = isPoBox;
        if (aw.isPoBox) {
           aw.addressOne = 'PO BOX '+poBoxRemainder;
           aw.addressTwo = null;
           System.debug('getAddressWrap isPoBox aw.addressOne='+aw.addressOne);
        }
        System.debug('getAddressWrap aw.addressOne='+aw.addressOne+' aw.addressTwo='+aw.addressTwo+' aw.isPoBox='+aw.isPoBox);
        return aw;
    } // getAddressWrap
    @AuraEnabled
    public static void updateTrackerValidation(CSO_Tracking__c trackerToUpdate, String validationField, String value){
        trackerToUpdate.put(validationField, value);
        update trackerToUpdate;
    }
    
} // class EZOnboardingRegistration