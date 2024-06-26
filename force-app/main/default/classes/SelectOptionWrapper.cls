/* 
 * Class used to wrap around the select options
 *
 * History
 * -------
   10/10/2017 Dan Carmen       Created

 *
 */
public with sharing class SelectOptionWrapper {

   public SelectOptionWrapper(String picklistName, String value, String label) {
      this.picklistName = picklistName;
      this.value = value;
      this.label = label;
   } // SelectOptionWrapper


   @AuraEnabled
   public String picklistName { get;set; }
   @AuraEnabled
   public String label { get;set; }
   @AuraEnabled
   public String value { get;set; }

} // class SelectOptionWrapper