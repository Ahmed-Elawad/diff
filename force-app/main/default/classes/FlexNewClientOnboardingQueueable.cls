/** 
 *
 * History
 * -------
   10/25/2022   Dan Carmen      Additional changes for CSO/Enterprise registraion

*/
public class FlexNewClientOnboardingQueueable implements Queueable {
    
    Contact cont;
    Account acct;
    
    
    public FlexNewClientOnboardingQueueable(Contact con, Account acc) {
        cont = con;
        acct = acc;
    }
    
    public void doDMLUpdate() {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
         DMLHelper.performDML2(new List<Contact>{cont}, DmlHelper.DML_UPDATE, 'FlexNewClientOnboardingQueueable', 'doDMLUpdate', 'Updating Contact on submission', true);
         DMLHelper.performDML2(new List<Account>{acct}, DmlHelper.DML_UPDATE, 'FlexNewClientOnboardingQueueable', 'doDMLUpdate', 'Updating Account on submission', true);
    } // doDMLUpdate
    
    public void execute(QueueableContext context) {
        doDMLUpdate();
    }
} // class FlexNewClientOnboardingQueueable