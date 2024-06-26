/* 
 * Encapsulate message information
 *
 * History
 * -------
   02/18/2019  Dan Carmen     Created

 */
public without sharing class CheckRecordMsg {
   
   public CheckRecordMsg(String p_labelStyle, String p_label, String p_msgStyle, String p_message) {
      labelStyle = p_labelStyle;
      label = p_label;
      msgStyle = p_msgStyle;
      message = p_message;
   } // CheckRecordMsg
   
   
   @AuraEnabled
   public String label{get;set;}
   
   @AuraEnabled
   public String labelStyle{get;set;}
   
   @AuraEnabled
   public String message{get;set;}

   @AuraEnabled
   public String msgStyle{get;set;}
   
   
} // class CheckRecordMsg