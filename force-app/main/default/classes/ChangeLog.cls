/* To record a history of changes
   
  History
  -------
  09/09/2014 Dan Carmen   Created
  08/20/2018 Cindy Freeman	added getFileWrapper method to replace getAttachment
  
 */
global with sharing class ChangeLog {
	
	global static Boolean allowLogging = false;

   public static String[] DEF_HEADER_FIELDS = new String[]{'Id','FieldName','NewValue'};

   global static String[] headerFields = DEF_HEADER_FIELDS;
   
   global static String logData = '';
   
   global static void addToLog(String recId, String fieldName, String newValue) {
   	if (allowLogging) {
         logData += recId+','+fieldName+','+newValue+'\n';
   	}
   } // addToLog
   
   global static Boolean hasLogData() {
      return (String.isNotBlank(logData));
   }
   
   global static Attachment getAttachment(String p_fileName) {
      Attachment attach = null;
      System.debug('getAttachment logData='+(logData != null ? logData.length() : -1));
      if (allowLogging && String.isNotBlank(logData)) {
         String fileData = getArrayAsString(headerFields);
         fileData += logData;
         
         Blob csvBlob = Blob.valueOf(fileData);
         String rightNow = DateTime.now().format('yyyyMMddHHmmss');
         String fileName= p_fileName+'.'+rightNow+'.csv';
         attach = new Attachment();    
         attach.Body = csvBlob;    
         attach.Name = fileName;
         attach.ContentType='text/csv';
      } // if
      return attach;
   } // getAttachment
   
      public static FileWrapper getFileWrapper(String p_fileName) {
      FileWrapper fw = null;
      System.debug('getFileWrapper logData='+(logData != null ? logData.length() : -1));
      if (allowLogging && String.isNotBlank(logData)) {
         String fileData = getArrayAsString(headerFields);
         fileData += logData;
         
         Blob csvBlob = Blob.valueOf(fileData);
         String rightNow = DateTime.now().format('yyyyMMddHHmmss');
         String fileName= p_fileName+'.'+rightNow+'.csv';
         fw = new FileWrapper(null, fileName, fileName, null, csvBlob);  
      } // if
      return fw;
   } // getFileWrapper
   
   
   public static String getArrayAsString(String[] strArray) {
      String output = '';
      for (String str : strArray) {
         output += (String.isNotBlank(output) ? ',' : '') + str;
      }
      output += '\n';
      return output;
   } // getArrayAsString
   
} // class ChangeLog