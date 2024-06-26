/* 
 * Survey Class for the Reference MPSC object.
 *
 * History
 * -------
 * 01/24/2018 Frank Lurz        Created
 */
public class ReferenceMPSCSurvey {
  public static void SendMPSCSurvey(List<Reference_MPSC__c> refMPSCs) {
    for (Reference_MPSC__c refMPSC : refMPSCs) {
      /***  commenting out the check of child Reference MPSC records with a MPSC Status != Completed  ***/
      /***List<Reference_MPSC__c> refMPSCchildrenList = [select Reference_MPSC_Parent__c
                                    From Reference_MPSC__c
                                    Where Reference_MPSC_Parent__c = :refMPSC.Id
                                    And MPSC_Status__c !=  'Completed'];
    
      if (!refMPSCchildrenList.isEmpty()) {
                   refMPSC.addError('You cannot submit a Survey for this record. There are related Reference MPSC records that are not Completed.');
      } //end if
      ***/
      if ( (refMPSC.Reference_MPSC_Parent__c != NULL) || ( (refMPSC.C2C__c != 'No') && (refMPSC.C2C__c != 'Parent') ) ) {
             system.debug('***FLurz*** - checking for records that should not have a Survey Sent...');
             system.debug('***FLurz*** - refMPSC.Reference_MPSC_Parent__c = ' + refMPSC.Reference_MPSC_Parent__c);
             system.debug('***FLurz*** - refMPSC.C2C__c = ' + refMPSC.C2C__c);
             refMPSC.Send_Survey__c = FALSE;
      } //end if
      else {
        refMPSC.Date_Survey_Sent__c = System.today();
        refMPSC.Survey_Status__c = 'Survey Sent';
        refMPSC.Date_Survey_Sent_to_Payroll_BSR__c = System.today();
        refMPSC.Date_Survey_Sent_to_Flex_HR_BSR__c = System.today();
        refMPSC.Date_Survey_Sent_to_TAA_BSR__c = System.today();
        system.debug('***FLurz*** - just after populating refMPSC.Date_Survey_Sent__c'); 
        system.debug('***FLurz*** - PRIOR TO THE CHATTER POST - refMPSC.Payroll_BSR__c = ' + refMPSC.Payroll_BSR__c); 
        List<ID> usersToMention = new List<ID>();
        if(refMPSC.Payroll_BSR__c != null)
           {
               usersToMention.add(refMPSC.Payroll_BSR__c);
           }
        String postText = 'Please complete the Service Feedback Loop for '+refMPSC.Name+ '.'; 
        ChatterMentionPost.createChatterMentionPost(refMPSC.id, usersToMention, new String[]{postText}, true, false);
        system.debug('***FLurz*** - AFTER THE CHATTER POST - postText = ' + postText); 
      }//end - else
    
    }//end - for

    ChatterMentionPost.postBatchFeedElements();

  }//SendMPSCSurvey
}