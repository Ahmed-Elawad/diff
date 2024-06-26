@isTest
private class Test_UserPwdExtension {
    
    /* - commented out - replacing with UserPwdExtensionTest
    
    static testMethod void testUserPwdExtension () {    
                
        PageReference pageRef = Page.TestUserPwdReset;
        Test.setCurrentPageReference(pageRef);
        
        // get a user to call this page
        Profile p = [SELECT ID, name from Profile where name = 'System Administrator' limit 1];
        User meU = [SELECT ID, email from User where ProfileId = :p.ID limit 1];
        
        // create standard controller
        ApexPages.StandardController sc = new ApexPages.standardController(meU);
        // create controller extension using standard controller
        UserPwdExtension myPageCon = new UserPwdExtension(sc);
        
        // is email from user ok?
        System.assertNotEquals(myPageCon.emale, Null );
                
        // check org ID
        String ans = myPageCon.getWhoandWhere();
        If (productionOrg())  // where are we testing?  real Paychex production org? 
        {   System.assertEquals(ans.substring(0,7), 'This is'); 
            System.assertEquals(myPageCon.orgBad, true); 
            productionOrgTest(myPageCon);
        }
        else
        {   System.assertEquals(ans.substring(0,7), 'Welcome'); 
            System.assertEquals(myPageCon.orgBad, false); 
            sandboxOrgTest(myPageCon);
        }               
                
    }
        
    private static void productionOrgTest(UserPwdExtension myPageCon) {
                        
        // add dummy user to change his password
        Profile padmin = [SELECT ID, name from Profile where name = 'System Administrator'];
        User me = [SELECT ID, email, CommunityNickname, ProfileId, EmailEncodingKey,
            UserRoleId, TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, Sales_Org__c from User
            WHERE ProfileId = :padmin.ID limit 1];
        User newU;
        newU = me.clone(false);
        newU.firstName = 'Test001';
        newU.lastName = 'User';
        newU.Alias = 'Test001';
        newU.Username = 'Tester001@sfdev.com';
        newU.CommunityNickname = 'Tester001';
        insert newU;
                
        myPageCon.resetPwd1();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(0).getDetail(),'Reset DENIED!');
        System.assert(ApexPages.getMessages().get(0).getSeverity() == ApexPages.Severity.ERROR);        
    
        // add dummy user 2 to change his password
        User newU2;
        newU2 = me.clone(false);
        newU2.firstName = 'Test200';
        newU2.lastName = 'User';
        newU2.Alias = 'Test200';
        newU2.Username = 'Tester200@sfdev.com';
        newU2.CommunityNickname = 'Tester200';
        insert newU2;
                
        myPageCon.resetPwd2();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(1).getDetail(),'Reset DENIED!');
        System.assert(ApexPages.getMessages().get(1).getSeverity() == ApexPages.Severity.ERROR);        
    
        // add dummy user 3 to change his password
        User newU3;
        newU3 = me.clone(false);
        newU3.firstName = 'Test300';
        newU3.lastName = 'User';
        newU3.Alias = 'Test300';
        newU3.Username = 'Tester300@sfdev.com';
        newU3.CommunityNickname = 'Tester300';
        insert newU3;
                
        myPageCon.resetPwd3();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(2).getDetail(),'Reset DENIED!');
        System.assert(ApexPages.getMessages().get(2).getSeverity() == ApexPages.Severity.ERROR);        

        myPageCon.orgBad = false;   // test as if trying to run on sandbox
        myPageCon.resetPwd1();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(3).getDetail().substring(0,10),'Password 1');
        System.assert(ApexPages.getMessages().get(3).getSeverity() == ApexPages.Severity.INFO);         
            
    } 


    private static void sandboxOrgTest(UserPwdExtension myPageCon) {

        // add dummy user to change his password
        Profile padmin = [SELECT ID, name from Profile where name = 'System Administrator'];
        User me = [SELECT ID, email, CommunityNickname, ProfileId, EmailEncodingKey,
            UserRoleId, TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, Sales_Org__c from User
            WHERE ProfileId = :padmin.ID limit 1];
        User newU;
        newU = me.clone(false);
        newU.firstName = 'Test001';
        newU.lastName = 'User';
        newU.Alias = 'Test001';
        newU.Username = 'Tester001@sfdev.com';
        newU.CommunityNickname = 'Tester001';
        insert newU;
                
        myPageCon.resetPwd1();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(0).getDetail().substring(0,10),'Password 1');
        System.assert(ApexPages.getMessages().get(0).getSeverity() == ApexPages.Severity.INFO);         

        // add dummy user 2 to change his password
        User newU2;
        newU2 = me.clone(false);
        newU2.firstName = 'Test200';
        newU2.lastName = 'User';
        newU2.Alias = 'Test200';
        newU2.Username = 'Tester200@sfdev.com';
        newU2.CommunityNickname = 'Tester200';
        insert newU2;
                
        myPageCon.resetPwd2();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(1).getDetail().substring(0,10),'Password 2');
        System.assert(ApexPages.getMessages().get(1).getSeverity() == ApexPages.Severity.INFO);         

        // add dummy user 3 to change his password
        User newU3;
        newU3 = me.clone(false);
        newU3.firstName = 'Test300';
        newU3.lastName = 'User';
        newU3.Alias = 'Test300';
        newU3.Username = 'Tester300@sfdev.com';
        newU3.CommunityNickname = 'Tester300';
        insert newU3;
                
        myPageCon.resetPwd3();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(2).getDetail().substring(0,10),'Password 3');
        System.assert(ApexPages.getMessages().get(2).getSeverity() == ApexPages.Severity.INFO);         

        myPageCon.orgBad = true;    // test as if trying to run on production
        myPageCon.resetPwd1();
        System.assertEquals(true,ApexPages.hasMessages());
        System.assertEquals(ApexPages.getMessages().get(3).getDetail(),'Reset DENIED!');
        System.assert(ApexPages.getMessages().get(3).getSeverity() == ApexPages.Severity.ERROR);        

    }

    
    private static boolean productionOrg() {
        String orgId = UserInfo.getOrganizationId();    
        String shortorgId = orgId.substring(0,15);  
        If (orgId.equals('00D300000006M6H'))  // real Paychex production org
            { return true;}
        else
            { return false; }
               
    }
     */
}