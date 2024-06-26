/* Batch process for closing opportunities
   
   History
   -------
   02/17/2020 Jacob Hinds       Created
   11/09/2020 Jacob Hinds       Commenting out DSA per APR
   05/18/2021 Carrie Marciano   Changed to use OppStage Labels
   09/12/2022 Pujitha Madamanchi APR0138132 - New Loss reason - PEO Inbound Expired
   06/14/2023 Lalan Kumar        APR0135718 Auto- Close Opp Process for Termed/Inactive Users
   12/22/2023 Dan Carmen         Change how opp is being saved - probability isn't setting correctly

 */
 
global with sharing class OpptyAutoCloseBatch implements Database.Batchable<SObject>, Schedulable {
   
   public static final String CLASS_NAME='OpptyAutoCloseBatch';
   public static String NOT_SOLD=Label.OppStage_Lost;
   public static String MODE_OpptyStatus='StatusLost';
    
    global JobHelper jh = new JobHelper(CLASS_NAME);
	global String mode = null;
    global Id[] testUserIds = new Id[]{};

    /** The time the process started. */
    global DateTime startTime;
    
    /** messages that occur during the process. */
    global String processNotes = '';
    
   global OpptyAutoCloseBatch() {
    } // OpptyAutoCloseBatch
    
    /*APR0135718: Added 'launchBatch' and 'Apex_Batch_Control__c' method*/
	global static void launchBatch(String mode) {
		OpptyAutoCloseBatch oacb = new OpptyAutoCloseBatch();
		oacb.mode = mode;
		Apex_Batch_Control__c abc = getAbc(mode);
		Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 200);
        if (abc != null && abc.Active__c) {
           database.executeBatch(oacb, batchSize);
        }
	} // launchBatch
	global static Apex_Batch_Control__c getAbc(String p_mode) {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(RecordTypeHelper.cleanRtName(CLASS_NAME+(String.isNotBlank(p_mode) ? p_mode : '')));
        if (abc == null) {
           abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        }
        return abc;
    } // getAbc
    
    global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      system.debug('starting Batch process');
      Apex_Batch_Control__c abc = getAbc(mode);
       
          /*APR0135718: Added below query to execute only if mode = MODE_OpptyStatus */
        if(mode == MODE_OpptyStatus){
		   Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 200);
		   Date checkDateLost = (abc!=null && abc.Check_Days__c != null? date.today().addDays(-((Integer)abc.Check_Days__c)):date.today().addDays(-30));
           String[] excludeOppTypes = Label.ExcludeOpptyType.split(',');
           System.debug('OpptyAutoCloseBatch.start checkDateLost='+checkDateLost+' excludeOppTypes='+excludeOppTypes);

           return Database.getQueryLocator([SELECT Id,Auto_Close_Date__c,OwnerId,Owner.ManagerId,Owner.DSA_FSS__c,RecordType.Name,NSS_Source__c
                                               ,StageName,Reason_Not_Sold__c,Probability,OpportunityType__c,Auto_Closed__c
                                         FROM Opportunity WHERE IsClosed = false and 
                                              OpportunityType__c NOT IN :excludeOppTypes AND (NOT NSS_Source__c like '%Inbound%') AND 
                                              Probability < 80 AND 
                                              Owner.IsActive = false 
                                                 AND ((Owner.Termination_Date__c != null AND Owner.Termination_Date__c<:checkDateLost)
                                                       OR (Owner.Transfer_Date__c != null AND Owner.Transfer_Date__c<:checkDateLost)
                                                       OR (Id in :testUserIds))]);
        }
        Date checkDate = (abc!=null && abc.Check_Days__c != null? date.today().addDays(-((Integer)abc.Check_Days__c)):date.today().addDays(-365));
        return Database.getQueryLocator([SELECT Id,Auto_Close_Date__c,OwnerId,Owner.ManagerId,Owner.DSA_FSS__c,RecordType.Name,NSS_Source__c
                                               ,StageName,Reason_Not_Sold__c,Probability,OpportunityType__c,Auto_Closed__c
                                         FROM Opportunity 
                                       WHERE isClosed = false AND LastModifiedDate > :checkDate AND Auto_Close_Date__c <= TODAY]);
      
    } // start
    
   global void execute(SchedulableContext sc) {
      system.debug('Batch Process scheduled');
      Apex_Batch_Control__c abc = getAbc(mode);
      if (abc != null && abc.Active__c) {
         system.debug('found setting, calling execute');
         OpptyAutoCloseBatch oac = new OpptyAutoCloseBatch();
         Integer batchSize = (abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 500);
         system.debug('found setting, batchSize'+batchSize);
         database.executeBatch(oac, batchSize);
      }
   } // execute
   
   public static String chatterType=Label.OpptyAutoClose_Chatter;
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        Boolean chatterInbound = (String.isNotBlank(chatterType) && (chatterType == 'All' || chatterType == 'Inbound'));
        Boolean chatterAll = (String.isNotBlank(chatterType) && (chatterType == 'All'));
        Opportunity[] opptysToClose = (List<Opportunity>)scope;
        processNotes += ('\nProcessing '+opptysToClose.size()+' Opportunities, mode='+(mode != null ? mode : 'default')+' recs='+opptysToClose.size());
        system.debug('OpptyAutoCloseBatch execute scope:'+scope);
        String chatterBody = 'Due to inactivity, this Opportunity has been Closed and will be sent to Marketing to be nurtured';
        Opportunity[] updateOpps = new Opportunity[]{};
        for(Opportunity oppty:opptysToClose){
            RecordType__c recordtype = RecordTypeHelper.getRtSetting(oppty.RecordType.Name);
            Opportunity updateOpp = new Opportunity(Id=oppty.Id);
            updateOpps.add(updateOpp);
             /*APR0135718: Update oppty staus as 'Lost' and Reason lost from custom setting else as 'Auto-Close'*/
			if(mode == MODE_OpptyStatus){
				updateOpp.StageName = NOT_SOLD;
                updateOpp.Auto_Closed__c=true;
                updateOpp.Reason_Not_Sold__c=recordtype!=null && !String.isEmpty(recordtype.Non_Inbound_Auto_Close_Reason__c) ? recordtype.Non_Inbound_Auto_Close_Reason__c : Label.Oppty_Auto_Close;
			} else {
                Boolean isInbound = (String.isNotBlank(oppty.NSS_Source__c) && oppty.NSS_Source__c.startsWith('Inbound'));
               //APR0138132 - New Loss reason - PEO Inbound Expired
                updateOpp.StageName = NOT_SOLD;
                updateOpp.Auto_Closed__c=true;
                if (recordtype !=null) {
                   updateOpp.Reason_Not_Sold__c=(isInbound && String.isNotBlank(recordtype.Opportunity_Auto_Close_Reason__c) ? recordtype.Opportunity_Auto_Close_Reason__c
                                               : (!isInbound && String.isNotBlank(recordtype.Non_Inbound_Auto_Close_Reason__c) ? recordtype.Non_Inbound_Auto_Close_Reason__c
                                                   : Label.Auto_Close_Stage));
                } else {
                   updateOpp.Reason_Not_Sold__c = Label.Auto_Close_Stage;
                }
                 
                Id[] mentionUsers = new Id[]{oppty.OwnerId};
                if(oppty.Owner.ManagerId!=null){
                    mentionUsers.add(oppty.Owner.ManagerId);
                }
                /*if(oppty.Owner.DSA_FSS__c!=null){
                    mentionUsers.add(oppty.Owner.DSA_FSS__c);
                }*/
                if (chatterAll || (isInbound && chatterInbound)) {
                   ChatterMentionPost.createChatterMentionPost(oppty.Id, mentionUsers, new String[] {chatterBody}, true, false);
                }
            }
        }
        DMLHelper.performDML2(updateOpps, DMLHelper.DML_UPDATE, CLASS_NAME, 'execute', 'updating opptys to closed', true);
        ChatterMentionPost.checkPostFeedElements();
       //TO DO: CHATTER FOR AUTO CLOSE
    } // execute
    
   global void finish(Database.BatchableContext BC){
      String message ='\n'+processNotes;
      system.debug('message:'+message);
      jh.completeJob(bc, CLASS_NAME+' process', message);
       /*APR0135718: launch MODE_OpptyStatus*/
	  if (mode == null && !Test.isRunningTest()) {
          launchBatch(MODE_OpptyStatus);
        }

   } // finish     
    
}