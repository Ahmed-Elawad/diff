public with sharing class ReferralContacts{
    final static string expired_label = Label.CPA_Expiry_days_after_invite;
    
    @AuraEnabled
    public static Boolean hasCustomPermission(){
        return FeatureManagement.checkPermission('Accountant_Program_Rep');
    }
    @AuraEnabled
    public static List<ReferralContactsData> fetchActiveReferralContacts(Id refAcId){
        List<ReferralContactsData> results = new List<ReferralContactsData>();
        Set<Id> conIds = new Set<Id>();
        Map<Id,User> conUserMap = new Map<Id,User>();
        
        List<Referral_Contact__c> refc = [Select id,Name,Email__c,Admin_CPA__c,Contact__c,CPA_Program_Status__c,Referral_Account__r.CPA_Program_Status__c, CPA_Program_status_formula__c from Referral_Contact__c where Referral_Account__c=:refAcId AND End_Date__c=null];
        System.debug('fetchActiveReferralContacts refc:'+refc);
        for(Referral_Contact__c ref:refc){
            if(ref.Contact__c!=null){
            	conIds.add(ref.Contact__c);    
            }
        }
        System.debug('fetchActiveReferralContacts ContactIds:'+conIds);
        //Prepare contactIds-with user map
        for(User usr:[Select id,IsActive,ContactId,Requested_Invite_Date__c from User where ContactId IN:conIds AND IsActive=true]){
            conuserMap.put(usr.ContactId,usr);
        }
        
        for(Referral_Contact__c ref:refc){
            User usr = conuserMap.get(ref.Contact__c);
            if(usr!=null && usr.isActive){
                DateTime invitedDate;
                DateTime invExpired;
                Integer addnalDays = Integer.valueOf(expired_label);
                
                invitedDate = usr.Requested_Invite_Date__c;
                invExpired = invitedDate.addDays(addnalDays);
                
                results.add(new ReferralContactsData(ref.Name,ref.Email__c,ref.Admin_CPA__c,ref.CPA_Program_Status__c,invitedDate,invExpired));
            }
        }
        return results;
    }
    
    @AuraEnabled
    public static List<RelatedReferralContactsData> relatedReferralContacts(Id refConId){
        List<RelatedReferralContactsData> results = new List<RelatedReferralContactsData>();
        Set<Id> conIds = new Set<Id>();
        Map<Id,User> conUserMap = new Map<Id,User>();
        
        Referral_Contact__c curRefCon = [Select id,Referral_Account__c from Referral_Contact__c where Id=:refConId];
        Id refAcId = curRefCon.Referral_Account__c;
        
        List<Referral_Contact__c> refc = [Select id,Name,MutualClients__c,Referral_Account__r.CPA_Program_Status__c,Referral_Account__r.MutualClients__c,Contact__c, CPA_Program_status_formula__c from Referral_Contact__c where Referral_Account__c=:refAcId AND End_Date__c=null AND id=:refConId];
        
        for(Referral_Contact__c ref:refc){
            if(ref.Contact__c!=null){
            	conIds.add(ref.Contact__c);    
            }
        }
        //Prepare contactIds-with user map
        for(User usr:[Select id,Name,UserName,ContactId,Requested_Invite_Date__c from User where ContactId IN:conIds]){
            conuserMap.put(usr.ContactId,usr);
        }
        
        for(Referral_Contact__c ref:refc){
            User usr = conuserMap.get(ref.Contact__c);
            if(usr!=null && ref.Id != refConId){
                results.add(new RelatedReferralContactsData(ref.Name,usr.UserName,ref.Referral_Account__r.CPA_Program_Status__c,ref.Referral_Account__r.MutualClients__c,ref.MutualClients__c));
            }
        }
        return results;
    }
    
    public static User fetchRefConUserInfo(Id refConId){
        List<Referral_Contact__c> refc = [Select id,Name,Email__c,Admin_CPA__c,Contact__c,Referral_Account__r.CPA_Program_Status__c, CPA_Program_status_formula__c from Referral_Contact__c where Id=:refConId AND Contact__c!=null];
        if(!refc.isEmpty()){
        	List<User> userLst = [Select id,ContactId,Requested_Invite_Date__c from User where ContactId =:refc[0].Contact__c];
            if(!userLst.isEmpty()){
                return userLst[0];    
            }   
        }
        return null;
    }
    
    public static Map<String,Object> fetchRefConUserData(Id refConId){
        List<Referral_Contact__c> refc = [Select id,Name,Email__c,Admin_CPA__c,Contact__c,Referral_Account__r.CPA_Program_Status__c, CPA_Program_status_formula__c from Referral_Contact__c where Id=:refConId AND Contact__c!=null];
        Map<String,Object> refConUserMap = new Map<String,Object>();
        if(!refc.isEmpty()){
        	List<User> userLst = [Select id,Name,Username,Requested_Invite_Date__c,LastLoginDate, Community_User_First_Login__c from User where ContactId =:refc[0].Contact__c];
            if(!userLst.isEmpty()){
                refConUserMap.put('isComUserFound',true);
                refConUserMap.put('user',userLst[0]);
                
                return refConUserMap;
            }   
        }
        refConUserMap.put('isComUserFound',false);
        return refConUserMap;
    }
    
    public static Partner_Portal_User_Details__c fetchPPUD (id refConId ) {
        /*Partner_Portal_User_Details__c pp = [select Event__c,Referral_Contact__c,Request_Date__c 
                                                from Partner_Portal_User_Details__c  
                                                where Referral_Contact__c =:refConId order by createdDate desc limit 1];*/
        List<Partner_Portal_User_Details__c> pp = [select Event__c,Referral_Contact__c,Request_Date__c 
										from Partner_Portal_User_Details__c  
										where Referral_Contact__c =:refConId order by createdDate desc];
        System.debug('fetchPPUD pp:'+pp);
        if(pp.size()>0){
            return pp[0];
        }
    	return null;
        //return pp;
    }
    
    public class ReferralContactsData{
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public Boolean adminCPA;
        @AuraEnabled public String status;
        @AuraEnabled public DateTime invitedDate;
        @AuraEnabled public DateTime invExpired;
        
        public ReferralContactsData(String name,String email,Boolean adminCPA,String status,DateTime invitedDate,DateTime invExpired){
            this.name = name;
            this.email = email;
            this.adminCPA = adminCPA;
            this.status = status;
            this.invitedDate = invitedDate;
            this.invExpired = invExpired;
        }
    }
    
    public class RelatedReferralContactsData{
        @AuraEnabled public String name;
        @AuraEnabled public String userName;
        @AuraEnabled public String programStatus;
        @AuraEnabled public Decimal raTotalMutClients;
        @AuraEnabled public Decimal rcTotalMutClients;
        
        public RelatedReferralContactsData(String name,String userName,String programStatus,Decimal raTotalMutClients,Decimal rcTotalMutClients){
            this.name = name;
            this.userName = userName;
            this.programStatus = programStatus;
            this.raTotalMutClients = raTotalMutClients;
            this.rcTotalMutClients = rcTotalMutClients;
        }
    }
}