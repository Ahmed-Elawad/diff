/* Class to add Creator's Name to Case Comment upon creation.

  History
  -------
  02/16/2017 Lynn Michels        Created
  
 */
 public without sharing class CaseCommentMethods implements TriggerInterface {
    
    public CaseCommentMethods() {
      
   }//CaseCommentMethods
   
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {
        //get the current user
        String userName = UserInfo.getName();
        String comment = (String)newRec.get('CommentBody');
        //prepend userName to comment
        comment = userName +': '+ comment;
        newRec.put('CommentBody',comment);
      
   } //checkBeforeTrigger
   
   public void processBeforeTriggerActions() {
     
   } //processBeforeTriggerActions
   
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {
    
   } //checkAfterTrigger
   
   public void processAfterTriggerActions() {
    
   } //processAfterTriggerActions
}