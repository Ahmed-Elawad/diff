/** Methods for NSS project
 *
 * History
 * -------
 * 09/09/2014 Cindy Freeman     created 
 * 12/22/2014 Cindy Freeman		modified to catch exceptions
 * 08/20/2015 Jacob Hinds		adding LastCallTime when dupe is checked, removed where clause to allow more dupes through
 * 03/23/2016 Cindy Freeman		add null check to prevent NullPointerException errors in checkDupPhone method
 * 09/06/2018 Cindy Freeman		add check that phone number length is > 6 to avoid sosl error
   12/06/2018 Dan Carmen        Replace qbdialer__LastCallTime__c with LatestCallTime__c
   06/25/2021 Dan Carmen        Fix Test Class, increment API version

 */
public without sharing class NSSMethods {
  

  public static List<soslResults> resultList;  
    public class soslResults {
       public String objType;
       public String objId;
       public String phoneField;
       public SObject sobj;
    }
    
    /** determine if need to run future or not */
    public static void checkDuplicatePhone(Set<Id> p_idsDialedSet, Id p_runningUserId) {      
      if (!p_idsDialedSet.isEmpty() && p_idsDialedSet.size() > 0)
      {  if (System.isFuture() || System.isBatch() || Test.isRunningTest()) 
      {  checkDupPhone(p_idsDialedSet, p_runningUserId);  }
        else 
            {   checkDupPhoneFuture(p_idsDialedSet, p_runningUserId);  }
      } 
      
    } // checkDuplicatePhone
    
    @future
    public static void checkDupPhoneFuture(Set<Id> p_idsDialedSet, Id p_runningUserId) {
      checkDupPhone(p_idsDialedSet, p_runningUserId);
    }
    
  /** when record is dialed, want to flag any other records with the same phone number so they
    dont appear in other seek lists **/
  public static void checkDupPhone(Set<Id> p_idsDialedSet, Id p_runningUserId) {
        
    	UserHelper uh = new UserHelper();
    	User runningUser = uh.getUserById(p_runningUserId);
              
    	Boolean isPAY = (runningUser.NSS_Team__c != 'HRS'? true : false);
    	Boolean isHRS = (runningUser.NSS_Team__c == 'HRS'? true : false);
        System.debug('checkDupPhone runningUser='+runningUser.Name+' isPAY='+isPAY+' isHRS='+isHRS);
           
    	Set<String> phoneSet = new Set<String>();      // set of phone numbers we are looking for
        
        List<Id> idsDialedList = new List<Id>();
        for (Id idDialed : p_idsDialedSet) {
           idsDialedList.add(idDialed);
        } // for (idsDialedSet
        
        String incomingObject = getObjType(idsDialedList.get(0));      // all incoming Ids should be of the same sobject type               
 
     	// populate phoneSet
        if (incomingObject == 'Lead')     
        {   List<Lead> leadQueryList = [Select Id, Name, Phone, MobilePhone, Other_Phone__c, Lead_Company__c, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c from Lead where Id in :idsDialedList];
          	for (Lead ld: leadQueryList)
          	{	if (ld.Phone != null && ld.Phone.length() > 6)
          		{	phoneSet.add(ld.Phone);	}  
          		if (ld.MobilePhone != null && ld.MobilePhone.length() > 6)
          		{	phoneSet.add(ld.MobilePhone);	}
          		if (ld.Other_Phone__c != null && ld.Other_Phone__c.length() > 6)
          		{	phoneSet.add(ld.Other_Phone__c);	}          			
          	} // for 
        } // if (incomingObject == 'Lead')
        else if (incomingObject == 'Account')
        { 	List<Account> acctQueryList = [Select Id, Name, Phone, NSSContactPhone__c, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c from Account where Id in :idsDialedList];
          	for (Account acct: acctQueryList)
          	{  	if (acct.Phone != null && acct.Phone.length() > 6)
          		{	phoneSet.add(acct.Phone);    }	
          	} // for
        } // elseif
        else
        {  List<Contact> ctctQueryList = [Select Id, Name, Account.Id, Phone, AssistantPhone, HomePhone, MobilePhone, OtherPhone, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c from Contact where Id in :idsDialedList];
          	for (Contact ctct: ctctQueryList)
          	{  	if (ctct.Phone != null && ctct.Phone.length() > 6)
          		{	phoneSet.add(ctct.Phone);    }
          		if (ctct.AssistantPhone != null && ctct.AssistantPhone.length() > 6)
          		{	phoneSet.add(ctct.AssistantPhone);    }
          		if (ctct.HomePhone != null && ctct.HomePhone.length() > 6)
          		{	phoneSet.add(ctct.HomePhone);    }
          		if (ctct.MobilePhone != null && ctct.MobilePhone.length() > 6)
          		{	phoneSet.add(ctct.MobilePhone);    }
          		if (ctct.OtherPhone != null && ctct.OtherPhone.length() > 6)
          		{	phoneSet.add(ctct.OtherPhone);    }
          	} // for
        } // else
		
		if (phoneSet.isEmpty())
		{	return;	}
		
        // get phone numbers in string for sosl
        String phoneString = '';
        for (String fone: phoneSet)
        {   String fone2;
        	fone2 = (fone.Left(2) == '+1') ? fone.substringAfter('+1') : null; 	
        	fone = Utilities.removeExtraChars(fone, '0123456789');
			fone2 = Utilities.removeExtraChars(fone2, '0123456789');
			if(fone.length() > 6 || (fone2 != null && fone2.length() > 6))
			{
				phoneString = phoneString +'"'+fone+'" OR ';  
        		phoneString = (fone2 != null) ? phoneString +'"'+ fone2+'" OR ' : phoneString; 	        	
			}
        	
        }
        phoneString = phoneString.Left(phoneString.length() - 4);
		System.debug('**CMF ** duplicatePhone phoneString='+phoneString);
		
		PaychexSettings__c setting = PaychexSettings__c.getInstance('DuplicatePhoneLimit');
		Integer limitNbr = (setting != null && setting.IsActive__c ? Integer.valueOf(setting.Attribute1__c) : 1000);
		Integer resultNbr = 0;		// count result from sosl
		
        // query and gather results
        resultList = new List<soslResults>();
        List<List<SObject>> searchList;
       	try {
       	  if (isPAY)
       	  {  searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
                   	Contact (Id, Name, AccountId, Phone, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c, LatestCallTime__c Limit :limitNbr)];
           	 resultNbr += saveResults(searchList[0], 'Contact');            
       		 searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
                  	Account(Id, Name, Phone, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c, LatestCallTime__c  Limit :limitNbr)];            
          	 resultNbr += saveResults(searchList[0], 'Account');
          	 searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
              	Lead(Id, Name, Company, Lead_Company__c, Phone, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c, LatestCallTime__c Limit :limitNbr)];  
          	 resultNbr += saveResults(searchList[0], 'Lead');
          } // if
          else
          {  searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
                   	Contact (Id, Name, AccountId, Phone, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c, LatestCallTime__c Limit :limitNbr)];
          	 resultNbr += saveResults(searchList[0], 'Contact');
          	 searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
                  	Account(Id, Name, Phone, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c, LatestCallTime__c Limit :limitNbr)];            
          	 resultNbr += saveResults(searchList[0], 'Account');
          	 searchList = [FIND :phoneString IN PHONE FIELDS RETURNING
              	Lead(Id, Name, Company, Lead_Company__c, Phone, DuplicatePhone_PAY__c, DuplicatePhone_HRS__c, DuplicatePhoneDT_PAY__c, DuplicatePhoneDT_HRS__c, LatestCallTime__c Limit :limitNbr)];  
          	 resultNbr += saveResults(searchList[0], 'Lead');
          } // else
        } // try
        catch (Exception ex) {
	       	 ErrorLog.logError('NSSMethods', 'checkDupPhone', null, null, 'Sosl error'+ex.getMessage()+', phone string='+phoneString);
             ErrorLog.checkSave();
        } // catch
        
        if ( resultNbr >= limitNbr)
        {	 ErrorLog.logError('NSSMethods', 'checkDupPhone', null, null, 'resultNbr '+resultNbr+' >= limitNbr '+limitNbr+' phoneString='+phoneString);
             ErrorLog.checkSave();
        } // if
        
        // read thru search results, update records as needed
        List<Contact> updateCtctList = new List<Contact>();
        List<Account> updateAcctList = new List<Account>();
        List<Lead> updateLeadList = new List<Lead>();

	       system.debug('hello?');
    	for (soslResults sf : resultList)
	    {  if (!p_idsDialedSet.contains(sf.objId))            
           {	if (isPAY)
                {  
                	system.debug('isPAY');
                	sf.sobj.put('DuplicatePhone_Pay__c', true);
                   sf.sobj.put('DuplicatePhoneDT_Pay__c', System.Now()); 
                   sf.sobj.put('LatestCallTime__c', Datetime.now());  
                   system.debug('time: '+Datetime.now().format('h:mm:a'));      
                } // if (isPay)
                if (isHRS)
                {  
                	system.debug('isHRS');
                	sf.sobj.put('DuplicatePhone_HRS__c', true);
                   sf.sobj.put('DuplicatePhoneDT_HRS__c', System.Now());
                   sf.sobj.put('LatestCallTime__c', Datetime.now());
                   system.debug('time: '+Datetime.now().format('h:mm:a'));           
                } // if (isPay)      
                if (sf.objType == 'Lead')
                {  updateLeadList.add((Lead)sf.sobj);  }
                else if (sf.objType == 'Account')
                {  updateAcctList.add((Account)sf.sobj);  }
                else
                {  updateCtctList.add((Contact)sf.sobj);  }          
           } // if (!idsDialedSet.contains... 
        } // for (soslResults

   		System.debug('**CMF ** duplicatePhone update list lead='+updateLeadList.size()+' acct='+updateAcctList.size()+' ctct='+updateCtctList.size());  
   		if (!updateLeadList.isEmpty())
   		{  Database.SaveResult[] results = Database.update(updateLeadList,false);    
   		   updateLeadList.clear();
   		} 
     
    	if (!updateAcctList.isEmpty())
   		{  Database.SaveResult[] results = Database.update(updateAcctList,false);   
   		   updateAcctList.clear();
   		} 
     
    	if (!updateCtctList.isEmpty())
   		{  Database.SaveResult[] results = Database.update(updateCtctList,false); 
   		   updateCtctList.clear();
   		} 
         
     return;
   
  } // checkDuplicatePhone          
          
    /** save sosl results in another list
    **/
    public static Integer saveResults(List<SObject> rsltList, String obj) {
      Integer cnt = 0;
      for (SObject rslt: rsltList)
      {  soslResults sf = new soslResults();
         sf.objType = obj;
         sf.objId = rslt.Id;
         sf.phoneField = Utilities.removeExtraChars((String)rslt.get('Phone'), '0123456789');           
         sf.sobj = rslt;
         resultList.add(sf);
         cnt ++;
      }// for      
      return cnt;
    } // saveResults
      
  /** return what object type this is
   **/            
   public static String getObjType(Id sobjId) {
     
     String objtype = 'Contact';     
     if (((String)sobjId).Left(3) == ObjectHelper.PREFIX_LEAD)
        {  objtype = 'Lead';  }
        else if (((String)sobjId).Left(3) == ObjectHelper.PREFIX_ACCOUNT)
        {  objtype = 'Account';  }
        
        return objtype;            
             
   } // getObjType           

   public static final String FLD_DIALED='Dialed__c';
   public static final String FLD_OWNED_BY='OwnedBy__c';
   public static final String FLD_OWNED_PREV='OwnedByPrev__c';
   public static final String FLD_WEB_START='WebleadStartTime__c';
   public static final String FLD_WEB_DIALED='WebleadDialedTime__c';

/*
   public static void checkWebLead(SObject newRec, SObject oldRec) {
      // capture all errors just in case.
      try {
         if (newRec.get(FLD_OWNED_BY) != null && (oldRec == null || oldRec.get(FLD_OWNED_BY) == null)) {
            checkWebLeadStart(newRec,oldRec);
         } else if (((Boolean)newRec.get(FLD_DIALED)) && !((Boolean)oldRec.get(FLD_DIALED)) 
                    && newRec.get(FLD_OWNED_PREV) != null
                    && newRec.get(FLD_WEB_START) != null
                    && newRec.get(FLD_WEB_DIALED) == null
                   ) {
            checkWebLeadDialed(newRec,oldRec);
         }
      } catch (Exception e) {
         // do we need to do anything at this point?
         System.debug('checkWebLead exception: '+e);
      } // try
   } // checkWebLead
*/   
   public static void checkWebLeadStart(SObject newRec, SObject oldRec) {
      String ownedBy = (String)newRec.get(FLD_OWNED_BY);
      if (ownedBy != null) {
         LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(ownedBy);
         if (llc != null && llc.IsActive__c && String.isNotBlank(llc.WebServiceName__c)) {
            newRec.put(FLD_WEB_START,Datetime.now());
            newRec.put(FLD_WEB_DIALED,null);
         }
      }
   } // checkWebLeadStart

   public static void checkWebLeadDialed(SObject newRec, SObject oldRec) {
      String ownedBy = (String)newRec.get(FLD_OWNED_PREV);
      if (ownedBy != null && newRec.get(FLD_OWNED_PREV) != null
                    && newRec.get(FLD_WEB_START) != null
                    && newRec.get(FLD_WEB_DIALED) == null) {
         LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(ownedBy);
         if (llc != null && llc.IsActive__c && String.isNotBlank(llc.WebServiceName__c)) {
            newRec.put(FLD_WEB_DIALED,Datetime.now());
         }
      }
   } // checkWebLeadDialed

} // class NSSMethods