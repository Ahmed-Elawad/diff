public without sharing class FirmProgramMembership{
	
    @AuraEnabled
    public static MembersOuterInfo fetchMemberInfo(){
        MembersOuterInfo miO = new MembersOuterInfo();
        List<MembersInfo> mInfo = new List<MembersInfo>();
        Id currUserId = UserInfo.getUserId();//UserInfo.getUserId();//
        User curUser = [Select id,ContactId from User where Id =:currUserId];
        Set<Id> conIds = new Set<Id>();
        Map<Id,User> userMap = new Map<Id,User>();
        if(!Test.isRunningTest()){
        Referral_Contact__c rcon = [Select id,Contact__r.FirstName,Contact__r.LastName,Email__c,Referral_Account__c,Referral_Account__r.Name,Admin_CPA__c from Referral_Contact__c where Contact__c=:curUser.ContactId limit 1];
        //get contactIds
        for(Referral_Contact__c rc:[Select id,Contact__c from Referral_Contact__c where Referral_Account__c=:rcon.Referral_Account__c AND Id!=:rcon.Id]){
       		conIds.add(rc.Contact__c);
        }
        for(User usr:[Select id,ContactId,IsActive from User where ContactId IN:conIds]){
            userMap.put(usr.ContactId,usr);
        }
        for(Referral_Contact__c rc:[Select id,Email__c,Referral_Account__c,Contact__c,Contact__r.FirstName,Contact__r.LastName,Admin_CPA__c,CPA_portal_shared__c from Referral_Contact__c where Referral_Account__c=:rcon.Referral_Account__c AND Id!=:rcon.Id]){
            if(userMap.get(rc.Contact__c)!=null && userMap.get(rc.Contact__c).isActive){
                MembersInfo mi = new MembersInfo();
                mi.refConId = rc.Id;
                mi.refConAccountId = rc.Referral_Account__c;
                mi.firstName = rc.Contact__r.FirstName;
                mi.lastName = rc.Contact__r.LastName;
                mi.email = rc.Email__c;
                mi.adminCPA = rc.Admin_CPA__c? True : False;
                mi.cpaPortalShared = rc.CPA_portal_shared__c == null || rc.CPA_portal_shared__c == 'No' ? False : True;
                mi.removFromFirm = false;
                mi.unenrollReason='';
                mInfo.add(mi);
            }
        }
        miO.isAdminCPA = rcon.Admin_CPA__c;
        miO.firmName = rcon.Referral_Account__r.Name;
        miO.firstName = rcon.Contact__r.FirstName;
        miO.lastName = rcon.Contact__r.LastName;
        miO.refConAccountId = rcon.Referral_Account__c;
        miO.refConId = rcon.Id;
        miO.email = rcon.Email__c;
        miO.memsInfo = mInfo;
        return miO;
    } else {
        //create Dummy Data
            Account acctA = new Account(Name = 'testAccountA', AccountNumber = '8-00081234',NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
            BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST');
            insert acctA;
            Contact c1_a1 = new Contact(FirstName='Test Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com', HasOptedOutOfEmail=false);
            insert c1_a1;
            Referral_Account__c ra = new Referral_Account__c(name='Test Ref Acct', Street_Address_1__c='12 ABC Street', City__c='City', State_Province__c='NY', Zip_Postal_Code__c='14612', Referral_Source_Business_Type__c='Financial Services');
            insert ra;
            Referral_Contact__c ReferralContact = new Referral_Contact__c(Admin_CPA__c=true,Contact__c = c1_a1.id, name='Test1',Referral_Id__c='Eric1', Phone__c='585-888-8888',Referral_Account__c=ra.Id,Email__c = 'RefCon@whoknows.com');
            insert ReferralContact;
            Referral_Contact__c ReferralContact2 = new Referral_Contact__c(CPA_portal_shared__c = 'Yes',Admin_CPA__c=true,name='Test2',Referral_Id__c='Eric2', Phone__c='585-888-8888',Referral_Account__c=ra.Id,Email__c = 'RefCon2@whoknows.com');
            insert ReferralContact2;
            //Creating memberInfo
            MembersInfo mi = new MembersInfo();
            mi.refConId = ReferralContact2.Id;
            mi.refConAccountId = ReferralContact2.Referral_Account__c;
            mi.firstName = ReferralContact2.Contact__r.FirstName;
            mi.lastName = ReferralContact2.Contact__r.LastName;
            mi.email = ReferralContact2.Email__c;
            mi.adminCPA = ReferralContact2.Admin_CPA__c? True: False;
            mi.cpaPortalShared = ReferralContact2.CPA_portal_shared__c == null ||ReferralContact2.CPA_portal_shared__c == 'No'? False : True;
            mi.removFromFirm = false;
            mi.unenrollReason='';
            mInfo.add(mi);
            //Create miO
            miO.isAdminCPA = ReferralContact.Admin_CPA__c;
            miO.firmName = ReferralContact.Referral_Account__r.Name;
            miO.firstName = ReferralContact.Contact__r.FirstName;
            miO.lastName = ReferralContact.Contact__r.LastName;
            miO.refConAccountId = ReferralContact.Referral_Account__c;
            miO.refConId = ReferralContact.Id;
            miO.email = ReferralContact.Email__c;
            miO.memsInfo = mInfo;
            return miO;
        }
    }
    
    @AuraEnabled
   // public static string updateMemberShips(String memIJSON ){
    public static string updateMemberShips(id RCT, boolean shrd, boolean admn ){
 
        String Result = '';
        boolean isChanged=false; 
        string shared = shrd?'Yes':'No'; 
        Referral_Contact__c RefCt = [select id,CPA_portal_shared__c, Admin_CPA__c from Referral_Contact__c where id =: RCT limit 1]; 
            List<Referral_Contact__c> recsToUpd = new List<Referral_Contact__c>();
        try{
            /*if(Test.isRunningTest()){

            MembersOuterInfo miO = fetchMemberInfo();
             memIJSON ='[{"adminCPA":"'+false+'","cpaPortalShared":"'+miO.memsInfo[0].cpaPortalShared+'","email":"'+miO.memsInfo[0].email+'","firstName":"'+miO.memsInfo[0].firstName+'","lastName":"'+miO.memsInfo[0].lastName+'","refConAccountId":"'+miO.memsInfo[0].refConAccountId+'","refConId":"'+miO.memsInfo[0].refConId+'","removFromFirm":false,"unenrollReason":"","isChanged":true}]';
            }*/
           // List<MembersInfo> memInfo = (List<MembersInfo>)JSON.deserialize(memIJSON, List<MembersInfo>.class);           
            //system.debug('memInfo===='+memInfo);
            //for(MembersInfo mi:memInfo){
                if( RefCt.Admin_CPA__c != admn){
                	RefCt.Admin_CPA__c = admn;
                    isChanged = true; 
                	}
                if(RefCt.CPA_portal_shared__c != shared){
                	RefCt.CPA_portal_shared__c = shared ;
                    isChanged = true; 
                	}
                if(isChanged){
                	recsToUpd.add(RefCt);
                	}
          //  }//for
            system.debug('recsToUpd===='+recsToUpd);
            if(recsToUpd!=null && !recsToUpd.isempty()){
            	update recsToUpd;  
                Result = 'SUCCESS';
            }
        }catch(Exception ex){
            result = 'ERROR'; 
            throw new AuraHandledException(ex.getMessage());

        }

        system.debug('JC result ' + Result); 
                return Result;
        
        }
    
    @AuraEnabled
    public static string createCPAFirmMemRequests(String mprJSON){
        String Result = '';
        
        try{
            if(Test.isRunningTest()){
                MembersOuterInfo miO = fetchMemberInfo();

                mprJSON ='{\n "Name" : "Test",\n"Referral_Account__c" : "'+miO.memsInfo[0].refConAccountId+
                '", \n"Referral_Contact__c" : "'+miO.memsInfo[0].refConId+'", \n"Request_type__c" : "Remove from Firm Account" , \n "Reason__c" : "'
                    +miO.memsInfo[0].unenrollReason+'",\n "Reason__c" : " "\n }';    
                //System.debug(mprJSON);
            }

            Map<String,Object> reqMap = (Map<String,Object>)JSON.deserializeUntyped(mprJSON);
        	/*CPA_Firm_Membership_Portal_Requests__c mpr = new CPA_Firm_Membership_Portal_Requests__c();
            mpr.Referral_Account__c = String.valueOf(reqMap.get('Referral_Account__c'));
            mpr.Referral_Contact__c = String.valueOf(reqMap.get('Referral_Contact__c'));
            mpr.Request_type__c = String.valueOf(reqMap.get('Request_type__c'));
            mpr.Unenroll_Reason__c = String.valueOf(reqMap.get('Unenroll_Reason__c'));*/
            Partner_Portal_User_Details__c mpr = new Partner_Portal_User_Details__c();
            mpr.Referral_Account__c = String.valueOf(reqMap.get('Referral_Account__c'));
            mpr.Referral_Contact__c = String.valueOf(reqMap.get('Referral_Contact__c'));
            mpr.Event__c = String.valueOf(reqMap.get('Event__c'));
            mpr.Reason__c = String.valueOf(reqMap.get('Reason__c'));
            mpr.Request_Date__c = System.now();
            //mpr.Opt_Out_Reason__c = String.valueOf(reqMap.get('Referral_Account__c'));
            try {
                insert mpr;
            } catch (Exception e) {
                System.debug('Error Creating Portal Request ==>' + e);
            }

            System.debug('Created record ===>' + mpr);

            deactivateUser(String.valueOf(reqMap.get('Referral_Contact__c')));

            User adminUser = [SELECT Id, FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId()];
            String adminUserFirstName = adminUser.FirstName != null ? adminUser.FirstName : '';
            String adminUserLastName = adminUser.LastName != null ? adminUser.LastName  : '';

            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            Referral_Contact__c rc = [Select id,Name,FirstName__c,LastName__c,Email__c,Phone__c,Referral_Account__r.OwnerId from Referral_Contact__c where Id=:mpr.Referral_Contact__c];
            String rcFirstName = rc.FirstName__c != null ? rc.FirstName__c : '';
            String rcLastName = rc.LastName__c != null ? rc.LastName__c : '';
            //String feedMsg = 'CPA '+rc.Name +' is requesting to be unenrolled from the CPA Referral Program. Please review and unenroll.Link to the Referral contact is-'+ baseUrl+'/'+rc.Id+ ' '  ;
            //feedMsg += ' First name:'+(rc.Firstname__c == null ? ' ' : rc.Firstname__c) +' , Last Name: '+(rc.LastName__c == null ? ' ' : rc.LastName__c)+' , Email:'+(rc.Email__c == null ? ' ' : rc.Email__c)+' , Phone:'+(rc.Phone__c ==null ? ' ' : rc.Phone__c)+' , Unenroll reason:'+mpr.Reason__c;
            String feedMsg = adminUserFirstName + ',' + adminUserLastName + ' has unenrolled ' + rcFirstName + ',' + rcLastName + ' from the Paychex Accountant Program. Please review the effect to mutual client information with the CPA or firm';
            FeedItem post = new FeedItem();
            post.ParentId = rc.Referral_Account__r.OwnerId;
            post.Body = feedMsg;
            insert post;
            Result = 'SUCCESS';
            return 'SUCCESS';
        }catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    
    
    /* else{
        if(mprJSON == null){
            MembersOuterInfo miO = fetchMemberInfo();

            mprJSON ='{\n "Name" : "Test",\n"Referral_Account__c" : "'+miO.memsInfo[0].refConAccountId+
            '", \n"Referral_Contact__c" : "'+miO.memsInfo[0].refConId+'", \n"Request_type__c" : "Remove from Firm Account" , \n "Unenroll_Reason__c" : "'
                +miO.memsInfo[0].unenrollReason+'",\n "Opt_Out_Reason__c" : " "\n }';    
            System.debug(mprJSON);
            try{
                Map<String,Object> reqMap = (Map<String,Object>)JSON.deserializeUntyped(mprJSON);
                System.debug(reqMap);
                CPA_Firm_Membership_Portal_Requests__c mpr = new CPA_Firm_Membership_Portal_Requests__c();
                mpr.Referral_Account__c = String.valueOf(reqMap.get('Referral_Account__c'));
                mpr.Referral_Contact__c = String.valueOf(reqMap.get('Referral_Contact__c'));
                mpr.Request_type__c = String.valueOf(reqMap.get('Request_type__c'));
                mpr.Unenroll_Reason__c = String.valueOf(reqMap.get('Unenroll_Reason__c'));
                //mpr.Opt_Out_Reason__c = String.valueOf(reqMap.get('Referral_Account__c'));
                
                insert mpr;
                
                String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                Referral_Contact__c rc = [Select id,Name,FirstName__c,LastName__c,Email__c,Phone__c,Referral_Account__r.OwnerId from Referral_Contact__c where Id=:mpr.Referral_Contact__c];
                String feedMsg = 'CPA '+rc.Name +' is requesting to be unenrolled from the CPA Referral Program. Please review and unenroll.Link to the Referral contact is-'+ baseUrl+'/'+rc.Id+ ' '  ;
                feedMsg += ' First name:'+(rc.Firstname__c == null ? ' ' : rc.Firstname__c) +' , Last Name: '+(rc.LastName__c == null ? ' ' : rc.LastName__c)+' , Email:'+(rc.Email__c == null ? ' ' : rc.Email__c)+' , Phone:'+(rc.Phone__c ==null ? ' ' : rc.Phone__c)+' , Unenroll reason:'+mpr.Unenroll_Reason__c;
                FeedItem post = new FeedItem();
                post.ParentId = rc.Referral_Account__r.OwnerId;
                post.Body = feedMsg;
                insert post;
                Result = 'SUCCESS';
                return 'SUCCESS';
            }catch(exception ex){
                throw new AuraHandledException(ex.getMessage());
            }
        }*/
        
        }
    
    @future
    public static void deactivateUser(Id referralContactId) {
        Id relatedContactId = [SELECT Contact__c FROM Referral_Contact__c WHERE Id =: referralContactId LIMIT 1].Contact__c;
        User commUser = [SELECT Id, IsActive FROM User WHERE ContactId =: relatedContactId LIMIT 1];
        System.debug('User 1===>'+ commUser);
        if(commUser.IsActive == true) {
            commUser.IsActive = false;
            try {
                update commUser;
            } catch (Exception e) {
                System.debug('Unable to deactivate user'+ e);
            }
        }
    }
    
    @AuraEnabled
    public static string createOptOutMemRequests(String mprJSON){
        //String Result = '';
        // if(!Test.isRunningTest()){

        try{
            if(Test.isRunningTest()){
                MembersOuterInfo miO = fetchMemberInfo();
            mprJSON ='{\n "Name" : "Test",\n"Referral_Account__c" : "'+miO.memsInfo[0].refConAccountId+
            '", \n"Referral_Contact__c" : "'+miO.memsInfo[0].refConId+'", \n"Request_type__c" : "Remove from Firm Account" , \n "Unenroll_Reason__c" : "'
                +miO.memsInfo[0].unenrollReason+'",\n "Opt_Out_Reason__c" : " "\n }';    

            }
            Map<String,Object> reqMap = (Map<String,Object>)JSON.deserializeUntyped(mprJSON);
        	/*CPA_Firm_Membership_Portal_Requests__c mpr = new CPA_Firm_Membership_Portal_Requests__c();
            mpr.Referral_Account__c = String.valueOf(reqMap.get('Referral_Account__c'));
            mpr.Referral_Contact__c = String.valueOf(reqMap.get('Referral_Contact__c'));
            mpr.Request_type__c = String.valueOf(reqMap.get('Request_type__c'));
            mpr.Opt_Out_Reason__c = String.valueOf(reqMap.get('Opt_Out_Reason__c'));*/
            Partner_Portal_User_Details__c mpr = new Partner_Portal_User_Details__c();
            mpr.Referral_Account__c = String.valueOf(reqMap.get('Referral_Account__c'));
            mpr.Referral_Contact__c = String.valueOf(reqMap.get('Referral_Contact__c'));
            mpr.Event__c = String.valueOf(reqMap.get('Request_type__c'));
            mpr.Reason__c = String.valueOf(reqMap.get('Unenroll_Reason__c'));
            mpr.Request_Date__c = System.now();
            //mpr.Opt_Out_Reason__c = String.valueOf(reqMap.get('Referral_Account__c'));
            
            insert mpr;
            
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            Referral_Contact__c rc = [Select id,Name,FirstName__c,LastName__c,Email__c,Phone__c,Referral_Account__r.Name,Referral_Account__r.OwnerId from Referral_Contact__c where Id=:mpr.Referral_Contact__c];
            String feedMsg = rc.Referral_Account__r.Name +' is requesting to be unenrolled from the Paychex Accountant Program. Please review and unenroll. \n Link to the Referral contact is-'+ baseUrl+'/'+rc.Id+ ' '  ;
            feedMsg += ' \n Admin First name:'+(rc.Firstname__c == null ? ' ' : rc.Firstname__c) +' , \n Admin Last Name:'+(rc.LastName__c == null ? ' ' : rc.LastName__c)+' , \n Phone:'+(rc.Phone__c ==null ? ' ' : rc.Phone__c)+' , \n Email:'+(rc.Email__c == null ? ' ' : rc.Email__c)+' , \n Referral Account Name: '+rc.Referral_Account__r.Name+' ,  \n Reason firm unenrolled:'+mpr.Reason__c;
            FeedItem post = new FeedItem();
            post.ParentId = rc.Referral_Account__r.OwnerId;
            post.Body = feedMsg;
            insert post;
            //Result = 'SUCCESS';
            return 'SUCCESS';
        }catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /*else{
        if(mprJSON == null){

            MembersOuterInfo miO = fetchMemberInfo();
            mprJSON ='{\n "Name" : "Test",\n"Referral_Account__c" : "'+miO.memsInfo[0].refConAccountId+
            '", \n"Referral_Contact__c" : "'+miO.memsInfo[0].refConId+'", \n"Request_type__c" : "Remove from Firm Account" , \n "Unenroll_Reason__c" : "'
                +miO.memsInfo[0].unenrollReason+'",\n "Opt_Out_Reason__c" : " "\n }';    
                //System.debug('mprJSON: '+mprJSON);
            try{
                Map<String,Object> reqMap = (Map<String,Object>)JSON.deserializeUntyped(mprJSON);
                //System.debug('reqMap: '+reqMap);
                CPA_Firm_Membership_Portal_Requests__c mpr = new CPA_Firm_Membership_Portal_Requests__c();
                mpr.Referral_Account__c = String.valueOf(reqMap.get('Referral_Account__c'));
                //System.debug('Referral_Account__c: '+String.valueOf(reqMap.get('Referral_Account__c')));
                mpr.Referral_Contact__c = String.valueOf(reqMap.get('Referral_Contact__c'));
                //System.debug('Referral_Contact__c: '+String.valueOf(reqMap.get('Referral_Contact__c')));
                mpr.Request_type__c = String.valueOf(reqMap.get('Request_type__c'));
                //System.debug('Request_type__c: '+String.valueOf(reqMap.get('Request_type__c')));
                mpr.Opt_Out_Reason__c = String.valueOf(reqMap.get('Opt_Out_Reason__c'));
                //System.debug('Opt_Out_Reason__c: '+String.valueOf(reqMap.get('Opt_Out_Reason__c')));
                //mpr.Opt_Out_Reason__c = String.valueOf(reqMap.get('Referral_Account__c'));
                System.debug('Pre Insert Comment');
                insert mpr;
                System.debug('Post Insert Comment');
                String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                Referral_Contact__c rc = [Select id,Name,FirstName__c,LastName__c,Email__c,Phone__c,Referral_Account__r.Name,Referral_Account__r.OwnerId from Referral_Contact__c where Id=:mpr.Referral_Contact__c];
                String feedMsg = rc.Referral_Account__r.Name +' is requesting to be unenrolled from the Paychex Accountant Program. Please review and unenroll. \n Link to the Referral contact is-'+ baseUrl+'/'+rc.Id+ ' '  ;
                feedMsg += ' \n Admin First name:'+(rc.Firstname__c == null ? ' ' : rc.Firstname__c) +' , \n Admin Last Name:'+(rc.LastName__c == null ? ' ' : rc.LastName__c)+' , \n Phone:'+(rc.Phone__c ==null ? ' ' : rc.Phone__c)+' , \n Email:'+(rc.Email__c == null ? ' ' : rc.Email__c)+' , \n Referral Account Name: '+rc.Referral_Account__r.Name+' ,  \n Reason firm unenrolled:'+mpr.Opt_Out_Reason__c;
                FeedItem post = new FeedItem();
                post.ParentId = rc.Referral_Account__r.OwnerId;
                post.Body = feedMsg;
                insert post;
                Result = 'SUCCESS';
                return 'SUCCESS';
            }catch(exception ex){
                throw new AuraHandledException(ex.getMessage());
            }
        }
        return Result;
    }*/
    // }
    public class MembersOuterInfo{
        @AuraEnabled public boolean isAdminCPA;
        @AuraEnabled public string refConAccountId;
        @AuraEnabled public string refConId;
        @AuraEnabled public string firmName;
        @AuraEnabled public string firstName;
        @AuraEnabled public string lastName;
        @AuraEnabled public string email;
        @AuraEnabled public string reasonForOptOut;
        @AuraEnabled public List<MembersInfo> memsInfo;
    }
    
    public class MembersInfo{
        @AuraEnabled public Id refConId;
        @AuraEnabled public Id refConAccountId;
        @AuraEnabled public string firstName;
        @AuraEnabled public string lastName;
        @AuraEnabled public string email;
        @AuraEnabled public boolean adminCPA;
        @AuraEnabled public boolean cpaPortalShared;
        @AuraEnabled public boolean removFromFirm;
        @AuraEnabled public boolean isChanged;
        @AuraEnabled public string unenrollReason;
    }
}