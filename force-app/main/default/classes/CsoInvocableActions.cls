/* 
   Test class for CsoInvocableActions

   
  History
  -------
  09/22/2022 Jermaine Stukes       Created

 */
public class CsoInvocableActions {
    public static final String CLASSNAME='CsoInvocableActions';

    @InvocableMethod(label='Resend Flex Post Call'
                     description='Resends call if CSO Registration process has stalled'
                     category='Contact')
    public static void resendUserRegistration(List<Contact> csoContactList) {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
        Boolean okayToResend = (abc != null && abc.Active__c);
        System.debug('resendUserRegistration abc='+(abc != null)+' okayToResend='+okayToResend);
        if (okayToResend) {
           for(Contact con : csoContactList){
            
              FlexNewClientOnboardingController fc = new FlexNewClientOnboardingController();
              fc.contact = con;
              fc.resendPostCall();
           }
        } // if (okayToResend
    } // resendUserRegistration
    
} // class CsoInvocableActions