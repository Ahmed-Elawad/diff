/* 
   Scheduled job for calculating some summary numbers to use with the RJ History table
   
   RJHistorySummary rjhs = new RJHistorySummary();
   rjhs.execute(null);

  History
  -------
  08/03/2020 Dan Carmen   Created
  09/16/2020 Dan Carmen   Added RecordsAddedToday__c column

 */
global with sharing class RJHistorySummary implements Schedulable {

   global void execute(SchedulableContext SC) {
      runProcess();
   } // execute
    
   public static String[] INIT_PRES_TYPES=Label.RJ_History_Initial_Presentations.split(',');
   public static Integer REVENUE_DAYS=Integer.valueOf(Label.RJ_History_Amount_Days);
   public static String[] TASK_RTS=Label.RJ_History_Task_RecordTypes.split(',');

   global void runProcess() {
      FiscalYearSettings curFY = Utilities.getFYByDate(Date.today());
      Integer oppChangesToday=[Select count() from Opportunity where LastModifiedDate=today];
      Integer oppsAddedToday=[Select count() from Opportunity where CreatedDate=today];
      Integer userChangesToday=[Select count() from User where LastModifiedDate=today];
      Integer oliChangesToday=[Select count() from OpportunityLineItem where LastModifiedDate=today];
      Integer oliAddedToday=[Select count() from OpportunityLineItem where CreatedDate=today];
      Integer tskChangesToday=[Select count() from Task where LastModifiedDate=today];
      Integer tskAddedToday=[Select count() from Task where CreatedDate=today];
      Integer eventChangesToday=[Select count() from Event where LastModifiedDate=today];
      Integer eventAddedToday=[Select count() from Event where CreatedDate=today];
      Integer acctAddedToday=[Select count() from Account where CreatedDate=today];
      Integer ctctAddedToday=[Select count() from Contact where CreatedDate=today];
      System.debug('runProcess oppChangesToday='+oppChangesToday+' userChangesToday='+userChangesToday+' oliChangesToday='+oliChangesToday+' tskChangesToday='+tskChangesToday+' eventChangesToday='+eventChangesToday);
       
      Integer oppFYCount=0;
      Decimal oppFYAmount=0; 
      Integer oliFYCount=0;
      Decimal oliFYAmount=0;
      Integer tskFYCount=0;
      Integer evntFYCount=0;
       
      Date revStartDate = Date.today().addDays(-REVENUE_DAYS);
      Date revEndDate = Date.today();

      AggregateResult[] results = [Select sum(Amount) oppAmt from Opportunity 
                              where IsClosed=true and IsWon=true 
                                and OpportunityType__c='Payroll'
                                and CloseDate >= :revStartDate and CloseDate <= :revEndDate];
      // should only be one row returned. 
      if (results != null && results.size() > 0) {
         oppFYAmount = (Decimal)results[0].get('oppAmt');
      }

      results = [Select sum(TotalPrice) oppAmt from OpportunityLineItem
                              where Opportunity.IsClosed=true and Opportunity.IsWon=true 
                                and Opportunity.OpportunityType__c='Payroll'
                                and Opportunity.CloseDate >= :revStartDate and Opportunity.CloseDate <= :revEndDate];
      if (results != null && results.size() > 0) {
         oliFYAmount = (Decimal)results[0].get('oppAmt');
      }
         

       if (curFY != null) {
         oppFYCount = [Select count() from Opportunity 
                              where IsClosed=true and IsWon=true 
                                and OpportunityType__c='Payroll'
                                and CloseDate >= :curFY.StartDate and CloseDate <= :curFY.EndDate];
          
         
         oliFYCount = [Select count() from OpportunityLineItem
                        Where Opportunity.IsClosed=true and Opportunity.IsWon=true 
                          and Opportunity.OpportunityType__c='Payroll'
                          and Opportunity.CloseDate >= :curFY.StartDate and Opportunity.CloseDate <= :curFY.EndDate];
         
         tskFYCount = [Select count() from Task
                        Where ActivityDate >= :curFY.StartDate and ActivityDate <= :curFY.EndDate
                          and IsClosed=true
                          and RecordType.Name in :TASK_RTS];
          
         evntFYCount = [Select count() from Event
                        Where ActivityDate >= :curFY.StartDate and ActivityDate <= :curFY.EndDate
                          and Type in :INIT_PRES_TYPES
                        ];
          
         System.debug('runProcess oppFYCount='+oppFYCount+' oppFYAmount='+oppFYAmount+' oppChangesToday='+oppChangesToday+' oliFYCount='+oliFYCount+' oliFYAmount='+oliFYAmount+' tskFYCount='+tskFYCount+' evntFYCount='+evntFYCount);
      } // if (curFY != null
       
       
      String timeStamp=Datetime.now().format('yyyyMMddhhmmss');
       
      // store the information in the table
      RJHistory__c histOpp = new RJHistory__c(Name='Opp'+timeStamp,ObjectName__c='OPPORTUNITY', RunDate__c=Datetime.now(), RunStatus__c='QueryResults' ,RecordsChangedToday__c=oppChangesToday
                                           ,FiscalYearRecordCount__c=oppFYCount, PeriodAmount__c=oppFYAmount, RecordsAddedToday__c=oppsAddedToday);
      RJHistory__c histOli = new RJHistory__c(Name='Oli'+timeStamp,ObjectName__c='OPPORTUNITYLINEITEM', RunDate__c=Datetime.now(), RunStatus__c='QueryResults' ,RecordsChangedToday__c=oliChangesToday
                                           ,FiscalYearRecordCount__c=oliFYCount, PeriodAmount__c=oliFYAmount, RecordsAddedToday__c=oliAddedToday);
      RJHistory__c histUsr = new RJHistory__c(Name='Usr'+timeStamp,ObjectName__c='USER', RunDate__c=Datetime.now(), RunStatus__c='QueryResults' ,RecordsChangedToday__c=userChangesToday
                                           ,FiscalYearRecordCount__c=null, PeriodAmount__c=null);
      RJHistory__c histTsk = new RJHistory__c(Name='Tsk'+timeStamp,ObjectName__c='TASK', RunDate__c=Datetime.now(), RunStatus__c='QueryResults' ,RecordsChangedToday__c=tskChangesToday
                                           ,FiscalYearRecordCount__c=tskFYCount, PeriodAmount__c=null, RecordsAddedToday__c=tskAddedToday);
      RJHistory__c histEvt = new RJHistory__c(Name='Evt'+timeStamp,ObjectName__c='EVENT', RunDate__c=Datetime.now(), RunStatus__c='QueryResults' ,RecordsChangedToday__c=eventChangesToday
                                           ,FiscalYearRecordCount__c=evntFYCount, PeriodAmount__c=null, RecordsAddedToday__c=eventAddedToday);
      RJHistory__c histAcct = new RJHistory__c(Name='Acct'+timeStamp,ObjectName__c='ACCOUNT', RunDate__c=Datetime.now(), RunStatus__c='QueryResults', RecordsAddedToday__c=acctAddedToday);
      RJHistory__c histCtct = new RJHistory__c(Name='Ctct'+timeStamp,ObjectName__c='CONTACT', RunDate__c=Datetime.now(), RunStatus__c='QueryResults', RecordsAddedToday__c=ctctAddedToday);
      RJHistory__c[] histories = new RJHistory__c[]{histOpp,histOli,histUsr,histTsk,histEvt,histAcct,histCtct};
          
      DmlHelper.performDML2(histories, DmlHelper.DML_INSERT, 'RJHistorySummary', 'runProcess', 'insert RJHistories', true);

   } // runProcess
    
    
} // class RJHistorySummary