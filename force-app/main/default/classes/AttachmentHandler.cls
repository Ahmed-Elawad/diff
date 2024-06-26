/** Methods for Attachments
 * 
 * History
 * -------
   09/12/2022 Dan Carmen         Created
 
 */
public class AttachmentHandler implements TriggerInterfaceC {
    
    //Add Trigger Information
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
       Id quoteUserId = EZOnboardingRegistration.getQuoteUserId();
       System.debug('handleTrigger runningUser='+UserInfo.getUserId()+' quoteUserId='+quoteUserId+' isInsert='+(oldMap == null));
       if (quoteUserId != null && quoteUserId == UserInfo.getUserId() && (oldMap == null)) {
          handleQuoteInsert((Attachment[])recs);
       }
    } // handleTrigger
    
    public static void handleQuoteInsert(Attachment[] attaches) {
       Map<Id,Attachment> quoteAttachMap = new Map<Id,Attachment>();
       for (Attachment attach : attaches) {
          if (String.valueOf(attach.ParentId).startsWith('006') && attach.Name.containsIgnoreCase('Completed')) {
             quoteAttachMap.put(attach.ParentId,attach);
          }
       } // for (Attachment attach : attachs
       System.debug('handleQuoteInsert attaches='+attaches.size()+' quoteAttachMap='+quoteAttachMap.size());
       if (!quoteAttachMap.isEmpty()) {
          Opportunity[] opps = [SELECT Id,Name, Primary_Oracle_Quote__c,Primary_Oracle_Quote__r.Name,Probability,ClientRegistrationTestMode__c 
                                      ,ClientTracking__c
                                      ,ClientTracking__r.Id, ClientTracking__r.QuoteSigned__c, ClientTracking__r.QuoteSignedDate__c, ClientTracking__r.ProcessNotes__c
                                  FROM Opportunity 
                                 Where ID IN :quoteAttachMap.keySet()
                                   and ClientTracking__c != null
                                   and Primary_Oracle_Quote__c != null];
          System.debug('handleQuoteInsert opps='+opps);               
          CSO_Tracking__c[] updateTrackers = new CSO_Tracking__c[]{};
          for (Opportunity opp : opps) {
             Attachment attach = quoteAttachMap.get(opp.Id);
             if (attach != null && attach.Name.startsWithIgnoreCase(opp.Primary_Oracle_Quote__r.Name)) {
                opp.ClientTracking__r.QuoteSigned__c = true;
                opp.ClientTracking__r.QuoteSignedDate__c=Datetime.now();
                StringHelper.addToProcessNotes(opp.ClientTracking__r, 'Marking Quote Signed through AttachmentHandler');
                updateTrackers.add(opp.ClientTracking__r);
             }
          }
          CsoMethods.SKIP_TRIGGERS=true;
          DmlHelper.performDML2(updateTrackers, DmlHelper.DML_UPDATE, 'AttachmentHelper', 'handleQuoteInsert', 'Update CSO Trackers with Quote Info', true); 
       } // if (!quoteAttachMap.isEmpty
    } // handleQuoteInsert
    
   /* public static String QUOTE_CREATED_BY='DocuSign API User';
    public static void opportunityDocusignQuote(List<Attachment> listOfAttachment){
        
        User checkUser = null;
        try {
            checkUser = [Select Id, Name from User Where IsActive=true and Name=:QUOTE_CREATED_BY limit 1];
        } catch (Exception e) {
            
        }
        System.debug('checkUser '+checkUser);
        Set<Id> setOfOpportunityId = new Set<Id>();
        for(Attachment atta : listOfAttachment){
            System.debug('atta.CreatedById '+atta.CreatedById);
            System.debug('atta.CreatedBy.Name '+atta.CreatedBy.Name);
            
            if((String.valueOf(atta.ParentId).startsWith('006') && ((checkUser != null && checkUser.Id == atta.CreatedById) || atta.CreatedBy.Name == QUOTE_CREATED_BY) && atta.Name.containsIgnoreCase('Completed')) || Test.isRunningTest()){
                setOfOpportunityId.add(atta.ParentId);
            }
        }
        
        Map<Id,Opportunity> mapOfOpportunity = new Map<Id,Opportunity>([SELECT Id,Primary_Oracle_Quote__c,Primary_Oracle_Quote__r.Name,Probability,ClientRegistrationTestMode__c FROM Opportunity Where ID IN : setOfOpportunityId]);
        
        List<EZ_Onboarding_Refresh__e> listOfEZ = new List<EZ_Onboarding_Refresh__e>();
        for(Attachment atta : listOfAttachment){
            if((String.valueOf(atta.ParentId).startsWith('006') && ((checkUser != null && checkUser.Id == atta.CreatedById) || atta.CreatedBy.Name == QUOTE_CREATED_BY) && atta.Name.containsIgnoreCase('Completed') && mapOfOpportunity.containsKey(atta.ParentId) && atta.Name.startsWithIgnoreCase(mapOfOpportunity.get(atta.ParentId).Primary_Oracle_Quote__r.Name)) || Test.isRunningTest()){
                EZ_Onboarding_Refresh__e ez = new EZ_Onboarding_Refresh__e();
                ez.Record_Id__c = atta.ParentId;
                listOfEZ.add(ez);
            }
        }
        s
        if(!listOfEZ.isEmpty()){
            try{
                Insert listOfEZ;
            }catch(exception e){
                
            }
        }
        
    }
*/
} // class AttachmentHandler