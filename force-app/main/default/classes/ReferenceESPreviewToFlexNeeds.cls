/* 
 * Controller for ReferenceESPreviewtoFlexNeeds.page.
   Shows all Functionality Needed records in a table
   Table has pagination
 *
 * History
 * -------
 * 01/06/2016 Jacob Hinds        Created.
 *
 */
public with sharing class ReferenceESPreviewToFlexNeeds {

   public integer counter=0;  //keeps track of the offset
   public integer listSize=20; //sets the page size or number of rows
   public integer totalSize; //used to show user the total size of the list
	public ReferenceESPreviewToFlexNeeds(ApexPages.StandardController stdController) {
		totalSize = [select count() from Reference_ES_Functionality_Needed__c];
	}


   public List<Reference_ES_Functionality_Needed__c> getNeeds{
      get {
      	List<Reference_ES_Functionality_Needed__c> needs = [SELECT Id,Name,Availability__c,Description__c FROM Reference_ES_Functionality_Needed__c order by Name 
                                limit :listSize
                                offset :counter];
      	return needs; 
      }
   } //getNeeds
   
   public PageReference Beginning(){ //user clicked beginning
      counter = 0;
      return null;
   }

   public PageReference Previous(){ //user clicked previous button
      counter -= listSize;
      return null;
   }

   public PageReference Next(){ //user clicked next button
      counter += listSize;
      return null;
   }

   public PageReference End(){ //user clicked end
      //counter = totalSize - math.mod(totalSize, listSize);
      counter = totalSize - listSize;
      return null;
   }

   public Boolean getDisablePrevious(){ 
      //this will disable the previous and beginning buttons
      if (counter>0) return false; else return true;
   }

   public Boolean getDisableNext(){ //this will disable the next and end buttons
      if (counter + listSize < totalSize) return false; else return true;
   }

   public Integer gettotalSize(){
      return totalSize;
   }
   
   public Integer getCurrentCount(){
      return counter+1;
   }
   
   public Integer getPageSize(){
      Integer size;
      if(totalSize>(counter+listSize)){
      	size = counter+listSize;
      }
      else{
      	size = totalSize;
      }
      return size;
   }
}