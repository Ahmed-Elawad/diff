/** 
 * The test methods for the OpportunityCreateCase class and OpptyCheckStatus trigger.
 *
 * History
 * -------
 * 06/28/2010 Dan Carmen        Created
 * 10/07/2010 Dan Carmen        Added logic to delete case and reference core payroll when
 *                              status changed from sold to pending or not sold.
 * 09/15/2011 Dan Carmen        Added logic for PEO
 * 10/31/2011 Dan Carmen        Added in check for PEO Service Center
 * 02/22/2012 Cindy Freeman     Added in check for Advisor Select
 * 09/05/2013 Dan Carmen        Cleaned up code, added ASO changes
 * 09/12/2013 Dan Carmen        Added HNBF record types
 * 05/29/2015 Jacob Hinds       Added in Reason Sold/Not Sold in opptys
 * 03/27/2017 Cindy Freeman     commented out testMPSCStatusFromSoldAndCurrentStepNotCaseCreation to avoid hitting too many SOQL limit
 * 13/06/2017 Saketh            Updated to include Referral Contact wihle inserting Opportunities so that it passes the validation on Referral Contacts 
 * 06/26/2017 Lynn Michels      Updated status for PEO record types to Qualified and added criteria to get by validation rules
 * 11/01/2017 Cindy Freeman     create Referral Account and Contact before create Acct so can set CPA Name Ref and avoid validation rule
 * 03/07/2018 Lynn Michels      added method to create BenAdmin Cases from Sold Ops with FLEX Benefits Administration products
 * 05/08/2018 Lynn Michels      adding value for How_was_the_Advisor_Selected__c to prevent validation rule error and updating the opp status to create benadmin case for HNBF opps
   07/08/2019 Dan Carmen        Change for Core Sales profile move
   07/29/2019 Brandon Vidro		Added Primary Competition field to testCoreOppty
   08/06/2019 Brandon Vidro     Added H&B Renewal Date to acct
   04/10/2020 Brandon Vidro     Added Promotion field to Opp for COVID-19
   11/03/2020 Carrie Marciano  Added Approved Quote Exception/Reason to opportunities due to new validation rule that requires approved quotes for oppty to be marked Sold
   05/29/2021 Dan Carmen        Updated to use Labels for StageName
   07/26/2022 Carrie Marciano	Added Approved Quote Exception to sold oppty creation to pass validation rule
   09/27/2022 Josh Cartwright   updated createSoldOppty to add fields to pass validation rule 
   08/08/2023 Carrie Marciano	Added oppty1.P_C_Quote_Result__c = 'Warm Transfer to PC'; to get past validation rule requiring PC Quote Result to be populated on Sold oppties
   11/07/2023 Eric Porter     Updated CreateSoldOppty method to include new fields on newly created Opptys(Pain_Points__c, What_Brought_Them_To_Paychex__c, and Products_Of_Interest__c).
   3/20/2024  Carrie Marciano    Removed code related to old MPSC Process
 */
@isTest
private class OpportunityCreateCaseTest {

   public static Opportunity createSoldOppty(boolean verifyCreate) {
      // create referral account and contact
      Referral_Account__c ra1 = new Referral_Account__c(name='Test Ref Acct', Street_Address_1__c='12 ABC Street', City__c='City', State_Province__c='NY', Zip_Postal_Code__c='14612', Referral_Source_Business_Type__c='Financial Services');
      insert ra1;
      system.debug('**CLM BankLeadSalesRepChatterPostTest - insert RefAcct '+ ra1.Id);
      Referral_Contact__c r1 = new Referral_Contact__c(name='Test1',Referral_Id__c='Dan1', Phone__c='7161234569',Referral_Account__c=ra1.Id);
      insert r1;
      
      // create an account
      Account acct = new Account(Name='Test Acct', CPA_Name_Ref__c = r1.Id, H_B_Renewal_Date__c = 'May', Work_Comp_Renewal_Date__c = 'May');
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id);
      insert ctct;
      /*
      Referral_Account__c ra1 = new Referral_Account__c(name='Test Ref Acct', Street_Address_1__c='12 ABC Street', City__c='City', State_Province__c='NY', Zip_Postal_Code__c='14612', Referral_Source_Business_Type__c='Financial Services');
      insert ra1;
      system.debug('**CLM BankLeadSalesRepChatterPostTest - insert RefAcct '+ ra1.Id);
      Referral_Contact__c r1 = new Referral_Contact__c(name='Test1',Referral_Id__c='Dan1', Phone__c='7161234569',Referral_Account__c=ra1.Id);
      insert r1;
      */
      // create core opportunities
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
      Opportunity oppty1 = new Opportunity(Name='Test Opporty1', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      Opportunity oppty2 = new Opportunity(Name='Test Opporty2', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      
      // create PEO opportunities
      Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
      Opportunity oppty3 = new Opportunity(Name='Test Opporty3', RecordTypeId=peoOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      Opportunity oppty4 = new Opportunity(Name='Test Opporty4', RecordTypeId=peoOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());

      // create Advisor Select opportunities
      Schema.RecordTypeInfo advOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K,'Opportunity');
      Opportunity oppty5 = new Opportunity(Name='Test Opporty5', RecordTypeId=advOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId()
                                         ,How_was_the_Advisor_Selected__c = 'No FA'
                                         ,Will_a_FA_be_attached_to_the_Plan__c ='No'
                                         ,Did_a_FA_Refer_this_Plan__c='No');
      Opportunity oppty6 = new Opportunity(Name='Test Opporty6', RecordTypeId=advOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId()
                                         ,How_was_the_Advisor_Selected__c = 'No FA'
                                         ,Will_a_FA_be_attached_to_the_Plan__c ='No'
                                         ,Did_a_FA_Refer_this_Plan__c='No');
      
      // create ASO opportunities
      Opportunity oppty7 = new Opportunity(Name='Test Opporty7', RecordTypeId=peoOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
                                         
      Opportunity oppty8 = new Opportunity(Name='Test Opporty8', RecordTypeId=peoOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      
      Opportunity[] opptys = new Opportunity[]{oppty1,oppty2,oppty3,oppty4,oppty5,oppty6,oppty7,oppty8};
      insert opptys;
      
      PickListValue__c tempPL = new PickListValue__c(name='testName',PicklistType__c='Competitor');
      insert tempPL;
      Competitor__c comp1 = new Competitor__c(Name='test1', Opportunity__c = oppty1.Id , PickListValue__c = tempPL.Id);
      Competitor__c comp2 = new Competitor__c(Name='test2', Opportunity__c = oppty2.Id , PickListValue__c = tempPL.Id);
      Competitor__c comp3 = new Competitor__c(Name='test3', Opportunity__c = oppty3.Id , PickListValue__c = tempPL.Id);
      Competitor__c comp4 = new Competitor__c(Name='test4', Opportunity__c = oppty4.Id , PickListValue__c = tempPL.Id);
      Competitor__c comp5 = new Competitor__c(Name='test5', Opportunity__c = oppty5.Id , PickListValue__c = tempPL.Id);
      Competitor__c comp6 = new Competitor__c(Name='test6', Opportunity__c = oppty6.Id , PickListValue__c = tempPL.Id);
      Competitor__c comp7 = new Competitor__c(Name='test7', Opportunity__c = oppty7.Id , PickListValue__c = tempPL.Id);
      Competitor__c comp8 = new Competitor__c(Name='test8', Opportunity__c = oppty8.Id , PickListValue__c = tempPL.Id);
      Competitor__c[] compList = new Competitor__c[]{comp1,comp2,comp3,comp4,comp5,comp6,comp7,comp8};
      insert compList;
      
      // link the contact to the opportunity
      OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty1.Id, IsPrimary=true);
      OpportunityContactRole ocr2 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty2.Id, IsPrimary=true);
      OpportunityContactRole ocr3 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty3.Id, IsPrimary=true);
      OpportunityContactRole ocr4 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty4.Id, IsPrimary=true);
      OpportunityContactRole ocr5 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty5.Id, IsPrimary=true);
      OpportunityContactRole ocr6 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty6.Id, IsPrimary=true);      
      OpportunityContactRole ocr7 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty7.Id, IsPrimary=true);      
      OpportunityContactRole ocr8 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty8.Id, IsPrimary=true);      
      OpportunityContactRole[] ocrs = new OpportunityContactRole[]{ocr1,ocr2,ocr3,ocr4,ocr5,ocr6,ocr7,ocr8};
      insert ocrs;
      
      System.assertEquals(0,[Select count() from Case]);
      
      // create cases that already exist - make sure dupes aren't created
      Schema.RecordTypeInfo caseRtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_CORE,'Case');
      Case case2 = new Case(ContactId = ctct.Id
                              ,AccountId = acct.Id
                              ,Service_Location__c = oppty2.Service_Location__c
                              ,User__c = oppty2.OwnerId
                              ,RecordTypeId = caseRtCore.getRecordTypeId()
                              ,OwnerId = UserInfo.getUserId()
                              ,Opportunity__c = oppty2.Id
                               );
      Schema.RecordTypeInfo caseRtPeo = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_PEO,'Case');
      Case case4 = new Case(ContactId = ctct.Id
                              ,AccountId = acct.Id
                              ,User__c = oppty4.OwnerId
                              ,RecordTypeId = caseRtPeo.getRecordTypeId()
                              ,OwnerId = UserInfo.getUserId()
                              ,Opportunity__c = oppty4.Id
                               );
      Schema.RecordTypeInfo caseRtAdv = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_ADV,'Case');
      Case case6 = new Case(ContactId = ctct.Id
                              ,AccountId = acct.Id
                              ,User__c = oppty6.OwnerId
                              ,RecordTypeId = caseRtAdv.getRecordTypeId()
                              ,OwnerId = UserInfo.getUserId()
                              ,Opportunity__c = oppty6.Id
                               );
      Schema.RecordTypeInfo caseRtAso = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_ASO,'Case');
      Case case8 = new Case(ContactId = ctct.Id
                              ,AccountId = acct.Id
                              ,User__c = oppty8.OwnerId
                              ,RecordTypeId = caseRtAso.getRecordTypeId()
                              ,OwnerId = UserInfo.getUserId()
                              ,Opportunity__c = oppty8.Id
                               );
      Case[] cases = new Case[]{case2,case4,case6,case8};
      insert cases;
      Test.startTest();
      // should only be three cases
      System.assertEquals(4,[Select count() from Case]);
      
      // update all opportunities to create their cases
      oppty1.TotalOpportunityQuantity = 1;
      oppty1.Employees_Paid_Per_Payroll__c = 2;
      oppty1.Promotion__c = 'None';
      oppty1.Frequency__c = '1';
      oppty1.NextStep = 'Test';
      oppty1.Amount = 100;
      oppty1.Primary_Competition__c = 'Bank';
      oppty1.StageName = Label.OppStage_Sold;
      oppty1.Referral_Contact__c = r1.id;
      oppty1.Service_Location__c = 'Foxboro Branch 0008';
      oppty1.Prod_Payroll__c = true;
      oppty1.Reason_Not_Sold__c = 'API';
      oppty1.Approved_Quotes_Exception__c = True;
      oppty1.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ;  
      oppty1.P_C_Quote_Result__c = 'Warm Transfer to PC';
      oppty1.Pain_Points__c='HRIS';
      oppty1.Products_of_Interest__c='Hiring & Onboarding';
      oppty1.What_brought_them_to_Paychex__c='Bank';
      oppty1.Reason_Won__c ='Pricing';
      oppty1.Reason_Won_Details__c  ='Pricing transparency';
            
      oppty2.TotalOpportunityQuantity = 1;
      oppty2.Employees_Paid_Per_Payroll__c = 2;
      oppty2.Promotion__c = 'None';
      oppty2.Frequency__c = '1';
      oppty2.NextStep = 'Test';
      oppty2.Amount = 100;
      oppty2.Primary_Competition__c = 'Bank';
      oppty2.StageName = Label.OppStage_Sold;
      oppty2.Referral_Contact__c = r1.id;
      oppty2.Service_Location__c = 'Foxboro Branch 0008';
      oppty2.Prod_Payroll__c = true;
      oppty2.Reason_Not_Sold__c = 'API';
      oppty2.Approved_Quotes_Exception__c = True;
      oppty2.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ;   
      oppty2.P_C_Quote_Result__c = 'Warm Transfer to PC'; 
      oppty2.Pain_Points__c='HRIS';
      oppty2.Products_of_Interest__c='Hiring & Onboarding';
      oppty2.What_brought_them_to_Paychex__c='Bank';
      oppty2.Reason_Won__c ='Pricing';
      oppty2.Reason_Won_Details__c  ='Pricing transparency';

      oppty3.Amount = 100;
      oppty3.Promotion__c = 'None';
      oppty3.NextStep = 'Test';
      oppty3.StageName = Label.OppStage_Sold; //'Sold - Revenue Recognition';
      oppty3.Primary_Competition__c = 'Bank';
      oppty3.Payroll_Platform__c = 'PAS';
      oppty3.Service_Location__c = OpportunityCreateCase.PEO_SERVICE_CENTER;
      oppty3.Reason_Not_Sold__c = 'API';
      oppty3.Approved_Quotes_Exception__c = True;
      oppty3.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ;
      oppty3.Pain_Points__c='HRIS';
      oppty3.Products_of_Interest__c='Hiring & Onboarding';
      oppty3.What_brought_them_to_Paychex__c='Bank';
      oppty3.Reason_Won__c ='Pricing';
      oppty3.Reason_Won_Details__c  ='Pricing transparency';

      oppty4.Amount = 100;
      oppty4.NextStep = 'Test';
      oppty4.Promotion__c = 'None';
      oppty4.StageName = Label.OppStage_Sold; //'Sold - Revenue Recognition';
      oppty4.Primary_Competition__c = 'Bank';
      oppty4.Payroll_Platform__c = 'PAS';
      oppty4.Service_Location__c = OpportunityCreateCase.PEO_SERVICE_CENTER;
      oppty4.Reason_Not_Sold__c = 'API';
      oppty4.Approved_Quotes_Exception__c = True;
      oppty4.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ;
      oppty4.Pain_Points__c='HRIS';
      oppty4.Products_of_Interest__c='Hiring & Onboarding';
      oppty4.What_brought_them_to_Paychex__c='Bank';
      oppty4.Reason_Won__c ='Pricing';
      oppty4.Reason_Won_Details__c  ='Pricing transparency';


      oppty5.Amount = 100;
      oppty5.NextStep = 'Test';
      oppty5.Promotion__c = 'None';
      oppty5.Primary_Competition__c = 'Bank';
      oppty5.StageName = Label.OppStage_Sold;
      oppty5.Service_Location__c = OpportunityCreateCase.ADV_SERVICE_CENTER;
      oppty5.Reason_Not_Sold__c = 'API';
      oppty5.Approved_Quotes_Exception__c = True;
      oppty5.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ; 
      oppty5.Pain_Points__c='HRIS';
      oppty5.Products_of_Interest__c='Hiring & Onboarding';
      oppty5.What_brought_them_to_Paychex__c='Bank';
      oppty5.Reason_Won__c ='Pricing';
      oppty5.Reason_Won_Details__c  ='Pricing transparency';


      
      oppty6.Amount = 100;
      oppty6.NextStep = 'Test';
      oppty6.Promotion__c = 'None';
      oppty6.Primary_Competition__c = 'Bank';
      oppty6.StageName = Label.OppStage_Sold;
      oppty6.Service_Location__c = OpportunityCreateCase.ADVFSA_SERVICE_CENTER;
      oppty6.Reason_Not_Sold__c = 'API';
      oppty6.Approved_Quotes_Exception__c = True;
      oppty6.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ; 
      oppty6.Pain_Points__c='HRIS';
      oppty6.Products_of_Interest__c='Hiring & Onboarding';
      oppty6.What_brought_them_to_Paychex__c='Bank';
      oppty6.Reason_Won__c ='Pricing';
      oppty6.Reason_Won_Details__c  ='Pricing transparency';
            
      oppty7.Amount = 100;
      oppty7.NextStep = 'Test';
      oppty7.Promotion__c = 'None';
      oppty7.Primary_Competition__c = 'Bank';
      oppty7.StageName = Label.OppStage_Sold;
      oppty7.Payroll_Platform__c = 'PAS';
      oppty7.Service_Location__c = OpportunityCreateCase.ASO_SERVICE_CENTER;
      oppty7.Reason_Not_Sold__c = 'API';
      oppty7.Approved_Quotes_Exception__c = True;
      oppty7.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ;
      oppty7.Pain_Points__c='HRIS';
      oppty7.Products_of_Interest__c='Hiring & Onboarding';
      oppty7.What_brought_them_to_Paychex__c='Bank';
      oppty7.Reason_Won__c ='Pricing';
      oppty7.Reason_Won_Details__c  ='Pricing transparency';
            
      oppty8.Amount = 100;
      oppty8.NextStep = 'Test';
      oppty8.Promotion__c = 'None';
      oppty8.Primary_Competition__c = 'Bank';
      oppty8.StageName = Label.OppStage_Sold;
      oppty8.Payroll_Platform__c = 'PAS';
      oppty8.Service_Location__c = OpportunityCreateCase.ASO_SERVICE_CENTER;
      oppty8.Reason_Not_Sold__c = 'API';
      oppty8.Approved_Quotes_Exception__c = True;
      oppty8.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ;
      oppty8.Pain_Points__c='HRIS';
      oppty8.Products_of_Interest__c='Hiring & Onboarding';
      oppty8.What_brought_them_to_Paychex__c='Bank';
      oppty8.Reason_Won__c ='Pricing';
      oppty8.Reason_Won_Details__c  ='Pricing transparency';
       
      //Test.startTest();
      update opptys;
      //Test.stopTest();
      Test.stopTest();
      // should now be 7 cases - only 3 more should be created.
      System.assertEquals(7,[Select count() from Case]);
       
      if (verifyCreate) {

         Case c = [Select Id, ContactId ,AccountId 
                         ,Service_Location__c
                         ,RecordType.Name
                         ,OwnerId
                         ,Owner.Name
                     from case
                    where AccountId = :acct.Id
                      and Opportunity__c = :oppty1.Id];
       
         System.assertEquals(acct.Id,c.AccountId);
         System.assertEquals(ctct.Id,c.ContactId);
         System.assertEquals(oppty1.Service_Location__c,c.Service_Location__c);
         System.assertEquals(OpportunityCreateCase.RT_CASE_CORE,c.RecordType.Name);
       
      } // if (verifyCreate
      return oppty1;
   } // createSoldOppty

   private static User getCoreRep() {
      User u = [Select Id, Name, Sales_Org__c from User where Profile.Name in :Utilities.CORE_PROFS and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='PAY' limit 1];
      return u;
   } // getCoreRep
   
   static testMethod void testCoreOppty() {
      User u = getCoreRep();
      System.runAs(u) {
         Opportunity oppty = createSoldOppty(true);
      }
   } // testCoreOppty
      
   static testMethod void testChangeStatusFromSoldToPending() {
      User u = getCoreRep();

      // create an account
      Account acct = new Account(Name='Test Acct', OwnerId=u.Id);
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id, OwnerId = u.Id);
      insert ctct;
      // create a core opportunity
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
      Opportunity oppty = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Sold
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=u.Id
                                         ,Service_Location__c = 'Foxboro Branch 0008'
                                         ,Prod_Payroll__c = true);
                                       
      insert oppty;
      // create a case
      Schema.RecordTypeInfo caseRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_CORE,'Case');
      Case thisCase = new Case(ContactId = ctct.Id
                              ,AccountId = acct.Id
                              ,Service_Location__c = oppty.Service_Location__c
                              ,User__c = oppty.OwnerId
                              ,RecordTypeId = caseRt.getRecordTypeId()
                              ,OwnerId = UserInfo.getUserId()
                              ,Opportunity__c = oppty.Id
                               );
      insert thisCase;
      
      //RecordType rcpRt = AccountHelper.getRecordType('Reference Onboarding Core Payroll','Reference_Core_Payroll__c');
      Schema.RecordTypeInfo rcpRt = RecordTypeHelper.getRecordType('Reference Onboarding Core Payroll','Reference_Core_Payroll__c');
      Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(
                             RecordTypeId = rcpRt.getRecordTypeId()
                            ,Case_Lookup__c = thisCase.Id
                            ,Opportunity_Lookup__c = oppty.Id
                            ,Sales_Rep__c = oppty.OwnerId
                            ,Proposed_Run_Date__c = oppty.CloseDate
                            ,Client_Load_Received__c = false
                            ,OwnerId = thisCase.OwnerId
                            ,Contact__c = thisCase.ContactId
                            );
      insert rcp;
      
      Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
      Opportunity oppty4 = new Opportunity(Name='Test Opporty', RecordTypeId=peoOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Sold
                                         ,Approved_Quotes_Exception__c = True
      									 ,Approved_Quote_Exception_Reason__c = 'No Attached Quote'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      insert oppty4;
      
      Schema.RecordTypeInfo caseRtPeo = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_PEO,'Case');
      Case case4 = new Case(ContactId = ctct.Id
                              ,AccountId = acct.Id
                              ,User__c = oppty4.OwnerId
                              ,RecordTypeId = caseRtPeo.getRecordTypeId()
                              ,OwnerId = UserInfo.getUserId()
                              ,Opportunity__c = oppty4.Id
                               );
      insert case4;
      // verify reference object also created
      System.assertEquals(1,[Select count() from Reference_PEO__c where Opportunity__c = :oppty4.Id]);
      
      //System.runAs(u) {
         oppty.StageName = Label.OppStage_Qualified;
         oppty4.StageName = Label.OppStage_Qualified;
         Test.startTest();
         Opportunity[] opptys = new Opportunity[]{oppty,oppty4};
         update opptys;
         Test.stopTest();
      //} // System.runAs
      
      // verify case and reference object are deleted
      System.assertEquals(0,[Select count() from Reference_Core_Payroll__c where Opportunity_Lookup__c = :oppty.Id]);
      System.assertEquals(0,[Select count() from Case where Opportunity__c = :oppty.Id]);
      // decided not to delete reference PEO if stage changed
      System.assertEquals(1,[Select count() from Reference_PEO__c where Opportunity__c = :oppty4.Id]);
      System.assertEquals(1,[Select count() from Case where Opportunity__c = :oppty4.Id]);
   
   } // testChangeStatusFromSoldToPending
   
   static testMethod void testChangeStatusFromSoldForMPSC() {
        User u = getCoreRep();
        
      // create an account
      Account acct = new Account(Name='Test Acct', OwnerId=u.Id);
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id, OwnerId = u.Id);
      insert ctct;
      // create a core opportunity with MPSC Service Location
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
      Opportunity oppty = new Opportunity(Name='MPSC Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Sold
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=u.Id
                                         ,Service_Location__c = 'MPSC Rochester 940'
                                         ,Prod_Payroll__c = true);
                                         
      insert oppty;
      // create an MPSC case
      Schema.RecordTypeInfo caseRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_CASE_MPSC,'Case');
      Case thisCase = new Case(ContactId = ctct.Id
                              ,AccountId = acct.Id
                              ,Service_Location__c = oppty.Service_Location__c
                              ,User__c = oppty.OwnerId
                              ,RecordTypeId = caseRt.getRecordTypeId()
                              ,OwnerId = UserInfo.getUserId()
                              ,Opportunity__c = oppty.Id
                               );
      insert thisCase;
      
      //create an MPSC Reference Core Payroll record
      Schema.RecordTypeInfo rcpRt = RecordTypeHelper.getRecordType('Reference MPSC Onboarding Core Payroll','Reference_Core_Payroll__c');
      Reference_Core_Payroll__c rcp = new Reference_Core_Payroll__c(
                             RecordTypeId = rcpRt.getRecordTypeId()
                            ,Case_Lookup__c = thisCase.Id
                            ,Opportunity_Lookup__c = oppty.Id
                            ,Sales_Rep__c = oppty.OwnerId
                            ,Proposed_Run_Date__c = oppty.CloseDate
                            ,Client_Load_Received__c = false
                            ,OwnerId = thisCase.OwnerId
                            ,Contact__c = thisCase.ContactId
                            ,Current_Step__c = 'Case Creation');
      insert rcp;
      
     System.assertEquals(1,[SELECT count() FROM Reference_Core_Payroll__c
                                           WHERE Opportunity_Lookup__c =: oppty.id
                                           AND RecordType.Name =: 'Reference MPSC Onboarding Core Payroll']);
     System.assertEquals(1,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_MPSC]); 
    
    //if the Reference Core Payroll record is still in Case Creation when the opportunity goes from Sold to Not Sold,
    //delete the CAse and Reference Core Payroll records.                                           
    oppty.StageName=Label.OppStage_Lost;
    
    Test.startTest();
    update oppty;
    Test.stopTest();
    
    System.assertEquals(0,[SELECT count() FROM Reference_Core_Payroll__c
                                                WHERE Opportunity_Lookup__c =: oppty.id
                                                AND RecordType.Name =: 'Reference MPSC Onboarding Core Payroll']);
    System.assertEquals(0,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_MPSC]);  
    }// end testChangeStatusFromSoldForMPSC
 
   static testMethod void testChangeStatusFromSoldNoCase() {
      User u = getCoreRep();

      // create an account
      Account acct = new Account(Name='Test Acct', OwnerId=u.Id);
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id, OwnerId = u.Id);
      insert ctct;
      // create a core opportunity
      Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
      Opportunity oppty = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Sold
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=u.Id
                                         ,Service_Location__c = 'Foxboro Branch 0008'
                                         ,Prod_Payroll__c = true);
      insert oppty;

      System.runAs(u) {
         oppty.StageName = Label.OppStage_Qualified;
         Test.startTest();
         update oppty;
         Test.stopTest();
      } // System.runAs
      
      // verify case and reference object are deleted
      
   } // testChangeStatusFromSold
   
   static testMethod void testASOOnboardingCaseCreation() {
    
     User u = [Select Id, Name, Sales_Org__c from User where Profile.Name='HRS PEO-ASO Sales - SB'  and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='PAS' limit 1];
      
    // create an account
      Account acct = new Account(Name='Test Acct', OwnerId=u.Id);
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id, OwnerId = u.Id);
      insert ctct;
      // create an ASO opportunity with 'ASO Service Center' Location
      Schema.RecordTypeInfo asoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_ASO,'Opportunity');
      Opportunity oppty = new Opportunity(Name='Test ASO Opporty', RecordTypeId=asoOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=u.Id
                                         ,Service_Location__c = 'ASO Service Center'
                                         ,Prod_Payroll__c = true
                                         ,Payroll_Units__c = 5);
      insert oppty;
      
      
      System.assertEquals(0,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_ASO]); 
      
      oppty.Approved_Quotes_Exception__c = True;
      oppty.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ; 
      oppty.StageName = Label.OppStage_Sold;
      update oppty;
      
      System.assertEquals(1,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_ASO]);
  }//end testASOOnboardingCaseCreation
  /*
   static testMethod void testBenAdminCaseCreationonMMSOpp() {
    
     User u = [Select Id, Name, Sales_Org__c from User where Profile.Name='MMS Sales - SB'  and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='MMS' limit 1];
      
    // create an account
      Account acct = new Account(Name='Test Acct', OwnerId=u.Id);
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id, OwnerId = u.Id);
      insert ctct;
      // create an MMS opportunity with a FLEX Benefits Administration Essentials product (shown in the product summary field)
      Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
      Opportunity oppty = new Opportunity(Name='Test MMM Opporty', RecordTypeId=mmsOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=u.Id
                                         ,Service_Location__c = 'Foxboro Branch 0008'
                                         ,Prod_Payroll__c = true
                                         ,Payroll_Units__c = 5
                                         ,Product_Summary__c = 'FBAE;');
      insert oppty;
      
      
      System.assertEquals(0,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_MPSCBenAdmin]); 
      
      oppty.Approved_Quotes_Exception__c = True;
      oppty.Approved_Quote_Exception_Reason__c = 'No Attached Quote' ; 
      oppty.StageName = Label.OppStage_Sold;
      update oppty;
      
      System.assertEquals(1,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_MPSCBenAdmin]);
  }//end testBenAdminCaseCreationonMMSOpp
  
  
  static testMethod void testBenAdminCaseCreationonHNBFOpp() {
    
     User u = [Select Id, Name, Sales_Org__c from User where Profile.Name='HNBF Sales Rep - SB'  and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='HNBF' limit 1];
      
    // create an account
      Account acct = new Account(Name='Test Acct', OwnerId=u.Id);
      insert acct;
      // create a contact
      Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id, OwnerId = u.Id);
      insert ctct;
      // create an HNBF opportunity with a FLEX Benefits Administration Essentials product (shown in the product summary field)
      Schema.RecordTypeInfo hnbfOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_HNBF,'Opportunity');
      Opportunity oppty = new Opportunity(Name='Test HNBF Opporty', RecordTypeId=hnbfOpptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName=Label.OppStage_Qualified
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=u.Id
                                         ,Service_Location__c = 'Foxboro Branch 0008'
                                         ,Prod_Payroll__c = true
                                         ,Payroll_Units__c = 5
                                         ,Product_Summary__c = 'FBAE;');
      insert oppty;
      
      
      System.assertEquals(0,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_MPSCBenAdmin]); 
                                           
      oppty.StageName = 'Picked Up';
      update oppty;
      
      System.assertEquals(1,[SELECT count() FROM Case
                                           WHERE Opportunity__c =: oppty.Id
                                           AND RecordType.Name =: OpportunityCreateCase.RT_CASE_MPSCBenAdmin]);
  }//end testBenAdminCaseCreationonHNBFOpp
  */  
} // class OpportunityCreateCaseTest