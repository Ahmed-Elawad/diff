/**
 * Some test methods for the ContactBefore trigger.
 *
 * History
 * -------
 * 06/12/2012 Cindy Freeman		test logic for LeadSource verification from RJDB
   09/11/2013 Dan Carmen         Modify class to only test the lead source
   03/15/2015 Dan Carmen         Attach the contact to an account
   06/20/2020 Dan Carmen         Comment out RJDB specific tests - not needed.

 */
@isTest
private class ContactLeadSourceRJDBTest { 

   static testMethod void testleadSource() {
   	UserHelperTest.setupGenericUsers();
   	
    	// find a good lead source
      Schema.DescribeFieldResult F = Contact.LeadSource.getDescribe();
      List<Schema.Picklistentry> entries = F.getPicklistValues();
      String goodLeadSource1 = entries[0].getValue();
      String goodLeadSource2 = entries[1].getValue();
      
      String badLeadSource = 'BadLeadSource';

      // verify the lead source doesn't change if it's not the Relational Junction user
      User not_rj = [select id from User where Profile.Name='System Administrator' and FirstName != 'Relational' and LastName != 'Junction' and IsActive = True limit 1];
    	Account acct = new Account(Name='Test Acct');
    	insert acct;
    	
    	System.runAs(not_rj) {
         Contact c1 = new Contact(AccountId=acct.Id,LastName='Contact1',LeadSource=badLeadSource);
         insert c1;
         verifyContact(c1.Id,badLeadSource);
         Contact c2 = new Contact(AccountId=acct.Id,LastName='Contact2', LeadSource=goodLeadSource1);
         insert c2;
         verifyContact(c2.Id,goodLeadSource1);
    	}
      User rj = [select id from User where FirstName = 'Relational' and LastName = 'Junction' and IsActive = True limit 1];
      System.RunAs(rj) {
      	Contact c3 = new Contact(AccountId=acct.Id,LastName='Contact3',LeadSource = 'junk');
      	insert c3;
      	//verifyContact(c3.Id,Null);
      	Contact c4 = new Contact(AccountId=acct.Id,LastName='Contact4',LeadSource = goodLeadSource2);
      	insert c4;
      	verifyContact(c4.Id,goodLeadSource2);
      	c4.LeadSource = badLeadSource;
      	update c4;
      	// make sure the lead source doesn't change
        //verifyContact(c4.Id,goodLeadSource2);
      } // runAs
    	
        
    }
    
   /** Verify that the information returned from the contact matches what we expect.
    */
   private static void verifyContact(Id ctctId, String LeadSource) {
      Contact c = [Select Id, LeadSource from Contact where Id = :ctctId];
      System.assertEquals(leadsource, c.LeadSource);      
   } // verifyContact
       
}