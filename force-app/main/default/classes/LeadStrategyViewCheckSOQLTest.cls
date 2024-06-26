/* 
  Tests for the LeadStrategyViewCheckSOQL trigger. 
   
  History
  -------
  04/02/2012 Cindy Freeman   Created
  01/20/2014 Cindy Freeman	 added tests for Show My Zipcodes 
 */
@isTest

private class LeadStrategyViewCheckSOQLTest {

	static Lead_Strategy_Views__c getView(Id idValue) {
		return [select View_Name__c,order_by__c,Limit__c,page_size__c,Comment__c,Show_Account_Teams__c,soql__c,
					Parent_Object__c,Parent_Fields__c,Child_Object__c,Child_Fields__c
					from Lead_Strategy_Views__c where Id = :idValue];
	}
	
	static testMethod void testGoodInsert() {
		Lead_Strategy_Views__c lv1 = new Lead_Strategy_Views__c(View_Name__c='Test View1'
						,Show_Account_Teams__c = true
						,soql__c = 'Select Id, Name, Owner.Id,(select Id, FirstName, LastName from Contacts) from Account'
						,order_by__c = 'Name'
						,Parent_Object__c = 'Account'
						,Parent_Fields__c = 'Name,Owner.Id'
						,Child_Object__c = 'Contacts'
						,Child_Fields__c = 'FirstName,LastName');
		insert lv1;
		Lead_Strategy_Views__c lv1a = getView(lv1.id);		
		System.assertEquals(lv1a.Limit__c,100);
		System.assertEquals(lv1a.Comment__c, null);
		
		Profile p = [select id from profile where name='System Administrator'];
		User sa = [select id, isActive from User where profileId = :p.Id and isActive=true limit 1];
    	// run as a generic system administrator
        System.RunAs(sa) {
			Lead_Strategy_Views__c lv2 = new Lead_Strategy_Views__c(View_Name__c='Test View2'
						,Show_Account_Teams__c = true
						,soql__c = 'Select Id, Name, Owner.Id,(select Id, FirstName, LastName from Contacts) from Account where OwnerId = :UserId'
						,order_by__c = 'Name'
						,limit__c = 50
						,Parent_Object__c = 'Account'
						,Parent_Fields__c = 'Name,Owner.Id'
						,Child_Object__c = 'Contacts'
						,Child_Fields__c = 'FirstName,LastName');
			insert lv2;
			Lead_Strategy_Views__c lv2a = getView(lv2.id);		
			System.assertEquals(lv2a.Limit__c,50);
			System.assertEquals(lv2a.page_size__c,25);
			System.assertEquals(lv2a.Comment__c, null);       	
        }

		Lead_Strategy_Views__c lv3 = new Lead_Strategy_Views__c(View_Name__c='Test View3'
						,Show_Account_Teams__c = true
						,soql__c = 'Select Id, Name, AnnualRevenue from Account where AnnualRevenue > 0'
						,order_by__c = 'Name'
						,Parent_Object__c = 'Account'
						,Parent_Fields__c = 'Name,annualRevenue');
		insert lv3;
		Lead_Strategy_Views__c lv3a = getView(lv3.id);		
		System.assertEquals(lv3a.Comment__c, null);

		Lead_Strategy_Views__c lv4 = new Lead_Strategy_Views__c(View_Name__c='Test View4'
						,Show_My_Zipcodes__c = true
						,soql__c = 'Select Id, Name, AnnualRevenue from Account where AnnualRevenue > 0'
						,order_by__c = 'Name'
						,Parent_Object__c = 'Account'
						,Parent_Fields__c = 'Name,annualRevenue');
		insert lv4;
		Lead_Strategy_Views__c lv4a = getView(lv4.id);		
		System.assertEquals(lv4a.Comment__c, null);
        
	} // testGoodInsert
   
	static testMethod void testBadSOQL() {
		try {
			Lead_Strategy_Views__c lv4 = new Lead_Strategy_Views__c(View_Name__c='Test View4'
						,Show_Account_Teams__c = true
						,soql__c = 'Select Id, Name, Bad_Field_name from Account'
						,order_by__c = 'Name'
						,Parent_Object__c = 'Account'
						,Parent_Fields__c ='ID,Name,Bad_Field_name');
			insert lv4;
			System.assertEquals(false,true);
		}
		catch(Exception e) {
			System.assert(e.getMessage().contains('BAD SOQL'),e.getMessage());
		}				
	}	// end testBadSOQL

	static testMethod void testBadFields() {
		try {
			Lead_Strategy_Views__c lv5 = new Lead_Strategy_Views__c(View_Name__c='Test View5'
						,Show_Account_Teams__c = true
						,soql__c = 'Select Id, Name, Bad_Field_name, (Select Id,Name from Contacts) from Account'
						,order_by__c = 'Name'
						,Parent_Object__c = 'Account'
						,Parent_Fields__c = 'Name,Owner.Id,Bad_Field'
						,Child_Object__c = 'Contacts'
						,Child_Fields__c = 'FirstName,LastName');
			insert lv5;
			System.assertEquals(false,true);
		}
		catch(Exception e) {
			System.assert(e.getMessage().contains('missing'),e.getMessage());
		}				
	}	// end testBadSOQL
 
	static testMethod void testBadOptions() {
		try {
			Lead_Strategy_Views__c lv6 = new Lead_Strategy_Views__c(View_Name__c='Test View6'
						,Show_Account_Teams__c = true
						,Show_My_ZipCodes__c = true
						,soql__c = 'Select Id, Name from Lead'
						,order_by__c = 'Name'
						,Parent_Object__c = 'Lead'
						,Parent_Fields__c ='ID,Name');
			insert lv6;
			//System.assertEquals(false,true);
		}
		catch(Exception e) {
			System.assert(e.getMessage().contains('Please'),e.getMessage());
			System.assertEquals(true,true);
		}				
	}	// end testBadSOQL

	static testMethod void testTeamSOQL() {
		try {
			Lead_Strategy_Views__c lv6 = new Lead_Strategy_Views__c(View_Name__c='Test View6'
						,Show_Account_Teams__c = true
						,soql__c = 'Select Id, Name from Lead'
						,order_by__c = 'Name'
						,Parent_Object__c = 'Lead'
						,Parent_Fields__c ='ID,Name');
			insert lv6;
			System.assertEquals(false,true);
		}
		catch(Exception e) {
			System.assert(e.getMessage().contains('Please review'),e.getMessage());
		}				
	}	// end testBadSOQL
	   
}