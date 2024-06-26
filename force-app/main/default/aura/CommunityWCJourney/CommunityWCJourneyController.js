({
	init : function(component, event, helper) {
        let tabs = ['WC'];
        if (!component.get('v.noIndustryFound')) tabs.push('industry');
        if (component.get('v.showCovidQuestionnaire')) tabs.push('covidQuestionnaire');
        tabs.push('fileUploadWC');
        component.set('v.currentTabs', tabs);
	},
    setActiveTab: function(component, event, helper) {
        component.set("v.currTabId", component.get("v.activeTab"));
        let currTabLabel;
        switch(component.get('v.activeTab')) {
            case 'WC':
                currTabLabel = 'Workers\' Compensation';
                break;
            case 'covidQuestionnaire':
                currTabLabel = 'Workers\' Compensation - Covid Questionnaire';
                break;
            case 'industry':
                currTabLabel = 'Workers\' Compensation - Industry Specific';
                break;
            case 'fileUploadWC':
                currTabLabel = 'Workers\' Compensation - Documents';
                break;
        }
        
        if (currTabLabel) component.set('v.activeTabLabel', currTabLabel);
        else component.set('v.activeTabLabel', 'Workers\' Compensation');
    },
})