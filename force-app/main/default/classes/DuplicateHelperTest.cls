/* 
 * A Helper class for checking duplicates in code
 *
 * History
 * -------
   11/16/2022 Dan Carmen        Created
 
 */
@isTest
public class DuplicateHelperTest {
    
    // this should be the user for the marketo scenarios because we don't want the records blocked
    public static String testUser = Label.DuplicateHelper_TestUser+'%';
    
    // get the test user used for duplicate testing 
    public static User getDupeTestUser() {
       User testUser = [Select Id, Name from User where IsActive=true and UserName like :testUser limit 1];
       return testUser;
    } // getDupeTestUser
    
    static testMethod void testDupesOneRec() {
        // we should match to this
        Account testAccount = new Account(Name='Test Account', ShippingPostalCode='14624');
        insert testAccount;
        Lead ld = new Lead(Company='Test Account', PostalCode='14624', FirstName='John', LastName='Smith', Email='johnsmith@testing.com');
        Lead[] leads = new Lead[]{ld};
        User testUser = getDupeTestUser();
        System.runAs(testUser) {
           DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(leads);
           System.assertEquals(1,results.size());
           DuplicateHelper.DupeResult result = results[0];
           System.assertEquals(true, result.hasResults);
           System.assertEquals(1,result.accts.size());
           System.assertEquals(testAccount.Id, result.accts[0].Id);
        }
    } // testDupes
   
    static testMethod void testDupesMultipleRecs() {
        // we should match to these
        DuplicateHelper.dupeBatchSize=3;
        Account testAccount1 = new Account(Name='Test Account1', ShippingPostalCode='14624');
        Account testAccount2 = new Account(Name='Test Account2', ShippingPostalCode='14626');
        Account testAccount3 = new Account(Name='Test Lead1', ShippingPostalCode='14621');
        insert new Account[]{testAccount1,testAccount2,testAccount3};
        Contact testCtct2a = new Contact(AccountId=testAccount2.Id, FirstName='Frankie', LastName='Fiver', Email='frankie@testing.com', MailingPostalCode='14626');
        Contact testCtct2b = new Contact(AccountId=testAccount2.Id, FirstName='Fred', LastName='Fiver', Email='fred@testing.com', MailingPostalCode='14626');
        insert new Contact[]{testCtct2a,testCtct2b};
        Lead testLd1 = new Lead(Company='Test Lead1', PostalCode='14621', FirstName='Larry', LastName='Lincoln', Email='larry@testing.com');
        Lead testLd2 = new Lead(Company='Test Lead2', PostalCode='14622', FirstName='Mary', LastName='March', Email='mary@testing.com');
        insert new Lead[]{testLd1,testLd2};
            
        Lead ld1 = new Lead(Company='Test Account1', PostalCode='14624', FirstName='John', LastName='Smith', Email='johnsmith@testing.com');
        Lead ld2 = new Lead(Company='Test Account2', PostalCode='14626', FirstName='Frankie', LastName='Fiver', Email='frankie@testing.com');
        Lead ld3 = new Lead(Company='Test Lead1', PostalCode='14621', FirstName='Larry', LastName='Lincoln', Email='larry@testing.com');
        Lead ld4 = new Lead(Company='Test Lead2', PostalCode='14622', FirstName='Mary', LastName='March', Email='mary@testing.com');
        Lead ld5 = new Lead(Company='No Match Inc', PostalCode='14626', FirstName='Christy', LastName='Christmas', Email='christy@testing.com');

        User testUser = getDupeTestUser();
        System.runAs(testUser) {
        
           Lead[] leads = new Lead[]{ld1,ld2,ld3,ld4,ld5};
           DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(leads);
           System.assertEquals(5,results.size());
           DuplicateHelper.DupeResult result1 = results[0];
           System.assertEquals(true, result1.hasResults);
           System.assertEquals(1,result1.accts.size());
           System.assertEquals(0,result1.ctcts.size());
           System.assertEquals(0,result1.leads.size());
           System.assertEquals(testAccount1.Id, result1.accts[0].Id);
        
           DuplicateHelper.DupeResult result2 = results[1];
           System.assertEquals(true, result2.hasResults);
           System.assertEquals(1,result2.accts.size());
           System.assertEquals(1,result2.ctcts.size());
           System.assertEquals(0,result2.leads.size());
           System.assertEquals(testAccount2.Id, result2.accts[0].Id);
           System.assertEquals(testCtct2a.Id, result2.ctcts[0].Id);
        
           DuplicateHelper.DupeResult result3 = results[2];
           System.assertEquals(true, result3.hasResults);
           System.assertEquals(1,result3.accts.size());
           System.assertEquals(0,result3.ctcts.size());
           System.assertEquals(1,result3.leads.size());
           System.assertEquals(testAccount3.Id, result3.accts[0].Id);
           System.assertEquals(testLd1.Id, result3.leads[0].Id);
        
           DuplicateHelper.DupeResult result4 = results[3];
           System.assertEquals(true, result4.hasResults);
           System.assertEquals(0,result4.accts.size());
           System.assertEquals(0,result4.ctcts.size());
           System.assertEquals(1,result4.leads.size());
           System.assertEquals(testLd2.Id, result4.leads[0].Id);
        
           DuplicateHelper.DupeResult result5 = results[4];
           System.assertEquals(false, result5.hasResults);
           System.assertEquals(0,result5.accts.size());
           System.assertEquals(0,result5.ctcts.size());
           System.assertEquals(0,result5.leads.size());
        } // System.runAs

    } // testDupesMultipleRecs
    
    static testMethod void checkDml() {
       Database.DMLOptions dml = DuplicateHelper.getDmlSkipCheck();
       System.assertNotEquals(null,dml);
    } // checkDml

} // class DuplicateHelperTest