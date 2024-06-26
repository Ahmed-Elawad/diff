/* 
 * Test methods for the CloneAccountController.
               
 *
 * History
 * -------
   04/21/2009 Dan Carmen   Created
   11/13/2017 Dan Carmen   Check comments, update API version of the code.
   03/08/2022 Dan Carmen           Removed old custom latitude and longitude fields

 *
 */
@isTest
private class TestCloneAccountController {

    static testMethod void testGroupUpdateController() {
      RecordType rtCore = [select id, name from RecordType where name='Core Account Record Type'];
      Account testAcct = new Account(Name='testMethod Acct'
          ,AccountNumber='17-TEST'
          ,Site='Site'
          ,OwnerId=UserInfo.getUserId()
          ,RecordTypeId=rtCore.Id
          ,NumberOfEmployees=12
          ,Phone='(585) 123-4567'
          ,Fax='(585) 987-6543'
          ,Type='Core Client'
          ,BillingStreet='123 Bill St'
          ,BillingCity='Bill City'
          ,BillingState='NY'
          ,BillingPostalCode='14624'
          ,ShippingStreet='123 Ship St'
          ,ShippingCity='Ship City'
          ,ShippingState='NY'
          ,ShippingPostalCode='14624'
          ,Time_Zone__c='EST'
          ,Frequency__c='Weekly'
          ,Current_Prior_Method__c='Intuit'
          ,HRO_Number__c = 'testMethod'
          ,HRO_Implementation_Coordinator__c = null
          ,HRO_NCP_Received_Date__c = system.today()
          ,HRO_Service_Agreement_Received__c = true
          ,HRO_First_Run_or_New_Setup_Date__c = system.today()
          ,HRO_Preview_Hosting_Client__c = true
          ,HRO_Group__c = true
          ,HRO_Total_ID_s__c = 1
          );
      insert testAcct;
      Asset prod1 = new Asset(AccountId = testAcct.Id, Product_Plan_Code__c='test123', Name='test123', Start_Date__c=System.today(), Product_End_Date__c=null, PurchaseDate=System.today());
      insert prod1;
      Asset prod2 = new Asset(AccountId = testAcct.Id, Product_Plan_Code__c='test456', Name='test456', Start_Date__c=System.today(), Product_End_Date__c=null, PurchaseDate=System.today());
      insert prod2;
      
      Account testAcct2 = [select id, Name, AccountNumber, (select Id, Name, Product_Plan_Code__c, Start_Date__c, Product_End_Date__c, PurchaseDate from Assets) from Account where id=:testAcct.Id];
      System.assertEquals(testAcct.Id, testAcct2.Id );
      
      // isAccountSet method
      // test isAccountSet if account is not set
      CloneAccountController cacNull = new CloneAccountController();
      boolean isSet = cacNull.getIsAccountSet();
      System.assertEquals(false,isSet);
      
      // test getIsAccountSet if account is set
      ApexPages.currentPage().getParameters().put('id', testAcct.Id);
      CloneAccountController cacAcct = new CloneAccountController();
      isSet = cacAcct.getIsAccountSet();
      System.assertEquals(true,isSet);
      
      // checkAddRows method
      // check if no account is set
      cacNull.setNumberGroupRecords(0);
      String nextPage = cacAcct.addMoreRows().getUrl();
      System.assertEquals('/apex/cloneaccount1',nextPage);
      System.assertEquals(0,cacNull.getNumberGroupRecords());
      // check if account is set
      cacAcct.setNumberGroupRecords(0);
      cacAcct.checkAddRows();
      System.assertEquals(5,cacAcct.getNumberGroupRecords());
      // check to make sure it will not go over 100 rows
      cacAcct.setNumberGroupRecords(97);
      cacAcct.checkAddRows();
      cacAcct.checkAddRows();
      System.assertEquals(100,cacAcct.getNumberGroupRecords());
      
      // check to make sure the options are correct
      List<SelectOption> prods = cacAcct.getProds();
      System.assertEquals(2,prods.size());
      
      // check the getHasProds method
      // no products
      System.assertEquals(false,cacNull.getHasProds());
      // has products
      System.assertEquals(true,cacAcct.getHasProds());
      
      // test the checkboxes
      String[] products = new String[]{prod1.Product_Plan_Code__c};
      cacAcct.setProducts(products);
      String[] products2 = cacAcct.getProducts();
      System.assertEquals(products.size(),products2.size());
      
      // test the next button without an account set
      // stay on cloneaccount1 page
      nextPage = cacNull.nextFromStep1().getUrl();
      System.assertEquals('/apex/cloneaccount1',nextPage);
      
      // test the next button. Account is set, group accounts is null.
      // stay on cloneaccount1 page
      nextPage = cacAcct.nextFromStep1().getUrl();
      System.assertEquals('/apex/cloneaccount1',nextPage);
      
      // test the next button. Account is set, group accounts is set to 5, no groups set.
      // stay on cloneaccount1 page
      cacAcct.setNumberGroupRecords(5);
      List<Account> accts = cacAcct.getAccts();
      System.assertEquals(5,accts.size());
      nextPage = cacAcct.nextFromStep1().getUrl();
      System.assertEquals('/apex/cloneaccount1',nextPage);
      // test if one of the accounts added matches the account number of existing account.
      Account testAcct3 = new Account(Name='testMethod Acct3',AccountNumber='17-TEST');
      cacAcct.getAccts().add(testAcct3);
      nextPage = cacAcct.nextFromStep1().getUrl();
      System.assertEquals('/apex/cloneaccount1',nextPage);
      // test with account with invalid account number
      Account testAcct4 = new Account(Name='testMethod Acct4',AccountNumber='17-44');
      cacAcct.getAccts().clear();
      cacAcct.getAccts().add(testAcct4);
      nextPage = cacAcct.nextFromStep1().getUrl();
      System.assertEquals('/apex/cloneaccount1',nextPage);
      // test with accounts for 1 insert and 2 updates. 1 update already has product.
      Account testAcct5 = new Account(Name='testMethod Acct5',AccountNumber='17-TEST5');
      insert testAcct5;
      Account testAcct6 = new Account(Name='testMethod Acct6',AccountNumber='17-TEST6');
      insert testAcct6;
      Asset prod6 = new Asset(AccountId = testAcct6.Id, Product_Plan_Code__c=prod1.Product_Plan_Code__c, Name='test123', Start_Date__c=System.today(), Product_End_Date__c=null, PurchaseDate=System.today());
      insert prod6;
      Account testAcct7 = new Account(Name='testMethod Acct7',AccountNumber='17-TEST7');
      cacAcct.getAccts().clear();
      cacAcct.getAccts().add(testAcct5);
      cacAcct.getAccts().add(testAcct6);
      cacAcct.getAccts().add(testAcct7);
      nextPage = cacAcct.nextFromStep1().getUrl();
      System.assertEquals('/apex/cloneaccount2',nextPage);
      System.assertEquals(true,cacAcct.getShowUpdates());
      System.assertEquals(true,cacAcct.getShowInserts());
      System.assertEquals(true,cacAcct.getShowSelected());
      
      // no inserts or updates, should return false
      System.assertEquals(false,cacNull.getShowUpdates());
      System.assertEquals(false,cacNull.getShowInserts());
      System.assertEquals(false,cacNull.getShowSelected());
      nextPage = cacAcct.save().getUrl();
      System.assertEquals('/'+cacAcct.getThisAcct().id,nextPage);
      
      // test with only an insert
      cacAcct.getAccts().clear();
      Account testAcct8 = new Account(Name='testMethod Acct8',AccountNumber='17-TEST8');
      cacAcct.getAccts().add(testAcct8);
      nextPage = cacAcct.nextFromStep1().getUrl();
      System.assertEquals('/apex/cloneaccount2',nextPage);
      System.assertEquals(false,cacAcct.getShowUpdates());
      System.assertEquals(true,cacAcct.getShowInserts());
      System.assertEquals(true,cacAcct.getShowSelected());
      nextPage = cacAcct.save().getUrl();
      System.assertEquals('/'+cacAcct.getThisAcct().id,nextPage);
      
      // check update name and insert name sizes
      cacAcct.getUpdateNames();
      cacAcct.getInsertNames();
      //System.assertEquals(cacAcct.updateNames.size(),cacAcct.getUpdateNames().size());
      //System.assertEquals(cacAcct.insertNames.size(),cacAcct.getInsertNames().size());
      
      // cancel button
      nextPage = cacAcct.cancel().getUrl();
      System.assertEquals('/'+cacAcct.getThisAcct().id,nextPage);
      
      /* for testing reference.
      controller = new thecontroller();
controller.setLastName('lastname');
controller.setFirstName('firstname');
controller.setCompany('acme');
controller.setEmail('firstlast@acme.com');
nextPage = controller.save().getUrl();
// Verify that the success page displays
System.assertEquals('/apex/success', nextPage);
Lead[] leads = [select id, email from lead where Company = 'acme'];
System.assertEquals('firstlast@acme.com', leads[0].email);
      */
   } // testGroupUpdateController
} // class TestCloneAccountController