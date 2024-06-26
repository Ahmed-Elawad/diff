/** 
* Create an external community user. 
*
* History
* -------
* 06/08/2022    Varun              Created.
* 12/16/2022    Vinay              Added resendWelcomeEmail, addProspectPermissionSet,
                                   getProfileIdBasedOnName methods.
* 01/20/2023    Josh Cartwright    removing chatter posts - no need  
* 02/20/2023    Vinay              Added End_Date__c filed to SOQL query in getReferralContactData method.
*/

public without sharing class ConvertContactToCPACommunityUser {
    
    @AuraEnabled(cacheable=true)
    public static Referral_Contact__c getReferralContactData(String refContactId) {
        return [SELECT Id, OwnerId , Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Contact__c, End_Date__c FROM Referral_Contact__c Where Id=: refContactId];
    }

    @AuraEnabled
    public static void resendWelcomeEmail(Id contactId) {
        System.debug('In resend Welcome Email');
        User communityUser = [SELECT Id,ContactId,Community_User_First_Login__c,ProfileName__c FROM User WHERE ContactId =:contactId AND IsActive=true];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='CPA_Getting_Started_Prospect' LIMIT 1];

        PermissionSetAssignment[] psaToInsert = new PermissionSetAssignment[]{};
        PermissionSetAssignment[] psaToDelete = new PermissionSetAssignment[]{};
        
        if(communityUser!=null){
           //get existing permission set assignments
            PermissionSetAssignment[] existingPSAs = [SELECT Id,AssigneeId,PermissionSetId FROM PermissionSetAssignment 
                                                       WHERE PermissionSetId =:ps.Id AND AssigneeId =:communityUser.Id];
            if(communityUser.Community_User_First_Login__c == null && communityUser.ProfileName__c == 'CPA Customer Community Login User Clone') {
                if(existingPSAs!=null && !existingPSAs.isEmpty()){
                    for(PermissionSetAssignment psa:existingPSAs){
                        psaToDelete.add(psa);
                    }
                }
                PermissionSetAssignment newPSA = new PermissionSetAssignment(PermissionSetId=ps.Id,AssigneeId=communityUser.Id);
                psaToInsert.add(newPSA);
                //delete existing assignments and insert new ones to retrigger welcome email
                if(!psaToDelete.isEmpty()) {
                    System.debug('In resend Welcome Email DML===>'+ psaToDelete);
                    DmlHelper.performDML2(psaToDelete, DmlHelper.DML_DELETE, 'ConvertContactToCPACommunityUser', 'resendWelcomeEmailNow', 'deleting existing PSA', true);
                }
                if(!psaToInsert.isEmpty()) {
                    DmlHelper.performDML2(psaToInsert, DmlHelper.DML_INSERT, 'ConvertContactToCPACommunityUser', 'resendWelcomeEmailNow', 'inserting new PSA', true);
                }
            }
        }
    }
    
    
    /**
* Queries the user object using a contact ID and returns a user record if a match is found
* @Params: {Id(The contact record id)} - Community User records have a lookup to the contact record that was used to create them
* @Return: {User record, null}
*/


    @AuraEnabled
    public static User verifyExistingUserForContact(Id conId) {
        System.debug('In verifyExistingUserForContact Method');
        User[] usrs = [SELECT Name,IsActive,ContactId,AccountId, Username, CommunityNickname, Alias,Email,LastLoginDate, Community_User_First_Login__c FROM User WHERE ContactId =: conId LIMIT 100];
        for (User u : usrs) {
            System.debug('In verifyExistingUserForContact Method User =====>' + u);
            if (conId == u.ContactId) {
                return u;
            }
        }
        return null;
    }
    
    
    /**
* Creates a community user record
* @Params {String(username), String(nickName), Id(contact record ID), String(user alias), String(community audiance)}
* @Return: {Id(new user record id on success, null on failure)}
*/
    @AuraEnabled
    public static String createCommunityUserNew(String uName, String nickName, Id conId, String alias,String email) {
        System.debug('Start user creation request');
        //Bharat Changes - Renamed usrId to retVal, changed returntype from Id to String, Added query and If-else block
        String returnValue;
        String newUserId;
        String accId = [SELECT AccountId FROM Contact WHERE Id=:conId LIMIT 1].AccountId;
        Profile prof = [SELECT Id FROM Profile where name='CPA Customer Community Login User Clone'];
        // create an instance of the class or is this call fine??
        Contact conRec = ConvertContactToCommunityUser.getContactForId(conId);
        DateTime inviteDate;
        //it would be better to pass this into the method.
        String runningUser = UserInfo.getName();
        inviteDate = system.now();
        
        User communityUsr = new User(
            UserName = uName,
            FirstName = conRec.FirstName,
            LastName = conRec.LastName,
            Alias = alias,
            email = email,//conRec.Email,
            ContactId = conId,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = nickName,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community',
            License_Type__c = 'Community',
            UserPermissionsKnowledgeUser = true,
            Community_User_Created_By__c = runningUser,
            Requested_Invite_Date__c = inviteDate
        );
        
        System.debug('New user profile: '+communityUsr);
        try {
            // insert communityUsr;
            // Database.DMLOptions dlo = new Database.DMLOptions();
            // dlo.EmailHeader.triggerUserEmail = true;
            Database.SaveResult sr =  Database.insert(communityUsr);
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    if(err.getStatusCode() == StatusCode.DUPLICATE_USERNAME){
                        returnValue = 'DUPLICATE_USERNAME';
                    } else {
                        returnValue = null;
                    }
                }
            } else {
                system.debug('User created: ' + sr.getId());
                newUserId = communityUsr.Id;
                assignProspectPermissionSet(newUserId);
                // CS Helper method checks the existing locations in CS for the account which the contact
                // is related to to ensure locations are stood up for the process. Good placement for already 
                // existing accounts to ensure all locations exist as needed in CS.
                //assignProspectPermissionSet(communityUsr.Id);
                //updateChecklistWithUser(accId,communityUsr.Id, inviteDate);
                // ClientSpaceHelper.checkLocationsForAccount(conRec.AccountId);
                returnValue = null;
            }
        } catch(DmlException ex) {
            system.debug('Error creating user' + ex);
            ErrorLog.logError('ConvertContactToCommunityUser', 'createCommunityUser', 'createCommunityUser Error', communityUsr.Id, ex, communityUsr, true);
            returnValue = ex.getMessage();
        } catch (Exception e) {
            ErrorLog.logError('ConvertContactToCommunityUser', 'createCommunityUser', 'General Process Error', communityUsr.Id, e, communityUsr, true);
            returnValue = e.getMessage();
        }
        return returnValue;
    }

    @future
    public static void assignProspectPermissionSet(Id commUserId) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='CPA_Getting_Started_Prospect' LIMIT 1];
        if(ps!=null && commUserId!=null){
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId=ps.id,AssigneeId=commuserId);
            insert psa;
        }
    }
    
    @AuraEnabled
    public static void saveRefCnt(Id referralCt, string cpaStatus, string email) {
        Partner_Portal_User_Details__c ppud = new Partner_Portal_User_Details__c();
        ppud.Referral_Contact__c = referralCt; 
        ppud.Request_Date__c = datetime.now();
        ppud.Event__c='Invited'; 
        system.debug('jc ppud' + ppud);
        insert ppud; 
        //Referral_Contact__c con =  new Referral_Contact__c(Id=referralCt, CPA_Program_Status__c=cpaStatus, Email__c=email);
        ReferralAccountMethods.SKIP_TRIGGERS = True;
       // update con; 
    
    }

    @AuraEnabled
    public static void updateUser(Id userId, string userName, string email, Boolean reactivateUser) {
        List<User> userListToUpdate = new List<User>();
        User u = [SELECT Id, Username, Email, Requested_Invite_Date__c, IsActive FROM User WHERE Id=: userId];
        u.Username = userName;
        u.Email = email;
        u.Requested_Invite_Date__c = System.now();
        if(reactivateUser == true) {
            u.IsActive = true;
        }
        userListToUpdate.add(u);
        if(!userListToUpdate.isEmpty()) {
            DmlHelper.performDML2(userListToUpdate, DmlHelper.DML_UPDATE, 'ConvertContactToCPACommunityUser', 'updateUser', 'updating existing User', true);
        }
    }
}