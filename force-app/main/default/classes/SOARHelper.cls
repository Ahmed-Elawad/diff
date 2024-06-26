/*
 *  This class will parse the messages received from email services.  Then it will search for existing prospect-client and contact
 *  or create a new prospect-client and contact if needed.  It will then search for a SOAR opportunity created within the last 24 hours. 
 *  If found, the product from this email will be added to that opty and a new referral rcd is created.  If no opty is found 
 *  a new referral rcd and opty are created.
 *
 * History
 * --------
 * 01/11/2016  Cindy Freeman    rewritten to use custom setting instead of Product Mapping object
 * 03/06/2016  Cindy Freeman    tweaked code if Dupe Blocker finds Lead that is dupe of new account, this will still insert new acct
 *                              modifed getAcctInfo query so returns correct account
 * 03/22/2016  Cindy Freeman    modified to catch International zip codes, 
                                turned off Dupe Blocker account scenario that was blocking AddOn account creation
 * 03/28/2016  Cindy Freeman    modified getReferralOwner method to use default user on specific SoarProductMapping record instead of 
 *                              looking up zip code or using Hold Out user
 * 05/17/2016 Cindy Freeman     modified for 2 new fields in Soar email, used to reply to SP when opty is Sold.  Use new custom setting 
 *                              field to prevent DSM from being populated on referral so DSM don't get Soar emails
 *                              Fix bug when creating AddOn clients (hopefully)
 * 06/05/2016 Cindy Freeman     added code to parse plaintext email body so can manually resend Soar emails if needed
 * 06/30/2016 Cindy Freeman     moving Zip_Segment__c name to referral.ZipSegment__c so ends up in opportunity.Zip_Tier__c
 * 07/06/2016 Cindy Freeman     added try/catch around forwardEmail to send message to Jeff
 * 07/18/2016 Josh Cartwright   added in check for preview clients, direct all preview add ons to user
 * 08/30/2016 Cindy Freeman     modified forwardEmail to handle multiple email addresses
 * 05/01/2017 Cindy Freeman    modifed product name for Preview Add-Ons, change to use Parent Zip if child account, 2 new fields from SP form 
 * 06/20/2017 Cindy Freeman     fixed bug of _ in email getting replaced with space giving bad email
 * 06/21/2017 Cindy Freeman     found catch that was not throwing error causing referrals to get Lost in Space! (bad update of ctct email)
 * 06/28/2017 Cindy Freeman     add code to populate Partner Referral record created for the SOAR email
 * 09/12/2017 Cindy Freeman     when cloning account copy Permanent Hold Out descriptions when copying Hold Outs
 * 10/30/2017 Cindy Freeman     added method to fix Notes that are too long or have an email address in them
 * 03/05/2018 Frank Lurz        change to use Parent NumberOfEmployees and Parent owner's Sales Org, and added the Sales Parent when creating AddOn clients
 * 05/18/2018 Frank Lurz        fixed bug of attempted Sales Parent grandparent when adding Sales Parent to creating of AddOn clients
 * 03/05/2019 Cindy Freeman     check Processed flag on partner referral is was processed successfully
 * 03/26/2019 Cindy Freeman     added code to send emails and update Partner Referral comments if problems
 * 05/01/2019 Carrie Marciano   added code to pull in Opportunity Type default based on SOAR product
 * 10/30/2019 Brandon Vidro     Set NumberOfEmployees on account creation
 * 02/06/2020 Jake Hinds        Small change for smb zip lookup, try to find all segments if listed segment not found
 * 04/08/2020 Manmeet Vaseer    SFDC-2703 (US2-US5): Select the SOAR Product mapping based on the newly calculated aggregate Employee Count.
 * 07/07/2020 Manmeet Vaseer    SFDC-2703 (US4): Incoming SOAR submissions are routed to the TAA Territory Owner when the client is a current PEO Client regardless of Employee Count.
   07/07/2020 Dan Carmen        Add in additional logging. 
   08/14/2020 Manmeet Vaseer    Add in additional logging and 'break' statements in getSoarProductMapping() method under 'for' loop.
   08/27/2020 Manmeet Vaseer    Modified getSoarProductMapping() method to add Precedence when selecting the soar product mapping.
   10/21/2020 Jake Hinds        Changes for MMS CSSR and advantage
   01/14/2020 Jake Hinds        Adding client number to dupe blocker search to try and better match when more than one clt record exists
   03/17/2022 Dan Carmen        Added extra check for parent owners
   03/29/2022 Carrie Marciano   Added akkt.NumberOfEmployees = akkt.SalesParent__r.NumberOfEmployees; to ensure that child accounts actually use the rollup of employees on their parent to determine owner
   04/11/2022 Carrie Marciano   Added xml to error message emails to help troubleshooting
   05/04/2022 Carrie Marciano   Added BenAdmin Holdout fields and ITBLess12/ITBMore12 criteria for Flock
   06/16/2022 Reetesh Pandey    Added Code for SOAR Lead Routing new fields - Assign_to_Queue__c,Override_hold_out__c, Check_Hold_out__c
   07/19/2022 Carrie Marciano   Fix for ITBLess12/ITBMore12 functionality, error reporting and other production issues
   08/11/2022 Carrie Marciano   Fix for INC3092394
   23/09/2022 Jaipal            Added new Fields(ForceZipSegment,FallbackSalesOrg) in SOAR Product Mapping to route the Referral Owner to TAA if CSSR Rep not found in that Zip code.
   10/28/2022 Carrie Marciano	Added ex.getStackTraceString() to line 204 and 209 which prints on Partner Referral Comments field to capture more logging for troubleshooting
   11/14/2022 Shilpa G			Added null check for Account Hold Out Reason while evaluating the Hold Out reason is equal to a setting on the SOAR Product Mapping
   12/29/2022 Dan Carmen        Changed to use SF Duplicated Management
   06/15/2023 Jaipal            Added check to Assigned queue to get the name from SPM custom setting and assign to that specific queue. APR0153430: SOAR Queue Routing Update   
   07/24/2023 Carrie Marciano	changed search for acct/contact to use createAcct and createContact both use duplicateHelper
   07/27/2023 Shilpa G      	APR0151875: Changed to route new payroll SOAR leads that result from Current Client referrals to Prospect-Client owner of the referring client.
   09/28/2023 Dan Carmen        Comment out remaining Dupeblocker code.
   03/21/2024 Carrie Marciano   added check for Sales Contact, if not checked check it on the contact used so Sales can see it

*/ 
  
public without sharing class SOARHelper {
   public class SoarRef {
      public String id;                   // account id
      public String EEEmail;
      public String personID;
      public String bis;
      public String currClient;          //leadsource change
      public String costCenter;
      public String clientNumber;      
      public String firstName;
      public String lastName;
      public String fullName;
      public String companyName;
      public String employeeCount;
      public String phoneNumber;
      public String squishedPhone;
      public String address;
      public String city;
      public String state;
      public String zipCode;
      public String product;
      public String platform;
      public String addOnClient;
      public String advClient;
      public String notes;
      public Integer region;
      public Integer soarId;
      public String salesOrg;
      public String federalId;
      public String contactEmail;
      public String plainTextBody;
      public Boolean ITBLess12=False;           // account.CurrentClient__c = True and account.CSSR_Segment__c = False - "In the Base" less than 12 months
      public Boolean ITBMore12=False;           // account.CurrentClient__c = True and account.CSSR_Segment__c = True - "In the Base" more than 12 months
      public Boolean largeMkt;                  // is this a large Market HRS account?
      public Boolean isInternational = false;   // is this an international zip code?
      public String partRefId;                  // id of the Partner Referral record for this Soar email
      public String parseMsg;                   // set to errMsg if something happened during parsing 
      public Boolean isAdvantage{
         get {return (advClient == 'Yes' || platform == 'Advantage'); }
      }
      
      public String zipSegmentName=null;
	  //SOAR Fix
	  public boolean ForceZipSegment = false;
	  public String FallbackSalesOrg;
      
      public Boolean isCurrentClientReferral = false;
      public String referralBusId;
      public String referralClientId;
      public String referralOfficeId;
      public String currentClientReferralId;
            
   } // class SoarRef
        
   /** The type used for the product mapping table */
   public static final String MAPPING_SOAR='Oppty-SOAR';
   /** The type used for the Referral Partner table. */
   public static final String PARTNER_SOAR='SOAR Referral';
   
   public static SoarProductMapping__c spm {get; set;}
        
   public static Contact referringEmp {get; set;}             // contact record of person submitting SOAR referral
   public static User referringUser {get; set;}               // user record of person submitting SOAR referral
   public static Account addonAcct {get; set;}                // existing account used to get owners for addOn Account
   public static Account acct {get; set;}                     // account being referred 
   public static Contact ctct {get; set;}                     // contact being referred 
   public static PartnerReferral__c partRef {get; set;}       // partner Referral created when Soar email came in
   public static Account curClientRef {get;set;}
     
   public static Map<String,HoldOut_ExpirationDates__c> holdOutMap;         // map of Sales Org and HoldOut_ExpirationDates__c
   
   //public static Id pc_soar_queueId;
   public static void processSoarRef(List<SoarRef> srList) {                
      List<HoldOut_ExpirationDates__c> holdOutList = HoldOut_ExpirationDates__c.getall().values();           
      holdOutMap = new Map<String,HoldOut_ExpirationDates__c>();   
      List<String> currentClientReferralIds = new List<String>();
      for (HoldOut_ExpirationDates__c ho : holdOutList) {   
          holdOutMap.put(ho.Sales_Org__c, ho);  
      }      
      //pc_soar_queueId = [select id from group where type='queue' and developername= 'PC_SOAR_Queue' limit 1].id;
      for (SoarRef sr : srList){    
         System.debug('SOARHelper here at processSoarRef, soarRef='+sr);
         getProductsAndRefPartners();
         partRef = getPartnerReferral(sr.partRefId);
         System.debug('processSoarRef has partRef='+(partRef != null));
         
         Boolean okay;
         sr.fullName = sr.firstName + ' ' + sr.lastName; 
         sr.isInternational = (Pattern.matches('\\d{5}(-\\d{4})?',sr.zipCode)?false:true);          // is this an international zip code?
         sr.currClient = ((sr.bis == null || sr.bis.length() == 0)? 'No' : 'Yes');                  // used to change leadsource on opty
         sr.squishedPhone = Utilities.removeExtraChars(sr.phoneNumber, '0123456789');  
         sr.contactEmail = (sr.contactEmail == null || sr.contactEmail.length() == 0 ? null : sr.contactEmail.replace(' ', '_')); // put _ back so looks like valid email address
         sr.ITBLess12 = False;
         sr.ITBMore12 = False;
         referringEmp = getPayxEmp(sr.personID, sr.EEEmail);
         StringHelper.addToProcessNotes(partRef,'referringEmp='+(referringEmp != null ? referringEmp.Id+'-'+referringEmp.Name : 'Not Found'));
         system.debug('SOARHelper referringEmp: ' + referringEmp);
     	 sr.referralOfficeId = sr.referralOfficeId != null && sr.referralOfficeId != '' ? Utilities.removeLeadingZero(sr.referralOfficeId.left(4)) : null;
         sr.currentClientReferralId = sr.referralBusId != null && sr.referralBusId != '' ? sr.referralBusId : ((sr.referralClientId !=null && sr.referralClientId != '' && sr.referralOfficeId != null && sr.referralOfficeId != '') ? sr.referralOfficeId+'-'+sr.referralClientId : null);
         if(sr.currentClientReferralId != null){
          	curClientRef = getClient(sr.currentClientReferralId);
         }
         try {
           if (referringEmp == null){
                sr.parseMsg = ' Invalid referring employee. ';
                updatePartRef(sr.parseMsg, false);  
               
                Throw new SOARException(' Invalid referring employee personId='+sr.personID+ ' email='+sr.EEEmail);  
           }  
             
           sr.personID = (String.isBlank(sr.personID) ? referringEmp.HR_Person_Id__c : sr.personID);
           referringUser = getPayxUser(sr.personId); 
           if (String.isNotBlank(sr.id)){
               okay = findClient(sr);
               if ( !okay || (okay && acct == null)){
                    sr.parseMsg = 'Bad account ID no existing account. ';
                    updatePartRef(sr.parseMsg, false);    
                    Throw new SOARException('bad account ID no existing account, acctId='+sr.id); 
               }         
           } // if existing client id 
             
           System.debug('SOARHelper sr.addOnClient='+sr.addOnClient);           
           if (sr.addOnClient == 'Yes'){
               addonAcct = acct;                   // save found acct so new account gets same owner
               acct = null;
               ctct = null;
               okay = false;					   // clear okay value from parent account query so can be set with addonAcct query		
               System.debug('SOARHelper moved acct to addonAcct='+addonAcct.Id);
               
               //need to default all add ons to preview clients to a specific rep - per SF case - 21819851 
               if(addonAcct.type == 'Preview Client'){
                    sr.product = 'Flex Add On (Current Preview Client)';      //'Preview - Additional';        
               }//if(addonAcct.type == 'Preview Client')    //JC - set property to preview                                
           } // if (sr.addOnClient == Yes)
             
           System.debug('SOARHelper sr.product 1='+sr.product);   
           if (acct == null){
               System.debug('SOARHelper acct=null so calling createAcct');                
               acct = createAcct(sr, addonAcct);   
               sr.id = acct.Id;
               okay = findClient(sr);           // this will requery acct 
            } // if (acct == null)
            
            // now we have acct need find/create contact  
            If(okay && acct !=null){
                ctct = createContact(sr);
                System.debug('SOARHelper createContact ctct: '+(ctct==null?'null':ctct.Id));
        	} // acct != null  
             
            if (acct.NumberOfEmployees >= 50 || acct.X401k_Assets__c >= 650000){
               sr.largeMkt = true; 
            }
            
            System.debug('SOARHelper acct.CurrentClient__c: '+acct.CurrentClient__c);
            if(acct.CurrentClient__c && acct.CSSR_Segment__c){
                sr.ITBMore12 = True;
                System.debug('SOARHelper ITBMore12');   
            } 
            else if(acct.CurrentClient__c && !acct.CSSR_Segment__c){
                sr.ITBLess12 = True;
                System.debug('SOARHelper ITBLess12');
            }
               
            okay = processReferral(sr);
            
         } // try
         catch (SOARException se) {
            //forwardEmail('SOAR error: '+se.getMessage()+'; '+se.getStackTraceString(), sr.plainTextBody);
            sr.parseMsg = 'SOAR error: '+se.getMessage()+'; '+se.getStackTraceString();
            updatePartRef(sr.parseMsg, false);     
         } // catch SOARException
         catch (Exception ex) {
            //forwardEmail('SOAR error: '+ex.getMessage()+'; '+ex.getStackTraceString(), sr.plainTextBody);
            sr.parseMsg = 'SOAR error: '+ex.getMessage()+'; '+ex.getStackTraceString();
            updatePartRef(sr.parseMsg, false);     
         } // catch Exception 
      } // for (SoarRef      
    } // processSoarRef
    
    
   // get contact record of referring employee (payroll specialist)
   private static Contact getPayxEmp(String personID, String refempEmail) {
      Contact[] ctList;
      if (String.isNotBlank(personID)){
        ctList = [Select Id, Name, HR_Person_Id__c, Email, Title from Contact Where Account.Name = :UserHelper.PAYCHEX_COMP AND HR_Person_ID__c = :personID]; 
      }
      else                 
      {  ctList = [Select Id, Name, HR_Person_Id__c, Email, Title from Contact Where Account.Name = :UserHelper.PAYCHEX_COMP 
                  AND Email = :refempEmail AND HR_Person_ID__c != null];   }
      if (!ctList.isEmpty()){
        return ctList.get(0);   
      }
      else
      {  
          return null;   
      }
   } // getPayxEmp

   // get user record of referring employee (payroll specialist)
   private static User getPayxUser(String personId) {
      User usr = new UserHelper().getUserByPersonId(personId);
      if (usr != null && usr.Profile.Name == AddUserController.CHATTER_PROFILE) {
         usr = null;
      }         
      return usr;
   } // getPayxUser
    
    // find existing prospect-client 
    private static Boolean findClient(SoarRef sr) {
        System.debug('SOARHelper findClient begin');
		Boolean okay = true;
        ctct = null;
        
        acct = getAcctInfo(sr.id);
        System.debug('SOARHelper findClient getAcctInfo acct: '+(acct==null?'null':acct.Id));
        If(acct == null){
        	okay = false;    
        }
        System.debug('SOARHelper findClient okay: '+okay );        
        return okay;
    } // findClient
    
  private static Account getClient(String clientId){
    List<Account> acctList = new List<Account>();
    if(clientId!=null && String.isNotBlank(clientId)){
    	Decimal busId = 0;
        busId = !clientId.contains('-') ? decimal.valueOf(clientId) : 0;
      	acctList = [Select Id,AccountNumber,OwnerId,Owner.Sales_Division__c from Account where AccountNumber = :clientId OR Bis_ID__c = :busId];
    }
    if (!acctList.isEmpty())
      	return acctList.get(0);   
    else
      	return null;   
  }
  
    // create contact - using this method to find the contact with DuplicateHelper
    private static Contact createContact (SoarRef sr){
        system.debug('SOARHelper createContact begin sr.FirstName: '+sr.FirstName+' sr.LastName: '+sr.LastName);
        Schema.RecordTypeInfo ctctrt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);  
        Id existingCtctId = null;
        ZipCheckOwner.accountIdsProcessedSet.clear();       // do this so contact gets correct owner (same as account)
 
        Contact newCtct = new Contact(recordtypeId = ctctrt.getRecordTypeId()
                                        ,FirstName = sr.firstName
                                        ,LastName = sr.lastName
                                        ,Phone = sr.phoneNumber
                                        ,AccountId = sr.id
                                        ,AccountId__c = sr.Id
                                        ,Email = sr.contactEmail
                                        ,DoNotCall = false
                                        ,HasOptedOutOfEmail = false
                                        ,Use_Zip_Assignment_Rules__c = true
                                        ,Sales_Contact__c = true);
        system.debug('SOARHelper createContact newCtct: '+newCtct);
        DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Contact[]{newCtct}); 
        // should only be one record returned
        DuplicateHelper.DupeResult result = results[0];
        system.debug('SOARHelper createContact result: '+result);
        if (!result.ctctIds.isEmpty()) {
           system.debug('SOARHelper createContact result.ctctIds: '+result.ctctIds);
           // make sure the contacts are for the right account
           Contact[] ctcts = [Select Id, Name, AccountId, Sales_Contact__c from Contact where Id in :result.ctctIds and AccountId=:sr.Id order by CreatedDate desc];
           system.debug('SOARHelper createContact ctcts: '+ctcts); 
           if (!ctcts.isEmpty()) {
                Contact updateSalesCtct = ctcts[0];   
                // ensure the contact being used is a Sales Contact so sales reps can see it
                if(updateSalesCtct.Sales_Contact__c == false){
                    updateSalesCtct.Sales_Contact__c = true;
                    update updateSalesCtct;
                    system.debug('SOARHelper createContact after update Sales Contact to True');
                }
                existingCtctId = ctcts[0].Id;
           }
        }
        
        if (existingCtctId == null){ 
           try {
               Database.DMLOptions dml = DuplicateHelper.getDmlSkipCheck();
               Database.insert(newCtct,dml);
               existingCtctId = newCtct.Id;
           } catch (exception e){
              String errmsg = e.getMessage();
              if (errmsg.containsIgnoreCase('Email')){
                newCtct.email = null;
                    insert newCtct;
               }
              else
              {   sr.parseMsg = ' Bad insert of new contact. ';
                  updatePartRef(sr.parseMsg, false); 
                  throw new SOARException(' Bad insert of new contact, msg='+e.getMessage());
              }
            } // catch
        } 

        newCtct = [Select Id, Name, FirstName,LastName, Phone, Owner.Id, recordtypeId, AccountId, Email 
               from Contact where Id = :newCtct.Id or Id = :existingCtctId];  // requery just in case               

        return newCtct;
    } // createContact
    
   // create account
   private static Account createAcct  (SoarRef sr, Account onAcct) {
          // default record type
          String recordTypeName = RecordTypeHelper.CORE_ACCOUNT;
          sr.salesOrg = 'PAY';

          System.debug('SOARHelper.createAcct sr.employeeCount = ' + sr.employeeCount);
          if (sr.platform.startsWithIgnoreCase('MMS')           // sr.platform == 'MMS - 50+ EE\'s') 
             || (onAcct == null && integer.valueOf(sr.employeeCount) > 49)
             || (onAcct != null && (onAcct.Owner.Sales_Org__c.startsWithIgnoreCase('MMS') || onAcct.Owner.Profile.Name.startsWithIgnoreCase('MMS')))) {
             recordTypeName = RecordTypeHelper.MMS_ACCOUNT;
             sr.salesOrg = 'MMS';
          } 
          else if(sr.platform.contains('PEO'))  {
          //   recordTypeName = Label.RT_Prospect_Acct;
             sr.salesOrg = 'MMS';
          }
          
          Schema.RecordTypeInfo acctRt = RecordTypeHelper.getRecordType(recordTypeName, ObjectHelper.OBJECT_ACCOUNT); 
          Id rcdTypeId = acctRt.getRecordTypeId();
          Id existingAcctId = null; 
          
          Account newAcct = new Account(recordtypeId = rcdTypeId
                                            ,Type = 'Prospect'
                                            ,Name = sr.companyName
                                            ,BillingStreet = sr.address
                                            ,BillingCity = sr.city
                                            ,BillingState = sr.state
                                            ,BillingPostalCode = sr.zipCode
                                            ,Phone = sr.phoneNumber
                                            ,Employees__c = Integer.valueOf(sr.employeeCount)
                                            ,NumberOfEmployees = Integer.valueOf(sr.employeeCount)
                                            ,Federal_ID_Number__c = sr.federalId
                                            ,Use_Zip_Assignment_Rules__c = false
                                            ,AccountNumber=sr.clientNumber);//JSH 01/14/2020 adding to try and better match when more than one clt record exists
                
          if (onAcct == null ){      //  || recordTypeName == RecordTypeHelper.CORE_ACCOUNT)       
              System.debug('SOARHelper createAcct using zip assignment rules for new acct, newAcct.Employees__c = ' + newAcct.Employees__c);
              DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Account[]{newAcct}); 
              // should only be one record returned
              DuplicateHelper.DupeResult result = results[0];
              if (!result.acctIds.isEmpty()) {
                 existingAcctId = result.acctIds[0];
                 newAcct = getAcctInfo(existingAcctId);
              }
              
              if (existingAcctId == null){
                  try{
                      newAcct.Use_Zip_Assignment_Rules__c = true;
                      // so it doesn't hit the duplication rules
                      Database.DMLOptions dml = DuplicateHelper.getDmlSkipCheck();
                      Database.insert(newAcct,dml);   
                      newAcct = getAcctInfo(newAcct.Id);
                     
                      User newOwnerUser = null;
                      UserHelper uh = new UserHelper();
                      newOwnerUser = uh.getUserById(newAcct.OwnerId);
                      Boolean ownerIsSystemAdmin = (newOwnerUser.Profile.Name == Utilities.PROF_SYS_ADMIN);
                      System.debug('SOARHelper createAcct newOwner='+newAcct.OwnerId+'-'+newOwnerUser.Name+' isSA='+ownerIsSystemAdmin);                      
                      if (newAcct.Owner.Name == 'PO Box' || newAcct.OwnerId == UserInfo.getUserId() || ownerIsSystemAdmin){  // || newAcct.Owner.Name.contains('Open') )     // zip code not in table so new account was assigned to running user (me)
                         System.debug('SOARHelper createAcct owner is PO Box or same as running user - looking for default owner');
                         User defaultUser = getDefaultUser(sr, newAcct,  (sr.isInternational?'International':'Unknown Rep'));
                         System.debug('SOARHelper chg newAcct owner to defaultUser='+(defaultUser==null?'null':defaultUser.Name));                      
                         newAcct.OwnerId = defaultUser.Id;          
                         update newAcct;                 
                      }                   
                  } // try
                  catch (exception e)   // catch DupeBlocker exception, should never get here
                  {     sr.parseMsg = ' Bad insert of new account for non-AddOn acct. '+ e.getMessage();
                        updatePartRef(sr.parseMsg, false); 
                        throw new SOARException(' Bad insert of new prospect-client for non-AddOn acct,msg-'+e.getMessage());  
                  }
              }                           
              System.debug('SOARHelper createAcct non-AddOn, newAcct id='+newAcct.Id+' ownerId='+newAcct.OwnerId);
          } // if (onAcct==null)
          else // is an AddOnClient       
          {     // think about putting all these in a field set so dont have to hard code them
                newAcct.OwnerId = onAcct.OwnerId;
                newAcct.Hold_Out__c = onAcct.Hold_Out__c;
                newAcct.Hold_Out_Expiration__c = onAcct.Hold_Out_Expiration__c;
                newAcct.Permanent_Hold_Out_Description__c = onAcct.Permanent_Hold_Out_Description__c;
                newAcct.HRS_Account_Owner__c = onAcct.HRS_Account_Owner__c;
                newAcct.HRS_Hold_Out__c = onAcct.HRS_Hold_Out__c;
                newAcct.HRS_Hold_Out_Expiration__c = onAcct.HRS_Hold_Out_Expiration__c;              
                newAcct.Premier_PBS_Account_Owner__c = onAcct.Premier_PBS_Account_Owner__c;
                newAcct.Premier_PBS_Hold_Out__c = onAcct.Premier_PBS_Hold_Out__c;
                newAcct.Premier_PBS_Hold_Out_Expiration__c = onAcct.Premier_PBS_Hold_Out_Expiration__c;
                newAcct.PEO_ASO_Permanent_Hold_Out_Description__c = onAcct.PEO_ASO_Permanent_Hold_Out_Description__c  ;
                newAcct.HNBF_Account_Owner__c = onAcct.HNBF_Account_Owner__c;
                newAcct.HNBF_Hold_Out__c = onAcct.HNBF_Hold_Out__c;
                newAcct.HNBF_Hold_Out_Expiration__c = onAcct.HNBF_Hold_Out_Expiration__c;
                newAcct.HNBF_Permanent_Hold_Out_Description__c = onAcct.HNBF_Permanent_Hold_Out_Description__c;
                newAcct.BenAdmin_Hold_Out__c = onAcct.BenAdmin_Hold_Out__c;
                newAcct.BenAdmin_Hold_Out_Expiration__c = onAcct.BenAdmin_Hold_Out_Expiration__c;
                newAcct.BenAdmin_Hold_Out_Reason__c = onAcct.BenAdmin_Hold_Out_Reason__c;
                newAcct.MS_Hold_Out__c = onAcct.MS_Hold_Out__c;
                newAcct.MS_Hold_Out_Expiration__c = onAcct.MS_Hold_Out_Expiration__c;
                newAcct.Federal_ID_Number__c = (newAcct.Federal_ID_Number__c == null ? sr.federalId : newAcct.Federal_ID_Number__c);
                if (onAcct.isChild__c) {
                    newAcct.SalesParent__c = onAcct.SalesParent__c;
                }
                else {
                    newAcct.SalesParent__c = onAcct.id;
                }
                
                //CRMfusionDBR101.DB_Api.preventBlocking();
                Database.DMLOptions dml = DuplicateHelper.getDmlSkipCheck();
                try {              
                    Database.insert(newAcct,dml);   
                    //insert newAcct;
                }
                catch (exception e1)
                {       sr.parseMsg = ' Bad insert of new account for AddOn acct. '+e1.getMessage();
                        updatePartRef(sr.parseMsg, false); 
                        throw new SOARException(' Bad insert of new prospect-client for AddOn acct,msg-'+e1.getMessage());  
                }  
          } // else
          
          return newAcct;
    }  // createAcct
    
   public static Boolean processReferral(SoarRef sr) {    
      system.debug ('SOARHelper.processReferral, inside'); 
      Boolean okay = true;      
      
      // use product to find SoarProductMapping and referral partner
      spm = getSoarProductMapping(sr,acct);
      system.debug ('SOARHelper.processReferral, spm: ' + (spm != null ? spm.Name : 'Not Found')); 
      sr.zipSegmentName = spm.ZipSegment__c;      
      StringHelper.addToProcessNotes(partRef,'processReferral spm='+(spm != null ? spm.Name : 'Not Found'+' zipSegmentName='+(sr.zipSegmentName != null ? sr.zipSegmentName : 'no segment')));
       
      Referral_Partner__c rp;

       if (spm.Sales_Org__c == 'ADV'){
         rp = salesOrgRefPartMap.get(UserHelper.SO_CORE);   
      }
      else
      {  
          rp = salesOrgRefPartMap.get(spm.sales_org__c); 
      } 
      system.debug ('SOARHelper.processReferral, rp: ' + rp); 
      // fix referral partner, if PAY but is MMS account, change ref partner to MMS    
      if (rp.Name == UserHelper.SO_CORE && (acct.RecordType.Name.contains(UserHelper.SO_MMS) || (acct.isChild__c && acct.SalesParent__r.RecordType.Name.contains(UserHelper.SO_MMS)))){
        rp = salesOrgRefPartMap.get(UserHelper.SO_MMS);  
      }
      
      String rpProduct = rp.Name;    // used to get correct owner for opty
      StringHelper.addToProcessNotes(partRef,' rpProduct='+rpProduct);
      system.debug ('SOARHelper.processReferral, rp.Name: ' + rpProduct); 
      
      // create new referral record
      ReferralWrapper rw = new ReferralWrapper();
      rw.ref.Referring_User__c = (referringUser == null ? null : referringUser.Id);           
      
       /*
        * SFDC-2703 (US2)
        * Set the IsAncillary__c field value of Referral Partner to 'true' if the Opportunity_Type__c 
        * in the SOAR Product Mapping is set to 'Ancillary'.
        * This will cause Payroll_Unit__c set to true when creating Opportunity in handleApproved().
        */        
      rw.ref.IsAncillary__c = (spm.Opportunity_Type__c == 'Ancillary' ? true : false);
       
      rw.ref.Email__c = referringEmp.Email;               // edited in ReferralMethods.checkEmail to contact.email        
      rw.ref.ReferFromContact__c = referringEmp.Id;
      rw.ref.Referring_Employee_Title__c = referringEmp.Title;
      rw.ref.Account__c = sr.id;
      rw.ref.SourceContact__c = ctct.Id;                  // prospect-client contact 
      rw.ref.No_Referring_Opty_Needed__c = true;  
      rw.ref.Referral_Contact__c = null;
      rw.ref.Referral_Source__c = 'SOAR';
      rw.ref.Started_From__c = 'Contact';    
      rw.ref.Referral_Partner__c = rp.Id;
      rw.ref.Referral_Partner__r = rp;
      if (sr.isAdvantage){
           rw.ref.Notes__c = 'Advantage - ' + sr.notes; 
      }
      else if (sr.product == 'New Client' && sr.platform == 'ASO/PEO'){
           rw.ref.Notes__c = 'ASO/PEO - ' + sr.notes;   
      }
      else{
           rw.ref.Notes__c = sr.product + ' - ' + sr.notes;   
      }        
      rw.ref.SellingLeadSource__c = Label.LeadSource_Internal_Soar;
      if (sr.currClient  == 'Yes' && sr.addOnClient == 'Yes'){  
        rw.ref.SellingLeadSource__c = Label.LeadSource_Internal_SOAR_Id;  
      }
      if (sr.currClient  == 'Yes' && sr.addOnClient == 'No' && sr.product != 'New Client'){
        rw.ref.SellingLeadSource__c = Label.LeadSource_Internal_SOAR_Prod;  
      }
      
      setReferralName(rw, rp.Name, acct);
      rw.lockTitle = true;
      rw.ref.Send_Email__c = false;
      rw.ref.Status__c = 'Referral Sent';        
                    
      if(String.isBlank(spm.Assigned_Queue__c)){
            setReferralOwner(rw,rp,acct,sr);
      }
      
      system.debug ('SOARHelper.processReferral, rw.ref.HR_Person_Id__c: ' + rw.ref.HR_Person_Id__c);
      // look up paychex contact and user rcd for the optyOwner, person getting the referral 
       if(rw.ref.HR_Person_Id__c != null){
           Contact[] payxCtct = [Select Id, Name, HR_Person_Id__c from Contact  Where HR_Person_Id__c = :rw.ref.HR_Person_Id__c];       
           rw.ref.Contact__c = (payxCtct.size() > 0 ? payxCtct.get(0).Id : null);                          
           rw.ref.HR_Person_Id__c = (payxCtct.size() > 0 ? payxCtct.get(0).HR_Person_Id__c : null);  
           system.debug ('SOARHelper.processReferral, payxCtct: ' +payxCtct); 
       }
       Id queueId = (String.isNotBlank(spm.Assigned_Queue__c) && (new UserHelper()).getQueue(spm.Assigned_Queue__c) != null) ? (new UserHelper()).getQueue(spm.Assigned_Queue__c).Id: null;
       rw.ref.OwnerId = (String.isNotBlank(spm.Assigned_Queue__c) && queueId!= null) ? queueId : (referringUser == null ? rw.ref.User__c : referringUser.Id);          
           
       Id sellingOptyId = checkDuplicateReferral(rw, sr);
       system.debug ('SOARHelper.processReferral, sellingOptyId: ' +sellingOptyId); 
       if (sellingOptyId != null){
           rw.ref.Status__c = 'SOAR Duplicate';
           Database.insert(rw.ref, false);
           StringHelper.addToProcessNotes(partRef,'SOAR Duplicate');
           //sendDupEmail(rw, sr);
       }
       else {   
           System.debug('processReferral has Ref='+(rw.ref != null)+' has partRef='+(partRef != null));
           rw.ref.ProcessNotes__c = (partRef != null ? partRef.ProcessNotes__c : null);
           Database.Saveresult rslt = Database.insert(rw.ref,false);
           List<Id> refIds = new List<Id>();
           if (rslt.isSuccess()){
               refIds.add(rslt.getId()); 
               System.debug('processReferral refId: '+rslt.getId());  
           }           
           else
           {  Database.Error[] err = rslt.getErrors(); 
            sr.parseMsg = 'Bad insert of new referral';
            updatePartRef(sr.parseMsg, false);                       
            Throw new SOARException('bad insert of new referral-'+err.get(0).getMessage());
           }
         
           //system.debug ('SOARHelper.processReferral, before creating new Opportunity: ' + refIds);          
           ReferralMethods.handleApproved(refIds);      // creates selling opty
           Referral__c newRef = [Select Id, Selling_Opportunity__r.Id 
                                 from Referral__c
                                 where Id = :refIds.get(0)];
           sellingOptyId = newRef.Selling_Opportunity__r.Id; 
           system.debug ('SOARHelper.processReferral, sellingOptyId (after handleApproved, where new Opportunity is created): ' +sellingOptyId);
       } // else 
        
       // update SOAR product list on selling oppty
       Opportunity sellOpty = new Opportunity();
       if(spm.Opportunity_Type__c != null) {
           sellOpty = new Opportunity(Id=sellingOptyId, SOAR_referral_products__c=sr.product, SOAR_Region__c = sr.region, SOAR_Id__c = sr.soarId, OpportunityType__c = spm.Opportunity_Type__c);
       }else{
           sellOpty = new Opportunity(Id=sellingOptyId, SOAR_referral_products__c=sr.product, SOAR_Region__c = sr.region, SOAR_Id__c = sr.soarId);
       }
       
       system.debug ('SOARHelper sellOpty data. OpportunityType__c: ' + sellOpty.OpportunityType__c + ' sellingOptyId: ' + sellingOptyId +' sr.product: ' + sr.product + ' sr.region: ' + sr.region + ' sr.soarId: ' + sr.soarId); 
       update sellOpty;
       
       // update Partner Referral
       partRef.Account__c = acct.Id;
       system.debug ('SOARHelper update Partner Referral acct.Id: '+acct.Id);
       partRef.Contact__c = ctct.Id;
       system.debug ('SOARHelper update Partner Referral ctct.Id: '+ctct.Id);
       partRef.Referral__c = rw.ref.Id;
       system.debug ('SOARHelper update Partner Referral rw.ref.Id: '+rw.ref.Id);
       updatePartRef('Successful', true);

       return okay;
    } // processReferral
    
    public static void setReferralName(ReferralWrapper rw, String rpName, Account acct) {
      String tempName = new UserHelper().getProdTranslation(rpName);
      system.debug ('SOARHelper.processReferral, tempName: ' + tempName); 
       
      if (tempName == null){ 
           tempName = rpName;
      }              
      rw.ref.Name = tempName;
      if (acct != null){
           rw.ref.Name = (acct.Name.length() > (79-tempName.length()) ? acct.Name.substring(0,79-tempName.length())+'-'+rw.ref.Name : acct.Name+'-'+rw.ref.Name);   
      }                

    } // setReferralName
    
    // this exception is used to throw missing data error messages
    public class SOARException extends Exception {}
 
    public static void setReferralOwner(ReferralWrapper rw, Referral_Partner__c rp, Account akkt, SoarRef sr) { //, SoarProductMapping__c spm) {
      User optyOwner = null;        

      if (spm==null&&((sr.isAdvantage) || (addonAcct != null && addonAcct.Type == 'Advantage Client'))) 
      {   sr.salesOrg = UserHelper.SO_ADV;      }
      else
      { sr.salesOrg = rp.Name;  }       // set salesOrg from ref Part which came from SoarProductMapping  
      StringHelper.addToProcessNotes(partRef,'sr.salesOrg='+sr.salesOrg);
      User refUser = null;
      //check if SMB Account Owner should be used
      if(spm.Leverage_Current_Client_Owner__c && sr.isCurrentClientReferral){
      	if(curClientRef!=null){
        	if(Label.SMB_Channel_Divisions.contains(curClientRef.Owner.Sales_Division__c)){
             	refUser = new UserHelper().getUserById(curClientRef.OwnerId);
             	rw.ref.User__c = refUser.Id;
             	StringHelper.addToProcessNotes(partRef,'Referral Owner: Account Owner from referring client: '+curClientRef.OwnerId);
        	}
      	}
       	else{
          	sr.parseMsg = ' Invalid referring client. ';
          	updatePartRef(sr.parseMsg, false); 
          	Throw new SOARException(' Invalid referring clientId='+sr.currentClientReferralId);  
        }
      }
      // see if there is a default user on the Soar Product Mapping record
       if (refUser == null && spm.Default_Rep_HR_Person_ID__c != null || rp.Default_User__c != null) {
         UserHelper uh = new UserHelper();
         refUser = (spm.Default_Rep_HR_Person_ID__c != null ? uh.getUserByPersonId(spm.Default_Rep_HR_Person_ID__c) : uh.getUserById(rp.Default_User__c));
         refUser = checkUser(refUser);
         StringHelper.addToProcessNotes(partRef,'Referral Owner: Default user from Soar Product Mapping: '+spm.Default_Rep_HR_Person_ID__c);
      }
       if(refUser == null && String.isNotBlank(spm.Check_Hold_out__c)){
           if(akkt.hold_out__c && akkt.Permanent_Hold_Out_Description__c != null && akkt.Permanent_Hold_Out_Description__c.equals(spm.Check_Hold_out__c)){
               refUser = new UserHelper().getUserById(akkt.OwnerId);
               rw.ref.User__c = refUser.Id; 
               rw.ref.HR_Person_Id__c = refUser.HR_Person_Id__c;
               StringHelper.addToProcessNotes(partRef,'Referral Owner: Account Owner from HoldOut: '+akkt.OwnerId);
           }
       }
             
      ZipWrapper zipWrap = null;
      //String zipCode = (String.IsBlank(akkt.Owner_ZipCode__c) ? sr.zipCode : akkt.Owner_ZipCode__c);
      String zipCode;
       
      if (akkt.isChild__c) {
           zipCode = akkt.SalesParent__r.Owner_Zip_Code__c;
           akkt.Employees__c = akkt.SalesParent__r.NumberOfEmployees;
           akkt.NumberOfEmployees = akkt.SalesParent__r.NumberOfEmployees;
      }// end if (akkt.isChild__c)
      else
      {    zipCode = (String.IsBlank(akkt.Owner_ZipCode__c) ? sr.zipCode : akkt.Owner_ZipCode__c);  }
       
       /*APR0110021 ancillary sales for cssr clients should go to cssr. new clients or addons should go to the territory rep*/
       //APR0125222 updating to only set if the SOAR mapping doesnt have a default user 
       if(spm.Opportunity_Type__c == 'Ancillary' && akkt.CSSR_Segment__c && !akkt.isChild__c && spm.Default_Rep_HR_Person_ID__c == null){
           refUser = akkt.Owner; 
           refUser = checkUser(refUser); 
           StringHelper.addToProcessNotes(partRef,'Referral Owner: Default user set for CSSR: '+spm.Default_Rep_HR_Person_ID__c);
        }
       
      if (refUser == null) {
          //SOAR Fix
         if(spm.Force_Zip_Segment__c && String.isNotBlank(sr.zipSegmentName)){
            zipWrap = ZipCodeLookupController.getZipAssignment(zipCode, sr.salesOrg, akkt, sr.zipSegmentName,true);		  
		  }else{			  
          zipWrap = ZipCodeLookupController.getZipAssignment(zipCode, sr.salesOrg, akkt, sr.zipSegmentName); 
		  }
          StringHelper.addToProcessNotes(partRef, 'Searching for refUser zipCode='+zipCode+' salesOrg='+sr.salesOrg+' segmentName='+sr.zipSegmentName+' matchFound='+(zipWrap != null));
          //if there's no match for the specific zip segment called out, try to find a match without the segment.  trying to account for Tier1/Tier2
          System.debug('SOARHelper zipWrap after searching for refUser zipCode '+zipWrap);
          if(zipWrap==null && ((sr.salesOrg == 'PAY' && String.isNotBlank(sr.zipSegmentName)) || String.isNotBlank(spm.Fallback_Sales_Org__c)) ){
              String salesOrg = (String.isNotBlank(spm.Fallback_Sales_Org__c) ? spm.Fallback_Sales_Org__c : sr.salesOrg);
              
              zipWrap = ZipCodeLookupController.getZipAssignment(zipCode, salesOrg, akkt, null);
              if (salesOrg != sr.salesOrg) {
                  Referral_Partner__c newRp = salesOrgRefPartMap.get(salesOrg);
                  if (newRp != null) {
                      rw.ref.Referral_Partner__c = newRp.Id;
                      rw.ref.Referral_Partner__r = newRp;
                      rw.ref.ReferralPartnerName__c = newRp.Name;
                      setReferralName(rw, newRp.Name,  acct);
                  } // newRp != null
              } // salesOrg != sr.salesOrg
          }
          
         // only use owners from account if there is HoldOut, otherwise get owner from zip wrapper 
         // use parent account info if a child account         
         if (sr.salesOrg != 'ADV' && !spm.Override_hold_out__c){
            String holdOutFieldName = ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT, sr.salesOrg);      
             if (holdOutFieldName != null) {                   
                if ((Boolean)akkt.get(holdOutFieldName)) {                  
                      refUser = ReferralController.getAcctOwner(rp.Name, akkt, false);                                         
                      refUser = checkUser(refUser); 
                      System.debug('SOARHelper refUser from holdout ');
                } // if ((Boolean)akkt.get(holdOutFieldName))
             } // if (holdOutFieldName != null)
         } // if (sr.salesOrg!='ADV')
      } // if (refUser == null)
       
      if ((refUser == null || 
          (sr.salesOrg == 'PAY' && akkt.recordtype.name == RecordTypeHelper.MMS_ACCOUNT) || 
          (sr.salesOrg == 'MMS' && akkt.recordtype.name == RecordTypeHelper.CORE_ACCOUNT))
            && zipWrap != null){
          refUser = checkUser(zipWrap.usr); 
          System.debug('SOARHelper refUser from zipwrap '+refUser);
          StringHelper.addToProcessNotes(partRef,'Referral Owner: from zipwrap.zipSeg: '+(zipWrap.zipSeg != null ? zipWrap.zipSeg.Name : null));
          rw.ref.ZipSegment__c = (zipWrap.zipSeg != null ? zipWrap.zipSeg.Name : null);       
      }
      
      //if could not find user based on account owner with hold out or zip assignment go get default user from Unknown Rep custom setting entry for SalesOrg, this 
      //can potentially change the opportunity type being set for the product since it is using unknown rep entry - you will see spm.Opportunity_Type__c 
      //and spm.Name change compared to the values used earlier in the code
      if (refUser == null) {
         System.debug('SOARHelper refUser is null before getDefaultUser'); 
         refUser = getDefaultUser(sr, acct, (sr.isInternational?'International':'Unknown Rep')); 
         StringHelper.addToProcessNotes(partRef,'Referral Owner: from Unknown Rep: '); 
      }
      
      //System.debug('SOARHelper refUser before refUser != null '+ refUser + ' spm.Opportunity_Type__c: ' + spm.Opportunity_Type__c + ' spm.Name: ' + spm.Name);  
      if (refUser != null) {          
         refUser = new UserHelper().getUserById(refUser.Id);
         System.debug('SOARHelper refUser from UserHelper '+refUser); 
         rw.ref.User__c = refUser.Id; 
         rw.ref.HR_Person_Id__c = refUser.HR_Person_Id__c;
      }
            
      if (rw.ref.DSA__c == null && refUser != null)     
      {  rw.ref.DSA__c = refUser.DSA_FSS__c;    }
      
      if (rw.ref.DSM__c == null && refUser != null && !spm.Exclude_DSM__c) 
      {  rw.ref.DSM__c = refUser.ManagerId; }
   } // setReferralOwner
   
   // if not blank, no person id, or an unassigned user.
   public static User checkUser(User p_usr) {
      System.debug('SOARHelper checkUser p_usr '+p_usr);  
      User usr = (p_usr != null && (!p_usr.isActive || String.IsBlank(p_usr.HR_Person_Id__c) || UserHelper.UNASSIGNED_SET.contains(p_usr.HR_Person_Id__c))) ? null : p_usr;
      System.debug('SOARHelper checkUser usr '+usr); 
      return usr;
   } // checkUser
         
   private static List<SoarProductMapping__c> soarProductMapList = null;        
   private static Map<String,Referral_Partner__c> salesOrgRefPartMap = null;    // <sales_org, Referral_Partner__c>
   
   private static void getProductsAndRefPartners() {    
        soarProductMapList = SoarProductMapping__c.getall().values();           
        Referral_Partner__c[] refPartners = ReferralQueries.selectRefPartners(PARTNER_SOAR,null);

        salesOrgRefPartMap = new Map<String,Referral_Partner__c>();     
        for (Referral_Partner__c refPart : refPartners) 
        {   salesOrgRefPartMap.put(refPart.Name, refPart);  }

        return;     
   } // fillinMaps
   
   /* using SoarRef info and possibly account info, find the right SoarProductMapping record */
   public static SoarProductMapping__c getSoarProductMapping(SoarRef sr, Account act) {

        List<SoarProductMapping__c> tempSpmList = new List<SoarProductMapping__c>();
        SoarProductMapping__c matchedSPM;
       
        System.debug('SOARHelper sr.product: ' + sr.product);
        for (SoarProductMapping__c xspm: soarProductMapList){
            //System.debug('SOARHelper xspm.Product__c ' + xspm.Product__c + ' sr.product: ' + sr.product);
            if (xspm.Product__c == sr.product) {
                   tempSpmList.add(xspm);  
           }
        } // for SoarProductMapping__c
        
        if (tempSpmList.isEmpty() || tempSpmList.size() == 0)
        {   return null;    }
        else if (tempSpmList.size() == 1)
        {   matchedSPM = tempSpmList.get(0);    }
        else       
        {   
            System.debug('SOARHelper.getSoarProductMapping, the sr.employeeCount = ' + sr.employeeCount);
            System.debug('SOARHelper.getSoarProductMapping, the act.NumberOfEmployees = ' + act.NumberOfEmployees);
            
            //Integer emp = (sr.employeeCount != null ? integer.valueOf(sr.employeeCount) : act.NumberOfEmployees);
            
            /*
             * SFDC-2703 (US2)
             * 'act' always refers to the new account. If it is a AddOn Client/account then it's isChild__c property will be set to true and
             * SalesParent__r set to the existing parent account.
             * 
             * act.NumberOfEmployees is set to sr.employeeCount when we create a new account in createAcct().
             * 
             * Basic logic to calcualte the employee count is that 
             *          a) if it is a parent acccount (without AddOn Client), then use the total number of employee count.
             *          b) if it is a child account (with AddOn Client), then use the parent's total number of employee count + the employee count that was in the SOAR message.
             */
            Integer emp = 0;
            if (act.isChild__c) {
                System.debug('SOARHelper.getSoarProductMapping, This is child account (with AddOnClient). act.SalesParent__r.NumberOfEmployees = ' + act.SalesParent__r.NumberOfEmployees + ',  act.NumberOfEmployees = ' + act.NumberOfEmployees);
                emp = act.SalesParent__r.NumberOfEmployees + Integer.valueOf(act.NumberOfEmployees);
            }
            else {
                System.debug('SOARHelper.getSoarProductMapping, This is parent account (without AddOnClient). act.NumberOfEmployees = ' + act.NumberOfEmployees);
                emp = act.NumberOfEmployees;
            }
            System.debug('SOARHelper.getSoarProductMapping, the emp = ' + emp);
            
            Boolean matchedADV = false;
            Boolean matchedPlatform = false;
            Boolean spmMatchFound = false;
            
            /*
             * The highest precedence is given to the following criteria when selecting Soar Product Mapping (SPM).
             * Once, the SPM is selected, no other criteria will be run.
             */
            for (SoarProductMapping__c tempSpm:tempSpmList)
            {   
                
                /*
                 * SFDC-2703 (US4)
                 * 
                 * Business Logic:
                 *          a) If Account Type is populated in SOAR Product Mapping and it matches the value in Type field of the Parent Account
                 *              i) Then use this SOAR Product Mapping, regardless of number of employees.
                 *              Note: Default Rep from this SOAR Product Mapping will be assigned to the newly created Oppourtunity. So, we want to
                 *              make sure that the Default Rep is not empty.
                 * 
                 */                
                if(tempSpm.Account_Type__c != null) {
                    //System.debug('SOARHelper.getSoarProductMapping, tempSpm.Account_Type__c: ' + tempSpm.Account_Type__c + ', tempSpm.Default_Rep_HR_Person_ID__c: ' + tempSpm.Default_Rep_HR_Person_ID__c);
                    // exsiting parent account and new child (add on client) account.
                    if (act.isChild__c && act.SalesParent__r.Type != null && tempSpm.Account_Type__c == act.SalesParent__r.Type) {
                        System.debug('SOARHelper.getSoarProductMapping, Account is AddOnClient. act.SalesParent__r.Type: ' + act.SalesParent__r.Type);
                        matchedSPM = tempSpm;
                        spmMatchFound = true;
                        break;
                    }
                    // existing parent account
                    else if (!act.isChild__c && act.Type != null && tempSpm.Account_Type__c == act.Type) { 
                        System.debug('SOARHelper.getSoarProductMapping, Account is not AddOnClient. act.Type: ' + act.Type);
                        matchedSPM = tempSpm;
                        spmMatchFound = true;
                        break;
                    }
                }
                /*APR0110021 ancillary sales for cssr clients should go to cssr  - I don't think this is actually necessary.  No matter what spm is found we are setting ownership
                 *  via the account owner either way
                if(tempSpm != null && act != null &&  tempSpm.Opportunity_Type__c == 'Ancillary' && act.CSSR_Segment__c && !act.isChild__c && tempSpm.Sales_Org__c == 'MMS'){
                       matchedSPM = tempSpm;
                       spmMatchFound = true;
                       break;
                }*/

                /*
                 * SFDC-2703 (US5)
                 * 
                 * Business Logic:
                 * The logic will only be executed if the Default Rep is NOT already being used.
                 * Then, we will leverage the unused Default_Rep_HR_Person_ID__c field to set it to Hold Out Owner.
                 * The Hold Out owner is selected based on the HoldOut_ExpirationDates__c custom settings.
                 * The logic will only be executed on Child Account (i.e. with AddOnClient).
                 */                         
                if(tempSpm.Default_Rep_HR_Person_ID__c == null && act.isChild__c)   {
                    HoldOut_ExpirationDates__c holdOut = holdOutMap.get(tempSpm.Sales_Org__c);
                    //System.debug('SOARHelper.getSoarProductMapping, tempSpm.Sales_Org__c: ' + tempSpm.Sales_Org__c + ', holdOut: ' + holdOut);
                    //System.debug('SOARHelper.getSoarProductMapping, tempSpm.Sales_Org__c: ' + tempSpm.Sales_Org__c);
                    if (holdOut != null) {
                        // get the Values of the Hold Out and correspondng Owner fields from the Parent Account
                        boolean actParentHoldoutVal = (boolean) act.SalesParent__r.get(holdOut.Account_Hold_Out__c);
                        //Id actParentHoldoutOwnerIdVal = (Id) act.SalesParent__r.get(holdOut.Account_Owner__c);
                        //System.debug('SOARHelper.getSoarProductMapping, Account is AddOnClient. actParentHoldoutVal: ' + actParentHoldoutVal);
                        // Only if the Hold Out field is checked/selected/true
                        if (actParentHoldoutVal == true) {
                            User parentOwner = getAcctUser(act.SalesParent__r, holdOut);
                            //User parentOwner = [SELECT Name, HR_Person_Id__c FROM User WHERE Id = :actParentHoldoutOwnerIdVal];
                            System.debug('SOARHelper.getSoarProductMapping, parentOwner.Name=' + (parentOwner != null ? parentOwner.Name : 'Not Found') );
                            if( parentOwner != null)    {
                                tempSpm.Default_Rep_HR_Person_ID__c = parentOwner.HR_Person_Id__c;
                                tempSpm.Default_Rep__c = parentOwner.Name;
                                matchedSPM = tempSpm;
                                spmMatchFound = true;
                                break;
                            }
                        }                
                    }
                }
            } // for tempSpm
            
            /*
             * The second highest precedence is given to the following criteria when selecting Soar Product Mapping (SPM).
             * Once, the SPM is selected, no other follow up criteria will be run.
             */
            if(spmMatchFound == false) {
                for (SoarProductMapping__c tempSpm:tempSpmList)
                {   
                    if (tempSpm.Account_Type__c == null && sr.isAdvantage && tempspm.AdvClient__c  
                        && (tempSpm.Emp_Count_Min__c == null || (emp >= tempSpm.Emp_Count_Min__c && emp <= tempSpm.Emp_Count_Max__c)))
                    {   
                        System.debug('SOARHelper.getSoarProductMapping, sr.isAdvantage: ' + sr.isAdvantage + ', tempspm.AdvClient__c: ' 
                                     + tempspm.AdvClient__c + ', tempSpm.Emp_Count_Min__c: ' + tempSpm.Emp_Count_Min__c + ', tempSpm.Emp_Count_Max__c: ' + tempSpm.Emp_Count_Max__c
                                     + ', emp: ' + emp);  
                        matchedSPM = tempSpm;
                        matchedADV = true;
                        spmMatchFound = true;
                        break;
                    }
                }
            }
      
            /* The third highest precedence is given to the following criteria when selecting Soar Product Mapping (SPM).
             * Once, the SPM is selected, no other follow up criteria will be run.
             * APR0110021 - ignore platform for payroll divisions
             */
            if(spmMatchFound == false) {
                for (SoarProductMapping__c tempSpm:tempSpmList)
                {   
                    if (tempSpm.Account_Type__c == null &&  
                        (tempSpm.Emp_Count_Min__c == null || (emp >= tempSpm.Emp_Count_Min__c && emp <= tempSpm.Emp_Count_Max__c)) &&
                        (!tempSpm.AdvClient__c) &&
                        //((tempSpm.Platform__c != null && sr.platform == tempSpm.Platform__c) || tempSpm.Sales_Org__c == 'PAY' || tempSpm.Sales_Org__c == 'MMS'))
                        (tempSpm.Platform__c != null && sr.platform == tempSpm.Platform__c))
                    { 
                        System.debug('SOARHelper.getSoarProductMapping based on SPM tempSpm.Platform__c: ' + tempSpm.Platform__c + ', sr.platform: ' + sr.platform);                      
                        matchedSPM = tempSpm;
                        matchedPlatform = true;
                        spmMatchFound = true;
                        break;
                    }                   
                }
            }
            
             /*
             * the following criteria uses 'Inside the Base' values when selecting Soar Product Mapping (SPM).
             * Once, the SPM is selected, no other follow up criteria will be run.
             */
            if(spmMatchFound == false) {
                for (SoarProductMapping__c tempSpm:tempSpmList){             
                    if (tempSpm.Account_Type__c == null && (!tempSpm.AdvClient__c) && ((tempSpm.ITBLess12__c == True && sr.ITBLess12 == tempSpm.ITBLess12__c) || (tempSpm.ITBMore12__c == True && sr.ITBMore12 == tempSpm.ITBMore12__c))
                        && (tempSpm.Emp_Count_Min__c == null || (emp >= tempSpm.Emp_Count_Min__c && emp <= tempSpm.Emp_Count_Max__c))){   
                          System.debug('SOARHelper.getSoarProductMapping ITB match: '+tempSpm.Name+' tempSpm.Emp_Count_Min__c: ' + tempSpm.Emp_Count_Min__c + ', tempSpm.Emp_Count_Max__c: ' + tempSpm.Emp_Count_Max__c
                                     + ' tempSpm.ITBLess12__c: ' + tempSpm.ITBLess12__c + ' sr.ITBLess12: ' + sr.ITBLess12 
                                     + ' tempSpm.ITBMore12__c: ' + tempSpm.ITBMore12__c + ' sr.ITBMore12: ' + sr.ITBMore12);
                                       
                            matchedSPM = tempSpm;
                            spmMatchFound = true;
                            break;
                    }
                }
            }

             
            
            /*
             * The forth highest precedence is given to the following criteria when selecting Soar Product Mapping (SPM).
             * Once, the SPM is selected, no other follow up criteria will be run.
             */
            if(spmMatchFound == false) {
                for (SoarProductMapping__c tempSpm:tempSpmList)
                {   
                    if (tempSpm.Account_Type__c == null && !matchedADV && !matchedPlatform && tempSpm.Platform__c == null && !tempSpm.AdvClient__c
                        && (tempSpm.Emp_Count_Min__c == null || (emp >= tempSpm.Emp_Count_Min__c && emp <= tempSpm.Emp_Count_Max__c)))
                    {   
                        System.debug('SOARHelper.getSoarProductMapping, matchedADV: ' + matchedADV + ', matchedPlatform: ' 
                                     + matchedPlatform + ', tempSpm.Platform__c: ' + tempSpm.Platform__c 
                                     + ', tempSpm.AdvClient__c: ' + tempSpm.AdvClient__c + ', tempSpm.Emp_Count_Min__c: ' + tempSpm.Emp_Count_Min__c 
                                     + ', tempSpm.Emp_Count_Max__c: ' + tempSpm.Emp_Count_Max__c + ', emp: ' + emp);  
                        matchedSPM = tempSpm; 
                        spmMatchFound = true;
                        break;
                    }
                }
            }            
        } // else
        System.debug('SOARHelper.getSoarProductMapping, matchedSPM = ' + matchedSPM);
        return matchedSPM;
   } // getSoarProductMapping
   
   public static Map<Id,AccountTeamMember[]> atmMap = new Map<Id,AccountTeamMember[]>();
    
   public static User getAcctUser(Account acct, HoldOut_ExpirationDates__c holdOut) {
      User returnUsr = null;
      if (holdOut != null && String.isNotBlank(holdOut.Account_Owner__c)) {
          Id userId = (Id) acct.get(holdOut.Account_Owner__c);
          returnUsr = (userId != null ? [SELECT Name, HR_Person_Id__c FROM User WHERE Id = :userId] : null);
      } else if (holdOut != null && String.isNotBlank(holdOut.AccountTeamRole__c)) {
          AccountTeamMember[] atms = atmMap.get(acct.Id);
          if (atms == null) {
             atms = [Select Id, UserId, TeamMemberRole, User.Id, User.Name, User.HR_Person_Id__c from AccountTeamMember where AccountId=:acct.Id and User.IsActive=true];
             atmMap.put(acct.Id, atms);
          }
          for (AccountTeamMember atm : atms) {
             if (atm.TeamMemberRole == holdOut.AccountTeamRole__c) {
                returnUsr = atm.User;
                break;
             }
          }
      } // if (holdOut != null
      return returnUsr;
   } // getAcctUser 
       
   // find the Default User for this sales org if PO Box or is open territory or zip is not in table or is International zip
   public static User getDefaultUser(SoarRef sr, Account act, String p_product) {
      User defaultUser;
      Integer emp = (sr.employeeCount != null ? integer.valueOf(sr.employeeCount) : act.NumberOfEmployees);
      system.debug('SOARHelper in getDefaultUser p_product: ' + p_product + 'sr.salesorg: ' + sr.salesorg + ' emp: ' + emp); 
      for (SoarProductMapping__c xspm: soarProductMapList) {
         if (xspm.Product__c == p_product && xspm.Sales_Org__c == sr.salesorg) {
            if (xspm.Emp_Count_Min__c == null || (emp >= xspm.Emp_Count_Min__c && emp <= xspm.Emp_Count_Max__c)) {
               defaultUser = new UserHelper().getUserByPersonId(xspm.Default_Rep_HR_Person_ID__c);
               spm = xspm;
               if (defaultUser != null) {
                  defaultUser.ManagerId = (xspm.Exclude_DSM__c?null:defaultUser.ManagerId);
                  return defaultUser;
               }  
            } // if (xspm.Emp_Count_Min__c == null ||
         } // if (xspm.Product__c == p_product && xspm.Sales_Org__c == sr.salesorg
      } // for SoarProductMapping__c
      return null;
   } // getDefaultUser
   
   
   /* look for referral created within last month with same product for same account */       
   public static Id checkDuplicateReferral(ReferralWrapper rw, SoarRef sr) {
      Date prevDay = Date.today().addDays(-31);       
      Referral__c[] listRefs= [Select Id, Account__r.Id, Referral_Partner__r.Id, Referral_Source__c, Status__c, 
                           Selling_Opportunity__r.Id, Selling_Opportunity__r.SOAR_referral_products__c 
                           from Referral__c 
                           where Referral_Partner__r.Id = :rw.ref.Referral_Partner__r.Id
                           and Referral_Source__c = 'SOAR'
                           and Selling_Opportunity__r.SOAR_referral_products__c = :sr.product
                           and Account__r.Id = :rw.ref.Account__c
                           and CreatedDate > :prevDay];
      System.debug('SOARHelper.checkDuplicateReferral, Referral_Partner__r.Id = ' + rw.ref.Referral_Partner__r.Id + ', Selling_Opportunity__r.SOAR_referral_products__c=' + sr.product +
                  ', Account__r.Id=' + rw.ref.Account__c + ', CreatedDate > ' + prevDay);
       
      if (!listRefs.isEmpty())
      {  return listRefs.get(0).Selling_Opportunity__r.Id ; }
      else
      {  return null;   }                                   
      
   } // checkDuplicateRef
 
   /* get partner referral rcd so can fill in fields */
   public static PartnerReferral__c getPartnerReferral(String partRefId) {
        PartnerReferral__c pr = null;
        if (!String.isBlank(partRefId))
        {   Id prId = (Id)partRefId;
            pr = [Select Id, Account__c, Contact__c, Referral__c, Comments__c, Processed__c, ProcessNotes__c from PartnerReferral__c
                                    where Id = :prId limit 1];
        }       
        return pr;
   } // getPartnerReferral
      
    /** query for account and contact info */
    private static Account getAcctInfo(Id acctId) {  
      System.debug('SOARHelper getAcctInfo begin');  
      Account currAcct = null;      
      List<Id> acctIds = new List<Id>();
      acctIds.add(acctId);
      Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(acctIds);
      if (!acctMap.isEmpty()) 
      {     currAcct = acctMap.get(acctId); }
      System.debug('SOARHelper getAcctInfo currAcct: '+currAcct);
      return currAcct;     
    } 
       
    private static PaychexSettings__c payxSetting = null;
    
    /* method to send incoming email to person listed in custom setting */
    private static void forwardEmail (String p_subj, String p_body) {
      System.debug('SOARHelper forwardEmail, subj='+p_subj);
      System.debug('SOARHelper forwardEmail, body='+p_body);
      if (payxSetting == null)  
        {  payxSetting = PaychexSettings__c.getInstance('SoarForwardErrorEmail');
        if (payxSetting != null && !payxSetting.IsActive__c) 
        {  payxSetting = null;  }
        }
        
        try {
            if (payxSetting != null && payxSetting.Attribute1__c != null)
            {  Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                List<String> addrList = new List<String>();
                addrList = payxSetting.Attribute1__c.split(';');
                mail.setToAddresses(addrList);
                //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
                mail.setSubject (p_subj);
                mail.setPlainTextBody(p_body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        } // try
        catch (Exception ex) {
            if (payxSetting != null && payxSetting.Attribute1__c != null)
            {  Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                List<String> addrList = new List<String>();
                addrList = payxSetting.Attribute1__c.split(';');
                mail.setToAddresses(addrList);
                //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
                mail.setSubject('Problem with Soar email');
                mail.setPlainTextBody('A Soar email was just received but it had incomplete data or was missing the SFDC ID. \n\n'+p_body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } // if
        } // catch   
              
    } // forwardEmail
    
   /* code to parse an email of just plain text instead of html*/
   public static SoarRef parseXml(String toParse){ 
       SoarRef sr = new SoarRef();
       System.debug('SOARHelper here at parseXml');    
       sr.parseMsg = 'Success';
       String errMsg = '';
       try{
           toParse = toParse.replaceAll('&', '&amp;');
           Map<String, String> tempParse = new Map<String, String>();
           sr.plainTextBody = toParse;
           toParse = fixNotes(toParse);
           DOM.Document doc = new DOM.Document();
           try {
               doc.load(toParse);
               DOM.Xmlnode root = doc.getRootElement();
               tempParse = walkthrough(root, tempParse);     
               sr.Id = tempParse.get('ID');
               sr.EEEmail = tempParse.get('EEEmail');
               sr.personID = tempParse.get('PersonID');
               sr.bis = tempParse.get('BIS');           
               sr.currClient = ((sr.bis == null || sr.bis.length() == 0)? 'No' : 'Yes');    // leadsource change
               sr.costCenter = tempParse.get('CostCenter');
               sr.clientNumber = tempParse.get('ClientNumber');
               sr.companyName =  tempParse.get('CompanyName');
               sr.address =  tempParse.get('Address');
               sr.city =  tempParse.get('City');
               sr.state =  tempParse.get('State');
               sr.zipCode =  tempParse.get('ZipCode');
               sr.employeeCount = tempParse.get('EmployeeCount');
               sr.product = tempParse.get('Product');                                     
               sr.firstName = tempParse.get('FirstName');
               sr.lastName = tempParse.get('LastName');
               sr.fullName = sr.firstName + ' ' + sr.lastName;
               sr.phoneNumber =  tempParse.get('PhoneNumber');
               sr.squishedPhone = Utilities.removeExtraChars(sr.phoneNumber, '0123456789');
               sr.notes = tempParse.get('Notes');
               sr.platform = tempParse.get('Platform');
               sr.addOnClient = tempParse.get('AddOnClient');
               sr.advClient = tempParse.get('AdvClient');  
               sr.federalId = tempParse.get('FederalID');
               sr.contactEmail = tempParse.get('ContactEmail');           
               sr.Region = Integer.valueOf(tempParse.get('Region'));
               sr.soarId = Integer.valueOf(tempParse.get('SOARID'));    
         	   sr.referralBusId = tempParse.get('ReferralBusID');
         	   sr.referralClientId = tempParse.get('ReferralClientID');
         	   sr.referralOfficeId = tempParse.get('ReferralOfficeID');
         	   sr.isCurrentClientReferral = (sr.referralBusId != null && sr.referralBusId != '' || (sr.referralClientId != null && sr.referralClientId != '' && sr.referralOfficeId != null && sr.referralOfficeId != ''));
           }
           catch (System.Xmlexception ex) {
               errMsg += ' Parsing error '+ ex.getMessage();
               System.debug('parseXml xmlexception errMsg: '+errMsg);           
           }   
           if (String.isBlank(errMsg)){             
               if (String.isBlank(sr.companyName)){
                   errMsg += ' Missing Company Name  ';   
               }
               if (String.isBlank(sr.fullName)){
                   errMsg += ' Missing Contact Name. ';  
               }
               if ((sr.product != 'New Client' && String.isBlank(sr.Id)) ||
                   (sr.product == 'New Client' && sr.addOnclient == 'Yes' && String.isBlank(sr.Id))){
                       errMsg += ' Missing account ID, needed for additional product or Add On client. ';  
                   }
               if (String.isNotBlank(sr.contactEmail) && 
                   (sr.contactEmail.countMatches('@')>1 || sr.contactEmail.contains('<'))){
                       errMsg += ' Bad contact email address. ';  
                   }
           }
           
           sr.isInternational = (Pattern.matches('\\d{5}(-\\d{4})?',sr.zipCode)?false:true);       // is this an international zip code          
       }
       catch(Exception ex1){
           //forwardEmail('SOAR error email parser: '+ex1.getMessage()+'; '+ex1.getStackTraceString(), sr.plainTextBody);
           errMsg += ex1.getMessage()+'; '+ex1.getStackTraceString();
       }
       if (String.isNotBlank(errMsg)) {
           System.debug('parseXml isNotBlank(errMsg): '+errMsg);
           sr.parseMsg = errMsg;
           forwardEmail('SOAR error: '+errMsg, sr.plainTextBody);        
       }

       return sr;
            
    } // parseXML
    
    private static Map<String, String> walkthrough(DOM.XMLnode node, Map<String, String> tempParse)
    {   if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) 
        {   String nam = node.getName();
            String txt = node.getText().trim();
            txt = txt.replaceAll('\n', '');
            txt = txt.replaceAll('\r', '');
            tempParse.put(nam,txt);
        }
            
        for (Dom.XMLNode child: node.getChildElements()) 
        {   tempParse = walkThrough(child, tempParse);  }       
        return tempParse;
    } // walkthrough    
 
    /* need to get rid of <> around email addresses that are notes, also shorten notes that are too long
    */
    private static String fixNotes(String toParse) {
        Integer idxBeginNotes = toParse.indexOf('<Notes>')+7;
        Integer idxEndNotes = toParse.indexOf('</Notes>');
        String prefix = toParse.Left(idxBeginNotes);
        String suffix = toParse.substring(idxEndNotes);
        String notes = toParse.substring(idxBeginNotes, idxEndNotes);
        notes = notes.replaceAll('<',' ');
        notes = notes.replaceAll('>',' ');
        if (notes.length() > 2000 )
        {   notes = notes.Left(2000);   }
        
        return prefix+notes+suffix;
        
    } // fixNotes
    
    /* put update of Partner referral in 1 spot so it can be used in multiple places
    */
    private static void updatePartRef(String p_comments, Boolean p_processed)
    {   partRef.comments__c = p_comments;
        partRef.Processed__c = p_processed;
        update partRef;
    }

   
} // class SOARHelper