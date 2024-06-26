/* 
 * A class to wrap up all of the components of a File
 *
 * History
 * -------
   05/31/2018 Dan Carmen   Created

 */
public with sharing class FileWrapper {
   
   public FileWrapper(Id[] p_parentIds, String p_fileName, String p_displayName, String p_fileContent, Blob p_blob) {
      parentIds = p_parentIds;
      fileName = p_fileName;
      displayName = p_displayName;
      fileContent = p_fileContent;
      v_blob = p_blob;
   } // FileWrapper

   public Id[] parentIds;
   public String fileName;
   public String displayName;
   public String fileContent;
   public Blob v_blob;
   // the link to the version of the File we create
   public ContentVersion conVersion;

} // class FileWrapper