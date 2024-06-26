/**
 * Test method for SoarEmailHandler and SOARHelper
 * 
 * History
 * --------
 * 10/30/2018  Cindy Freeman    created
 * 12/17/2018  Cindy Freeman	added test for new campaign logic
   12/28/2022  Dan Carmen       Modify to use SF Duplicate Management
 */
 
 @isTest
public class AICPAEmailHandlerTest {

   private static User runningUser;
   private static Contact payxEmp;

   private static void setupTest() {
    // select a user to run as - make sure we get one with a person id
      runningUser = [Select Id, FirstName, LastName, Name, Email, HR_Person_Id__c from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true and HR_Person_Id__c != null limit 1];
      Account payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP);
      insert payxAcct;
      payxEmp = new Contact(FirstName=runningUser.FirstName, LastName=runningUser.LastName
                         ,AccountId=payxAcct.Id, HR_Person_Id__c=runningUser.HR_Person_Id__c, Email=runningUser.Email);      
      insert payxEmp;
      
      populatePayxSetting();
      
   } // setupTest

   static testMethod void testBlankEmail(){         
        Boolean testPassed = false;
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AICPAEmailHandler aEH = new AICPAEmailHandler();
        try{
            aEH.handleInboundEmail(email, env);
        }
        catch(AICPAEmailHandler.AICPAException ex)
        {   testPassed = true;  }     // catching the thrown error coz email body is empty
        System.assertEquals(true, testPassed);
        
    } //testBlankEmail
    
    
    static testMethod void testBadXML(){
      setupTest();
        Boolean testPassed = false;
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.htmlBody = '<LeadInformation><junk></LeadInformation>';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        AICPAEmailHandler aEH = new AICPAEmailHandler();
        try{
            aEH.handleInboundEmail(email, env);
        }
        catch(AICPAEmailHandler.AICPAException ex)
        {   testPassed = true;  }     // catching the thrown error coz email body is empty
        System.assertEquals(true, testPassed);
        
    } //testBadXML
    
    // test bad campaign 
  static testMethod void testCampaign() {
         setupTest();
         Boolean testPassed = false;
         
         System.runAs(runningUser) {
            messaging.Inboundemail email = new messaging.Inboundemail();
           email.htmlBody = '<LeadInformation>';
  
           email.htmlBody += addXML('AccountName','CMF Test Ref Acct');
           email.htmlBody += addXML('FirstName','Samuel');
           email.htmlBody += addXML('LastName','Spade');
           email.htmlBody += addXML('Street1','75 West 1st St');
           email.htmlBody += addXML('Street2',null);
           email.htmlBody += addXML('City','NYC');
           email.htmlBody += addXML('State','NY');
           email.htmlBody += addXML('Zip','10019');
           email.htmlBody += addXML('Campaign','Junk');
           email.htmlBody += addXML('Email','sam@spade.com');
           email.htmlBody += addXML('Phone','(585)533-4567');
           email.htmlBody += '</LeadInformation>';
           
           try { 
               Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
               AICPAEmailHandler aEH = new AICPAEmailHandler();
               aEH.handleInboundEmail(email, env);
               testPassed = true; 
            }
            catch (Exception e)
            {   testPassed = false;              
            }     // sends email instead of throwing error
            //System.assertEquals(false,testPassed);
            ErrorLog__c log = [Select Id, ClassName__c, MethodName__c from ErrorLog__c where createdDate = TODAY];
            System.assertEquals('AicpaEmailHelper',log.ClassName__c);
            System.assertEquals('processAicpaLeads',log.MethodName__c);
         } // runAs
         
  } // testCampaign
    
    // test missing Street
  static testMethod void testMissingStreet() {
         setupTest();
         Boolean testPassed = false;
         
         System.runAs(runningUser) {
            messaging.Inboundemail email = new messaging.Inboundemail();
           email.htmlBody = '<LeadInformation>';
  
           email.htmlBody += addXML('AccountName','CMF Test Ref Acct');
           email.htmlBody += addXML('FirstName','Samuel');
           email.htmlBody += addXML('LastName','Spade');
           email.htmlBody += addXML('Street1',null);
           email.htmlBody += addXML('Street2',null);
           email.htmlBody += addXML('City','');
           email.htmlBody += addXML('State',null);
           email.htmlBody += addXML('Zip','10019');
           email.htmlBody += addXML('Campaign','Paychex Gated Asset-Test');
           email.htmlBody += addXML('Email','sam@spade.com');
           email.htmlBody += addXML('Phone','(585)533-4567');
           email.htmlBody += '</LeadInformation>';
           
           try { 
               Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
               AICPAEmailHandler aEH = new AICPAEmailHandler();
               aEH.handleInboundEmail(email, env);
               testPassed = true; 
            }
            catch (Exception e)
            {   testPassed = false;              
            }     // sends email instead of throwing error
            //System.assertEquals(false,testPassed);
            ErrorLog__c log = [Select Id, ClassName__c, MethodName__c from ErrorLog__c where createdDate = TODAY];
            System.assertEquals('AicpaEmailHelper',log.ClassName__c);
            System.assertEquals('processAicpaLeads',log.MethodName__c);
         } // runAs
         
  } // test missing Street

    // test create ref acct and ref ctct and partner referral
  static testMethod void testCreate() {
         setupTest();
         Boolean testPassed = false;
         
         System.runAs(runningUser) {
            messaging.Inboundemail email = new messaging.Inboundemail();
            email.htmlBody = '<LeadInformation>';
  
            email.htmlBody += addXML('AccountName','CMF Test Ref Acct');
            email.htmlBody += addXML('FirstName','Samuel');
            email.htmlBody += addXML('LastName','Spade');
            email.htmlBody += addXML('Street1','75 West 1st St');
            email.htmlBody += addXML('Street2',null);
            email.htmlBody += addXML('City','NYC');
            email.htmlBody += addXML('State','NY');
            email.htmlBody += addXML('Zip','10019');
            email.htmlBody += addXML('Campaign','Paychex Gated Asset - 401k Retirement Paper');
            email.htmlBody += addXML('Email','sam@spade.com');
            email.htmlBody += addXML('Phone','(585)533-4567');
            email.htmlBody += '</LeadInformation>';
           
            try { 
               Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
               AICPAEmailHandler aEH = new AICPAEmailHandler();
               aEH.handleInboundEmail(email, env);
               testPassed = true; 
            }
            catch (Exception e)
            {   testPassed = false;              
            }     
            
            //System.assertEquals(true,testPassed);
         } // runAs
         PartnerReferral__c[] partRefList = [Select Id, Comments__c from PartnerReferral__c where createdDate = Today];
         System.assertEquals(1,partRefList.size());
         System.assertEquals('Successful', partRefList.get(0).Comments__c);
        
         Referral_Account__c refAcct = [Select Id, Name from Referral_Account__c where createdDate = Today];
         System.assertEquals('CMF Test Ref Acct',refAcct.Name);
        
         Referral_Contact__c refCtct = [Select Id, Referral_Account__c, First_Name__c, Last_Name__c, Name, Mailing_Street__c, Mailing_City__c,  
                          Mailing_State__c, Mailing_Postal_Code__c, LoadCampaignPrev__c, LatestCampaign__c, AICPA_Original_Type__c, AICPA_Latest_Campaign__c
                          from Referral_Contact__c where createdDate = Today];
         System.assertEquals(refAcct.Id, refCtct.Referral_Account__c);
         System.assertEquals('Samuel Spade', refCtct.Name);
         System.assertEquals('Paychex Gated Asset - 401k Retirement Paper', refCtct.AICPA_Latest_Campaign__c);
    
  } // testCreate

    // create ref acct and ref ctct, test dupe blocker code
  static testMethod void testCreate2() {
         setupTest();
         
         AICPALeadSettings__c aicpaSetting = AICPALeadSettings__c.getInstance('Paychex Gated Asset');
      
         Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('Core Referral Source Record Type', ObjectHelper.OBJECT_REF_ACCOUNT);
         Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('Core Referral Record Type', ObjectHelper.OBJECT_REF_CONTACT);
         
         Referral_Account__c refacct1 = new Referral_Account__c (name = 'Referral Account1'
                                ,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                ,Referral_Type__c = 'Broker'
                                ,Street_Address_1__c = '10 Main St'
                                ,City__c = 'Anytown'
                                ,State_Province__c = 'NY'                                
                                ,Zip_Postal_Code__c = '10019');
         insert refacct1;
         //AICPAEmailHelper.DUPE_OVERRIDE_REFACCT_SET = new Set<Id>{refacct1.Id};
         
         // use the Name field for the Referral_Contact__c - a trigger will parse out to first and last name fields.
         Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'Sam Spade', First_Name__c='Sam', Last_Name__c='Spade'
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212', Email__c='sam@spade.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct1.Id);
         insert refcon1;
         //AICPAEmailHelper.DUPE_OVERRIDE_REFCTCT_SET = new Set<Id>{refcon1.Id};
         
         Boolean testPassed = false;
         
         System.runAs(runningUser) {
            messaging.Inboundemail email = new messaging.Inboundemail();
             email.htmlBody = '<LeadInformation>';
  
            email.htmlBody += addXML('AccountName','Referral Account1');
            email.htmlBody += addXML('FirstName','Samuel');
            email.htmlBody += addXML('LastName','Spade');
            email.htmlBody += addXML('Street1','10 Main Street');
            email.htmlBody += addXML('Street2','Suite 100');
            email.htmlBody += addXML('City','Anytown');
            email.htmlBody += addXML('State','NY');
            email.htmlBody += addXML('Zip','10019');
            email.htmlBody += addXML('Campaign','Paychex Gated Asset-some paper');
            email.htmlBody += addXML('Email','sam@spade.com');
            email.htmlBody += addXML('Phone','(585)555-1212');
            email.htmlBody += '</LeadInformation>';
           
            try { 
               Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
               AICPAEmailHandler aEH = new AICPAEmailHandler();
               aEH.handleInboundEmail(email, env);
               testPassed = true; 
            }
            catch (Exception e)
            {   testPassed = false;   }     // sends email instead of throwing error
            
            //System.assertEquals(true,testPassed);
         } // runAs
        PartnerReferral__c[] partRefList = [Select Id, Comments__c from PartnerReferral__c where createdDate = Today];
        System.assertEquals(1,partRefList.size());
        System.assertEquals('Successful', partRefList.get(0).Comments__c);
        
        Referral_Account__c refAcct = [Select Id, Name, Street_Address_2__c from Referral_Account__c where createdDate = Today];
        System.assertEquals('Suite 100',refAcct.Street_Address_2__c);
        
        Referral_Contact__c refCtct = [Select Id, First_Name__c, Last_Name__c, Name, Mailing_Street__c, Mailing_City__c,  
                          Mailing_State__c, Mailing_Postal_Code__c, LoadCampaignPrev__c, LatestCampaign__c, AICPA_Original_Type__c
                          from Referral_Contact__c where createdDate = Today];
        System.assertEquals('Sam',refCtct.First_Name__c);
        System.assertEquals('10 Main Street Suite 100', refCtct.Mailing_Street__c);
        System.assertEquals('Anytown', refCtct.Mailing_City__c);
        System.assertEquals('NY', refCtct.Mailing_State__c);
        System.assertEquals('10019', refCtct.Mailing_Postal_Code__c);
        System.assertEquals(aicpaSetting.CampaignId__c, refCtct.LoadCampaignPrev__c);
       System.assertEquals(aicpaSetting.CampaignId__c, refCtct.LatestCampaign__c);        
       System.assertEquals('CPA.com Gated White Paper', refCtct.AICPA_Original_Type__c);            
  } // testCreate
    
    
   /** populate setting used to determine if email needs to be forwarded
   */
  
   public static void populatePayxSetting() { 
        PaychexSettings__c payx = new PaychexSettings__c (
            Name = 'AICPAForwardEmail'
            ,IsActive__c=true
            ,Attribute1__c = 'cmfreema@paychex.com');
        upsert payx;        
        PaychexSettings__c errpayx = new PaychexSettings__c (
            Name = 'AICPAForwardErrorEmail'
            ,IsActive__c=true
            ,Attribute1__c = 'cmfreema@paychex.com');
        upsert errpayx;        
       
        Schema.RecordTypeInfo cmpgnRt = RecordTypeHelper.getRecordType('Marketing Record Type', 'Campaign');
        Campaign cmp = new Campaign(Name = 'Paychex Gated Asset', Status='In Progress',StartDate = System.TODAY(), IsActive=true,
                                    Originator__c='Marketing', LeadSource__c='Referral-CPA-AICPA', Type='Referral Program', RecordTypeId=cmpgnRt.getRecordTypeId());
        insert cmp;
       
        AICPALeadSettings__c als = new AICPALeadSettings__c (
          Name = 'Paychex Gated Asset',CampaignID__c=cmp.Id, Original_Type__c = 'CPA.com Gated White Paper');
        upsert als;
                                   
    } // populatePayxSetting  
     
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }
     
} // AICPAEmailHandlerTest