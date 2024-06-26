/* 
  Methods to handle the Quotes from the trigger.
   
  History
  -------
  05/25/2017 Cindy Freeman   Created
  07/17/2017 Cindy Freeman	 modified to set Implementation Manager on all quotes, not just MMS
  06/08/2018 Cindy Freeman	 modified to use local getUserIM method instead of UserHelper method
  08/08/2018 Justin Stouffer modified to populate the Sales Approver fields using role hierarchy or CPQApprover ALL Custom Setting 
 */ 

public without sharing class QuoteMethods {
    public QuoteMethods(){}
 /*  
   public static Boolean TRIGGER_AFTER_EXECUTED=false;
   
   // for testing purposes
   public static Boolean SKIP_FUTURE=false;
   
   public static void checkQuote(SBQQ__Quote__c[] quotes, Map<Id,SBQQ__Quote__c> oldMap) {
      
      Id[] quoteCheckOppIds = new Id[]{};
      
      for (SBQQ__Quote__c quote : quotes) {
         SBQQ__Quote__c oldQuote = (oldMap != null ? oldMap.get(quote.Id) : null);
         if (!quoteIdsProcessed.contains(quote.Id)) {
            quoteIdSet.add(quote.Id);
         } 
         // only trigger this if something changes
         System.debug('checkQuote primary='+quote.SBQQ__Primary__c);
         if (quote.SBQQ__Opportunity2__c != null && quote.SBQQ__Primary__c
               && (oldQuote == null
                   || (quote.Have_ASO__c != oldQuote.Have_ASO__c
                       || quote.Have_PEO__c != oldQuote.Have_PEO__c
                       || quote.Have_HR_Essentials__c != oldQuote.Have_HR_Essentials__c
                       || quote.Include_Handbook__c != oldQuote.Include_Handbook__c))) {
            quoteCheckOppIds.add(quote.Id);
         }
      } // for (SBQQ__Quote__c quote
      
      System.debug('checkQuote quoteCheckOppIds='+quoteCheckOppIds.size()+' quoteIdSet='+quoteIdSet.size());

      if (!quoteIdSet.isEmpty()) {
         quoteIdsProcessed.addAll(quoteIdSet);
         processQuoteChanges();
      }
      
      if (!quoteCheckOppIds.isEmpty()) {
         if (SKIP_FUTURE || System.isFuture() || System.isBatch() || System.isQueueable()) {
            checkOppsNow(quoteCheckOppIds);
         } else {
            checkOppsFuture(quoteCheckOppIds);
         }
      }
   } // checkQuote

   @future
   public static void checkOppsFuture(Id[] quoteCheckOppIds) {
      checkOppsNow(quoteCheckOppIds);
   } // checkOppsFuture

   public static void checkOppsNow(Id[] quoteCheckOppIds) {
      SBQQ__Quote__c[] quotes = [Select Id
                                       ,Have_ASO__c
                                       ,Have_PEO__c
                                       ,Have_HR_Essentials__c
                                       ,Include_Handbook__c
                                       ,SBQQ__Opportunity2__c
                                       ,SBQQ__Opportunity2__r.Id
                                       ,SBQQ__Opportunity2__r.HR_Solutions_ASO__c
                                       ,SBQQ__Opportunity2__r.HR_Solutions_PEO__c
                                       ,SBQQ__Opportunity2__r.HR_Essentials__c
                                       ,SBQQ__Opportunity2__r.HR_Fundamentals__c
                                   From SBQQ__Quote__c
                                  Where Id in :quoteCheckOppIds];
      System.debug('checkOppsNow quotes='+quotes);
      Opportunity[] oppsToUpdate = new Opportunity[]{};
      for (SBQQ__Quote__c quote : quotes) {
         Opportunity opp = quote.SBQQ__Opportunity2__r;
         if (opp != null 
              && (quote.Have_ASO__c != opp.HR_Solutions_ASO__c
                  || quote.Have_PEO__c != opp.HR_Solutions_PEO__c
                  || quote.Have_HR_Essentials__c != opp.HR_Essentials__c
                  || quote.Include_Handbook__c != opp.HR_Fundamentals__c)) {
            opp.HR_Solutions_ASO__c = quote.Have_ASO__c;
            opp.HR_Solutions_PEO__c = quote.Have_PEO__c;
            opp.HR_Essentials__c = quote.Have_HR_Essentials__c;
            opp.HR_Fundamentals__c = quote.Include_Handbook__c;
            oppsToUpdate.add(opp);
         }
      }
      
      if (!oppsToUpdate.isEmpty()) {
         OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
         DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'QuoteMethods', 'checkOppsNow', 'Update Opportunities', true);
      }
   } // checkOppsNow 

   // map of zone number and user Id for Implementation Managers
   public static Map<String, Id> zoneIMMap = new Map<String, Id>();

   // set of users that had their Zone changed
   public static Set<Id> userIdSet = new Set<Id>();
   // users we have already processed
   public static Set<Id> userIdsProcessed = new Set<Id>();

   // set of quotes that need their Implementation Manager set 
   public static Set<Id> quoteIdSet = new Set<Id>();
   // quotes we have already processed 
   public static Set<Id> quoteIdsProcessed = new Set<Id>();
   
   // called from UserAfter trigger, looks to see if the Zone changed for the user   
   public static void checkUserAfter(User newUser, User oldUser, Boolean isDelete) {
   	
      if (!isDelete && oldUser != null) {
         if (newUser.Sales_Org__c == oldUser.Sales_Org__c           
                    && newUser.Zone__c != null && oldUser.Zone__c != null && newUser.Zone__c != oldUser.Zone__c) {   
            userIdSet.add(newUser.Id);
         }                      
      } // if
      
   } // checkUserAfter

   // called from UserAfter trigger 
   public static void processQuoteZoneChanges() {
      if (!userIdSet.isEmpty()) {
        if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            processQuoteChanges();
        } else {
            processQuoteChangesFuture();
        }
      }
   } // processQuoteZoneChanges
   
   @future
   public static void processQuoteChangesFuture() {
        processQuoteChanges();
   }  
   
   // call from QuoteAfter or UserAfter triggers 
   public static void processQuoteChanges() {
        if (userIdSet.isEmpty() && quoteIdSet.isEmpty())
        {   return; }
                
        String query_whole = null;
        String query_prefix = 'Select Id, SBQQ__SalesRep__c, SBQQ__SalesRep__r.Zone__c, SBQQ__SalesRep__r.ManagerId, SBQQ__SalesRep__r.Manager.ManagerId, SBQQ__SalesRep__r.Manager.Manager.ManagerId, ';
        query_prefix += 'SBQQ__SalesRep__r.Manager.UserRole.ParentRoleId, SBQQ__SalesRep__r.Manager.Manager.UserRole.ParentRoleId, SBQQ__SalesRep__r.Manager.Manager.Manager.UserRole.ParentRoleId,';
        query_prefix += 'SBQQ__SalesRep__r.Sales_Org__c, Sales_Approver_Level_1__c, Sales_Approver_Level_2__c, Sales_Approver_Level_3__c, ';
        query_prefix += 'Implementation_Manager__c, SBQQ__Status__c from SBQQ__Quote__c where';
        //String query_suffix = 'and SBQQ__SalesRep__r.Sales_Org__c = \'MMS\' and SBQQ__Status__c != \'In Review\' and SBQQ__Status__c != \'Approved\'';
        String query_suffix = 'and SBQQ__Status__c != \'In Review\' and SBQQ__Status__c != \'Approved\'';
        if (!quoteIdSet.isEmpty()) 
        {   query_whole = query_prefix + ' id in :quoteIdSet ' + query_suffix;  
            system.debug('*** CLM *** quoteIdSet not empty ' + query_whole);    
            quoteIdsProcessed.addAll(quoteIdSet);
        }
        else if (!userIdSet.isEmpty())
        {   query_whole = query_prefix + ' SBQQ__SalesRep__c in :userIdSet ' + query_suffix; 
            system.debug('*** CLM *** userIdSet not empty ' + query_whole);    
            userIdsProcessed.addAll(userIdSet);
        }
        system.debug('*** CLM *** before database.query ' + query_whole);                                                
        List<SBQQ__Quote__c> quoteBeforeList = Database.query(query_whole);
        system.debug('*** CLM *** after database.query ' + quoteBeforeList.size());                           
        List<SBQQ__Quote__c> updateQuoteList = new List<SBQQ__Quote__c>();
                                                        
        for (SBQQ__Quote__c quote : quoteBeforeList) 
           
        {   system.debug('*** CLM *** quote.SBQQ__SalesRep__r.zone__c ' + quote.SBQQ__SalesRep__r.zone__c); 
            Id imId = getUserIM(quote.SBQQ__SalesRep__r.zone__c);  
            Boolean updated = FALSE;
          system.debug('*** CLM *** imId ' + imId);  
            if (imId !=  null)
            {   if (quote.Implementation_Manager__c == null || quote.Implementation_Manager__c != imID)
                {   quote.Implementation_Manager__c = imId; 
                 	updated = TRUE;
                    system.debug('*** CLM *** quote.Implementation_Manager__c ' + imId);
                }
            }
            id checkId = QuoteMethods.checkManagerID(quote.SBQQ__SalesRep__r.ManagerID,quote.SBQQ__SalesRep__r.Manager.UserRole.ParentRoleId);
            System.debug('processQuoteChanges level 1 checkId='+checkId);
         	if (quote.Sales_Approver_Level_1__c == null || quote.Sales_Approver_Level_1__c != checkId)
            {   
                quote.Sales_Approver_Level_1__c = checkId;
             	updated = TRUE;
            }
            checkId = QuoteMethods.checkManagerID(quote.SBQQ__SalesRep__r.Manager.ManagerID,quote.SBQQ__SalesRep__r.Manager.Manager.UserRole.ParentRoleId);
            System.debug('processQuoteChanges level 2 checkId='+checkId);
         	if (quote.Sales_Approver_Level_2__c == null || quote.Sales_Approver_Level_2__c != checkId)
            {   
                quote.Sales_Approver_Level_2__c = checkId;
             	updated = TRUE;
            }
         	checkId = QuoteMethods.checkManagerID(quote.SBQQ__SalesRep__r.Manager.Manager.ManagerID,quote.SBQQ__SalesRep__r.Manager.Manager.Manager.UserRole.ParentRoleId);
            System.debug('processQuoteChanges level 3 checkId='+checkId);
            if (quote.Sales_Approver_Level_3__c == null || quote.Sales_Approver_Level_3__c != checkId)
            {   
                quote.Sales_Approver_Level_3__c = checkId;
             	updated = TRUE;
            }
            System.debug('processQuoteChanges updated='+updated);
            if(updated){
                updateQuoteList.add(quote);
            }
            quoteIdsProcessed.add(quote.Id);            
        } // for
        
        System.debug('processQuoteChanges updateQuoteList='+updateQuoteList.size());
        if (!updateQuoteList.isEmpty()) {
          QuoteTriggerHelper.TRIGGER_BEFORE_EXECUTED=true;
          TRIGGER_AFTER_EXECUTED=true;
          update updateQuoteList;
          QuoteTriggerHelper.TRIGGER_BEFORE_EXECUTED=false; 
          TRIGGER_AFTER_EXECUTED=false;
          
        }
        
        userIdSet.clear();
        quoteIdSet.clear();
        
   } // processQuoteChanges
    
   public static id checkManagerID(id managerId, id parentRoleId){
      System.debug('checkManagerID managerId='+managerId+' parentRoleId='+parentRoleId); 
    	if(managerId != NULL 
           && managerId != '00570000001buMq'
           && managerId != '00570000001buMqAAI'
           && managerId != '00570000001bhsn'
           && managerId != '00570000001bhsnAAA'
           && parentRoleId != NULL
           && parentRoleId != '00E30000000nAUP'
           && parentRoleId != '00E30000000nAUPEA2'){ 
         System.debug('checkManagerID in the if');
        	return managerId;
      } else {
         System.debug('checkManagerID in the else');
         CPQApprover__c cpqa = CPQApprover__c.getValues('All');
         if(cpqa != NULL){
            System.debug('checkManagerID return the CPQApprover record');
            return cpqa.Id__c;
         } else {
            System.debug('checkManagerID return the managerid');
        		return managerId; 
         }
      }
   } // checkManagerID
 
    //  get Implementation Manager to put onto Quote so IM can be the approver for MPSC quotes
   
   public static Id getUserIM(String zoneNum) {
        
      if (zoneIMMap.isEmpty()) 
        {	List<UserIM_Mapping__c> userIMList = new List<UserIM_Mapping__c>();
            userIMList = UserIM_Mapping__c.getall().values(); 
    
            Set<String> hrPersonSet = new Set<String>();
            for (UserIM_Mapping__c uIM: userIMList)
            {  hrPersonSet.add(uIM.HR_Person_ID__c);  }

            // get user records so we have the user ID
         	List<User> userList = [Select Id, isActive, Name, HR_Person_ID__c, Zone__c from User 
                           where isActive = true and HR_Person_ID__c in :hrPersonSet];
            
            // put all the users in a map by HR Person ID so it is easy to find them                           
            Map<String, Id> hrPersonUserMap = new Map<String, Id>();
            for (User usr: userList)
            {  hrPersonUserMap.put(usr.HR_Person_ID__c, usr.Id);  }
            // put zone and User ID into a map
            for (UserIM_Mapping__c uIM: userIMList)
            {  zoneIMMap.put(uIM.Name,hrPersonUserMap.get(uIM.HR_Person_Id__c)); }        
        } // if (zoneIMMap isEmpty)
        
        Id imId = zoneIMMap.get(zoneNum);         
        return imId;   
        
   } // getUserIM
           
 */           
    
}