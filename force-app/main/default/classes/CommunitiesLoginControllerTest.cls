/**
 * An apex page controller that exposes the site login functionality
 */
@IsTest global with sharing class CommunitiesLoginControllerTest {
    @IsTest//(SeeAllData=true) 
    global static void testCommunitiesLoginController () {
     	CommunitiesLoginController CLC = new CommunitiesLoginController();
     	System.assertEquals(null, CLC.forwardToAuthPage()); 

        
        CLC.forwardToAuthPage();
        CLC.Login();
        system.debug('jc message size ' +apexpages.getmessages().size());
		system.assertequals(1,apexpages.getmessages().size()) ; 	
        
        CLC.username = 'test@user.com';
        CLC.Login();
        system.debug('jc message size 2 ' +apexpages.getmessages().size());
		system.assertequals(2,apexpages.getmessages().size()) ; 
        
        CLC.password = 'test123!'; 
        CLC.Login();
        
        user usr = [select id, username from user where isactive = true and profile.name like '%Community%' limit 1];
        usr.Community_User_First_Login__c = null; 
        update usr; 
        
        CLC.username = usr.Username; 
        system.debug('JC usr' + usr);
        //CLC.rediredtToResetPage(); 
        
        CLC.forwardToCustomAuthPage(); 
    }    
}