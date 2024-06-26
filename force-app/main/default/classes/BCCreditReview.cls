/*
 *    09/08/2021 Carrie Marciano	Commented out for Forseva uninstall
*/
public with sharing class BCCreditReview {
    public BCCreditReview(){}
/*
	Account m_acct;
	
	public BCCreditReview(ApexPages.StandardController stdController) {
        m_acct = (Account) stdController.getRecord();
	}
    
    public ApexPages.PageReference startCreditPull() {
    	
    	Decimal initialCL = 0;
    	String initialCredRevStatus = null;
    	String initialCurrentRevStatus = null;
    	BusinessConnect__c bcSet = BusinessConnect__c.getOrgDefaults();
    	if(bcSet.Initial_Credit_Limit__c != null) 
    		initialCL = bcSet.Initial_Credit_Limit__c;
    	
    	if(bcSet.Initial_Credit_Review_Status__c != null) 
    		initialCredRevStatus = bcSet.Initial_Credit_Review_Status__c;
    	
    	if(bcSet.Initial_Current_Review_Status__c != null) 
    		initialCurrentRevStatus = bcSet.Initial_Current_Review_Status__c;
    		
		try {
			Account acct = [Select id
								, Business_Type__c
								, Suggested_Limit__c
								, forseva1__Credit_Review_Status__c
								, Current_Review_Status__c
								, forseva1__Credit_Review_Date__c  from Account where id =: m_acct.Id LIMIT 1];
			
			if(acct.Business_Type__c == 'ASO' || acct.Business_Type__c == 'MMS') {
				acct.forseva1__Credit_Review_Status__c = initialCredRevStatus;
				acct.Current_Review_Status__c = initialCurrentRevStatus;
				acct.forseva1__Credit_Review_Date__c = Date.today();
				acct.Suggested_Limit__c = initialCL;
				update acct;
			}
			
			//PageReference pqPage = Page.forseva1__AccountVerificationList;
			PageReference pqPage = Page.forseva1__CreditReview;
        	//pqPage.setRedirect(true);   
        	pqPage.getParameters().put('id', acct.Id);
        	return pqPage; 
			
		}
		catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return ApexPages.currentPage();         
		}

	}
    
*/    
}