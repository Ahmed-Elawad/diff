/** Helper to create files (since they use multiple operations)

 * History
 * -------
   05/25/2018 Dan Carmen       Created
   07/24/2018 Dan Carmen       Added a no argument constructor
   09/17/2018 Cindy Freeman    changed to without sharing
   09/18/2020 Dan Carmen       Add ContentUrl to the ContentVersion query
   
*/
public without sharing class AddFileQueueable implements Queueable {
   
   public static String CLASS_NAME='AddFileQueueable';
   
   // options are AllUsers, InternalUsers, SharedUsers
   public String fileVisibility='SharedUsers';
    
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      return abc;
   } // getBatchControl
    
   public AddFileQueueable() {
   }

   public AddFileQueueable(Id[] p_parentIds, String p_fileName, String p_displayName, String p_fileContent, Blob p_blob) {
      wrappersToProcess.add(new FileWrapper(p_parentIds, p_fileName, p_displayName, p_fileContent, p_blob));
   } // AddFileQueueable

   public AddFileQueueable(FileWrapper[] p_wrappersToProcess) {
      wrappersToProcess = p_wrappersToProcess;
   } // AddFileQueueable
   
   public void addAnotherFile(Id[] p_parentIds, String p_fileName, String p_displayName, String p_fileContent, Blob p_blob) {
      wrappersToProcess.add(new FileWrapper(p_parentIds, p_fileName, p_displayName, p_fileContent, p_blob));
   }

   public FileWrapper[] wrappersToProcess = new FileWrapper[]{};
   
   public void execute(QueueableContext context) {
      
      if (!wrappersToProcess.isEmpty()) {
         processRecs();
         launchQueueable(false);
      }
   } // execute

   // this can be called directly if we don't need to run it as a queueable job, but just want to use the functionality to create the file.   
   public void processRecs() {
      System.debug('processRecs wrappersToProcess='+wrappersToProcess.size());
      ContentVersion[] conVersionsToInsert = new ContentVersion[]{};
      for (FileWrapper fileWrap : wrappersToProcess) {
         fileWrap.conVersion = new ContentVersion();
         // S specify this document is in SF, use E for external files
         fileWrap.conVersion.ContentLocation = 'S';
         // The files name, extension is very important here which will help the file in preview. 
         fileWrap.conVersion.PathOnClient = fileWrap.fileName;
         // Display name of the files 
         fileWrap.conVersion.Title = fileWrap.displayName;
         fileWrap.conVersion.VersionData = (String.isNotBlank(fileWrap.fileContent) ? EncodingUtil.base64Decode(fileWrap.fileContent) : fileWrap.v_blob);
         //fileWrap.conVersion.VersionData = EncodingUtil.base64Decode(fileWrap.fileContent); // converting your binary string to Blob
         
         conVersionsToInsert.add(fileWrap.conVersion);
      }
      
      
      DmlHelper.performDML2(conVersionsToInsert, DmlHelper.DML_INSERT, 'AddFileQueueable', 'processRecs', 'Inserting ContentVersion records', true);
      
      // requery the contentVersion records to get the document id
      // First get the content document Id from ContentVersion
      Map<Id,ContentVersion> contVerMap = new Map<Id,ContentVersion>([select Id, ContentDocumentId, ContentUrl from ContentVersion where id in :conVersionsToInsert]);
      System.debug('processRecs contVerMap='+contVerMap.size());
      // create the ContentDocumentLinks
      ContentDocumentLink[] linksToInsert = new ContentDocumentLink[]{};
      for (FileWrapper fileWrap : wrappersToProcess) {
         if (fileWrap.conVersion != null && fileWrap.conVersion.Id != null) {
            ContentVersion conVersion = contVerMap.get(fileWrap.conVersion.Id);
            if (conVersion != null) {
               // replace in the wrapper in case we need to return the ids for elsewhere.
               fileWrap.conVersion = conVersion;
               for (Id recId : fileWrap.parentIds) {
                  ContentDocumentLink cdl = new ContentDocumentLink();
                  cdl.ContentDocumentId = conVersion.ContentDocumentId;
                  cdl.LinkedEntityId = recId; // you can use objectId,GroupId etc
                  cdl.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
                  // options are AllUsers, InternalUsers, SharedUsers
                  // TODO - not sure we actually need to set the visibility. We get an error if it's set to anything but AllUsers in this test.
                  //cdl.Visibility = fileVisibility;
                  System.debug('processRecs cdl='+cdl);
                  linksToInsert.add(cdl);
               }
            }
         }
      } // for (FileWrapper fileWrap
      
      DmlHelper.performDML2(linksToInsert, DmlHelper.DML_INSERT, 'AddFileQueueable', 'processRecs', 'Inserting ContentDocumentLink records', true);
   } // processRecs

/*
   public class FileWrapper {
      public FileWrapper(Id[] p_parentIds, String p_fileName, String p_displayName, String p_fileContent) {
         parentIds = p_parentIds;
         fileName = p_fileName;
         displayName = p_displayName;
         fileContent = p_fileContent;
      } // FileWrapper
      public Id[] parentIds;
      public String fileName;
      public String displayName;
      public String fileContent;
      // the link to the version of the File we create
      public ContentVersion conVersion;
   } // class FileWrapper
*/
   public void launchQueueable(Boolean isFirstRun) {
      Apex_Batch_Control__c abc = getBatchControl();
      System.debug('launchQueueable wrappersToProcess='+wrappersToProcess.size()+' testing='+Test.isRunningTest()+' abc='+abc);
      // enqueue this back up if there are more records to process and we're not running a test (except for the first iteration)
      if ((isFirstRun || !Test.isRunningTest()) && abc != null && abc.Active__c && !wrappersToProcess.isEmpty()) {
         // re-enqueue the job - can't chain the jobs from tests
         AddFileQueueable afq = new AddFileQueueable(wrappersToProcess);
         System.enqueueJob(afq);
      }
   } // launchQueueable

} // class AddFileQueueable