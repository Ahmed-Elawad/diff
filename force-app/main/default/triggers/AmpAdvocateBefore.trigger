/*
* Before Trigger for Advocates
* 
* 04/29/2020    Matt Fritschi   Created
* 
*
*  
*/

trigger AmpAdvocateBefore on amp_dev__Amp_Advocate__c (before insert, before update) {
    
    /*List<amp_dev__Amp_Advocate__c> changeAmpOwnership = new List<amp_dev__Amp_Advocate__c>();
    List<amp_dev__Amp_Advocate__c> possibleHRSHoldOutAmp = new List<amp_dev__Amp_Advocate__c>();
    List<Id> usersToCheck = new List<Id>();
    List<Id> checkHRSHoldOut = new List<Id>();
    List<Id> profileIds = new List<Id>();
    List<Id> possibleHRSProfileIds = new List<Id>();
    List<Id> checkAccounts = new List<Id>();
    List<Account> updateAccounts = new List<Account>();
    List<amp_dev__Amp_Advocate__c> changeToAccountOwner = new List<amp_dev__Amp_Advocate__c>();
    
    System.debug('AmpAdvocateBefore Trigger');
    
    for (amp_dev__Amp_Advocate__c newA : Trigger.new) 
    {
        amp_dev__Amp_Advocate__c oldA = (Trigger.isUpdate ? Trigger.oldMap.get(newA.id) : null);
        
        if(newA != null && oldA == null)
        {
            //Sets the Owner used for reporting.
            if(newA.Owner_For_Reporting__c == null && newA.OwnerId != null)
            {
                newA.Owner_For_Reporting__c = newA.OwnerId;
            }
            
            //If the new Advocate record was invited by P&C, 401k or HRS, give that User ownership
            if(newA.amp_dev__Status__c != null && (newA.amp_dev__Status__c == 'invited' || newA.amp_dev__Status__c == 'Invited'))
            {
                System.debug(newA);
                changeAmpOwnership.add(newA);
                //if(newA.CreatedById != null && !usersToCheck.contains(newA.CreatedById))
                //{
                //usersToCheck.add(newA.CreatedById);
                usersToCheck.add(newA.OwnerId);
                //}
            }
        }
        else if(newA != null && oldA != null)
        {
            if(newA.amp_dev__Status__c != null && oldA.amp_dev__Status__c != null && newA.amp_dev__Status__c != oldA.amp_dev__Status__c && newA.amp_dev__Status__c == 'Active')
            {
                checkHRSHoldOut.add(newA.OwnerId);
                possibleHRSHoldOutAmp.add(newA);
                System.debug('MF:  HRS Hold Out being set.');
            }
            else if(newA.Change_Owner_Date__c == null && oldA.Change_Owner_Date__c != null && oldA.Change_Owner_Date__c == System.Date.today() && newA.amp_dev__Status__c == 'Active')
            {
                changeToAccountOwner.add(newA);
            }
            
            if(newA.OwnerId != oldA.OwnerId)
            {
                System.debug('Changing the Reporting Owner from '+oldA.OwnerId+' to '+newA.OwnerId);
                newA.Owner_For_Reporting__c = newA.OwnerId;
            }
            
        }
    } // for newA
    
    if(!changeAmpOwnership.isEmpty())
    {
        setAdvChangeOwnerDate();
    }
    
    if(!checkHRSHoldOut.isEmpty())
    {
        setHRSHoldOutOnAccount();
    }
    
    if(!changeToAccountOwner.isEmpty())
    {
        changeOwnerToAccountOwner();
    }
    
    
    public static void setAdvChangeOwnerDate()
    {
        if(usersToCheck.size()>0)
        {
            //Gets all Users for the Ownership Change
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, ProfileId, Sales_Division__c FROM User WHERE Id IN :usersToCheck]);
            
            for(User u : userMap.values())
            {
                if(!profileIds.contains(u.ProfileId))
                {
                    profileIds.Add(u.ProfileId);
                }
            }
            
            //Gets the Profiles of the Users to check if Ownership change needs to happen
            Map<Id, Profile> profileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Id IN :profileIds]);
            
            
            //Check User Profile/Division and Change Ownership if necessary
            for(amp_dev__Amp_Advocate__c ampAdv : changeAmpOwnership)
            {
                //User ampUser = userMap.get(ampAdv.CreatedById);
                User ampUser = userMap.get(ampAdv.OwnerId);
                if(ampUser != null && ampUser.ProfileId != null)
                {
                    Profile ampUserProfile = profileMap.get(ampUser.ProfileId);
                    if((ampUserProfile != null && ampUserProfile.Name != null && (ampUserProfile.Name == 'PC Sales Rep - SB' 
                                                                                  || ampUserProfile.Name == 'PC Sales Manager - SB' 
                                                                                  || ampUserProfile.Name == 'PC Sales Administration - SB'
                                                                                  || ampUserProfile.Name == 'HRS 401(k) Sales - SB'
                                                                                  || ampUserProfile.Name == 'HRS Sales Manager - SB'
                                                                                  || ampUserProfile.Name == 'HRS Sales Administration - SB'
                                                                                  || ampUserProfile.Name == 'HRS Regional Sales Admin - SB')))
                    {
                        ampAdv.Change_Owner_Date__c = Date.today() + 365;
                        //ampAdv.OwnerId = ampUser.Id;
                    }
                } 
            }
        }
    }
    
    
    public static void setHRSHoldOutOnAccount()
    {
        if(checkHRSHoldOut.size() > 0)
        {
            Map<Id, User> HRSUserMap = new Map<Id, User>([SELECT Id, Name, ProfileId, Sales_Division__c FROM User WHERE Id IN :checkHRSHoldOut]);
            
            for(User u : HRSUserMap.values())
            {
                if(!possibleHRSProfileIds.contains(u.ProfileId))
                {
                    System.debug('MF:  Found User.');
                    possibleHRSProfileIds.Add(u.ProfileId);
                }
            }
            
            Map<Id, Profile> checkHRSProfileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile WHERE Id IN :possibleHRSProfileIds]);
            System.debug('checkHRSProfileMap.size() = '+checkHRSProfileMap.size());
            for(amp_dev__Amp_Advocate__c ampAdv : possibleHRSHoldOutAmp)
            {
                System.debug('MF: Checking each advocate');
                User ampUser = HRSUserMap.get(ampAdv.OwnerId);
                System.debug('ampUser='+ampUser);
                if(ampUser != null && ampUser.ProfileId != null)
                {
                    System.debug('MF: Found ampUser');
                    Profile ampUserProfile = checkHRSProfileMap.get(ampUser.ProfileId);
                    if((ampAdv.Account__c != null && ampUserProfile != null && ampUserProfile.Name != null && (ampUserProfile.Name == 'HRS 401(k) Sales - SB'
                                                                                                               || ampUserProfile.Name == 'HRS Sales Manager - SB'
                                                                                                               || ampUserProfile.Name == 'HRS Sales Administration - SB'
                                                                                                               || ampUserProfile.Name == 'HRS Regional Sales Admin - SB')))
                    {
                        System.debug('MF:  Account to be updated found.');
                        checkAccounts.add(ampAdv.Account__c);
                    }
                } 
            }
            
            updateAccounts = [SELECT Id, Name, HRS_Hold_Out__c, HRS_Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c FROM Account WHERE Id IN :checkAccounts AND HRS_Hold_Out__c = false];
            
            if(updateAccounts.size() > 0)
            {
                for(Account acct : updateAccounts)
                {
                    acct.HRS_Hold_Out__c = true;
                    acct.HRS_Hold_Out_Expiration__c = Date.today() + 365;
                    acct.Permanent_Hold_Out_Description__c = 'Referral Network Advocate';
                    System.debug('MF:  Account Updated.');
                }
                
                update updateAccounts;
            }
        }
    }
    
    public static void changeOwnerToAccountOwner()
    {
        List<Id> accountsToQuery = new List<Id>();
        for(amp_dev__Amp_Advocate__c adv : changeToAccountOwner)
        {
            accountsToQuery.add(adv.Account__c);
        }
        
        Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, OwnerId FROM Account WHERE Id IN :accountsToQuery]);
        
        for(amp_dev__Amp_Advocate__c adv : changeToAccountOwner)
        {
            Account acct = acctMap.get(adv.Account__c);
            if(acct != null && adv.OwnerId != null && acct.OwnerId != null && adv.OwnerId != acct.OwnerId)
            {
                adv.OwnerId = acct.OwnerId;
                adv.Owner_For_Reporting__c = adv.OwnerId;
            }
        }
    } */
    
    
} // trigger AmpAdvocateBefore