/* 
 * A batch job for updating the CPA Referral Type on the Referral Contacts.
 *
 * History
 * -------
 * 01/04/2011 Dan Carmen   Created
   10/26/2011 Dan Carmen   Clean up code - modifications to handle multiple accounts.
   06/28/2012 Dan Carmen   Modified to use JobHelper class
   11/06/2013 Josh Cartwright modified to update referral type picklist field
   09/17/2014 J Stouffer   Modified to use a custom setting to specify Referral Lead sources.
   06/02/2016 Dan Carmen   Allow code to take the account type into consideration for sold opps.
   08/30/2016 Dan Carmen   Make sure it only runs for CPAs
 *
 */
global with sharing class RefContactSetCpaType 
                      implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   /** The time the process started. */
   global DateTime startTime;
   /** The date to check against for closed opportunities. */
   global Date checkDate;
   /** The total number of referral contacts found. */
   global Integer cpaFound = 0;
   /** The number of differences found. */
   global Integer diffFound = 0;
   
   global Date months6 = Date.today().addMonths(-6);
   global Date year1 = Date.today().addMonths(-12);
   global Date year2 = Date.today().addMonths(-24);
   
   /** The business type used to query for referrals. This can be changed for testing purposes. */
   global String busType = 'Accounting Firm';


   global JobHelper jh = new JobHelper('RefContactSetCpaType');
   
   public static String REF_SOURCE_CPA=Label.ReferralSourceCPA;
   

   /** Default constructor.
    */
   global RefContactSetCpaType() {
      startTime = DateTime.now();
      checkDate = Date.today().addMonths(-12);
   } // RefContactSetCpaType
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.saveJob();
                                    
      set<string> bTypeSet = new set<string>() ;
      for(Lead_Source_for_Referrals__c ls: Lead_Source_for_Referrals__c.getAll().values()){
         if(ls.business_type__c && ls.ReferralSource__c==REF_SOURCE_CPA){
            bTypeSet.add(ls.value__c);
         }
      }
      
      return Database.getQueryLocator([Select Id
                                             ,Name
                                             ,Referral_Type__c
                                             ,Referral_Account__c
                                             ,Referral_Account__r.Name
                                             ,Referral_Account__r.Referral_Source_Business_Type__c
                                             ,Referral_Count__c
                                             ,(Select Id
                                                     ,X6_Months_Sold__c
                                                     ,X6_Months_Any__c
                                                     ,X1_Year_Sold__c
                                                     ,X1_Year_Any__c
                                                     ,X2_Years_Sold__c
                                                     ,X2_Years_Any__c
                                                     ,Mutual_Clients_Active__c
                                                     ,Mutual_Clients_Lost__c
                                                     ,Referral_Account__c
                                                 From Referral_Counters__r
                                                order by createdDate desc)
                                         from Referral_Contact__c rc
                                        where Referral_Account__r.Referral_Source_Business_Type__c in :bTypeSet
                                      ]);
   } // start

   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      RefContactSetCpaType rcsct = new RefContactSetCpaType();
      database.executeBatch(rcsct, 100);
   } // execute

   public static final String SOLD_2YEAR='2 Years-Sold';
   public static final String ANY_2YEAR='2 Years-Any';
   public static final String SOLD_1YEAR='1 Year-Sold';
   public static final String ANY_1YEAR='1 Year-Any';
   public static final String SOLD_6MONTH='6 Months-Sold';
   public static final String ANY_6MONTH='6 Months-Any';
   public static final String MUTUAL_ACTIVE='Mutual Clients Active';
   public static final String MUTUAL_LOST='Mutual Clients Lost';
   

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Referral_Contact__c> ctcts = (List<Referral_Contact__c>)scope;
      
      List<Referral_Contact__c> ctctsToUpdate = New List<Referral_Contact__c>();

      Id[] rfrlIds = new Id[]{};
      // add the number of cpas found
      cpaFound += ctcts.size();
      // create a map of counters by referral contact id
      Map<Id,List<Referral_Counter__c>> countersByRfrl = new Map<Id,List<Referral_Counter__c>>();
      // map of all referrals
      Map<Id,Referral_Contact__c> contactMap = new Map<Id,Referral_Contact__c>();
      
      Referral_Counter__c[] upsertRCs = new Referral_Counter__c[]{};
      
      for (Referral_Contact__c rc : ctcts){
         rfrlIds.add(rc.Id);
         contactMap.put(rc.Id,rc);
         List<Referral_Counter__c> counters = rc.Referral_Counters__r;
         

            system.debug('Josh Cartwight' + ctctsToUpdate);

         if (counters == null) {
            counters = new List<Referral_Counter__c>();
         }
         
         // ensure there is always at least one record
         if (counters.size() == 0) {
            System.debug('in execute - creating a new counter');
            Referral_Counter__c counter = new Referral_Counter__c(Referral_Contact__c = rc.Id, Referral_Account__c = rc.Referral_Account__c);
            counters.add(counter);
         }
         
         // clear out values
         for (Referral_Counter__c counter : counters) {
            clearCounter(counter);
            // add to upsert list
            upsertRCs.add(counter);
         }
         // store in the map
         countersByRfrl.put(rc.Id,counters);
      } // for (Referral_Contact__c

       
      getAllResults(rfrlIds, countersByRfrl, contactMap, upsertRCs);
      
      //
      for (Referral_Contact__c rc : contactMap.values()) {
         List<Referral_Counter__c> counters = countersByRfrl.get(rc.Id);
         Integer refCount = 0;
         if (counters != null) {
            for (Referral_Counter__c refCnt : counters) {
               refCount  += refCnt.X1_Year_Sold__c.intValue();
            }
         }
         String newRefType = getRefType(refCount);
         System.debug('name='+rc.Name+' refCount='+refCount+' newRefType='+newRefType+' curRefType='+rc.Referral_Type__c);
         
         if (rc.Referral_Type__c != newRefType) {
             //rc.Referral_Type__c = newRefType;
             Referral_Contact__c newRc = new Referral_Contact__c(Id=rc.Id, Referral_Type__c=newRefType);
             ctctsToUpdate.add(newRc);           
         }          
         
      } // for (Referral_Contact__c rc
      
      if (!ctctsToUpdate.isEmpty()){
         update ctctsToUpdate;        
      }
      if (!upsertRCs.isEmpty()) {
         Database.upsert(upsertRCs,false);
      }

   } // execute

   // use these for a default value
   public static String[] SOLD_ACCOUNT_TYPES = Label.AccountTypesSold.split(';');
   
   private Boolean getAllResults(Id[] rfrlIds, Map<Id,List<Referral_Counter__c>> countersByRfrl, Map<Id,Referral_Contact__c> contactMap, Referral_Counter__c[] upsertRCs) {
      //map all the LeadSource Values in Custom setting to lsource
                      
      Set<String> accountTypeSet = new Set<String>();
      accountTypeSet.addAll(SOLD_ACCOUNT_TYPES);

      set<string> sources = new set<string>() ;
      for(Lead_Source_for_Referrals__c ls: Lead_Source_for_Referrals__c.getAll().values()){
         if(ls.Lead_Source__c && ls.ReferralSource__c==REF_SOURCE_CPA){
            sources.add(ls.value__c);
         }
         if (ls.AccountType__c && String.isNotBlank(ls.Value__c) && ls.ReferralSource__c==REF_SOURCE_CPA) {
            accountTypeSet.add(ls.Value__c);
         }
      } // for(Lead_Source_for_Referrals__c

      // select all opportunities for referrals
      for (Opportunity[] opptys : [select Id,Name, Referral_Contact__c
                                         ,Referral_Account__c
                                         ,StageName, CloseDate
                                         ,Account.BIS_ID__c, Account.Lost_Date__c, Account.Type
                                        ,LeadSource
                                     from Opportunity 
                                    where CloseDate >= :year2
                                      and Referral_Contact__c IN :rfrlIds
                                      and LeadSource in :sources ]) {

      System.debug('getAllResults nbr opptys='+opptys.size());            
      for (Opportunity oppty : opptys) {
            system.debug('JGS oppty.Name='+oppty.Name+' oppty.LeadSource = ' + oppty.LeadSource);
            //if(sources.contains(oppty.LeadSource)){
               Referral_Counter__c counter = getCounter(oppty.Referral_Account__c, contactMap.get(oppty.Referral_Contact__c), countersByRfrl.get(oppty.Referral_Contact__c), upsertRCs);
               // always part of the any two years
               counter.X2_Years_Any__c++;
               
               Boolean oppSold = (oppty.StageName.startsWith('Sold')
                                  && (oppty.Account.BIS_ID__c != null || accountTypeSet.contains(oppty.Account.Type)));

               if (oppSold) {
                  counter.X2_Years_Sold__c++;
               }
               if (oppty.CloseDate > year1) {
                  counter.X1_Year_Any__c++;
                  if (oppSold) {
                     counter.X1_Year_Sold__c++;
                  }
               }
               if (oppty.CloseDate > months6) {
                  counter.X6_Months_Any__c++;
                  if (oppSold) {
                     counter.X6_Months_Sold__c++;
                  }
               }
         //}
            
         } // for (Opportunity oppty : opptys
                            
        } // for (Opportunity[] opptys
      
      List<AggregateResult> activeResults = new List<AggregateResult>( 
                      [select COUNT(Id) cnt,CPA_Name_Ref__c contactId 
                         from Account
                        where CPA_Name_Ref__c in :rfrlIds
                          and BIS_ID__c != null
                          and Lost_Date__c = null
                        group by CPA_Name_Ref__c ]);

      for (AggregateResult ar : activeResults) { 
         String contactId = (String)ar.get('contactId');
         System.debug('getAllResults aggregateResult contactId='+contactId);
         // get the counter
         Referral_Counter__c counter = getCounter(null, contactMap.get(contactId), countersByRfrl.get(contactId), upsertRCs);
         Integer cnt = Integer.valueOf(ar.get('cnt'));
         counter.Mutual_Clients_Active__c += cnt;
      } // for (AggregateResult

      List<AggregateResult> lostResults = new List<AggregateResult>( 
                      [select COUNT(Id) cnt,CPA_Name_Ref__c contactId 
                         from Account
                        where CPA_Name_Ref__c in :rfrlIds
                          and BIS_ID__c != null
                          and Lost_Date__c != null
                        group by CPA_Name_Ref__c ]);

      for (AggregateResult ar : lostResults) { 
         String contactId = (String)ar.get('contactId');
         // get the counter
         Referral_Counter__c counter = getCounter(null, contactMap.get(contactId), countersByRfrl.get(contactId), upsertRCs);
         Integer cnt = Integer.valueOf(ar.get('cnt'));
         counter.Mutual_Clients_Lost__c += cnt;
      } // for (AggregateResult

      return true;
   } // getAllResults
   
   /** Find the counter that matches the account id passed in. If account id is null, will use the referral account id from the contact.
    */
   public Referral_Counter__c getCounter(Id accountId, Referral_Contact__c rc, List<Referral_Counter__c> counters, Referral_Counter__c[] upsertRCs) {
      Referral_Counter__c counter = null;
      // if no account id, use the account on the referral contact
      Id checkAccountId = (accountId != null ? accountId : rc.Referral_Account__c);
      System.debug('getCounter checkAccountId='+checkAccountId+' accountId='+accountId+' rc.Referral_Account__c='+rc.Referral_Account__c);
      for (Referral_Counter__c checkCounter : counters) {
         if (checkCounter.Referral_Account__c == checkAccountId) {
            counter = checkCounter;
            break;
         }
      } // for (Referral_Counter__c
      if (counter == null) {
          System.debug('getCounter creating a new counter');
         counter = new Referral_Counter__c(Referral_Contact__c = rc.Id, Referral_Account__c = checkAccountId);
         
         clearCounter(counter);
         upsertRCs.add(counter);
         counters.add(counter);
      }
      return counter;
   } // getCounter
   
   public void clearCounter(Referral_Counter__c counter) {
      counter.X6_Months_Sold__c = 0;
      counter.X6_Months_Any__c = 0;
      counter.X1_Year_Sold__c = 0;
      counter.X1_Year_Any__c = 0;
      counter.X2_Years_Sold__c = 0;
      counter.X2_Years_Any__c = 0;
      counter.Mutual_Clients_Active__c = 0;
      counter.Mutual_Clients_Lost__c = 0;
   } // clearCounter 

   public String getRefType(Integer cnt) {
      if (cnt == null) {
         cnt = 0;
      }
      String refType = '50 CPA Non-referring';
      if (cnt>0 && cnt<3) {
         refType = '30 CPA Referring <3/Year';
      } else if (cnt == 3 || cnt == 4) {
         refType = '10 CPA Referring 3-4/Year';
      } else if (cnt > 4) {
         refType = '5 CPA Referring >4/Year';
      }
      return refType;
   } // getRefType
   
   global void finish(Database.BatchableContext BC){
      String message = '\nTotal CPAs Processed: '+cpaFound+' '; 
      message += '\nTotal Referral Types updated: '+diffFound+' ';
      message += '\nSold Opportunities checked from '+checkDate.format(); 
      
      jh.completeJob(bc, 'Referral Type Update', message);
   } // finish
 
} // RefContactSetCpaType