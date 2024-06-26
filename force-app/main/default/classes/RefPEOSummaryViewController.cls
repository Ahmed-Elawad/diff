/* 
 *  Controller for RefPEOSummaryView page.
 *  Using Field sets and a custom controller to control what is displayed based on the Profile
 *  of the person viewing the page.
 *
 * History
 * -------
 * 06/16/2016 Lynn Michels      Created  - the page was created only for SF1
 * 05/04/2017 Carrie Marciano   Added SB to end of profile names
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 *
 */
public without sharing class RefPEOSummaryViewController  {
    
    public Reference_PEO__c refPEO { get; set; } //get the reference PEO from the URL
    public String title {get; set;}  //using some criteria, set the title to be used in the page
    public String baseUrl {get; set;} 
    List<Profile> profileNameList = [Select Name from Profile where Id = :UserInfo.getProfileId() LIMIT 1];
    public String fieldSet = null;
    
    // The extension constructor initializes the private member
    // variable Reference_PEO__c by using the getRecord method from the standard
    // controller. getRecord() method returns the record specified in the ID parameter in the page URL
    public RefPEOSummaryViewController(ApexPages.StandardController stdController) {
        getBaseUrl();  
        //get all fields in field set that will display on the page by calling fieldList()
        if (!Test.isRunningTest())
        {
            stdController.addFields(fieldList());
        }
        this.refPEO = (Reference_PEO__c)stdController.getRecord(); 
    }
    
    //get all fields in field set that will display on the page    
    public List<String> fieldList(){
            List<String> fieldList = new List<String>();
            List<Schema.FieldSetMember> fieldSetFieldsList = getFieldSetFields();
            for (Schema.FieldSetMember f : fieldSetFieldsList)
            {
                fieldList.add(f.getFieldPath());
            }
            fieldList.add('Name'); //always add Name field for title on page.
            return fieldList;
        }//end fieldList
    
    //use Profile name to determine which field set to display
    public String getFieldSetName() {
        String name = (this.refPEO.Name != null ? '' : ': '+this.refPEO.Name);
        //if the user has a Sales profile
        if(profileNameList[0].Name == 'HRS Sales Manager - SB' ||profileNameList[0].Name == 'HRS PEO-ASO Sales - SB')
        {
            title = 'Sales Summary for Reference PEO:  ' + this.refPEO.Name;
            return fieldSet = 'Sales_Summary_Set';
        }
        //if the user has an HRG profile
        else if(profileNameList[0].Name == '2008-09 HRS Premier Support Rep' ||profileNameList[0].Name =='2008-09 HRS Premier Support Manager')
        {
            title = 'HRG Summary for Reference PEO:  ' + this.refPEO.Name;
            return fieldSet = 'HRG_Summary_Set';
        }
        //if the user does not have either Sales, or HRG, default to HRG (no reason, had to pick one)
        else
            title = 'HRG Summary for Reference PEO:  ' + this.refPEO.Name;
            return fieldSet = 'HRG_Summary_Set';
    }//end getFieldSetName

    //get fields from the field set
    public List<Schema.FieldSetMember> getFieldSetFields() {    
        getFieldSetName();
        return Schema.SObjectType.Reference_PEO__c.fieldSets.getMap().get(fieldSet).getFields();
        }//end getFieldSetFields
    
    //using our own Utilites class, get the base url
    public void getBaseUrl(){
        baseUrl = Utilities.instanceURL(); 
    }// end getBaseURL
    

    //get all of the peo discrepancies on this reference Peo
    public List<Reference_PEO_Discrepancy__c> getPeoDiscrepancies(){ 
        List<Reference_PEO_Discrepancy__c> peoDiscrepancies = new List<Reference_PEO_Discrepancy__c>();
        peoDiscrepancies = [SELECT id, Name, status__c, Discrepancy_Area__c,
                            Discrepancy_Type__c, Additional_Information__c,
                            HoldPayrollWillNotRun__c, NonHoldPayrollWillRun__c, Reference_PEO__c
                            FROM Reference_PEO_Discrepancy__c WHERE Reference_PEO__c =: refPEO.id];
        return peoDiscrepancies;
    }//end getPeoDiscrepancies
    
    //get all of the chatter posts on this reference Peo
    public List<FeedItem> getChatterPosts(){
        List<FeedItem> chatterPosts = new List<FeedItem>();
        chatterPosts = [SELECT Id, Body, ParentId, InsertedById, CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CreatedDate
                        FROM FeedItem WHERE ParentId =: refPEO.Id LIMIT 100];
        return chatterPosts;
    }// end getChatterPosts

}