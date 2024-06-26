({
    doInit: function(component, event, helper) {
        helper.addTabNumbers(component, event, helper);
    },
    
    setActiveTab: function(component, event, helper) {
        component.set("v.currTabId", component.get("v.selectedTabId"));
        console.log('SETTING ACTIVE TAB: ADDITIONALPRODOFINTERESTTABSELECT');
        
        let currTabLabel;
        switch(component.get('v.selectedTabId')) {
            /*case 'epliQuestionnaire':
                console.log('epliQuestionnaire');
                currTabLabel = 'Additional Information - EPLI Questionnaire';
                break;*/
            case '401kQuestionnaire':
                console.log('401kQuestionnaire');
                currTabLabel = 'Additional Information - Products of Interest';
                break;
            case 'Addntl_Misc_Docs':
                console.log('Addntl_Misc_Docs');
                currTabLabel = 'Additional Information - Documents';
                break;
        }
        
        if (currTabLabel) component.set('v.activeLabel', currTabLabel);
        else component.set('v.activeLabel', 'Additional Information');
        
        // assigns the makeReadOnly attr to true if logged in as a portal user and the EPLI is already akn
        // get the user and checklsit
        let User = component.get('v.runUser');
        let chk = component.get('v.OnbPEOChecklist');
        // if the profile is not customer community login user clone they're internal => userIsInternal = true
        let userIsInternal = User && User.Profile && User.Profile.Name !== 'Customer Community Login User Clone';
        // if the aknowledgement fields are null the form isn't aknowleged => EPLIIsAknowleged = false
        let EPLIIsAknowleged = chk.Client_Id_user_agreement_acknowledgment__c != undefined || chk.EPLI_Acknowledged_By__c != undefined;
        // if the user is internal and the epli is aknowleged lock the EPLI form
        if (userIsInternal && EPLIIsAknowleged) component.set('v.makeReadOnly', true);
        // SFDC-10438: If the contract status is approved the ADTNL products form & EPLI needs to be unlocked
        if (chk.CS_CM_Contract_Status__c != undefined || chk.CS_CM_Contract_Status__c == 'Approved') component.set('v.makeAddtnlReadOnly', false);
        
    },
})