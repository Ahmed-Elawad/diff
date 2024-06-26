/* Methods for working with cadence

 * History
 * -------
  07/01/2021 Eric Porter          Created
  08/03/2021 Dan Carmen           Change activity selection
  07/28/2022 Susmitha Somavarapu  Wholesaler and PEO - MutualClient Tab (US14 Clearslide)
  09/09/2022 Dan Carmen           Fixed queries for Strategic Accountant Firm, Accounting Firm, and Banks
  12/04/2023 Susmitha Somavarapu Commented line 65,83(Opportunities_to_Refer_Last_12_Months__c,)as per APR0160191.
  05/14/2024 Pratik Das	         APR0159917/APR0169069: New functionality in Touchpoint to indicate action required with an accept function

*/
global with sharing class CadenceTouchpointExtension {
    
    // @AuraEnabled(cacheable=true)
    // public static Referral_Account__c getTouchPointReferral(){
    //     return [Select Id,Name,Profiled_Date__c,
    //     Number_of_Business_Clients_with_EEs__c,
    //     Number_of_Clients_with_50_Ees__c,
    //     Number_of_Payrolls_the_Firm_Processes__c,
    //     Types_of_Payrolls_Processed__c,
    //     Software_Used_to_Process_Payrolls__c,
    //     Software_Renewal_Date__c,
    //     Number_of_Owner_Only_Clients__c,
    //     Who_Is_Referred_for_Payroll_HCM__c,
    //     Does_Firm_Receive_HR_Questions__c,
    //     Types_of_Benefit_Questions__c,
    //     Acquisition_Discussion__c,
    //     Power_of_Paychex_Firm_Presentation__c
    //      From Referral_Account__c where id = 'a0603000000OXZnAAO'].get(0);
    // }

    // @AuraEnabled(cacheable=true)
    // public static Referral_Account__c getTouchPointReferralContactWithAcctId(Id refActId){
    //     return [Select Id,Name,Profiled_Date__c,
    //     Number_of_Business_Clients_with_EEs__c,
    //     Number_of_Clients_with_50_Ees__c,
    //     Number_of_Payrolls_the_Firm_Processes__c,
    //     Types_of_Payrolls_Processed__c,
    //     Software_Used_to_Process_Payrolls__c,
    //     Software_Renewal_Date__c,
    //     Number_of_Owner_Only_Clients__c,
    //     Who_Is_Referred_for_Payroll_HCM__c,
    //     Does_Firm_Receive_HR_Questions__c,
    //     Types_of_Benefit_Questions__c,
    //     Acquisition_Discussion__c,
    //     Power_of_Paychex_Firm_Presentation__c
    //      From Referral_Account__c where id = :refActId].get(0);
    // }
    @AuraEnabled(cacheable=true)
    public static List<Referral_Contact__c> getReferralContactswithAcctId(Id refActId){
        return [Select Id,
                       Name,
                       Referral_Account__c,
                       Contact__c,
                       Email__c,
                       Phone__c,
                       Mobile_Phone__c,
                       Title__c,
                       PAYX_ID__c,
                       Contact__r.EligibleToEmail__c,
                       Email_Opt_Out__c,
                       Last_Activity_Date__c,
                       Birthday__c,
                       ScoreTotalReferrals__c,
                     //  Opportunities_to_Refer_Last_12_Months__c,
                       LinkedIn_Profile__c,
                       AICPA__c,
                       End_Date__c
                       From Referral_Contact__c where Referral_Account__c = :refActId AND End_Date__c= null];
    }
    @AuraEnabled(cacheable=true)
    public static Referral_Contact__c getReferralContactwithAcctId(Id refActId){
        return [Select Id,
                       Name,
                       Referral_Account__c,
                       Email__c,
                       Phone__c,
                       Title__c,
                       PAYX_ID__c,
                       Last_Activity_Date__c,
                       Birthday__c,
                       ScoreTotalReferrals__c,
                   //    Opportunities_to_Refer_Last_12_Months__c,
                       LinkedIn_Profile__c,
                       AICPA__c
                       From Referral_Contact__c where Referral_Account__c = :refActId LIMIT 1];
    }
    // @AuraEnabled
    // public static Referral_Contact__c getReferralContact(){
    //     return [Select Id,Name,Referral_Account__c From Referral_Contact__c where Referral_Account__c = 'a0603000000OXZnAAO'];
    // }
   
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunityWithAcctId(Id refActId){
        return [Select Id, Name,Referral_Account__c,OwnerContact__r.Name,
                StageName, CloseDate, ReferralContact__r.Name, Created_Date_Time__c 
                From Opportunity 
                where Referral_Account__c = :refActId];
    }
    @AuraEnabled(cacheable=true)
    public static List<Account> getMutualClientsForTouchPointwithAcctId(Id refActId){
        List<Account> mutualClients = new List<Account>();
        List<Referral_Contact__c> refCts = getReferralContactswithAcctId(refActId);
        
        mutualClients = ObjectBannerAuraService.getMutualClients(refcts);
        
        return mutualClients;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getMutualClientsForTouchPointwithAcctIdandRefBusiType(Id refActId, String refferalSourceBussType){
     List<Account> mutualClients = new List<Account>();
     if (refActId == null) {
         return mutualClients;
     }

     Id[] refCtctIds = new Id[]{};
     if (refferalSourceBussType != 'Strategic Account' ) {
        List<Referral_Contact__c> refCts = getReferralContactswithAcctId(refActId);
        System.debug('getMutualClientsForTouchPointwithAcctIdandRefBusiType refCts='+refCts.size());
        for (Referral_Contact__c refCtct : refCts) {
            if (refCtct.Id != null) {
               refCtctIds.add(refCtct.Id);
            }
         }
      } else {
         refCtctIds.add(refActId);
      } // if (refferalSourceBussType
        
      System.debug('getMutualClientsForTouchPointwithAcctIdandRefBusiType refActId='+refActId+' refferalSourceBussType='+refferalSourceBussType+' refCtctIds='+refCtctIds.size());
      mutualClients = [SELECT Id, 
                      Name, 
                      Fed_ID_Name__c, 
                      Bis_ID__c, 
                      CreatedDate, 
                      AccountNumber, 
                      Type,
                      ShippingAddress,
                      First_Run_Date__c,
                      Legal_State__c,
                      Owner_Zip_Code__c,
                      SignificantContact__r.Name,
                      BillingAddress, 
                      NumberOfEmployees, 
                      Owner.LastName,
                      X401K_Assets__c,
                      Paychex_401K_Assets__c
                 FROM Account
                WHERE Broker_Name_Ref__c IN :refCtctIds
                   OR Banker_Name_Ref__c in :refCtctIds
                   OR Insurance_Broker_Name_Ref__c in :refCtctIds
                   OR Referral_National_Account__c = :refActId
                   OR CPA_Name_Ref__c in :refCtctIds];
      /*
      }
      if(refferalSourceBussType != null ){
        if(refferalSourceBussType == 'Broker Dealer'  || refferalSourceBussType == 'Broker Dealer Branch'  ){
            mutualClients = (refCtctIds == null || refCtctIds.isEmpty() ? new Account[]{}
            : [SELECT Id, 
                      Name, 
                      Fed_ID_Name__c, 
                      Bis_ID__c, 
                      CreatedDate, 
                      AccountNumber, 
                      Type,
                      ShippingAddress,
                      First_Run_Date__c,
                      Legal_State__c,
                      Owner_Zip_Code__c,
                      SignificantContact__r.Name,
                      BillingAddress, 
                      NumberOfEmployees, 
                      Owner.LastName,
                      X401K_Assets__c,
                      Paychex_401K_Assets__c
                 FROM Account
                WHERE Broker_Name_Ref__c IN :refCtctIds]);
        }
        else if(refferalSourceBussType == 'Health Insurance Broker'  || refferalSourceBussType == 'Business Consultant' || refferalSourceBussType ==  'Full Service Agency' || refferalSourceBussType == 'P&C Broker' || refferalSourceBussType ==  'PEO Broker' || refferalSourceBussType ==  'Financial Services'){

            mutualClients = (refCtctIds == null || refCtctIds.isEmpty() ? new Account[]{}
                         : [SELECT Id, 
                                   Name, 
                                   Fed_ID_Name__c, 
                                   Bis_ID__c, 
                                   CreatedDate, 
                                   AccountNumber, 
                                   Type,
                                   ShippingAddress,
                                   First_Run_Date__c,
                                   Legal_State__c,
                                   Owner_Zip_Code__c,
                                   SignificantContact__r.Name,
                                   BillingAddress, 
                                   NumberOfEmployees, 
                                   Owner.LastName,
                                   X401K_Assets__c,
                                   Paychex_401K_Assets__c
                              FROM Account
                             WHERE Insurance_Broker_Name_Ref__c IN :refCtctIds]);

        }
        else if(refferalSourceBussType == 'Strategic Account' ){
            mutualClients = (refCtctIds == null || refCtctIds.isEmpty() ? new Account[]{}
                         : [SELECT Id, 
                                   Name, 
                                   Fed_ID_Name__c, 
                                   Bis_ID__c, 
                                   CreatedDate, 
                                   AccountNumber, 
                                   Type,
                                   ShippingAddress,
                                   First_Run_Date__c,
                                   Legal_State__c,
                                   Owner_Zip_Code__c,
                                   SignificantContact__r.Name,
                                   BillingAddress, 
                                   NumberOfEmployees, 
                                   Owner.LastName,
                                   X401K_Assets__c,
                                   Paychex_401K_Assets__c
                              FROM Account
                             WHERE Referral_National_Account__c  =:refActId]);
        }
        else if(refferalSourceBussType == 'Strategic Accountant Firm' || refferalSourceBussType == 'Accounting Firm'  ){
            mutualClients = (refCtctIds == null || refCtctIds.isEmpty() ? new Account[]{}
                         : [SELECT Id, 
                                   Name, 
                                   Fed_ID_Name__c, 
                                   Bis_ID__c, 
                                   CreatedDate, 
                                   AccountNumber, 
                                   Type,
                                   ShippingAddress,
                                   First_Run_Date__c,
                                   Legal_State__c,
                                   Owner_Zip_Code__c,
                                   SignificantContact__r.Name,
                                   BillingAddress, 
                                   NumberOfEmployees, 
                                   Owner.LastName,
                                   X401K_Assets__c,
                                   Paychex_401K_Assets__c
                              FROM Account
                             WHERE CPA_Name_Ref__c in :refCtctIds ]);
        }
        else if(refferalSourceBussType == 'Bank' ){
            mutualClients = (refCtctIds == null || refCtctIds.isEmpty() ? new Account[]{}
                         : [SELECT Id, 
                                   Name, 
                                   Fed_ID_Name__c, 
                                   Bis_ID__c, 
                                   CreatedDate, 
                                   AccountNumber, 
                                   Type,
                                   ShippingAddress,
                                   First_Run_Date__c,
                                   Legal_State__c,
                                   Owner_Zip_Code__c,
                                   SignificantContact__r.Name,
                                   BillingAddress, 
                                   NumberOfEmployees, 
                                   Owner.LastName,
                                   X401K_Assets__c,
                                   Paychex_401K_Assets__c
                              FROM Account
                             WHERE Bank_Name__c in :refCtctIds ]);
        }
      }  
     */
       System.debug('getMutualClientsForTouchPointwithAcctIdandRefBusiType mutualClients='+mutualClients.size());
       return mutualClients;
    } // getMutualClientsForTouchPointwithAcctIdandRefBusiType
    
    @AuraEnabled(cacheable=true)
    public static Integer getReferralsInPastMonths(Id refActId, Integer pastMonths){
        //get list of refctctIds
        List<Referral_Contact__c> refctcts = getReferralContactswithAcctId(refActId);
        List<Id> refctctIds = new List<Id>();
        for(Referral_Contact__c refctct: refctcts){
            refctctIds.add(refctct.Id);
        }
        //add if referral_Contact__c in list of Ids

        Date LastDate = Date.today();
        LastDate = LastDate.addMonths(-pastMonths);
        List<Opportunity> referrals = [Select Id, Name,Referral_Account__c,CreatedDate,Referral_Contact__c from Opportunity where Referral_Contact__c IN :refctctIds AND Referral_Account__c =: refActId AND CreatedDate >= :LastDate];
        return referrals.size();
    }
    @AuraEnabled(cacheable=true)
    public static Integer getCurrentMutualCount(Id refActId){
        List<Account> mcs = getMutualClientsForTouchPointwithAcctId(refActId);
        List<Account> activeMcs = new List<Account>();
        for(Account mc: mcs){
            if(mc.Type !='HRS Client (Only)'&& mc.Type !='Prospect' && mc.Type !='Lost Client'){
                activeMcs.add(mc);
            }
        }
        return activeMcs.size();
    }
    @AuraEnabled(cacheable=true)
    public static Integer getCurrentMutualAndProspectClientCount(Id refActId){
        List<Account> mcs = getMutualClientsForTouchPointwithAcctId(refActId);
        Referral_Account__c refacct = [Select Id, Name, Account__c from Referral_Account__c where Id =: refActId];
        List<Account> pcs = [Select Id,Name,Type from Account where Type='Prospect' and Id =:refacct.Account__c];
        Integer sum = mcs.size() + pcs.size();
        return sum;
    }
    @AuraEnabled
    public static string updateRefctcts( Object data ) {
        
        List < Referral_Contact__c > refctctsForUpdate = ( List < Referral_Contact__c > ) JSON.deserialize(
            JSON.serialize( data ),
            List < Referral_Contact__c >.class
        );
        try {
            update refctctsForUpdate;
            return 'Success: Referral Contact(s) updated successfully';
        }
        catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
        }

    }
@AuraEnabled(cacheable=true)
    public static Integer getnumOfOpenOpps(Id refActId){
    List<Opportunity> opps=  [select Id,Referral_Account__c,Name,StageName from Opportunity 
                    where Referral_Account__c =: refActId 
                    AND
                    StageName NOT IN ('Demo Completed',
             'Sold - Revenue Recognition',
             'Referred Not Sold',
             'Referred Started',
             'Referred Commissioned',
             'Rescinded',
             'Disqualified',
             'Rejected',
             'No Decision',
             'Lost',
             'Not Sold',
             'Sold - Commissioned',
             'Sold - Run',
             'Completed',
             'Sold - Case Submitted to New Case',
             'Sold - Started',
             'Final Underwriting',
             'Orientation'
             )];
    return opps.size();
    }  
    @AuraEnabled(Cacheable=true)
    public static Datetime getLastMeetingDate(Id refActId){
        List<Referral_Contact__c> refCtcts = getReferralContactswithAcctId(refActId);
        Datetime firstDate = refCtcts[0].Last_Activity_Date__c;
        for(Referral_Contact__c refctct : refCtcts){
            if(refctct.Last_Activity_Date__c> firstDate){
                firstDate = refctct.Last_Activity_Date__c;
            }

        }
        return firstDate;
    }
    @AuraEnabled(cacheable=true)
    public static String getCAContactName(Referral_Contact__c refctct){
        return refctct.Name;
    }
    global class EventTaskActivity implements Comparable {
        @AuraEnabled 
        public String Subject {get;set;}
        @AuraEnabled 
        public Date ActivityDate {get;set;}
        @AuraEnabled
        public String ContactName {get;set;}
        @AuraEnabled
        public String ActivityType {get;set;}
        @AuraEnabled
        public String OwnerName {get;set;}
        @AuraEnabled 
        public Id Id{get;set;}
        @AuraEnabled 
        public Datetime ActivityTime {get;set;}
        @AuraEnabled 
        public String Status {get;set;}
        //constructor for Events
        public EventTaskActivity(Event activity, SObject rec){
            Subject = activity.Subject;
            ActivityType = activity.Type;
            ContactName = (rec != null ? (String)rec.get('Name') : null);
            ActivityDate = activity.ActivityDate;
            OwnerName = activity.Owner.Name;
            Id = activity.Id;
            ActivityTime = activity.ActivityDateTime;
            if(activity.ActivityDate<Date.today()){
                Status = 'Closed';
            }else{
                Status = 'Open';

            }
        }
        //constructor for Tasks
        Public EventTaskActivity(Task activity, SObject rec){
            Id = activity.Id;
            Subject = activity.Subject;
            ActivityType = activity.Type;
            ContactName = (rec != null ? (String)rec.get('Name') : null);
            ActivityDate = activity.ActivityDate;
            OwnerName = activity.Owner.Name;
            ActivityTime = null;
            Status = activity.Status;
        }

      global Integer compareTo(Object objectToCompareTo) {
         if (objectToCompareTo != null) {
            EventTaskActivity compareAw = (EventTaskActivity)objectToCompareTo;
            if (ActivityDate != null && compareAw.ActivityDate != null) {
               return activityDate.daysBetween(compareAw.ActivityDate);
            }
         } // if (objectToCompareTo != null
         return -1;
      } // compareTo
   } // class EventTaskActivity
    
    @AuraEnabled(cacheable=true)
    public static List<Referral_Contact__c> getEmailCapableRefCtcts(Id refActId){
        List<Referral_Contact__c> refctcts = getReferralContactswithAcctId(refActId);
        List<Referral_Contact__c> filteredRefctcts = new List<Referral_Contact__c>();
        for(Referral_Contact__c refctct:refctcts){
            if(refctct.Contact__r.EligibleToEmail__c)
            filteredRefctcts.add(refctct);
        }
        return filteredRefctcts;
    }
    @AuraEnabled
    public static List<Id> getEmailContactIds(List<Referral_Contact__c> refctcts){
        List<Id> contactIDs = new List<Id>();
        for(Referral_Contact__c refctct : refctcts){
            contactIDs.add(refctct.Contact__c);
            //elligable to_email 
        }
        return contactIDs;
    }

    public static Integer ACTIVITY_NBR_RECS=15;
    
    @AuraEnabled(cacheable=true)
    public static List<EventTaskActivity> getActivitiesForReferralContact(Id refActId){
        List<EventTaskActivity> activityList = new List<EventTaskActivity>();

        //get all referralContacts given refActId
        List<Referral_Contact__c> refctcts = getReferralContactswithAcctId(refActId);
        System.debug('getActivitiesForReferralContact refctcts='+refctcts.size());
        Referral_Account__c[] refAccts = [Select Id, Name from Referral_Account__c where Id=:refActId];
        Referral_Account__c refAcct = (!refAccts.isEmpty() ? refAccts[0] : null);
        if (refAcct == null && refctcts.isEmpty()) {
           return activityList;
        }
        // put into a map for easy reference
        Map<Id,SObject> refSourceMap = new Map<Id,SObject>(refCtcts);
        System.debug('getActivitiesForReferralContact refSourceMap='+refSourceMap.size());
        if (refAcct != null) {
           refSourceMap.put(refAcct.Id,refAcct);
        }

        //use CAR on Activity to filter the Activity
        //SUbject, Activity Date, Contact Name(Referral Contact)
        List<Event> Events = [Select Id,Subject,Type,WhoId,ActivityDate,OwnerId,Owner.Name,WhatId, ActivityDateTime from Event where WhatId in :refSourceMap.keySet() order by ActivityDate desc limit :ACTIVITY_NBR_RECS];
        List<Task> Tasks = [Select Id,Subject,Type,WhoId,ActivityDate,OwnerId,Owner.Name,WhatId,Status from Task where WhatId in :refSourceMap.keySet() order by ActivityDate desc limit :ACTIVITY_NBR_RECS];
        for(Event evt: Events){
            EventTaskActivity act = new EventTaskActivity(evt,refSourceMap.get(evt.WhatId));
            ActivityList.add(act);
        }
        for(Task tsk: Tasks){
            EventTaskActivity act = new EventTaskActivity(tsk,refSourceMap.get(tsk.WhatId));
            ActivityList.add(act);
        }
        System.debug('getActivitiesForReferralContact Events='+Events.size()+' Tasks='+Tasks.size()+' ActivityList='+ActivityList.size());
        ActivityList.sort();
        return ActivityList;
    } // getActivitiesForReferralContact
    /*
    public class EmailWrapper{
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public Referral_Contact__c value{get;set;}

        public EmailWrapper(Referral_Contact__c refctct){
            label = refctct.Name; //+' :'+refctct.Email__c;
            value = refctct;
        }
    }
     */
    public class CAOption{
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value{get;set;}
        public CAOption(Referral_Contact__c refctct){
            label = refctct.Name; //+' :'+refctct.Email__c;
            value = refctct.Id;
        }

    }
    @AuraEnabled(cacheable=true)
    public static List<CAOption> getCAOptionList(Id refActId){
        List<CAOption> OptionsList = new List<CAOption>();
        List<Referral_Contact__c> refctcts = getReferralContactswithAcctId(refActId);
        for(Referral_Contact__c refctct:refctcts){
            OptionsList.add(new CAOption(refctct));
        }
        return OptionsList;

    }
    @AuraEnabled(cacheable=true)
    public static List<Referral_Contact__c> getReferralContactsEmailList(Id refActId){
        //List<EmailWrapper> emailList = new List<EmailWrapper>();
        List<Referral_Contact__c> refctcts = getEmailCapableRefCtcts(refActId);

        
        
        return refctcts;
    }
    @AuraEnabled(cacheable=true)
    public static Referral_Contact__c getReferralContact(Id refctctId){
        return [Select Id,Name from Referral_Contact__c where Id =:refctctId Limit 1];
    }
    public class TouchPointRefContact{
        @AuraEnabled
        public String Name {get;set;}
        
        @AuraEnabled
        public String Email {get;set;}
        
        @AuraEnabled
        public String Phone {get;set;}
        
        @AuraEnabled
        public String Mobile_Phone {get;set;}
        
        @AuraEnabled
        public String Title {get;set;}
        
        @AuraEnabled
        public String AICPA {get;set;}
        
        @AuraEnabled
        public Date Last_Activity_Date {get;set;}
        
        @AuraEnabled
        public String ScoreTotalReferrals {get;set;}
        
        @AuraEnabled
        public Decimal Referrals_In_Last_Year {get;set;}
        
        @AuraEnabled
        public Id Id {get;set;}
        public TouchPointRefContact(Referral_Contact__C refctct){
            Name = refctct.Name;
            Phone = refctct.Phone__c;
            Mobile_Phone = refctct.Mobile_Phone__c;
            Title = refctct.Title__c;
            AICPA = refctct.AICPA__c;
            Last_Activity_Date = refctct.Last_Activity_Date__c;
            ScoreTotalReferrals = refctct.ScoreTotalReferrals__c;
            Id = refctct.Id;
            Email = refctct.Email__c;
        }

    }
    /*@AuraEnabled(cacheable=true)
    public static List<TouchPointRefContact> getTPRefctcts(Id refActId){
        List<Referral_Contact__c> refctcts = getReferralContactswithAcctId(refActId);
        List<Id> refctctIds = new List<Id>();
        List<TouchPointRefContact> enhancedRefctcts = new List<TouchPointRefContact>();

        //Map<Id,List<Opportunity>> enhancedRefctctMap = new Map<Id,List<Opportunity>>();

        for(Referral_Contact__c refctct: refctcts){
            refctctIds.add(refctct.Id);
            TouchPointRefContact refctctEnhanced = new TouchPointRefContact(refctct);
            enhancedRefctcts.add(refctctEnhanced);
        }
        Date aYearAgo = Date.today().addMonths(-12);
        // List<Opportunity> refctctOpps = [Select Id,Referral_Contact__c,CreatedDate,Referral_Account__c, from Opportunity where CreatedDate>=:aYearAgo AND Referral_Contact__c IN : refctctIds AND Referral_Account__c =:refActId];
        List<ReferralScoreHistory__c> scoreHistories  = [Select Id,Name,Referral_Contact__c,StartDate__c,Count_Total_Referrals__c from ReferralScoreHistory__c where Referral_Contact__c In :refctctIds ORDER BY  StartDate__c DESC];
        scoreHistories.sort();
        // ** potential code if ReferralScoreHistory is too slow ** 

        // for(Opportunity opp: refctctOpps){
        //     if(enhancedRefctctMap.ContainsKey(opp.Referral_Contact__c)){
        //         List<Opportunity> refctctOppList = enhancedRefctctMap.get(opp.Referral_Contact__c);
        //         refctctOppList.add(opp);
        //         enhancedRefctctMap.put(opp.Referral_Contact__c,refctctOppList);
        //     }else{
        //         enhancedRefctctMap.put(opp.Referral_Contact__c,new List<Opportunity>{opp});
        //     }
        // }

       //filter scorHistories with no duplicates and if there are duplicates the latest start date wins
       List<ReferralScoreHistory__c> filteredScoreHistories = new List<ReferralScoreHistory__c>();
        //checks for duplicates and gives most recent score history object
        for(Integer i = 0; i<scoreHistories.size(); i++){
   System.debug(i);
            if(filteredScoreHistories.isEmpty()|| filteredScoreHistories[filteredScoreHistories.size()-1].Referral_Contact__c!=scoreHistories[i].Referral_Contact__c){
                filteredScoreHistories.add(scoreHistories[i]);
            }
            else if(scoreHistories[i].Referral_Contact__c == filteredScoreHistories[filteredScoreHistories.size()-1].Referral_Contact__c){
                ReferralScoreHistory__c hist1 = scoreHistories[i];
                ReferralScoreHistory__c hist2 = filteredScoreHistories[filteredScoreHistories.size()-1];
                if(hist1.StartDate__c>=hist2.StartDate__c && hist1.StartDate__c > aYearAgo){
                    filteredScoreHistories[filteredScoreHistories.size()-1] = hist1;
                }

            }
       }
      // adding the number of Referrals to the referral contact Object
        for(TouchPointRefContact enhancedRefctct: enhancedRefctcts){
            //List<ReferralScoreHistory__c> refctctHistories = new List<ReferralScoreHistory__c>();
            for(ReferralScoreHistory__c sH: filteredScoreHistories){
                if(sH.Referral_Contact__c == enhancedRefctct.Id ){
                    // refctctHistories.add(sH);
                    enhancedRefctct.Referrals_In_Last_Year = sH.Count_Total_Referrals__c;
                }
            }
            //referralContactHistories.add(rectctHistories);
        }


        return enhancedRefctcts;
    }*/
    public class TouchPointRefContactWrapper{
        @AuraEnabled
        public Decimal Referrals_In_Last_Year;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String Link;
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String Email;
        @AuraEnabled
        public String Phone;
        @AuraEnabled
        public String Mobile_Phone;
        @AuraEnabled
        public String Title;
        @AuraEnabled
        public String AICPA;
        @AuraEnabled
        public Date Last_Activity_Date;
        @AuraEnabled
        public String ScoreTotalReferrals;
        @AuraEnabled
        public Referral_Contact__C refCtct;
    }
    @AuraEnabled(cacheable=true)
    public static List<TouchPointRefContactWrapper> getTPRefctcts(Id refActId){
        List<Referral_Contact__c> refctcts = getReferralContactswithAcctId(refActId);
        List<Id> refctctIds = new List<Id>();
        List<TouchPointRefContactWrapper> enhancedRefctcts = new List<TouchPointRefContactWrapper>();
        
        //Map<Id,List<Opportunity>> enhancedRefctctMap = new Map<Id,List<Opportunity>>();
        
        for(Referral_Contact__c refctct: refctcts){
            refctctIds.add(refctct.Id);
            TouchPointRefContactWrapper refctctEnhanced = new TouchPointRefContactWrapper();
            refctctEnhanced.refCtct = refctct;
            refctctEnhanced.Name = refctct.Name;
            refctctEnhanced.Phone = refctct.Phone__c;
            refctctEnhanced.Mobile_Phone = refctct.Mobile_Phone__c;
            refctctEnhanced.Title = refctct.Title__c;
            refctctEnhanced.AICPA = refctct.AICPA__c;
            refctctEnhanced.Last_Activity_Date = refctct.Last_Activity_Date__c;
            refctctEnhanced.ScoreTotalReferrals = refctct.ScoreTotalReferrals__c;
            refctctEnhanced.Id = refctct.Id;
            refctctEnhanced.Link = '/' + refctct.Id;
            refctctEnhanced.Email = refctct.Email__c;
            enhancedRefctcts.add(refctctEnhanced);
        }
        Date aYearAgo = Date.today().addMonths(-12);
        // List<Opportunity> refctctOpps = [Select Id,Referral_Contact__c,CreatedDate,Referral_Account__c, from Opportunity where CreatedDate>=:aYearAgo AND Referral_Contact__c IN : refctctIds AND Referral_Account__c =:refActId];
        List<ReferralScoreHistory__c> scoreHistories  = [Select Id,Name,Referral_Contact__c,StartDate__c,Count_Total_Referrals__c from ReferralScoreHistory__c where Referral_Contact__c In :refctctIds ORDER BY  StartDate__c DESC];
        scoreHistories.sort();
        // ** potential code if ReferralScoreHistory is too slow ** 
        
        // for(Opportunity opp: refctctOpps){
        //     if(enhancedRefctctMap.ContainsKey(opp.Referral_Contact__c)){
        //         List<Opportunity> refctctOppList = enhancedRefctctMap.get(opp.Referral_Contact__c);
        //         refctctOppList.add(opp);
        //         enhancedRefctctMap.put(opp.Referral_Contact__c,refctctOppList);
        //     }else{
        //         enhancedRefctctMap.put(opp.Referral_Contact__c,new List<Opportunity>{opp});
        //     }
        // }
        
        //filter scorHistories with no duplicates and if there are duplicates the latest start date wins
        List<ReferralScoreHistory__c> filteredScoreHistories = new List<ReferralScoreHistory__c>();
        //checks for duplicates and gives most recent score history object
        for(Integer i = 0; i<scoreHistories.size(); i++){
            System.debug(i);
            if(filteredScoreHistories.isEmpty()|| filteredScoreHistories[filteredScoreHistories.size()-1].Referral_Contact__c!=scoreHistories[i].Referral_Contact__c){
                filteredScoreHistories.add(scoreHistories[i]);
            }
            else if(scoreHistories[i].Referral_Contact__c == filteredScoreHistories[filteredScoreHistories.size()-1].Referral_Contact__c){
                ReferralScoreHistory__c hist1 = scoreHistories[i];
                ReferralScoreHistory__c hist2 = filteredScoreHistories[filteredScoreHistories.size()-1];
                if(hist1.StartDate__c>=hist2.StartDate__c && hist1.StartDate__c > aYearAgo){
                    filteredScoreHistories[filteredScoreHistories.size()-1] = hist1;
                }
                
            }
        }
        // adding the number of Referrals to the referral contact Object
        for(TouchPointRefContactWrapper enhancedRefctct: enhancedRefctcts){
            //List<ReferralScoreHistory__c> refctctHistories = new List<ReferralScoreHistory__c>();
            for(ReferralScoreHistory__c sH: filteredScoreHistories){
                if(sH.Referral_Contact__c == enhancedRefctct.refCtct.Id ){
                    // refctctHistories.add(sH);
                    enhancedRefctct.Referrals_In_Last_Year = sH.Count_Total_Referrals__c;
                }
            }
            //referralContactHistories.add(rectctHistories);
        }
        
        
        return enhancedRefctcts;
    }   
    
    //APR0159917--Start
    @AuraEnabled(cacheable=true)
    public static boolean  isLastStep(Id cadenceId,Integer stepNumber){
        system.debug('MA'+cadenceId+'Inside CadenceTouchpointExtension'+stepNumber);
        Boolean lastStep=false;
        List<Cadence_Step__c> lstCadenceStep=[Select id,CadenceId__r.Outcome_Required__c from Cadence_Step__c where CadenceId__c=:cadenceId];
        //Integer totalCadencestep=0;
        if(lstCadenceStep[0].CadenceId__r.Outcome_Required__c==true){
            if(stepNumber==lstCadenceStep.size()){
                lastStep=true;
            }
            //totalstep=lstCadenceStep.size();
        }
        return lastStep;
    }
    //APR0159917--End

}