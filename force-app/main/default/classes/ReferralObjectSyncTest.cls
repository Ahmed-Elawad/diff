/* Test Method for ReferalObjects Sync 
*
*History
*----------------
* Josh Cartwright Created 3/24/2014
   03/18/2015 Dan Carmen        Reworked the processReferralAccounts and processReferralContacts methods
   02/08/2016 Dan Carmen        Add PartnerDetail information
   03/15/2016 Dan Carmen        Add SalesBroker_Primary_Record__c to pass validation rule
   09/27/2016 Dan Carmen        Add AccountContactRelation object into the mix
   03/16/2017 Dan Carmen        Changed criteria for ReferralObjectsSync call
   05/21/2018 Cindy Freeman     rearranged order of a couple lines in testReferralAcctCntctRole
   10/02/2020 Dan Carmen        Added LatestCampaign__c to mapping.
   06/07/2021 Dan Carmen        Do not fire Referral Account triggers during an update in the sync

*/
@IsTest
public class ReferralObjectSyncTest {
   
   public static void resetFlags() {
      ReferralObjectsSync.SKIP_SYNC=false;
      //ReferralObjectsSync.REFERRAL_ACCOUNTS_ENTERED = false;        
      //ReferralObjectsSync.REFERRAL_CONTACTS_ENTERED = false;
      ReferralObjectsSync.refObjectIdsProcessed.clear();        
   }

   static testMethod void testAccountCreate() {
      resetFlags();
//      id refAcctRT1 = RecordTypeHelper.getRecordType('Broker Dealer Referral Account Record Type','Referral_Account__c').getRecordTypeId();   
      id refAcctRT2 = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();   
      id refAcctRT3 = RecordTypeHelper.getRecordType('HRS Referral Source Record Type','Referral_Account__c').getRecordTypeId();    
      id refAcctRT4 = RecordTypeHelper.getRecordType('Paychex Internal Referral Account Record Type','Referral_Account__c').getRecordTypeId();  
      id refAcctRT5 = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type','Referral_Account__c').getRecordTypeId(); 
      id refAcctRT6 = RecordTypeHelper.getRecordType('Sales Partner Referral Account Record Type','Referral_Account__c').getRecordTypeId(); 
    
 //     id acctRT1 = RecordTypeHelper.getRecordType('Broker Dealer Referral Account Record Type','Account').getRecordTypeId();  
      id acctRT2 = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Account').getRecordTypeId();  
      id acctRT3 = RecordTypeHelper.getRecordType('HRS Referral Source Record Type','Account').getRecordTypeId();   
      id acctRT4 = RecordTypeHelper.getRecordType('Paychex Internal Referral Account Record Type','Account').getRecordTypeId(); 
      id acctRT5 = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type','Account').getRecordTypeId();    
      id acctRT6 = RecordTypeHelper.getRecordType('Sales Partner Referral Account Record Type','Account').getRecordTypeId();    
    
      id rDataId = [select id from user where name = :UserHelper.REFERRAL_OWNER and IsActive=true limit 1].id;
    
    
      //create referral account     
      Referral_Account__c refAcct1 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT2);      
      insert refacct1;
      // check partner detail records
      System.assertEquals(1,[select count() from PartnerDetail__c where Account__r.Mirror_Referral_Account__c = :refacct1.Id]);
    
      resetFlags();        

      //create parent referral account
        Referral_Account__c refAcct2 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT2);
        // set to null so it won't create a detail record based on that.
        refAcct2.Referral_Type__c = null;
        // set a field that should always be on the detail.
        refAcct2.Bank_Referral_Fee__c = 666;
        insert refAcct2;    

      System.assertEquals(1,[select count() from PartnerDetail__c where Account__r.Mirror_Referral_Account__c = :refacct2.Id]);
    
      //verify account is created  
      list<account> newAccts = [select id, RecordTypeID, Ref_Acct_ID__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode,Referral__c, 
                                 ownerId,name,CRD_Number__c,Broker_Clearing_Firm_Name__c,ShippingStreet,ShippingCity,ShippingState,ShippingCountry,
                                 ShippingPostalCode,Phone,Payment_Method__c ,Common_Remitter_Participation__c,Common_Remitter_Start_Date__c,Common_Remitter_End_Date__c,
                                 Email__c 
                                 from account where Ref_Acct_ID__c = :refAcct1.Id ];
                             
      system.assert(newAccts.size() == 1);
      system.assertequals(newAccts[0].Ref_Acct_Id__c,refacct1.Id);
      system.assertequals(newAccts[0].ownerId,rDataId);
      system.assertequals(newAccts[0].name,refacct1.Name);
      system.assertequals(newAccts[0].CRD_Number__c,refacct1.CRD_Number__c);
      system.assertequals(newAccts[0].Broker_Clearing_Firm_Name__c,refacct1.Broker_Clearing_Firm_Name__c);    
      system.assertequals(newAccts[0].BillingStreet,refAcct1.Street_Address_1__c);
      system.assertequals(newAccts[0].BillingCity,refAcct1.City__c);
      system.assertequals(newAccts[0].BillingState,refAcct1.State_Province__c); 
      system.assertequals(newAccts[0].BillingCountry,refAcct1.Country__c);
      system.assertequals(newAccts[0].BillingPostalCode,refAcct1.Zip_Postal_Code__c);
      system.assertequals(newAccts[0].ShippingStreet,refAcct1.Street_Address_1__c);    
      system.assertequals(newAccts[0].ShippingCity,refAcct1.City__c);     
      system.assertequals(newAccts[0].ShippingState,refAcct1.State_Province__c);     
      system.assertequals(newAccts[0].ShippingCountry,refAcct1.Country__c);     
      system.assertequals(newAccts[0].ShippingPostalCode,refAcct1.Zip_Postal_Code__c);      
      system.assertequals(newAccts[0].Phone,refAcct1.Phone__c);
      system.assertequals(newAccts[0].Payment_Method__c ,refAcct1.Payment_Method__c);
      system.assertequals(newAccts[0].Common_Remitter_Participation__c,refAcct1.Common_Remitter_Participation__c);
      system.assertequals(newAccts[0].Common_Remitter_Start_Date__c,refAcct1.Common_Remitter_Start_Date__c);
      system.assertequals(newAccts[0].Common_Remitter_End_Date__c,refAcct1.Common_Remitter_End_Date__c);
      system.assertequals(newAccts[0].Referral__c,refAcct1.Referral_Source_Business_Type__c);    
      system.assertequals(newAccts[0].Email__c,refAcct1.Email__c);            
      system.assertequals(newAccts[0].recordtypeid,acctRT2);    
      
      resetFlags();        
      //update an exsisting referral account - check to make sure a new account is not created
      refAcct1.Referral_Source_Business_Type__c = 'Broker Dealer Branch';
      refAcct1.Street_Address_2__c = 'apt1';
      update refAcct1;

      // verify there's still 1
      System.assertEquals(1,[select count() from PartnerDetail__c where Account__r.Mirror_Referral_Account__c = :refacct1.Id]);
        
      newAccts = [select id, Referral__c, BillingStreet, ShippingStreet, RecordTypeId 
                    from account where Ref_Acct_ID__c = :refAcct1.Id ];
                    
      system.assert(newAccts.size() == 1);                                   
      system.assertequals(newAccts[0].Referral__c,'Broker Dealer Branch'); 
      system.assertequals(newAccts[0].BillingStreet, refAcct1.Street_Address_1__c +'\r\n' +refAcct1.Street_Address_2__c); 
      system.assertequals(newAccts[0].ShippingStreet, refAcct1.Street_Address_1__c +'\r\n' +refAcct1.Street_Address_2__c); 
  
    
    //change the referral account record type 'Core Referral Source Record Type', verify account record type is updated    
        //refAcct1.recordtypeid = refAcctRT2;
        //update refAcct1;
    
        //newAccts = [select id, RecordTypeID
        //            from account where Ref_Acct_ID__c = :refAcct1.Id ];
                    
        //system.assert(newAccts.size() == 1);           
        //system.assertequals(newAccts[0].recordtypeid,acctRT2);        
        
    //change the referral account record type 'HRS Referral Source Record Type', verify account record type is updated    
        //resetFlags();        
        //refAcct1.recordtypeid = refAcctRT3;
        //update refAcct1;
    
        //newAccts = [select id, RecordTypeID
        //            from account where Ref_Acct_ID__c = :refAcct1.Id ];        

        //system.assert(newAccts.size() == 1);
        //system.assertequals(newAccts[0].recordtypeid,acctRT3);         
        
    //change the referral account record type 'Paychex Internal Referral Account Record Type', verify account record type is updated    
        //resetFlags();        
        //refAcct1.recordtypeid = refAcctRT4;
        //update refAcct1;
    
        //newAccts = [select id, RecordTypeID
        //                from account where Ref_Acct_ID__c = :refAcct1.Id ];

        //system.assert(newAccts.size() == 1);
        //system.assertequals(newAccts[0].recordtypeid,acctRT4);       
    
    //change the referral account record type 'Sales Channel Referral Account Record Type', verify account record type is updated    
        //resetFlags();        
        //refAcct1.recordtypeid = refAcctRT5;
        //update refAcct1;
    
        //newAccts = [select id, RecordTypeID
        //            from account where Ref_Acct_ID__c = :refAcct1.Id ];        

        //system.assert(newAccts.size() == 1);
        //system.assertequals(newAccts[0].recordtypeid,acctRT5);    
    
    //change the referral account record type 'Sales Partner Referral Account Record Type', verify account record type is updated    
        //resetFlags();        
        //refAcct1.recordtypeid = refAcctRT6;
        //update refAcct1;
    
        //newAccts = [select id, RecordTypeID
        //            from account where Ref_Acct_ID__c = :refAcct1.Id ];        

        //system.assert(newAccts.size() == 1); 
        //system.assertequals(newAccts[0].recordtypeid,acctRT6); 

      //Test Parent Account
      resetFlags();        
        refAcct1.Parent_Referral_Account__c = refAcct2.Id;
        update refAcct1; 
        
      // verify there's still only 1 partner detail
      System.assertEquals(1,[select count() from PartnerDetail__c where Account__r.Mirror_Referral_Account__c = :refacct1.Id]);

        newAccts = [select id, Parentid, ReferralParent__c from account where ref_Acct_Id__c= :refAcct1.Id]; 
        list<Referral_Account__c> refAcct2List = [Select id, Account__c from Referral_Account__c where id = :refAcct2.id];
        
        system.assert(newAccts.size() ==1);
        system.assertequals (newAccts[0].ReferralParent__c, refAcct2List[0].Account__c);  
        
      //Test Delete 
            
                   
   } // testAccountCreate

    static testMethod void testContactCreate(){
        resetFlags();
        //test referral contact    
        
//      id refCntctRT1 = RecordTypeHelper.getRecordType('Broker/CPA Referral Contact Record Type','Referral_Contact__c').getRecordTypeId(); 
        id refCntctRT2 = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();   
        id refCntctRT3 = RecordTypeHelper.getRecordType('HRS Referral Record Type','Referral_Contact__c').getRecordTypeId();    
        id refCntctRT4 = RecordTypeHelper.getRecordType('MMS Referral Record Type','Referral_Contact__c').getRecordTypeId();    
        id refCntctRT5 = RecordTypeHelper.getRecordType('Paychex Internal Referral Contact Record Type','Referral_Contact__c').getRecordTypeId();   
        id refCntctRT6 = RecordTypeHelper.getRecordType('Sales Partner Referral Contact Record Type','Referral_Contact__c').getRecordTypeId();  
    
//      id cntctRT1 = RecordTypeHelper.getRecordType('Broker/CPA Referral Contact Record Type','Contact').getRecordTypeId();    
        id cntctRT2 = RecordTypeHelper.getRecordType('Core Referral Record Type','Contact').getRecordTypeId();  
        id cntctRT3 = RecordTypeHelper.getRecordType('HRS Referral Record Type','Contact').getRecordTypeId();   
        id cntctRT4 = RecordTypeHelper.getRecordType('MMS Referral Record Type','Contact').getRecordTypeId();   
        id cntctRT5 = RecordTypeHelper.getRecordType('Paychex Internal Referral Contact Record Type','Contact').getRecordTypeId();  
        id cntctRT6 = RecordTypeHelper.getRecordType('Sales Partner Referral Contact Record Type','Contact').getRecordTypeId(); 
    
        id refAcctRT2 = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId(); 
    
        id rDataId = [select id from user where name = :UserHelper.REFERRAL_OWNER and IsActive=true limit 1].id;
    
        
        //create referral contact and Referral Account
        Referral_Account__c refAcct1 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT2);
        insert refAcct1;        
        resetFlags();        
        Referral_Contact__c refCntct1 = ReferralObjectSyncTest.createTestRefCntct(refCntctRT2, refAcct1.id);
        insert refCntct1;        
        Referral_Contact__c refCntct2 = new Referral_Contact__c(
                                         Name = 'New Contact'
                                        ,Referral_Account__c = refAcct1.id
                                        ,RecordtypeID = refCntctRT2
                                        ,Mailing_Street__c = '234'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '16423'
                                        ,Mailing_Country__c = 'US' );
        
        resetFlags();
        insert refCntct2; 
        
   
     
            
        list<Referral_Contact__c> refCntct = [select id, Contact_ID__c from Referral_Contact__c where id = :refCntct1.id];
        list<Contact> newContact = [select id,recordtypeid,Account.id, Account.Ref_Acct_ID__c,Ref_Contact_Id__c,ownerId,lastName, firstname,MailingStreet,
                                    MailingCity,MailingState,MailingPostalCode, Email,Broker_Branch_ID__c, Broker_Rep_ID__c,CRD_Number__c,Compensation_Type__c,
                                    account.BillingStreet,account.BillingCity,account.BillingState,account.BillingPostalCode                                
                                    from Contact where Ref_Contact_ID__c = :refCntct1.Id];  
        
        system.assert(newContact.size() == 1); 
        system.assertequals(newContact[0].recordtypeid,cntctRT2);
        system.assertequals(newContact[0].Account.Ref_Acct_ID__c, refAcct1.id);
        system.assertequals(newContact[0].Ref_Contact_Id__c,refCntct1.id);  
        system.assertequals(newContact[0].ownerId,rDataId); 
        system.assertequals(newContact[0].firstName+' '+newContact[0].lastName,refcntct1.Name);     
        system.assertequals(newContact[0].MailingStreet,refCntct1.Mailing_Street__c);   
        system.assertequals(newContact[0].MailingCity,refCntct1.Mailing_City__c);   
        system.assertequals(newContact[0].MailingState,refCntct1.Mailing_State__c);     
        system.assertequals(newContact[0].MailingPostalCode,refCntct1.Mailing_Postal_Code__c);              
        system.assertequals(newContact[0].Email,refcntct1.Email__c);
        system.assertequals(newContact[0].Broker_Branch_ID__c,refcntct1.Branch__c);       
        system.assertequals(newContact[0].Broker_Rep_ID__c,refcntct1.Broker_Rep_ID__c);     
        system.assertequals(newContact[0].CRD_Number__c ,refcntct1.CRD_Number__c);  
        system.assertequals(newContact[0].Compensation_Type__c,refcntct1.Compensation_Type__c); 
//      system.assertequals(newContact[0].Contact_ID__c, refCntct[0].Contact_ID__c);
        //change the referral contact record type to 'Core Referral Record Type' verify contact rt updates
        //refCntct1.recordtypeid = refCntctRT2; 
        //update refCntct1; 
        
        //newContact = [select id,recordtypeid                          
        //              from Contact where Ref_Contact_ID__c = :refCntct1.Id];  
        
        //system.assert(newContact.size() == 1); 
        //system.assertequals(newContact[0].recordtypeid,cntctRT2);
    
        //change the referral contact record type to 'HRS Referral Record Type' verify contact rt updates
        //resetFlags();        
        //refCntct1.recordtypeid = refCntctRT3; 
        //update refCntct1; 
    
        //newContact = [select id,recordtypeid                          
        //              from Contact where Ref_Contact_ID__c = :refCntct1.Id];  
        
        //system.assert(newContact.size() == 1); 
        //system.assertequals(newContact[0].recordtypeid,cntctRT3); 
        
        //change the referral contact record type to 'MMS Referral Record Type' verify contact rt updates   
        //refCntct1.recordtypeid = refCntctRT4; 
        //resetFlags();        
        //update refCntct1; 
    
        //newContact = [select id,recordtypeid                          
        //              from Contact where Ref_Contact_ID__c = :refCntct1.Id];  
        
        //system.assert(newContact.size() == 1); 
        //system.assertequals(newContact[0].recordtypeid,cntctRT4);
    
        //change the referral contact record type to 'Paychex Internal Referral Contact Record Type' verify contact rt updates      
        //refCntct1.recordtypeid = refCntctRT5; 
        //resetFlags();        
        //update refCntct1; 
    
        //newContact = [select id,recordtypeid                          
        //              from Contact where Ref_Contact_ID__c = :refCntct1.Id];  
        
        //system.assert(newContact.size() == 1); 
        //system.assertequals(newContact[0].recordtypeid,cntctRT5);
        
        //change the referral contact record type to 'Sales Partner Referral Contact Record Type' verify contact rt updates     
        //refCntct1.recordtypeid = refCntctRT6; 
        //resetFlags();        
        //update refCntct1; 
    
        //newContact = [select id,recordtypeid                  
         //             from Contact where Ref_Contact_ID__c = :refCntct1.Id];  
        
        //system.assert(newContact.size() == 1); 
        //system.assertequals(newContact[0].recordtypeid,cntctRT6);

      refCntct1.Mailing_Street__c = null; 
      resetFlags();        
      update refCntct1;
        
      refCntct = [select id, Street_Address_1__c,City__c,State__c,Zip_Code__c, Country__c  from Referral_Contact__c where id = :refCntct1.id];
      newContact = [select id, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from contact where Ref_Contact_ID__c = :refCntct1.id];
        
      system.assertequals(refCntct[0].Street_Address_1__c,newContact[0].MailingStreet);
      system.assertequals(refCntct[0].City__c,newContact[0].MailingCity);
      system.assertequals(refCntct[0].State__c,newContact[0].MailingState);
      system.assertequals(refCntct[0].Zip_Code__c,newContact[0].MailingPostalCode);
      system.assertequals(refCntct[0].Country__c,newContact[0].MailingCountry);
        
      list<Referral_Contact__c> refCntct2list = [select id, Contact_ID__c from Referral_Contact__c where id = :refCntct2.id];
      list<Contact> newContact2List = [select id from Contact where Ref_Contact_ID__c = :refCntct2.Id]; 
        
      system.assert(refCntct2list.size() == 1);
      system.assert(newContact2List.size()==1); 
   
      //string errorMessage = 'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, ERROR: There is already an Identical Record:';                  
      //errorMessage += '<p><a target="_blank" href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/'+ refCntct1.id + '">';
      //errorMessage +=  'Click Here for the Duplicate Record' + '</a></p><br/>: [],';
        
      Referral_Contact__c refCntct3 = ReferralObjectSyncTest.createTestRefCntct(refCntctRT2, refAcct1.id);

      //this method should never happen because see all data is not enabled.  
      try {
        resetFlags();
        insert refCntct3;
      } Catch(exception e){
         System.debug('testContactCreate e.getMessage='+e.getMessage());
         system.assert(e.getMessage().Contains(refCntct1.id));
      }
        
       // list<Referral_Contact__c> refCntct3list = [select id, Contact_ID__c from Referral_Contact__c where id = :refCntct3.id];
       // list<Contact> newContact3List = [select id from Contact where Ref_Contact_ID__c = :refCntct3.Id];
        
    } // testContactCreate

    static testMethod void testReferralAcctCntctRole(){
         resetFlags();
        id refCntctRT1 = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();   
        id refAcctRT1 = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId(); 
        id rDataId = [select id from user where name = :UserHelper.REFERRAL_OWNER and IsActive=true limit 1].id;
        
        Referral_Account__c refAcct1 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT1);
        refAcct1.OwnerId = rDataId;
        refAcct1.SalesBroker_Primary_Record__c = true; 

        Referral_Account__c refAcct2 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT1);
        refAcct2.OwnerId = rDataId;
        refAcct2.SalesBroker_Primary_Record__c = true; 
        Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
        resetFlags();        
        insert refAccts;
                
        Referral_Contact__c refCntct1 = ReferralObjectSyncTest.createTestRefCntct(refCntctRT1, refAcct1.id); 
        refCntct1.OwnerId = rDataId; 

        Referral_Contact__c refCntct2 = ReferralObjectSyncTest.createTestRefCntct(refCntctRT1, refAcct2.id); 
        refCntct2.OwnerId = rDataId; 
        resetFlags(); 
        Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCntct1,refCntct2};
        insert refCtcts;        

        System.assertEquals(2,[Select count() from Referral_Account__c]);
        System.assertEquals(2,[Select count() from Referral_Contact__c]);       

        //Referral_Contact__c refCntct2 = ReferralObjectSyncTest.createTestRefCntct(refCntctRT1, refAcct1.id); 
        //refAcct2.OwnerId = rDataId; 
        //insert refCntct2;             
        Referral_Contact_Role__c refCntctRole = ReferralObjectSyncTest.createRefCntctRole (refCntct1.Id, refAcct1.Id);
        // second role to link to the other account
        Referral_Contact_Role__c refCntctRole2 = ReferralObjectSyncTest.createRefCntctRole (refCntct1.Id, refAcct2.Id);

        resetFlags();
        Referral_Contact_Role__c[] roles = new Referral_Contact_Role__c[]{refCntctRole,refCntctRole2};
        insert roles; 
            
        System.assertEquals(2,[Select count() from Account]);
        System.assertEquals(2,[Select count() from Contact]);
        System.assertEquals(2,[Select count() from AccountContactRole]);
        System.assertEquals(3,[Select count() from AccountContactRelation]);
        
        System.assertEquals(2,[Select count() from Referral_Contact_Role__c]);
        
        
        refCntctRole =[select id, AccountContactRoleId__c, AccountContactRelationId__c, Role__c
                                 from Referral_Contact_Role__c where Referral_Contact__c = :refCntct1.id and Referral_Account__c = :refAcct1.id];

        System.debug('testReferralAcctCntctRole AccountContactRoleId__c='+refCntctRole.AccountContactRoleId__c+' AccountContactRelationId__c='+refCntctRole.AccountContactRelationId__c);

        // verify the id is set on the custom object.
        AccountContactRole acctCtctRole = [Select Id, AccountId, ContactId, Role from AccountContactRole where Id = :refCntctRole.AccountContactRoleId__c ];
        system.assertequals(acctCtctRole.role, refCntctRole.Role__c);
        
        AccountContactRelation acctCtctRltn = [Select Id, AccountId, ContactId, Roles, IsActive, EndDate, StartDate from AccountContactRelation where Id = :refCntctRole.AccountContactRelationId__c];
        System.assertEquals(acctCtctRltn.Roles, refCntctRole.Role__c);
        System.assertEquals(true, acctCtctRltn.IsActive);
        System.assertEquals(Date.today(), acctCtctRltn.StartDate);
        System.assertEquals(null, acctCtctRltn.EndDate);
      
        refCntctRole.Role__c = 'CPA';
        resetFlags();        
        update refCntctRole; 
     
        list<account> newAcct1 = [select id from account where account.Ref_Acct_ID__c =:refAcct1.Id]; 
    
        acctCtctRole = [select id,Role,AccountId 
                            from AccountContactRole where Id = :refCntctRole.AccountContactRoleId__c];  
        
        system.assertequals(newAcct1[0].id,acctCtctRole.AccountId);
        system.assertequals(acctCtctRole.role, refCntctRole.Role__c); 
        
        acctCtctRltn = [Select Id, AccountId, ContactId, Roles, IsActive, EndDate, StartDate from AccountContactRelation where Id = :refCntctRole.AccountContactRelationId__c];
        System.assertEquals(true, acctCtctRltn.Roles.contains(refCntctRole.Role__c));
        System.assertEquals(true, acctCtctRltn.IsActive);
        System.assertEquals(Date.today(), acctCtctRltn.StartDate);
        System.assertEquals(null, acctCtctRltn.EndDate);
        
        //refCntctRole.Referral_Contact__c = refCntct2.Id; 
       //update refCntctRole;
        
       //list<Contact> newContact = [select id                              
       //                            from Contact where Ref_Contact_ID__c = :refCntct2.Id]; 
                                   
       //newRefCntctRole =[select id, AccountContactRoleId__c
       //                  from Referral_Contact_Role__c where Referral_Contact__c = :refCntct2.id and Referral_Account__c = :refAcct1.id];
       //newAcctCntctRole = [select id,Role,Accountid, Contactid 
       //                    from AccountContactRole where Id = :newRefCntctRole[0].AccountContactRoleId__c]; 
                                         
       //system.assertequals(newAcctCntctRole[0].ContactId ,newContact[0].Id);
                        
        refCntctRole.Role__c = ReferralObjectsSync.INACTIVE;
        resetFlags();        
        update refCntctRole; 

        refCntctRole =[select id, AccountContactRoleId__c, AccountContactRelationId__c, Role__c
                                 from Referral_Contact_Role__c where id=:refCntctRole.Id];
                                 
        // one of the roles should be deleted
        System.assertEquals(1,[Select count() from AccountContactRole]);
        System.assertEquals(null, refCntctRole.AccountContactRoleId__c);

        acctCtctRltn = [Select Id, AccountId, ContactId, Roles, IsActive, EndDate, StartDate from AccountContactRelation where Id = :refCntctRole.AccountContactRelationId__c];
        System.assertEquals(false, acctCtctRltn.IsActive);
        System.assertEquals(Date.today(), acctCtctRltn.StartDate);
        System.assertEquals(Date.today(), acctCtctRltn.EndDate);

    } // testReferralAcctCntctRole

    //method to tests the deletion of a ref account deletes the corresponding account
    static testMethod void testDelete(){
       resetFlags();
    id refAcctRT1 = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId(); 
    id refCntctRT1 = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();   
    
    //create test ref account
    Referral_Account__c refAcct1 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT1); 
    insert refAcct1; 
    Id refAcctId = refAcct1.Id;
    
    //create contact
    Referral_Contact__c refCntct1 = ReferralObjectSyncTest.createTestRefCntct(refCntctRT1, refAcct1.id); 
    insert refCntct1;    
    Id refCtctId = refCntct1.Id;         
        
    //Confirm account is created
    //list<Referral_Account__c> refAcct = [select id, SF_Account_ID__c from Referral_Account__c where id = :refAcct1.id];
    list<account> accts = [select id, Mirror_Referral_Account__c from Account where Mirror_Referral_Account__c= :refAcctId];
    list<Referral_Contact__c> refCntcts = [select id, Contact__c, Referral_Account__c from Referral_Contact__c where id = :refCtctId];
    list<contact> cntcts = [select id, Mirror_Ref_Ctct__c, Accountid from contact where id = :refCntcts[0].Contact__c];

    
    system.assertEquals(accts[0].Mirror_Referral_Account__c,refAcctId);
    //system.assertEquals(cntct[0].accountid,refAcct[0].SF_Account_ID__c);
    
    //delete ref acct confirm acct is deleted, confirm contact exists wihtout an account
    delete refAcct1;
    accts =[select id, Mirror_Referral_Account__c from Account where Mirror_Referral_Account__c = :refAcctId];
    
    cntcts = [select id, accountid from contact where Mirror_Ref_Ctct__c = :refCtctId];
    system.debug(accts.size() + ' account size josh');
    system.assertEquals(0,accts.size());
    system.assert(cntcts[0].Accountid == null);
    
    //delete contact
    delete refCntct1; 
    
    cntcts = [select id, accountid from contact where Mirror_Ref_Ctct__c = :refCtctId];
    
    system.assert(cntcts.size()==0);
    
        
    
    } // testDelete

   static testMethod void testDupeChecking() {
      resetFlags();
      Id refCntctRtId = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId(); 
      Id refAcctRtId = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId(); 
        
      Referral_Account__c refAcct1 = ReferralObjectSyncTest.createTestRefAcct(refAcctRtId);
      insert refAcct1;      
      Referral_Contact__c refCtct1 = ReferralObjectSyncTest.createTestRefCntct(refCntctRtId, refAcct1.id); 
      insert refCtct1;
      // reselect the record to get the field values
      refCtct1 = [Select Id, Name, First_Name__c, Last_Name__c, Referral_Account__c from Referral_Contact__c where Id=:refCtct1.Id];
      
      // verify the account/contact were created
      Account acct = [Select id, Name from Account where Mirror_Referral_Account__c = :refAcct1.Id];
      Contact ctct = [Select Id, FirstName, LastName from Contact where Mirror_Ref_Ctct__c = :refctct1.Id];
      
      Referral_Contact__c checkRefCtct = new Referral_Contact__c(First_Name__c=refCtct1.First_Name__c, Last_Name__c=refCtct1.Last_Name__c
                                                   ,Referral_Account__c=refCtct1.Referral_Account__c);
      map<Referral_Contact__c,list<Contact>> resultMap = ReferralObjectsSync.dupeContactChecker(new Referral_Contact__c[]{checkRefCtct});
      // should be one match
      System.assertEquals(1,resultMap.size());
      Contact[] ctctList = resultMap.get(checkRefCtct);
      //System.assertEquals(ctct.Id, ctctList[0].Id);
   } // testDupeChecking

   public static ReferralType__c refType = null;

    //method that creates a generic test referral account   
    public Static Referral_Account__c createTestRefAcct(id refAcctRT1){
       if (refType == null) {
         refType = new ReferralType__c(Name='Test Type',PartnerDetail__c=true);
         try {
            insert refType;
         } catch (Exception e) {}
       }
      return new Referral_Account__c(name = 'RefAcctCreate'
                                        ,recordtypeid = refAcctRT1
                                        ,Referral_Source_Business_Type__c = 'Broker Dealer'
                                        ,Referral_Type__c=refType.Name
                                        ,Street_Address_1__c = '911 Panorama Trail South'
                                        ,City__c = 'Rochester'
                                        ,State_Province__c = 'NY'
                                        ,Zip_Postal_Code__c = '14586');
   } // createTestRefAcct
    
    //method that creates a generic test referral contact  
   public Static Referral_Contact__c createTestRefCntct(id refCntctRT1,id refAcct1){
        return new Referral_Contact__c(name = 'First Last'
                                        ,recordtypeid = refCntctRT1
                                        ,Referral_Account__c = refAcct1
                                        ,Mailing_Street__c = '123'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '14514'
                                        ,Mailing_Country__c = 'US');
    }
    //method that creates a referral account contact role 
    Static Referral_Contact_Role__c createRefCntctRole (id refCntct1, id RefAcct1){
        return new Referral_Contact_Role__c (Referral_Contact__c = refCntct1
                                             ,Referral_Account__c = refacct1
                                             ,Role__c = 'Financial Advisor');
    }

} // class ReferralObjectSyncTest