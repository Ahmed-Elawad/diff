/* This class handles the mass create of tasks - form the ContactMassCreateTasks page

  TaskController
   
  History
  -------
  07/08/2015 Dan Carmen   Added changes so tests will run in sandboxes
  04/01/2016 Dan Carmen   Change for NPE.
  04/14/2016 Dan Carmen   Clean up code.
  07/06/2020  Jacob Hinds         Added without sharing per PMD
 */

public without sharing class TaskController {

   String idStr;
   integer i;
   List<Task> whatIdTasks = new List<Task>();
   String[] whatids = new String[]{};
    
   public TaskController() {
      init();
   }

   public void init() {    
      //get the parameter from the query string
      idStr = ApexPages.currentPage().getParameters().get('idStr');
      whatIds = (String.isNotBlank(idStr) ? idStr.split('\\,',0) : new String[]{'null'});
      System.debug('IDSTR VALUE>>>>>>>>>'+whatIds);
   }

   //Method to get the Task type options from the custom Object.
   public List<SelectOption> getTaskType() {
      List<SelectOption> options = new List<SelectOption>();
        
      Schema.DescribeFieldResult fieldResult = Task_Type__c.Type__c.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
      for( Schema.PicklistEntry f : ple) {
         options.add(new SelectOption(f.getLabel(), f.getValue()));
      }       
      return options;
   } // getTaskType

   public void setTaskList(List<Task> tasks) {
      whatIdTasks= tasks;
   } // setTaskList

   public List<Task> getTaskList() {
      whatIdTasks = new List<Task>();
      if (whatIds != null && whatIds.size() > 0 && whatIds[0] != 'null') {
         System.debug('whatid Size>>>>>>>>>'+whatIds.size());
         for (Referral_Contact__c refCtct : [Select Id, Referral_Type__c from Referral_Contact__c where Id in :whatIds]) {
            whatIdTasks.add(new Task(whatid=refCtct.Id,Status='Completed',activitydate=System.Today(),Lead_Source_WAR_Call_Type__c=refCtct.Referral_Type__c,Subject='Call'));
         }
      } // if (String.isNotBlank(idStr
      return whatIdTasks;
   } // getTaskList
 
   public PageReference save() {
      //Save all the tasks.
      System.debug('whatIdTasks >>>>>>>>>'+whatIdTasks);
      upsert whatIdTasks;
      //redirect to the referral contact list page
      PageReference refCtctPage = new PageReference('/a07');
      return refCtctPage;        
   } // save
    
    public pageReference cancel(){
      //redirect to the referral contact list page
      PageReference refCtctPage = new PageReference('/a07');
      refCtctPage.setRedirect(true);
      return refCtctPage; 
    } 
    
    
} // class TaskController