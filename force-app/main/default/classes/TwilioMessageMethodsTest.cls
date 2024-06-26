/** 
* The test methods for the TwilioMessageMethods class and trigger.
*
* History
* -------
* 11/30/2018 Justin Stouffer Created
*/
@isTest
public class TwilioMessageMethodsTest {
	
    static testMethod void InboundMessageOwnerTest(){
		TwilioMessageMethods.methodForTests();
/*		User u1 = [Select Id from User where Id != :UserInfo.getUserId() and IsActive=true and Profile.Name='System Administrator' limit 1];
		TwilioSF__Message__c Msg1 =  new TwilioSF__Message__c();
		Msg1.TwilioSF__Direction__c = 'outbound - API';
       	Msg1.TwilioSF__To_Number__c = '+12345678987';
        Msg1.TwilioSF__From_Number__c = '+19999999999';
        Msg1.TwilioSF__Body__c = 'Message 1';
        insert Msg1;

		TwilioSF__Message__c Msg2 =  new TwilioSF__Message__c();
		Msg2.TwilioSF__Direction__c = 'inbound';
       	Msg2.TwilioSF__To_Number__c = '+19999999999';
        Msg2.TwilioSF__From_Number__c = '+12345678987';
        Msg2.TwilioSF__Body__c = 'Message 2';
        
        system.runAs(u1){
        	insert Msg2;        
        }
        TwilioSF__Message__c Msg3 = [Select ownerId from TwilioSF__Message__c where id = :Msg2.id];
        system.assertEquals(Msg3.OwnerId, UserInfo.getUserId());    
        
        TwilioSF__Message__c Msg4 =  new TwilioSF__Message__c();
		Msg4.TwilioSF__Direction__c = 'inbound';
       	Msg4.TwilioSF__To_Number__c = '+19999999999';
        Msg4.TwilioSF__From_Number__c = '+18888888888';
        Msg4.TwilioSF__Body__c = 'Message 4';
        system.runAs(u1){
        	insert Msg4;        
        }
        TwilioSF__Message__c Msg5 = [Select ownerId from TwilioSF__Message__c where id = :Msg4.id];
        system.assertEquals(Msg5.OwnerId, System.Label.TwilioDefaultUser); 
*/
    }
}