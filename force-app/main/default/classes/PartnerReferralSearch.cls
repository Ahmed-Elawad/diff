/*
   run this job to look for duplicate partner referrals, one with source = Inbound Call the other with source = Referral Controller
   created within 15 minutes of each other (Label.PartnerReferral_Duplicate_Timeframe)
        it will update the ReferralController partner referral with values from the Inbound Call partner referral
        it will delete in the Inbound Call partner referral
        it will delete the inbound call Referral record
        it will update the related Task if the WhoId is still the converted Lead
        it will update the related DialSource Action record if the account and contact fields are blank and the lead is the converted lead   
   History
  -------
  09/24/2098 Cindy Freeman      Created
  10/15/2019 Cindy Freeman      modified check on Apex_Batch_Control to be sure entry is active
  11/14/2019 Cindy Freeman      add Job Tracker logging, changed time diff calc to use Absolute so dont care which Partner Referral was created first
  11/20/2019 Cindy Freeman      added logging, check that inbound Referral has been created before try to delete it
  11/25/2019 Cindy Freeman      changed query to filter for source = Incound Call or ReferralController, modified jobtracker notes
  12/06/2019 Cindy Freeman      changed to match Partner Referrals on account and contact, not just lead
  12/24/2019 Cindy Freeman      changed query to look for Lead or Account and Contact
  12/31/2019 Cindy Freeman      changed if stmt to insert job tracker record
  05/30/2024 Dan Carmen         changed to use the Queueable delay instead of a callout
  06/10/2024 Pujitha Madamanchi Added DialSource field to be populated on merge

 */
public class PartnerReferralSearch implements Queueable {
//public class PartnerReferralSearch {
        
     private Id acctId;         // account id from referral
     private Id ctctId;         // contact id from referral
     private Id partRefId;      // partner referral from referral
     private Id leadId;         // converted lead from referral
     public Job_Tracker__c jt;
     public String qContext;    // Queueable context put onto Job Tracker
      
      public PartnerReferralSearch(Id p_acctId, Id p_partRefId, Id p_leadId) {
         this.acctId = p_acctId;
         this.ctctId = null;
         this.partRefId = p_partRefId;
         this.leadId = p_leadId;                   
         system.debug('PartnerReferralSearch p_acctId='+acctId + ' p_partRefId='+partRefId+' p_leadId='+leadId);
         //create job tracker to track job
         jt= new Job_Tracker__c(Process_Start__c=system.now(),Job_Name__c = 'PartnerReferralSearch');
     } // PartnerReferralSearch
    
     public PartnerReferralSearch(Id p_acctId, Id p_ctctId, Id p_partRefId, Id p_leadId) {
        this.acctId = p_acctId;
        this.ctctId = p_ctctId;
        this.partRefId = p_partRefId;
        this.leadId = p_leadId;                   
        system.debug('PartnerReferralSearch p_acctId='+acctId + ' p_partRefId='+partRefId+' p_leadId='+leadId);
        //create job tracker to track job
        jt= new Job_Tracker__c(Process_Start__c=system.now(),Job_Name__c = 'PartnerReferralSearch');
    } // PartnerReferralSearch
    
    public String queryFlds = 'Id, Name, Account__c, Contact__c, Lead__c, Lead__r.IsConverted, Source__c, FirstName__c, LastName__c, Email__c, Title__c,';
    public String queryFlds2 = 'Phone__c, First_Call_Attempted__c, First_Contact_Made__c, ActivityId__c, Disposition__c, Marketo_Lead_Rating__c, ';
    public String queryFlds3 = 'MarketingStage__c, Referral__c, CreatedDate, DialSource_Action__c from PartnerReferral__c ';
    
    
    public void execute(QueueableContext context) {
            qContext = context.getJobId();
            partRefSearch();
    }
    
    /* made the cleanup work separate from the execute in case we need to call it directly instead of queueing it
    */
    public void partRefSearch() {
        Boolean foundBothRecords = false;
        ErrorLog__c errLog = null;
        system.debug('PartnerReferralSearch acctId='+acctId + ' ctctId='+ctctId+' partRefId='+partRefId+' leadId='+leadId);
        system.debug('PartnerReferralSearch about to go to sleep');
        Apex_Batch_Control__c abc = getBatchControl();
        if (abc != null && abc.Active__c)  {         
            System.debug('PartnerReferralSearch waking up');
            
            jt.Notes__c = 'Processing acct='+ acctId +' leadId='+leadId+' partRefId='+partRefId;
            jt.Nbr_Batches__c=1;
            jt.Nbr_Errors__c = 0;
            
            PartnerReferral__c refcntlrPartRef = null;
            PartnerReferral__c inboundPartRef = null;
            
            //String queryString = 'Select ' + queryFlds + queryFlds2 + queryFlds3 + ' where Lead__c = \'' + leadId + '\' Order by CreatedDate desc';
            String queryString = 'Select ' + queryFlds + queryFlds2 + queryFlds3 + ' where ';
            String leadString;
            if (leadId != null)
            {   leadString = 'Lead__c = \'' + leadId + '\' ';   }
            String acctString;                  
            if (acctId != null && ctctId != null)
            {   acctString = '(Account__c = \'' + acctId + '\' and Contact__c = \'' + ctctId + '\') ';  }
            if (String.isNotBlank(leadString) && String.isNotBlank(acctString))
            {   queryString += '('+leadString+' OR '+acctString+') ';   }
            else if (String.isNotBlank(leadString))
            {   queryString += leadString;  }
            else if (String.isNotBlank(acctString))
            {   queryString += acctString;  } 
            
            queryString += 'And (Source__c = \'Inbound Call\' Or Source__c =\'ReferralController\') Order by CreatedDate desc'; 
            System.debug('PartnerReferralSearch query='+queryString);
            List<sObject> sObjList = Database.query(queryString);
            if (!sObjList.isEmpty())
            {   for (PartnerReferral__c partRef : (PartnerReferral__c[])sObjList)
                {   if (partRef.source__c == 'Inbound Call' && inboundPartRef == null)
                    {   inboundPartRef = partRef;   }
                    if (partRef.source__c == 'ReferralController' && refcntlrPartRef == null)
                    {   refcntlrPartRef = partRef;  } 
                    if (inboundPartRef != null && refcntlrPartRef != null)          // break out of loop we found the latest partner referrals
                    {   break;  }
                } // for
                
                if (inboundPartRef != null && refcntlrPartRef != null)
                {   foundBothRecords = true;
                    // should give number of minutes betw datetime
                    Long inboundDt = inboundPartRef.CreatedDate.getTime();
                    System.debug('inboundDt='+inboundDt);
                    Long refcntlDt = refcntlrPartRef.CreatedDate.getTime();
                    System.debug('refcntlDt='+refcntlDt);
                    Double timeDiffSec = (inboundDt - refcntlDt)/1000;  // looking if inbound is later than refcntl                 
                    Double timeDiffMin = math.abs(timeDiffSec/60);      //  dont care if inbound was created before or after refcntl, just if was within timeframe 
                    System.debug('PartnerReferralSearch time diffSec = '+timeDiffSec+' timeDiffMin='+timeDiffMin);
                    jt.Notes__c += '\n Inbound '+inboundPartRef.Name+' created '+inboundPartRef.CreatedDate.getTime()+'\n Refcntl '+refcntlrPartRef.Name+' created'+refcntlrPartRef.CreatedDate.getTime();                                    
                    // get max time difference from a label 
                    Integer maxTime = Integer.valueOf(Label.PartnerReferralTimeFrame);
                    if (timeDiffMin > 0 && timeDiffMin <= maxTime)      // && inboundPartRef.CreatedDate > refcntlrPartRef.CreatedDate)
                    {   System.debug('PartnerReferralSearch inboundPartRef and refcntlrPartRef with same converted Lead created within timeframe, lets do some cleanup');
                        jt.Notes__c += '\n Inbound and Refcntl created within timeframe, do cleanup';
                      try { 
                        refcntlrPartRef.Source__c = 'Inbound Call';
                        refcntlrPartRef.FirstName__c = inboundPartRef.FirstName__c;
                        refcntlrPartRef.LastName__c = inboundPartRef.LastName__c;
                        refcntlrPartRef.Email__c = inboundPartRef.Email__c;
                        refcntlrPartRef.Title__c = inboundPartRef.Title__c;
                        refcntlrPartRef.Phone__c = inboundPartRef.Phone__c;                        
                        refcntlrPartRef.First_Call_Attempted__c = inboundPartRef.First_Call_Attempted__c;
                        refcntlrPartRef.First_Contact_Made__c = inboundPartRef.First_Contact_Made__c;                   
                        refcntlrPartRef.Disposition__c = inboundPartRef.Disposition__c;
                        refcntlrPartRef.ActivityId__c = inboundPartRef.ActivityId__c;
                        refcntlrPartRef.Marketo_Lead_Rating__c = inboundPartRef.Marketo_Lead_Rating__c;
                        refcntlrPartRef.MarketingStage__c = inboundPartRef.MarketingStage__c;
                        refcntlrPartRef.DialSource_Action__c = inboundPartRef.DialSource_Action__c;
                        System.debug('PartnerReferralSearch updating refcntlrPartRef id='+refcntlrPartRef.Id);
                        PartnerReferral__c[] prUpdateList = new List<PartnerReferral__c>{refcntlrPartRef};
                        DmlHelper.performDML(prUpdateList, DmlHelper.DML_UPDATE, 'PartnerReferralSearch', 'partRefSearch', 'Updating refcntlPartRef', false);
                        //update refcntlrPartRef;
                                            
                        // delete Referral shell created by inbound call
                        if (inboundPartRef.Referral__c!=null)
                        {   Referral__c inboundRef = new Referral__c(Id=inboundPartRef.Referral__c);
                            System.debug('PartnerReferralSearch deleting inbound Referral id='+inboundRef.Id);
                            //Referral__c[] refDeleteList = new List<Referral__c>{inboundRef};
                            //DmlHelper.performDML(refDeleteList, DmlHelper.DML_DELETE, 'PartnerReferralSearch', 'partRefSearch', 'Deleting inbound Referral', false);
                            delete inboundRef;
                        }
                        
                        // delete Inbound partner referral
                        System.debug('PartnerReferralSearch deleting inbound Partner Referral id='+inboundPartRef.Id);
                        //PartnerReferral__c[] prDeleteList = new List<PartnerReferral__c>{inboundPartRef};
                        //DmlHelper.performDML(prDeleteList, DmlHelper.DML_DELETE, 'PartnerReferralSearch', 'partRefSearch', 'Deleting inbound PartRef', false);
                        delete inboundPartRef;
                        
                        // get related task and DialSource action to cleanup
                        Task inboundTask = [Select Id, WhoId, WhatId, DS_Denali__DialSource_Action__c,
                                            DS_Denali__DialSource_Action__r.Id,  
                                            DS_Denali__DialSource_Action__r.DS_Denali__Account__c, DS_Denali__DialSource_Action__r.DS_Denali__Contact__c,
                                            DS_Denali__DialSource_Action__r.DS_Denali__Lead__c 
                                            From Task where Id = :inboundPartRef.ActivityId__c];
                        if (leadId != null && inboundTask.WhoId == leadId)
                        {   inboundTask.WhoId = refcntlrPartRef.Contact__c;
                            inboundTask.WhatId = refcntlrPartRef.Account__c;
                            System.debug('PartnerReferralSearch updating task id='+inboundTask.Id+' changing WhoId from converted Lead to Contact');
                            Task[] tskUpdateList = new List<Task>{inboundTask};
                            DmlHelper.performDML(tskUpdateList, DmlHelper.DML_UPDATE, 'PartnerReferralSearch', 'partRefSearch', 'Updating Inbound Task', false);
                            //update inboundTask;
                        }
                        
                        if ((leadId != null && inboundTask.DS_Denali__DialSource_Action__r.DS_Denali__Lead__c == leadId) &&
                            inboundTask.DS_Denali__DialSource_Action__r.DS_Denali__Contact__c == null &&
                            inboundTask.DS_Denali__DialSource_Action__r.DS_Denali__Account__c == null)
                        {   DS_Denali__DialSource_Action__c dsAction = new DS_Denali__DialSource_Action__c();
                            dsAction.Id = inboundTask.DS_Denali__DialSource_Action__r.Id;
                            dsAction.DS_Denali__Account__c = refcntlrPartRef.Account__c;
                            dsAction.DS_Denali__Contact__c = refcntlrPartRef.Contact__c;
                            System.debug('PartnerReferralSearch updating DialSource Action id='+dsAction.Id+' filling in account id');
                            DS_Denali__DialSource_Action__c[] actionUpdateList = new List<DS_Denali__DialSource_Action__c>{dsAction};
                            DmlHelper.performDML(actionUpdateList, DmlHelper.DML_UPDATE, 'PartnerReferralSearch', 'partRefSearch', 'Updating DialSource action', false);
                            //update dsAction;
                        }
                        
                      } // try
                      catch (Exception ex)
                      {     System.debug('PartnerReferralSearch exception = '+ex.getMessage());  
                            errLog = ErrorLog.logError('PartnerReferralSearch', 'partRefSearch', 'partRefSearch', leadId, ex);
                            ErrorLog.checkSave();
                      }
                        
                    } // if (timeDiff < maxTime ... 
                    else // not within time frame
                    {   jt.Notes__c += '\n Inbound and Refcntl created outside timeframe, do nothing';    }   
                } // if (inboundPartRef != null && refcntlrPartRef != null)
                else
                {   jt.Notes__c += '\n Only 1 Partner Referral, Inbound='+(inboundPartRef!=null?inboundPartRef.Name:'null')+' RefCntlr='+(refcntlrPartRef!=null?refcntlrPartRef.Name:'null');   }   
            } // if (!sObjList.isEmpty)
            else
            {   jt.Notes__c += '\n No Inbound Call or ReferralController partner referral records found.';  }

            jt.Status__c = 'Completed';
            jt.Job_Id__c = qContext;
            jt.Process_End__c = system.now();
            //if (foundBothRecords && abc.LogProcess__c)        // if you uncomment this line you need to fix the test class
            if (abc.LogProcess__c)
            {   insert jt;  }            
        } // if (abc != null && abc.Active__c)
    } // partRefSearch                                
    
    public static final String CLASS_NAME='PartnerReferralSearch';
    
    public static Apex_Batch_Control__c getBatchControl() {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        return abc;
    } // getBatchControl
        
    public static void launchQueueable(PartnerReferralSearch prs) {
       Apex_Batch_Control__c abc = getBatchControl();
       if (prs != null && abc.Active__c) {
          Integer delay = (abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 1);
          if (delay > 0) {
             System.enqueueJob(prs,delay);
          } else {
             System.enqueueJob(prs);
          }
       }
    } // launchQueueable
    
} // partnerReferralSearch