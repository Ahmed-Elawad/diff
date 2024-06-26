/*
 * 
 * PopulateCreateActivityCustomSettings.populateAllPicklists();
 * 
 * PopulateCreateActivityCustomSettings.deleteAllPicklists();
 * 
 * PopulateCreateActivityCustomSettings.updatePicklistDetail_PicklistDataField();
 */
public without sharing class PopulateCreateActivityCustomSettings {
    // delete custom settings data
    public static void deleteAllPicklists() {
        List<Create_Activity_Button__c> picklistValues = [SELECT Name FROM Create_Activity_Button__c];
        if(picklistValues != null && picklistValues.size() > 0) {
            delete picklistValues;
        }
    }
    
    /*
     * SFDC-3487 (US6-b)
     * Add 'Drop' value for the Type field.
    */
    public static void updatePicklistDetail_PicklistDataField() {
        PicklistDetail__c  pd = [SELECT Id, PicklistData__c FROM PicklistDetail__c WHERE ObjectName__c='Event' AND Developer_Name__c = 'Prism_PEO_Event_Record_Type' AND FieldName__c = 'Type'];
        pd.PicklistData__c = 'Assessment-Q-Enrollment-Q-Expense/Mileage-Q-Drop-Q-Lunch-Q-Meeting-Q-Networking-Q-Presentation - Demo-Q-Presentation - Discovery-Q-Presentation - Follow-up-Q-Presentation - Initial-Q-Presentation - Partner-Q-Presentation - Pickup-Q-Presentation - Proposal-Q-Referral Source - Initial-Q-Seminar-Q-Unavailable';
        upsert pd;        
    }
    
    /*
      * This method should be invoked manually (in the Console) to add new records in 
      * the 'Create Activity Button' custom settings.
      */
    public static void populateAllPicklists()   {
        populateActivityTypePicklist();
        populateFollowUpActivityTypePicklist();
    }
    
    public static void populateActivityTypePicklist()   {
        List<Create_Activity_Button__c> csList = new List<Create_Activity_Button__c>();
        
        Create_Activity_Button__c cs;
        cs = new Create_Activity_Button__c(Name='1', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=10, Label_Name__c='Call - Client', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='2', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=20, Label_Name__c='Call - Internal', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='3', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=30, Label_Name__c='Call - Third Party', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='4', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=40, Label_Name__c='Data Extract', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='5', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=50, Label_Name__c='Demo', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='6', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=60, Label_Name__c='Discover Flex (CPA)', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='7', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=70, Label_Name__c='Discovery - SIPM Appt', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='8', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=80, Label_Name__c='Discovery - Standard Appt', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='9', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=90, Label_Name__c='Event', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='10', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=100, Label_Name__c='Interface', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='11', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=110, Label_Name__c='Other', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='12', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=120, Label_Name__c='Paychex Flex Live Seminar', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='13', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=130, Label_Name__c='Pre-Demo Strategy Call', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='14', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=140, Label_Name__c='Post Demo Debrief', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='15', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=150, Label_Name__c='Sandbox', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='16', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=160, Label_Name__c='Shadow', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='17', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=170, Label_Name__c='Task');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='18', Picklist_Name__c='Activity Type', Group_Name__c='Sales Engineer',Sort_Order__c=180, Label_Name__c='Testing', Is_Event__c=true);
        csList.add(cs);        
        
        cs = new Create_Activity_Button__c(Name='50', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=10, Label_Name__c='Call', Exclude_For_PEO_User__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='51', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=20, Label_Name__c='Initial Presentation', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='52', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=30, Label_Name__c='Follow Up Call', Exclude_For_PEO_User__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='53', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=40, Label_Name__c='Follow Up Meeting', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='54', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=50, Label_Name__c='Note');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='55', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=60, Label_Name__c='Log an Email');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='56', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=70, Label_Name__c='Schedule Discovery', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='57', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=80, Label_Name__c='Schedule Demo', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='58', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=90, Label_Name__c='Schedule Proposal Meeting', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='59', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=100, Label_Name__c='Schedule Pick Up', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='60', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=110, Label_Name__c='Meeting', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='61', Picklist_Name__c='Activity Type', Group_Name__c='Opportunity',Sort_Order__c=110, Label_Name__c='Marketing', Is_Event__c=true);
        csList.add(cs);
        
        cs = new Create_Activity_Button__c(Name='100', Picklist_Name__c='Activity Type', Group_Name__c='Lead',Sort_Order__c=10, Label_Name__c='Telemarketing');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='101', Picklist_Name__c='Activity Type', Group_Name__c='Lead',Sort_Order__c=20, Label_Name__c='Follow Up Call');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='102', Picklist_Name__c='Activity Type', Group_Name__c='Lead',Sort_Order__c=30, Label_Name__c='Note');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='103', Picklist_Name__c='Activity Type', Group_Name__c='Lead',Sort_Order__c=40, Label_Name__c='Log an Email');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='104', Picklist_Name__c='Activity Type', Group_Name__c='Lead',Sort_Order__c=50, Label_Name__c='Call');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='105', Picklist_Name__c='Activity Type', Group_Name__c='Lead',Sort_Order__c=60, Label_Name__c='Meeting', Is_Event__c=true);
        csList.add(cs);
        
        cs = new Create_Activity_Button__c(Name='150', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=10, Label_Name__c='Current Client Call', Exclude_For_PEO_User__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='151', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=20, Label_Name__c='Follow Up Call', Exclude_For_PEO_User__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='152', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=30, Label_Name__c='Call', Exclude_For_PEO_User__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='153', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=40, Label_Name__c='Telemarketing');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='154', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=50, Label_Name__c='Note');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='155', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=60, Label_Name__c='Log an Email');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='156', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=70, Label_Name__c='Meeting', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='157', Picklist_Name__c='Activity Type', Group_Name__c='Contact',Sort_Order__c=70, Label_Name__c='Marketing', Is_Event__c=true);
        csList.add(cs);
        
        cs = new Create_Activity_Button__c(Name='200', Picklist_Name__c='Activity Type', Group_Name__c='Referral_Contact__c',Sort_Order__c=10, Label_Name__c='Follow Up Call');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='201', Picklist_Name__c='Activity Type', Group_Name__c='Referral_Contact__c',Sort_Order__c=20, Label_Name__c='Telemarketing');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='202', Picklist_Name__c='Activity Type', Group_Name__c='Referral_Contact__c',Sort_Order__c=30, Label_Name__c='Call');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='203', Picklist_Name__c='Activity Type', Group_Name__c='Referral_Contact__c',Sort_Order__c=40, Label_Name__c='Meeting', Is_Event__c=true);
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='204', Picklist_Name__c='Activity Type', Group_Name__c='Referral_Contact__c',Sort_Order__c=50, Label_Name__c='Note');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='205', Picklist_Name__c='Activity Type', Group_Name__c='Referral_Contact__c',Sort_Order__c=60, Label_Name__c='Log an Email');
        csList.add(cs);
        
        cs = new Create_Activity_Button__c(Name='250', Picklist_Name__c='Activity Type', Group_Name__c='Default',Sort_Order__c=10, Label_Name__c='Note');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='251', Picklist_Name__c='Activity Type', Group_Name__c='Default',Sort_Order__c=20, Label_Name__c='Log an Email');
        csList.add(cs);
        
        insert csList;
    }
    
    public static void populateFollowUpActivityTypePicklist()   {
        List<Create_Activity_Button__c> csList = new List<Create_Activity_Button__c>();
        
        Create_Activity_Button__c cs;
        cs = new Create_Activity_Button__c(Name='300', Picklist_Name__c='Follow Up Activity Type', Group_Name__c='Default',Sort_Order__c=10, Label_Name__c='Follow Up Call');
        csList.add(cs);
        cs = new Create_Activity_Button__c(Name='301', Picklist_Name__c='Follow Up Activity Type', Group_Name__c='Default',Sort_Order__c=20, Label_Name__c='Follow Up Meeting', Is_Event__c=true);
        csList.add(cs);
        
        insert csList;
    }    
}