/* 
   
  History
  -------
  09/11/2019 Dan Carmen       Move workflow logic to code
  10/02/2019 Brandon Vidro    Added setQuoteNumber 
 */
public with sharing class QuoteTriggerHelper {
    public QuoteTriggerHelper(){}
/*	
	public static Boolean TRIGGER_BEFORE_EXECUTED=false;
	
	public static void setPrimaryContact(List<SBQQ__Quote__c> newQuotes){
		QuotePrimaryContactAssigner.setPrimaryContact(newQuotes);
		if (Trigger.isInsert && Trigger.isBefore) {
		   // remove logic from workflow and add to Trigger
		   Map<String,Schema.RecordTypeInfo> byNameMap = SBQQ__Quote__c.SObjectType.getDescribe().getRecordTypeInfosByName();
		   Schema.RecordTypeInfo quoteRtInfo = byNameMap.get('Quote');
		   
		   for (SBQQ__Quote__c quote : newQuotes) {
		      //if (quote.Name != null) {
		         quote.SBQQ__ExpirationDate__c = null;
		         quote.SBQQ__WatermarkShown__c = true;
		         if (quoteRtInfo != null) {
                  quote.RecordTypeId = quoteRtInfo.getRecordTypeId();
		         }
		         quote.SBQQ__Status__c = 'Draft';
		         quote.Final_Approver__c = null;
		      //}
		   } // for (SBQQ__Quote__c quote
		} // if (Trigger.isInsert && Trigger.isBefore
	} // setPrimaryContact
    
    public static void setQuoteNumber(List<SBQQ__Quote__c> newQuotes) {
        if(Trigger.isInsert && Trigger.isBefore) {
            List<Id> opptyIds = new List<Id>();
            List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
            Map<Id, List<Id>> oppQuoteMap = new Map<Id, List<Id>>();
            List<Id> quoteIds = new List<Id>();
            
            for (SBQQ__Quote__c quote : newQuotes)
            {
                opptyIds.add(quote.SBQQ__Opportunity2__c);
            }
            
            quotes = [Select Id, SBQQ__Opportunity2__c from SBQQ__Quote__c where SBQQ__Opportunity2__c in :opptyIds];                 
            
            for(SBQQ__Quote__c quote: quotes) {
                quoteIds.add(quote.Id);
                if(!oppQuoteMap.containsKey(quote.Id)) {
                    oppQuoteMap.put(quote.SBQQ__Opportunity2__c, new List<Id>(quoteIds));
                }
            }
            
            for (SBQQ__Quote__c quote : newQuotes)
            {
                if(!oppQuoteMap.isEmpty()){
                    quote.Quote_Number__c = oppQuoteMap.get(quote.SBQQ__Opportunity2__c).size() + 1;
                } else {
                    quote.Quote_Number__c = 1;
                }
            }
            
        }//if (Trigger.isInsert && Trigger.isBefore
        
    } //setQuoteNumber
*/
} // class QuoteTriggerHelper