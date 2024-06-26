/* Test Methods for FieldChecker

  History
  -------
  03/18/2020 Dan Carmen        Created
  
 */
@isTest
public class FieldCheckerTest {

   @testSetup
   public static void setupTestData() {
      TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{FieldChecker.CLASSNAME}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{FieldChecker.CLASSNAME}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{FieldChecker.CLASSNAME}, classes, TriggerMethods.INTERFACE_C);
      insert classes;
   } // setupTestData
    
    public static String[] states= new String[]
{'Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho','Illinois'
,'Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri'
,'Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina','North Dakota','Ohio','Oklahoma'
,'Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington'
,'West Virginia','Wisconsin','Wyoming'};

public static String[] abbrevs= new String[]
{'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE'
,'NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'};
   
   static testMethod void testStates() {
       System.assertEquals(states.size(), abbrevs.size(), 'There should be the same number of states and abbreviations!');
       Account[] accts = new Account[]{};
       Contact[] ctcts = new Contact[]{};
       Lead[] lds = new Lead[]{};
       for (String state : states) {
           accts.add(new Account(Name='Account'+state, ShippingState=state, BillingState=state));
           ctcts.add(new Contact(LastName=state, FirstName='Jimmy', MailingState=state));
           lds.add(new Lead(Company=state, LastName=state, FirstName='Kelly', State=state));
       }
       insert accts;
       insert ctcts;
       insert lds;
       
       Map<Id,Account> acctMap = new Map<Id,Account>([select Id, Name, ShippingState, BillingState from Account where Id in :accts]);
       Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, Name, MailingState from Contact where Id in :ctcts]);
       Map<Id,Lead> ldMap = new Map<Id,Lead>([Select Id, Name, State from Lead where Id in :lds]);
       
       for (Integer cnt=0; cnt<abbrevs.size(); cnt++) {
          String abbrev = abbrevs[cnt];
          Account acct = accts[cnt];
          Account checkAcct = acctMap.get(acct.Id);
          System.assertEquals(abbrev,checkAcct.BillingState);
          System.assertEquals(abbrev,checkAcct.ShippingState);
          Contact ctct = ctcts[cnt];
          Contact checkCtct = ctctMap.get(ctct.Id);
          System.assertEquals(abbrev,checkCtct.MailingState);
          Lead ld = lds[cnt];
          Lead checkLd = ldMap.get(ld.Id);
          System.assertEquals(abbrev,checkLd.State);
       }
   } // testStates
    
} // class FieldCheckerTest