/* 
 * The methods used for marking zip codes to be re-run.
 *
 * History
 * -------
 * 12/10/2009 Dan Carmen   Created
 * 10/18/2010 Dan Carmen   Added isSystemAdmin variable.
 * 10/22/2010 Dan Carmen   Added HNBF, option to select which ownership field to set.
 * 03/02/2011 Dan Carmen   Updates to fix security loopholes.
   07/11/2011 Dan Carmen   Remove normalize options.
   02/06/2012 Dan Carmen   Added sequence update.
   06/22/2012 Dan Carmen   Added Run Add User Batch option.
   08/02/2012 Dan Carmen   Change batch size for Add User Batch
   03/25/2013 Dan Carmen   Add Org Structure/Org Unit options
   11/01/2013 Dan Carmen   Added Prospect Ownership Batch
   06/02/2015 Dan Carmen   Added UserTransferBatch
   04/04/2016 Dan Carmen   Added ability to setup the batch jobs in the custom settings.
   05/26/2016 Dan Carmen   Remove the extra batches from the code - rely on the custom settings
   08/03/2016 Dan Carmen   Changes for making it dynamic.
   08/13/2018 Dan Carmen   Change to run schedulable only classes
   08/17/2021 Dan Carmen   Pull out launchJob so it can be called separately
   11/09/2021 Dan Carmen   Fix for jobs launching twice
 
 */
public with sharing class UpdateZipOwnershipController {

   private Integer MAX_ROWS=1000;
   
   public Boolean isSystemAdmin{get; private set;}
   
   /** This is used for testing purposes
    */
   public void setMaxRows(Integer rows) {
      MAX_ROWS = rows;
   } // setMaxRows
   
   public UpdateZipOwnershipController() {
      clearVariables();
      changesDisplayed = false;
      setChangesPending();
      ownershipOption = 'Any';
      User u = [Select Id, Profile.Name from User where Id = :UserInfo.getUserId()];
      // TODO - this is TEMPORARY - for testing purposes.
      isSystemAdmin = (u.Profile.Name.startsWith('System Administrator') || u.Profile.Name == 'NSS Manager');
   } // UpdateZipOwnership
   
   public String ownershipOption{get;set;}
   
   public List<SelectOption> getOwnershipOptions() {
      List<SelectOption> options = new List<SelectOption>();
      options.add(new SelectOption('Any','Any Owner'));
      for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
         if (salesOrg.HasOwnership__c) {
            options.add(new SelectOption(salesOrg.Name, salesOrg.Name));
         }
      } // for (SalesOrg__c salesOrg
      return options;
   } // getOwnershipOptions
   
   private void clearVariables() {
      za = new Zip_Assignment__c();
      zip1 = '';
      zip2 = '';
   } // clear the variables
     
   public String zip1 {get; set;}
   
   public String zip2 {get; set;}
   
   public Zip_Assignment__c za {get; set;}
   
   private Boolean hasZip = false;
   
   private String searchMsg = '';
   
   public String getSearchMsg() {
      return searchMsg;
   }
   public PageReference searchZips() {
      System.debug('Start searchZips');
      hasZip = (checkHasValidZip(zip1) || checkHasValidZip(zip2));
      System.debug('hasZip='+hasZip);
      searchMsg = '';
      
      if (za.User__c != null || hasZip ) {
         System.debug('in if, number of messages='+ApexPages.getMessages().size());
         // should be no messages from the checkHasValidZip method
         if (ApexPages.getMessages().size() == 0) {
            searchZipsForOwner();
         }
      } else {
         System.debug('No valid criteria');
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You must enter at least one valid criteria to continue'));
      }
      clearVariables();
      System.debug('End searchZips');
      return Page.UpdateZipOwnership;
   } // searchZips
   
   private Boolean checkHasValidZip(String zip) {
      System.debug('Start checkHasValidZip');
      if ((zip == null) || (zip.length() == 0)) {
         System.debug('zip value is blank');
         return false;
      }
      if (zip.length() < 5) {
         System.debug('Zip is incorrect size zip='+zip);
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'The Zip Code you entered, '+zip+', is not 5 characters in length. Please enter the value again'));
         return false;
      }
      System.debug('End checkHasValidZip');
      return true;
   } // checkHasValidZip
   
   public Boolean showSearchResults {
       get {return zips != null;}
   }
   
   public Integer numberChanges{
      get {return (zips != null ? zips.size() : 0);}
   }
   
   private List<Zip_Assignment__c> zips = null;
   
   public List<Zip_Assignment__c> getZips() {
      if (changesDisplayed) {
         return zips;
      }
      return null;
   } // getZips
   
   /** Search through the zip codes for all owned by this user
    */
   private void searchZipsForOwner() {
      System.debug('Start searchZipsForOwner');
      searchMsg = 'Search Criteria, ';

      String query = 'Select Id, Name, User__c, Sales_Org__c, Segment_Name__c, Zip_Segment__c from Zip_Assignment__c where ';
      if (za.User__c != null) {
         User u = [Select Name from User where Id = :za.User__c];
         searchMsg += 'Name='+u.Name+' ';
         query += ' ( User__c = \''+za.User__c+'\' )';
         if (hasZip) {
            query += ' and ';
         }
      }
      if (hasZip) {
         query += '( Name ';
         Boolean hasRange = ((zip1.length() == 5) && (zip2.length() == 5));
         if (hasRange) {
            searchMsg += 'Zip Code between '+zip1+' and '+zip2+' ';
            query += '>= \''+String.escapeSingleQuotes(zip1)+'\' and Name <= \''+String.escapeSingleQuotes(zip2)+'\'';
         } else {
            String thisZip = (zip1.length() == 5) ? zip1 : zip2;
            searchMsg += 'Zip Code = '+thisZip+' ';
            query += '=\'';
            query += String.escapeSingleQuotes(thisZip);
            query += '\'';
         }
         query += ') ';
      } // if (hasZip)
      if (ownershipOption != null && ownershipOption != 'Any') {
        query += ' and Sales_Org__c=\''+ownershipOption+'\' ';
         searchMsg += 'Sales Org='+ownershipOption+' ';
      }
      query += ' limit '+MAX_ROWS;
      System.debug('query='+query);
      Integer resultSize = 0;

      zips = (List<Zip_Assignment__c>)Database.query(query);
      System.debug('total results='+zips.size());
      
      if (zips == null || (zips != null && zips.size() == 0)) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No results were found for '+searchMsg+'. Please try your search again.'));
         zips = null;
      } else if (zips.size() >= MAX_ROWS) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You have queried the maximum number of records(). You may need to modify your criteria to make sure all of your data is selected'));
      }
   } // searchZips

   public PageReference saveChanges() {
    if (zips != null) {
       Set<Id> idSet = new Set<Id>();
       for (Zip_Assignment__c za : zips) {
          idSet.add(za.Id);
       }
         ZipAssignment.createChangeRecords(idSet);
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Number of Changes made='+zips.size()));
         zips = null;
         clearVariables();
    } // if (zips != null
    
      setChangesPending();
      return Page.UpdateZipOwnership;
      //return null;
   } // saveChanges
   
   public Boolean changesDisplayed {get; private set;}
   
   public void changeChangesDisplayed() {
      changesDisplayed = !changesDisplayed;
   }
   public String getDisplayButtonTitle() {
      if (changesDisplayed) {
         return 'Click to Hide the Zip Codes that were found';
      }
      return 'Click to Display the Zip Codes that were found';
   } // getDisplayButtonTitle
   
   public Boolean showRunBatchBlock {
      get {return true;}
   }
   
   
   /** Count the number of pending records
    */
   private void setChangesPending() {
      Integer pending = [select count() from Zip_Assignment_Change__c where Processed__c=false and Zip_Assignment__r.ZipOkay__c=true limit 1];
      changesPending = (pending > 0);
   } // setChangesPending
   
   /** Get how many records are pending to be processed.
    */
   public Boolean changesPending {get; private set;}

   private Id batchProcessId = null;
   
   public String selectedBatchOption{get;set;}
   
   private List<SelectOption> batchOptions = null;
   
   public List<SelectOption> getBatchOptions() {
      if (batchOptions == null) {
         batchOptions = new List<SelectOption>();
         
         // query the records so they can be selected ordered.
         for (Apex_Batch_Control__c abc : [Select Id, Name, BatchTitle__c from Apex_Batch_Control__c
                                             Where BatchTitle__c != null
                                               and Active__c = true
                                              order by SortOrder__c, BatchTitle__c]) {
            batchOptions.add(new SelectOption(abc.Name, abc.BatchTitle__c));
         } // for

         // leave in so tests don't break         
         if (batchOptions.isEmpty()) {
            batchOptions.add(new SelectOption('Update Ownership','Update Ownership'));
         }
      } // if (batchOptions == null
      return batchOptions;
   } // getBatchOptions
   

   public Boolean showJobInfo {
      get {return batchProcessId != null; }
   } // showJobInfo
   
   /** Status != 'Completed' */
   /* TODO - not being used at this time.
   public AsyncApexJob jobInfo {
      get {return (batchProcessId != null ? [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                            FROM AsyncApexJob WHERE ID =: batchprocessid ] : null); }
   }
   */   

   public PageReference runBatchJob() {
      Boolean foundInSetting = false;
      if (String.isNotBlank(selectedBatchOption)) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(selectedBatchOption);
         //foundInSetting = launchJob(abc);
         if (abc != null) {
            try {
               Type t = Type.forName(abc.Name);
               if (abc.ScheduleOnly__c) {
                  Schedulable schedulableClass = (Schedulable)t.newInstance();
                  schedulableClass.execute(null);
               } else {
                  Database.Batchable<SObject> batchObj = (Database.Batchable<SObject>)t.newInstance();
                  batchProcessId = Database.executeBatch(batchObj, (Integer)abc.BatchSize__c);
               }
               foundInSetting = true;
            } catch (Exception e) {
               System.debug('runBatchJob error launching batch: '+e.getStackTraceString());
            }
         }
      } // if (String.isNotBlank
      if (!foundInSetting) {
         // kept for legacy purposes.
        if (selectedBatchOption == 'Update Ownership') {
            batchProcessId = Database.executeBatch(new ZipBatch(), 1);
         }
      } // if (!foundInSetting
      
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch process launched: '+selectedBatchOption+', batchProcessId='+batchProcessId));
      return Page.UpdateZipOwnership;
   } // runBatchJob
    
   public Boolean launchJob(Apex_Batch_Control__c abc) {
      Boolean success=false;
      if (abc != null) {
         try {
            Type t = Type.forName(abc.Name);
            if (abc.ScheduleOnly__c) {
               Schedulable schedulableClass = (Schedulable)t.newInstance();
               schedulableClass.execute(null);
            } else {
               Database.Batchable<SObject> batchObj = (Database.Batchable<SObject>)t.newInstance();
               batchProcessId = JobHelper.launchBatchWithSchedule(batchObj, abc.Name, Datetime.now(), 1);
               //batchProcessId = Database.executeBatch(batchObj, (Integer)abc.BatchSize__c);
            }
            success = true;
         } catch (Exception e) {
            System.debug('runBatchJob error launching batch: '+e.getStackTraceString());
         }
      }

      return success;
   } // launchJob
   
} // class UpdateZipOwnershipController