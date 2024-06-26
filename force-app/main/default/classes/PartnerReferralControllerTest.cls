/* Test methods for the PartnerReferralController class.
   
  History
  -------
  02/05/2016 Dan Carmen   Created
  08/31/2017 Jermaine Stukes  Added test for bad cont
  12/14/2018 Dan Carmen       Change to display product selection
  07/15/2019 Matt Fritschi    Added two new products, checks for the auto selection of payroll with Freshlime or Paycard
  11/01/2021 Pujitha Madamachi  Added Tier I process

 */
@isTest
private class PartnerReferralControllerTest {

   static testMethod void testBadPartnerId() {
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('PartnerId','BadId');
      System.CurrentPageReference().getParameters().put('CustomerForm','true');
      PartnerReferralController prc = new PartnerReferralController(sc1);
      
      System.assertEquals(true,prc.customerForm);
      System.assertEquals(false,prc.partnerIdFound);
      
   } // testBadPartnerId
   
   static testMethod void testParentNoChildren() {
      
      Partner__c partParent = new Partner__c(Name='Test Parent', PartnerId__c='Test1', PostalCode__c='12345');
      insert partParent;
      
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('PartnerId',partParent.PartnerId__c);
      System.CurrentPageReference().getParameters().put('CustomerForm','true');
      PartnerReferralController prc = new PartnerReferralController(sc1);
      
      System.assertEquals(true,prc.customerForm);
      System.assertEquals(true,prc.partnerIdFound);
      System.assertEquals(false,prc.hasMultipleBranches);
      System.assertEquals(false,prc.hasPartnerLogo);
      System.assertEquals(false,prc.refCtctEntry);
      System.assertEquals(false,prc.partnerRef.SubmitAsEmail__c);
      
      System.assertEquals(Label.ReferralFormLocationLabel,prc.partnerLocationLabel);
      
      prc.partnerRef.LastName__c='TestLast';
      prc.partnerRef.Company__c='Test Company';
      // setting this to false because we don't want anything else to occur during this test - just testing the controller!
      prc.partnerRef.ProcessReferral__c = false;
      
      prc.submitReferral();
      
      System.assertEquals(1,[select count() from PartnerReferral__c]);
   } // testParentNoChildren

   static testMethod void testParentWithOneChildAndDetail() {
      
      Account acct = new Account(Name='Test Parent', ShippingPostalCode='12340', PartnerId__c='Test1');
      insert acct;
      
      PartnerDetail__c partDetail = new PartnerDetail__c(Account__c=acct.Id, ReferralFormDescription__c='This is a test description for the form'
                                             ,ReferralFormLocationLabel__c='Place');
      insert partDetail;
      
      Partner__c partParent = new Partner__c(Name='Test Parent', PartnerId__c='Test1', PostalCode__c='12340', Account__c=acct.Id, PartnerDetail__c=partDetail.Id);
      insert partParent;
      
      Partner__c partChild1 = new Partner__c(Name='Child 1', ParentPartner__c=partParent.Id, PostalCode__c='12341');
      insert partChild1;
      
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('PartnerId',partParent.PartnerId__c);
      System.CurrentPageReference().getParameters().put('CustomerForm','false');
      PartnerReferralController prc = new PartnerReferralController(sc1);
      
      System.assertEquals(false,prc.customerForm);
      System.assertEquals(true,prc.partnerIdFound);
      System.assertEquals(false,prc.hasMultipleBranches);
      System.assertEquals(false,prc.hasPartnerLogo);
      
      // the single branch should be defaulted
      System.assertEquals(partChild1.Id,prc.partnerRef.PartnerBranch__c);
      System.assertEquals(partDetail.ReferralFormLocationLabel__c,prc.partnerLocationLabel);
      System.assertEquals(partDetail.ReferralFormDescription__c, prc.bankDescription);
      
      prc.partnerRef.LastName__c='TestLast';
      prc.partnerRef.Company__c='Test Company';
      // setting this to false because we don't want anything else to occur during this test - just testing the controller!
      prc.partnerRef.ProcessReferral__c = false;
      
      prc.submitReferral();
      System.assertEquals(1,[select count() from PartnerReferral__c]);


   } // testParentWithOneChildAndDetail

   static testMethod void testParentWithChildren() {
      
      Partner__c partParent = new Partner__c(Name='Test Parent', PartnerId__c='Test1', PostalCode__c='12340');
      insert partParent;
      Partner__c partChild1 = new Partner__c(Name='Child 1', ParentPartner__c=partParent.Id, PostalCode__c='12341');
      Partner__c partChild2 = new Partner__c(Name='Child 2', ParentPartner__c=partParent.Id, PostalCode__c='12342');
      Partner__c partChild3 = new Partner__c(Name='Child 3', ParentPartner__c=partParent.Id, PostalCode__c='12343');
      Partner__c[] children = new Partner__c[]{partChild1,partChild2,partChild3};
      insert children;
      
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('PartnerId',partParent.PartnerId__c);
      System.CurrentPageReference().getParameters().put('CustomerForm','false');
      PartnerReferralController prc = new PartnerReferralController(sc1);
      
      System.assertEquals(false,prc.customerForm);
      System.assertEquals(true,prc.partnerIdFound);
      System.assertEquals(true,prc.hasMultipleBranches);
      System.assertEquals(false,prc.hasPartnerLogo);
      
      prc.partnerRef.LastName__c='TestLast';
      prc.partnerRef.Company__c='Test Company';
      // setting this to false because we don't want anything else to occur during this test - just testing the controller!
      prc.partnerRef.ProcessReferral__c = false;
      
      prc.submitReferral();
      // should fail because a branch wasn't selected
      System.assertEquals(0,[select count() from PartnerReferral__c]);
      
      
   } // testParentWithChildren
   
   static testMethod void testProductSelection()
   {
       Account acct = new Account(Name='Test Parent', ShippingPostalCode='12340', PartnerId__c='Test1');
      insert acct;
      
      PartnerDetail__c partDetail = new PartnerDetail__c(Account__c=acct.Id, ReferralFormDescription__c='This is a test description for the form'
                                             ,ReferralFormLocationLabel__c='Place',ReferralProducts__c='Payroll;401(k);Freshlime;Paycard');
      insert partDetail;
      
      Partner__c partParent = new Partner__c(Name='Test Parent', PartnerId__c='Test1', PostalCode__c='12340', Account__c=acct.Id, PartnerDetail__c=partDetail.Id);
      insert partParent;
      
      Partner__c partChild1 = new Partner__c(Name='Child 1', ParentPartner__c=partParent.Id, PostalCode__c='12341');
      insert partChild1;
      
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('PartnerId',partParent.PartnerId__c);
      System.CurrentPageReference().getParameters().put('CustomerForm','false');
      PartnerReferralController prc = new PartnerReferralController(sc1);
      
      prc.partnerRef.LastName__c='TestLast';
      prc.partnerRef.Company__c='Test Company';
      prc.partnerRef.Products__c = '[Freshlime;Paycard;Merchant Services]';
      
      prc.submitReferral();
       
      PartnerReferral__c newPart = [SELECT Id, Name, Products__c FROM PartnerReferral__c WHERE LastName__c = 'TestLast' LIMIT 1];
      System.assertEquals(true,newPart.Products__c.contains('Payroll') && newPart.Products__c.contains('Freshlime') && newPart.Products__c.contains('Paycard') && newPart.Products__c.contains('Merchant Services'));
   } // testProductSelection
    
    static testMethod void testMisc() {
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      PartnerReferralController prc = new PartnerReferralController(sc1);
      prc.entryMethod=PartnerReferralController.ENTRY_PARTNERID;
      System.assertEquals(true, prc.pageTitle.contains('Request Form'));
      System.assertEquals('Business Contact Information', prc.prospectInfoTitle);
      System.assertEquals(false,prc.formEntryOkay);

      prc.entryMethod=PartnerReferralController.ENTRY_REF_CTCT;
      System.assertEquals(true, prc.pageTitle.contains('Referral Request'));
      System.assertEquals('Referral Information', prc.prospectInfoTitle);
      
      prc.checkForPaymentMsg();
      System.assertEquals(false,prc.showAvailProdOptions);
      prc.clearForm();
      System.assertEquals(false,prc.isGuestUser);
      System.assertEquals(50,prc.textAreaColumns);
      prc.submitAnother();
      
   } // testMisc
   
   static testMethod void testRefCtct() {
      id refAcctRT1 = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();   
      id refCtctRT1 = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();  
   
      //create test ref account
      Referral_Account__c refAcct1 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT1); 
      insert refAcct1; 
      Id refAcctId = refAcct1.Id;
    
      //create contact
      Referral_Contact__c refCtct1 = ReferralObjectSyncTest.createTestRefCntct(refCtctRT1, refAcct1.id); 
      insert refCtct1;    
      Id refCtctId = refCtct1.Id;        

      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('Id',refCtct1.Id);
      PartnerReferralController prc = new PartnerReferralController(sc1);
      

   } // testRefCtct
    
    static testMethod void testRefContactCPA() {
        id refAcctRT1 = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();   
        id refCtctRT1 = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();  
        
        //create test ref account
        Referral_Account__c refAcct1 = ReferralObjectSyncTest.createTestRefAcct(refAcctRT1); 
        insert refAcct1; 
        Id refAcctId = refAcct1.Id;
        
        //create contact
        Referral_Contact__c refCtct1 = ReferralObjectSyncTest.createTestRefCntct(refCtctRT1, refAcct1.id); 
        insert refCtct1;    
        Id refCtctId = refCtct1.Id;        
        
        ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
        System.CurrentPageReference().getParameters().put('Id',refCtct1.Id);
        PartnerReferralController prc = new PartnerReferralController(sc1);
        
        
    } // testRefCtct
    static testMethod void testRefContactBADCPA() 
    {
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('ContactId','BadId');
        try
        {
            PartnerReferralController prc = new PartnerReferralController(sc1);
            System.assertEquals(true, String.isNotBlank(prc.contactId));
        }
        catch(exception e)
        {
            String errorMessage = 'Bad Id passed in for Partner Referral! ';
            Boolean expectedExceptionThrown =  e.getMessage().contains(errorMessage) ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }   
    } //testRefContactBADCPA
    
    static testMethod void testTierI() {
      
      Account acct = new Account(Name='Test Parent', ShippingPostalCode='12340', PartnerId__c='Test1',Referral_Type__c='52 Bank Tier 1');
      insert acct;
      
      PartnerDetail__c partDetail = new PartnerDetail__c(Account__c=acct.Id, ReferralFormDescription__c='This is a test description for the form'
                                             ,ReferralFormLocationLabel__c='Place');
      insert partDetail;
      
      Partner__c partParent = new Partner__c(Name='Test Parent', PartnerId__c='Test1', PostalCode__c='12340', Account__c=acct.Id, PartnerDetail__c=partDetail.Id);
      insert partParent;
      
      Partner__c partChild1 = new Partner__c(Name='Child 1', ParentPartner__c=partParent.Id, PostalCode__c='12341');
      insert partChild1;
      
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new PartnerReferral__c());
      System.CurrentPageReference().getParameters().put('PartnerId',partParent.PartnerId__c);
      System.CurrentPageReference().getParameters().put('CustomerForm','false');
      PartnerReferralController prc = new PartnerReferralController(sc1);
      
      System.assertEquals(true,prc.tierI);
      System.assertEquals('Referee Information', prc.prospectInfoTitle);
      System.assertEquals('Referring partner and/or Employee Info 1', prc.refereeInfoTitle);
   } // testTierI
} // class PartnerReferralControllerTest