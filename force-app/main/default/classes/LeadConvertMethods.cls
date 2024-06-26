/* Class to handle trigger actions when Leads are converted

  History
  -------
  04/05/2017 Cindy Freeman        Created
  04/18/2018 Dan Carmen           Disable account trigger on update
  05/14/2018 Dan Carmen           This will all be handled in the AccountCheckFlds class
  
 */

public without sharing class LeadConvertMethods {

	/** map of ConvertedAccountId and Lead.NumberOfEmployees **/ 
	public static Map<Id, Integer> convertedAcctMap = new Map<Id, Integer>();
	
	public static void checkAfterTrigger(Lead newRec, Lead oldRec) {
	   /* 
      try {
         if (newRec.IsConverted && ((oldRec != null) && (oldRec.IsConverted != newRec.IsConverted))) 
         {	convertedAcctMap.put(newRec.convertedAccountId, newRec.NumberOfEmployees);	}
      } catch (Exception e) {
         System.debug('checkAfterTrigger LeadConvertMethods e='+e.getMessage());
      }
      */
    } // checkAfterTrigger
   
    public static void processAfterTriggerActions() {
       /* 
      if (!convertedAcctMap.isEmpty())
      {	  updateConvertedAccts();		}
      */  
    } // processAfterTriggerActions

    /*
    // need to update correct employee field on account with Lead numberOfEmployees 
    
    public static void updateConvertedAccts() {
       
    	List<Account> updateAccts = new List<Account>();
    	List<Account> convertedAccts = [Select Id, Employees__c, NumberOfEmployees from Account where Id in :convertedAcctMap.keySet()];
    	for (Account acct : convertedAccts)
    	{	if (acct.Employees__c == null || acct.Employees__c == 0)  
    		{	acct.Employees__c = convertedAcctMap.get(acct.Id);	
    			updateAccts.add(acct);
    		}
    	} // for
    	try {
    		if (!updateAccts.isEmpty()) {
    		   // disable the trigger to reduce processing
    		   ZipCheckOwner.SKIP_TRIGGERS=true;
            update updateAccts;
            ZipCheckOwner.SKIP_TRIGGERS=false;
         }
    	} // try
    	catch (Exception e) {
    		System.debug('checkAfterTrigger LeadConvertMethods updateConvertedAccts e='+e.getMessage());
    	} // catch
    	    	
    } // updateConvertedAccts
	*/
} // class LeadConvertMethods