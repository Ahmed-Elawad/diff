/*  
 * Requirements: https://wiki.paychex.com/display/CP/APR0108928+-+CPA+Contact+Me+Form+Automation
 * 
 * The CPA/accountant channel is requesting to automate the process for the “contact me” form 
 * on https://www.paychex.com/accounting-professionals. This will provide a consistent, 
 * increased speed of sales representative awareness, as well as a formal, trackable path of activity, 
 * potential referral, and potential sale.
 * 
 * Related Class: AccountantReferralPartnerEmailHandler
 * 
 * History
 * --------
 * 01/29/2021   Manmeet Vaseer  Created.
   12/21/2022 Dan Carmen        Clean up code, use SF Duplicate Management.
   03/10/2023   Pujitha Madamanchi  Drupal Form for Payoll Acquisition
 
 */
public class AccountantReferralPartnerHelper {

    // Account Info
    //String companyName;
    //String zipCode;
    
    // Contact Info
    //String firstName;
    //String lastName;
    //String email;
    //String phone;
    
    String comments;
    String formUrl;    
  List<String> products;
    
    PartnerReferral__c partnerRef;    
    Campaign camp;
    
    public AccountantReferralPartnerHelper(AccountantReferralPartnerEmailHandler.ContactMePayload pl, PartnerReferral__c partRef)  {
        this.partnerRef = partRef;
        //this.companyName = pl.companyName;
        //this.zipCode = pl.zipCode;
        //this.firstName = pl.firstName;
        //this.lastName = pl.lastName;
        //this.email = pl.email;
        //this.phone = pl.phone;
        this.comments = pl.comments;
        this.formUrl = pl.formUrl;
        this.products = pl.productsOfInterest;
    } // AccountantReferralPartnerHelper
        
    public boolean processReferrals()  {
        Referral_Contact__c rc = getReferralContact();
        if(rc != null)  {
            if (rc.Contact__c != null) {
              partnerRef.Contact__c = rc.Contact__c;
              partnerRef.Account__c = rc.Contact__r.AccountId;           
            }
            StringHelper.addToProcessNotes(partnerRef,'Account/Contact Referral created successfully.');
            boolean success = assignCampaignToReferralContact(rc);
            if(success) success = postToReferralChatter(rc);
            return success;
        }
        
        StringHelper.addToProcessNotes(partnerRef,'Unable to create (or find existing) Referral_Contact__c.');
        return false;
    } // processReferrals
    
    Boolean postToReferralChatter(Referral_Contact__c rc)  {
    Id mainOwner = rc.OwnerId;
        Id managerId = [SELECT Id, ManagerId FROM User WHERE ID=:mainOwner].ManagerId;
        StringHelper.addToProcessNotes(partnerRef,'Chatter Posting to ownerId: ' + mainOwner + ', and managerId: ' + managerId);
        
        if(mainOwner != null)  {
            String campaignName = '';
            if(camp != null) campaignName = camp.Name;
            List<String> postText = new List<String>{
                '\nThis Accountant completed a form on paychex.com and requested information. The Accountant record has been assigned to you for timely follow-up:\n',
                    '\nCampaign Name: ' + campaignName,
                    '\nCompany Name: ' + partnerRef.Company__c,
                    '\nFirst Name: ' + partnerRef.FirstName__c,
                    '\nLast Name: ' + partnerRef.LastName__c,
                    '\nEmail: ' + partnerRef.Email__c,
                    '\nPhone: ' + partnerRef.Phone__c,
                    '\nZip Code: ' + partnerRef.ZipPostalCode__c,
                    '\nProducts: ' + products,
                    '\nComments: ' + comments,
                    '\nForm URL: ' + formUrl
                    };
                        
            List<id> userToMentionIdList = new List<Id>{mainOwner};
            if(managerId != null) userToMentionIdList.add(managerId);
            ChatterMentionPost.createChatterMentionPost(rc.Id, userToMentionIdList, postText, true);  
            StringHelper.addToProcessNotes(partnerRef,'Posted to Chatter successfully for Owner: ' + mainOwner);
            
            return true;
        }

        StringHelper.addToProcessNotes(partnerRef,'Unable to post to Chatter due to invalid Owner Id.');        
        return false;
    } // postToReferralChatter
    
    boolean assignCampaignToReferralContact(Referral_Contact__c rc)  {
        try {
            camp = [SELECT Id, Name FROM Campaign WHERE Form_URL__c=:formUrl AND IsActive=true ORDER BY LastModifiedDate Desc LIMIT 1];
            rc.LatestCampaign__c = camp.Id;
            if (rc.Contact__c != null) {
                rc.Contact__r.LatestCampaign__c = camp.Id;
                update rc.Contact__r;
                
                CampaignMember cm = new CampaignMember(CampaignId=camp.Id, ContactId=rc.Contact__r.Id, Status='Responded'); 
                insert cm;
            }
            update rc;
            
            StringHelper.addToProcessNotes(partnerRef,'Assigned Campaign Id ' + camp.Id + ' to Referral Contact successfully.');
            return true;
        }     

        catch(QueryException e)  {
            partnerRef.Comments__c = 'No Campaign found for Form URL: ' + formUrl + ', Error: ' + e + ', Stack Trace: ' + e.getStackTraceString();
        }
        
        StringHelper.addToProcessNotes(partnerRef,'Error: Campaign not assigned to the Referral Contact.');
        return false;
    } // assignCampaignToReferralContact
    
    /*
     * Get the Existing Referral Account & Referral Contact.
     * Otherwise, create new Referral Account and/or Referral Contact.
     */
    Referral_Contact__c getReferralContact()  {
        Referral_Contact__c rc = null;
        Referral_Account__c ra = getReferralAccount();
        if(ra != null) {
            //RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Referral_Contact__c' AND DeveloperName = 'CoreReferralRecordType'];
            Set<Id> rContactIds = dupeBlockerRContactCheck(partnerRef.FirstName__c, partnerRef.LastName__c, partnerRef.Email__c, ra.Id);
            if(!rContactIds.isEmpty())  {
                List<Referral_Contact__c> rcs = [SELECT Id, RecordTypeId, OwnerId, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Product_of_Interest__c, LatestCampaign__c
                                                       , Referral_Account__c, Contact__c, Contact__r.Id, Contact__r.LatestCampaign__c, Contact__r.AccountId
                                                      FROM Referral_Contact__c WHERE Id IN :rContactIds];
                StringHelper.addToProcessNotes(partnerRef,'getReferralContact rcs='+rcs.size()+' match rc='+(!rcs.isEmpty() ? rcs[0].Id : 'Not Found'));
                if(rcs.size() > 0)  {
                    rc = rcs.get(0);
                    rc.Product_of_Interest__c=getProductsOfInterest();
                    update rc;
                    return rc;
                }
            } // if(!rContactIds.isEmpty
            
            rc =  createNewReferralContact(ra);
            rc = [SELECT Id, OwnerId, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Product_of_Interest__c, LatestCampaign__c
                       , Referral_Account__c, Contact__c, Contact__r.Id, Contact__r.LatestCampaign__c, Contact__r.AccountId
                  FROM Referral_Contact__c WHERE Id = :rc.Id];
            return rc;
        } // if(ra != null
        
        StringHelper.addToProcessNotes(partnerRef,'Unable to create (or find existing) Referral_Account__c.');
        return rc;
    } // getReferralContact
    
    /*
     * Get the Existing Referral Account.
     * If not found, create a new Referral Account.
     */
    Referral_Account__c getReferralAccount()  {
        Referral_Account__c ra = new Referral_Account__c();
        
        Set<Id> rAcctIds = dupeBlockerRAccountCheck(partnerRef.Company__c, partnerRef.ZipPostalCode__c);
        if(!rAcctIds.isEmpty())  {
            List<Referral_Account__c> ras = [SELECT Id, OwnerId, Zip_Postal_Code__c, Account__c, RecordTypeId, Referral_Source_Business_Type__c FROM Referral_Account__c WHERE Id IN :rAcctIds];
            if(ras.size() > 0)  {
                ra = ras.get(0);
                StringHelper.addToProcessNotes(partnerRef,'Existing Referral Account Found: ' + ra.Id);
                return ra;
            }
        }

        ra = createNewReferralAccount();
        System.debug('ra:'+ra);
        if(ra!=null){
           ra = [SELECT Id, Name, OwnerId, Zip_Postal_Code__c, Phone__c, Account__c, RecordTypeId, Referral_Source_Business_Type__c FROM Referral_Account__c WHERE Id = :ra.Id];
        }
        return ra;
    } // getReferralAccount
    
    Referral_Account__c createNewReferralAccount()  {
        Referral_Account__c newRA = null;
        try{
            camp = [SELECT Id, Name, Referral_Source_Business_Type__c, Hold_Out_Reason__c, Referral_Account_Owner__c FROM Campaign WHERE Form_URL__c=:formUrl AND IsActive=true ORDER BY LastModifiedDate Desc LIMIT 1];
            Map<String,Schema.RecordTypeInfo> byNameMap = Referral_Account__c.SObjectType.getDescribe().getRecordTypeInfosByName();
            Schema.RecordTypeInfo rtInfo = byNameMap.get(RecordTypeHelper.CORE_REFERRAL_ACCOUNT);
            if(rtInfo != null)  {
                newRA = new Referral_Account__c();
                newRA.RecordTypeId=rtInfo.getRecordTypeId();
                newRA.Referral_Source_Business_Type__c = camp.Referral_Source_Business_Type__c!=null? camp.Referral_Source_Business_Type__c : null;
                if(camp.Hold_Out_Reason__c!=null){
                    newRA.Hold_Out_Reason__c = camp.Hold_Out_Reason__c;
                    newRA.Hold_Out__c = true;
                }
                
                if(camp.Referral_Account_Owner__c!=null){
                    newRA.OwnerId = camp.Referral_Account_Owner__c;
                }
                newRA.Name = partnerRef.Company__c;
                newRA.NameForDuplicateManagement__c=partnerRef.Company__c;
                newRA.Phone__c=partnerRef.Phone__c;
                newRA.Zip_Postal_Code__c = partnerRef.ZipPostalCode__c;
                newRA.Use_Zip_Assignment_Rules__c = true;
               /* newRA = new Referral_Account__c(Use_Zip_Assignment_Rules__c=true, RecordTypeId=rtInfo.getRecordTypeId(), Referral_Source_Business_Type__c='Accounting Firm'
                                                , Name=partnerRef.Company__c, NameForDuplicateManagement__c=partnerRef.Company__c, Phone__c=partnerRef.Phone__c
                                                ,Zip_Postal_Code__c=partnerRef.ZipPostalCode__c); */
                insert newRA;      
                StringHelper.addToProcessNotes(partnerRef,'New Referral Account Created: ' + newRA.Id);
            }
        }
        catch(QueryException e)  {
            partnerRef.Comments__c = 'No Campaign found for Form URL: ' + formUrl + ', Error: ' + e + ', Stack Trace: ' + e.getStackTraceString();
            StringHelper.addToProcessNotes(partnerRef,'No Campaign found for Form URL: ' + formUrl );
            System.debug('create new RefAcct : added to PR exception');
        }
        
        return newRA;
    } // createNewReferralAccount
    
    Referral_Contact__c createNewReferralContact(Referral_Account__c ra)  {
        Referral_Contact__c newRC = null;
        
        Map<String,Schema.RecordTypeInfo> byNameMap = Referral_Contact__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtInfo = byNameMap.get(RecordTypeHelper.CORE_REFERRAL_CONTACT);

        //RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Referral_Contact__c' AND DeveloperName = 'CoreReferralRecordType'];
        if(rtInfo != null)  {
      //ra = [SELECT Id, OwnerId, (SELECT Id FROM Accounts__r) FROM Referral_Account__c WHERE Id = :ra.Id];
            newRC = new Referral_Contact__c(RecordTypeId=rtInfo.getRecordTypeId(), OwnerId=ra.OwnerId, Referral_Account__c=ra.Id, Name=partnerRef.FirstName__c + ' ' + partnerRef.LastName__c,
                                           First_Name__c=partnerRef.FirstName__c, Last_Name__c=partnerRef.LastName__c, Phone__c=partnerRef.Phone__c, Email__c=partnerRef.Email__c,
                                           Product_of_Interest__c=getProductsOfInterest());
            insert newRC;
            StringHelper.addToProcessNotes(partnerRef,'New Referral Contact Created: ' + newRC.Id);
        }
        
        return newRC;
    } // createNewReferralContact
     
    String getProductsOfInterest()  {
        if (products != null && products.size() > 0) return String.join(products, ';');
        
        return '';
    }
    
    public Set<Id> dupeBlockerRAccountCheck(String accountName, String zipCode) {
        Set<Id> matchIds = new Set<Id>();
        Referral_Account__c ra = new Referral_Account__c(Name=accountName, NameForDuplicateManagement__c=accountName, Zip_Postal_Code__c=zipCode);
        DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new SObject[]{ra}); 
        DuplicateHelper.DupeResult result = results[0];
        if (result.hasResults && !result.refAcctIds.isEmpty()) {
           matchIds.addAll(result.refAcctIds);
        }
        return matchIds;
        /*
        Boolean isDupeBlockerSetup = Utilities.checkDupeBlocker('Referral_Account__c');
        
        if(isDupeBlockerSetup) {
            List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(ra);
            
            if(!matchSets.isEmpty()) {
                System.debug('matchSets.get(0).matchedIds: ' + matchSets.get(0).matchedIds);
                return matchSets.get(0).matchedIds;
            }
        }
        
        return null;
        */
    } // dupeBlockerRAccountCheck   
    
    public Set<Id> dupeBlockerRContactCheck(String firstName, String lastName, String yourEmail, Id rAccID) {
        Set<Id> matchIds = new Set<Id>();
        Referral_Contact__c rc = new Referral_Contact__c(First_Name__c=firstName, Last_Name__c=lastName, Email__c=yourEmail, Referral_Account__c=rAccID);
        DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new SObject[]{rc}); 
        DuplicateHelper.DupeResult result = results[0];
        if (result.hasResults && !result.refCtctIds.isEmpty()) {
           matchIds.addAll(result.refCtctIds);
        }
        return matchIds;
        /*
        Boolean isDupeBlockerSetup = Utilities.checkDupeBlocker('Referral_Contact__c');

        if(isDupeBlockerSetup) {
            Referral_Contact__c rc = new Referral_Contact__c(First_Name__c=firstName, Last_Name__c=lastName, Email__c=yourEmail, Referral_Account__c=rAccID);
            List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(rc);
            
            if(!matchSets.isEmpty()) {
                return matchSets.get(0).matchedIds;
            }
        }
        
        return null;
        */
    } // dupeBlockerRContactCheck
    
} // class AccountantReferralPartnerHelper