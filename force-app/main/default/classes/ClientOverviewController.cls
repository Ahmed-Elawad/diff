/*
Controller for Client Overview

 07/01/2012 John Callan and Justin Stouffer Created  
 0/30/2012  Justin Stouffer                 Revised
 07/06/2016 Josh Cartwright updated to include variables to show different sections 
 07/06/2020  Jacob Hinds         Added without sharing per PMD
*/
public without sharing class ClientOverviewController {

    private account currentAccount;
    public ApexPages.StandardController accountController {get; set;}
    public string atRisk {get; set;}
    public string potentialRisk {get; set;}
    public string BUPrimaryClient {get; set;}
    public string DNCEIndicator {get; set;}
    public boolean showKeyInformation {get;set;} // JC 
    public boolean isClientRecord  {get;set;}  // JC 
    public list<case> clientActionNeeded {get; set;}
    public Boolean isIE {get; set;}
    /* Is this displaying in Salesforce1? */
    public Boolean isSF1 {get; set;}
    public Boolean isMobile {get; set;}
    
   public string userProfile; 
   
   public ClientOverviewController(id acctId) {
      initialize(acctId);
    }
            
    public ClientOverviewController(ApexPages.StandardController controller) {
      this.accountController = controller;
      initialize(ApexPages.currentPage().getParameters().get('id'));
    }
    
    private void initialize(id id){
        if(!test.isRunningTest()){
            verifyBrowser();
        }
          
          isSF1 = (UserInfo.getUiThemeDisplayed()=='Theme4t'||UserInfo.getUiThemeDisplayed()=='Theme4d'); //Utilities.isSF1();
          isMobile = (UserInfo.getUiThemeDisplayed()=='Theme4t');
          if(id != NULL){
              List<Account> currentAccounts = [select At_Risk__c, Potential_Risk__c, Primary_Client_Combined__c, CurrentClient__c,
                                                      Do_Not_Call__c,Email_Opt_Out__c, Is_Referral_Source__c, (Select Id, CaseNumber From Cases where 
                                                      Priority = 'Critical' and (Status = 'Waiting on Customer' or Status = 'Waiting on Client'))
                                                      from Account where id = :id];
              if(currentAccounts.size() != 0){
                currentAccount = currentAccounts.get(0);                  
                    clientActionNeeded = currentAccount.Cases;
                    setatRisk();
                    setPotentialRisk();
                    setBUPrimaryClient();
                    setDNCEIndicator();
                    getRunningUser(); 
                    setAttributes(); 
              }
      
      //temp code to make sure new parameters are always set to true 

      isClientRecord = true; 
      
      
      }
        
    }    
    
    // Save using StandardController Account Save function
    public PageReference SaveButton(){
      accountController.save();
      return null;
    }
    
     // Creates a formatted display string
    private void setatRisk(){
        if(currentAccount.At_Risk__c != NULL){
        atRisk = '   ' + currentAccount.At_Risk__c.replace(';','\n   ').removeEnd('\n   ');
        }
    }

     // Creates a formatted display string   
    private void setPotentialRisk(){
        if(currentAccount.Potential_Risk__c != NULL){
        potentialRisk = '   ' + currentAccount.Potential_Risk__c.replace(';','\n   ').removeEnd('\n   ');
        }
    }
    
    // Creates a formatted display string
    private void setBUPrimaryClient() {
        if(currentAccount.Primary_Client_Combined__c != NULL){
        BUPrimaryClient = '   ' + currentAccount.Primary_Client_Combined__c.replace(';','\n   ').removeEnd('\n   ');
        }
    }
    
    // Creates a formatted display string
    private void setDNCEIndicator() {
        if(currentAccount.Do_Not_Call__c == TRUE && currentAccount.Email_Opt_Out__c == TRUE){
            DNCEIndicator = '   Do Not Call\n   Do Not Email';
        }
        Else if(currentAccount.Do_Not_Call__c == TRUE) {
            DNCEIndicator = '   Do Not Call';
        }
        Else if(currentAccount.Email_Opt_Out__c == TRUE) {
            DNCEIndicator = '   Do Not Email';
        }
    }

        
        //JC -  get running user
    private void getRunningUser(){
        User runningUser = UserHelper.getRunningUser();     
        userProfile = runningUser.Profile.name.left(38); 
    }   //getrunning user
        
          
   
        //JC - using method from utilities class to determine if the running user is a sales rep 
    public boolean isSalesProfile{
        get{return Utilities.isSalesProf(userProfile) ;} 
    

    }//isSalesProfile 
    
      //JC - Is this record also a referral?
    public boolean isReferralRecord{
        get{return currentAccount.Is_Referral_Source__c ; } 
        
    }//isreferralrecord
    
    public boolean isCurrentClient{
        get{return currentAccount.CurrentClient__c ; }  
        
    }//isCurrentClient
    
    
    //JC - show client onboarding? 
    public boolean showOnboarding{get;set;}
        
      
   //*** use getdescribe of objects to see if the user has access to each of the onboarding objects?? ?   - object helper class could be usefull 
   
   public boolean hasRefObjectAccess {get ; set; }
   
    
      //list of all Client_Overview_Configuration__c fields 
   public list <Client_Overview_Configuration__c> objectList = Client_Overview_Configuration__c.getall().values(); 
   
   public list <string> cSAPINames {get ; set; }  
    public void verifyBrowser()
    {
        isIE = false;
        String userAgent = ApexPages.currentPage().getHeaders().get('USER-AGENT');
        if(userAgent.contains('MSIE') || userAgent.contains('rv:11.0'))
        {isIE = true;}
    } 
   public void setAttributes () { 
        Profile_List__c profList = Profile_List__c.getInstance(userProfile);
        showOnboarding = (profList != null ? profList.Show_Onboarding_Overview__c : true);
                

//populate a list of reference objects in the Client Overview configuration custom setting
      if(csAPINames == null){    
        csAPINames = new list <string>(); 
        
        //set new properties to true - will update later when we decide how they will be used 
        
        showKeyInformation = true;  
        hasRefObjectAccess = true; 
        
      
      /*    likely doing the object access compare in the onboarding overview controller 
        for(Client_Overview_Configuration__c cOAccess: objectList){
        
            if(!cOAccess.Case_Only__c){                     
                string fieldName = cOAccess.Reference_Object_Relationship_API_Name__c;          
            
                system.debug('fieldname ' +fieldName);              
        
                fieldName = fieldName.replace('__r','__c');
                cSAPINames.add(fieldName);  
                
                system.debug('CSAPINanmes size ' +cSAPINames.size());
                
            }//if 
            
            
            
            }//for
        */
        
        }//if
        
        //showOnboarding = (currentAccount.CurrentClient__c ? (profList != null ? profList.Show_Onboarding_Overview__c : true) : false);
                
    
   }//setAttribute
   
   // *** on the user record, pull out sales org, do we use this to determine onboardings shown, differnt fields in each section
   
   // similar to profile list, do we use sales org setting
}