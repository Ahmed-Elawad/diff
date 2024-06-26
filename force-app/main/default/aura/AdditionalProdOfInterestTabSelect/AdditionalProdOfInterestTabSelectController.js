({
    setActiveTab: function(component, event, helper) {
        component.set("v.currTabId", component.get("v.selectedTabId"));
        console.log('SETTING ACTIVE TAB: ADDITIONALPRODOFINTERESTTABSELECT');
        
        let currTabLabel;
        switch(component.get('v.selectedTabId')) {
            case 'epliQuestionnaire':
                console.log('epliQuestionnaire');
                currTabLabel = 'Additional Information - EPLI Questionnaire';
                break;
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
        let User = component.get('v.runUser');
        let chk = component.get('v.OnbPEOChecklist');
        let userIsInternal = User && User.Profile && User.Profile.Name !== 'Customer Community Login User Clone';
        if (userIsInternal && (chk.Client_Id_user_agreement_acknowledgment__c != undefined || chk.EPLI_Acknowledged_By__c != undefined)) component.set('v.makeReadOnly', true);
        //If the contract status is approved the ADTNL products form & EPLI needs to be unlocked
        if (chk.CS_CM_Contract_Status__c != undefined || chk.CS_CM_Contract_Status__c == 'Approved') component.set('v.makeAddtnlReadOnly', false);
    },
})