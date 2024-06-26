({
    doInit : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        component.set("v.device", device);
        component.set("v.updateCurrentTp", false);
        helper.settpList(component, "TouchpointList", helper);    
    },
    refreshList : function(component, event, helper) {
        component.set("v.updateCurrentTp", false);
        helper.settpList(component, "TouchpointList", helper);    
    },
    updateTouchpointList : function(component, event, helper) {
        var touchpointDisplay = component.get("v.tpToDisplay");
        var displaySetting = touchpointDisplay == 'All Open Touchpoints' ? 'Today\'s List' : 'All Open Touchpoints';
        var buttonLabel =  touchpointDisplay == 'All Open Touchpoints' ? 'Display All Touchpoints' : 'Display Today\'s List Only';
        component.set("v.tpToDisplay", displaySetting); 
        component.set("v.tpBtnLabel", buttonLabel); 
        component.set("v.updateCurrentTp", false);
        helper.settpList(component, "TouchpointList", helper);
    },
    getAllTouchpoints : function(component, event, helper) {
        component.set("v.emailButtonStyle", 'brand-outline');
        component.set("v.todayOnlyButtonStyle", 'brand-outline');
        component.set("v.allTpButtonStyle", 'Brand');
        component.set("v.reTpButtonStyle", 'brand-outline');
        component.set("v.oeTpButtonStyle", 'brand-outline');
        component.set("v.tpToDisplay", 'All Open Touchpoints');
        component.set("v.emailsOnly", false);
        component.set("v.updateCurrentTp", false);
        component.set("v.recordLoaded", false); 
        helper.settpList(component, "TouchpointList", helper);
    },
    getRETouchpoints: function(component,event,helper){
        component.set("v.emailButtonStyle", 'brand-outline');
        component.set("v.todayOnlyButtonStyle", 'brand-outline');
        component.set("v.allTpButtonStyle", 'brand-outline');
        component.set("v.tpToDisplay", 'Recent Touchpoints');
        var tpToDisplay = component.get("v.tpToDisplay");
        component.set("v.titleDisplay", tpToDisplay);
        component.set("v.oeTpButtonStyle", 'brand-outline');
        component.set("v.reTpButtonStyle", 'brand');
        component.set("v.emailsOnly", false);
        component.set("v.updateCurrentTp", false);
        component.set("v.recordLoaded", false); 
        helper.settpList(component, "TouchpointList", helper);
        
    },
    getOETouchpoints: function(component,event,helper){
        component.set("v.emailButtonStyle", 'brand-outline');
        component.set("v.todayOnlyButtonStyle", 'brand-outline');
        component.set("v.allTpButtonStyle", 'brand-outline');
        component.set("v.tpToDisplay", 'Open Engagements');
        var tpToDisplay = component.get("v.tpToDisplay");
        component.set("v.titleDisplay", tpToDisplay);
        component.set("v.oeTpButtonStyle", 'brand');
        component.set("v.reTpButtonStyle", 'brand-outline');
        component.set("v.emailsOnly", false);
        component.set("v.updateCurrentTp", false);
        component.set("v.recordLoaded", false); 
        helper.settpList(component, "TouchpointList", helper);

    },
    getDueTodayList : function(component, event, helper) {
        component.set("v.emailButtonStyle", 'brand-outline');
        component.set("v.todayOnlyButtonStyle", 'Brand');
        component.set("v.allTpButtonStyle", 'brand-outline');
        component.set("v.reTpButtonStyle", 'brand-outline');
        component.set("v.oeTpButtonStyle", 'brand-outline');
        component.set("v.tpToDisplay", 'Today\'s List');
        component.set("v.emailsOnly", false);
        component.set("v.recordLoaded", false); 
        helper.settpList(component, "TouchpointList", helper);
    },
    getAutoSendEmails : function(component, event, helper) {
        component.set("v.emailButtonStyle", 'Brand');
        component.set("v.todayOnlyButtonStyle", 'brand-outline');
        component.set("v.allTpButtonStyle", 'brand-outline');
        component.set("v.reTpButtonStyle", 'brand-outline');
        component.set("v.oeTpButtonStyle", 'brand-outline');
        var emailList = component.get("v.emailTpList");
        component.set("v.tpDisplayList", emailList);
        component.set("v.emailsOnly", true);
        if(emailList.length){
            component.set("v.recordLoaded", false); 
            component.set("v.cadenceTouchpoint", emailList[0]);
            component.set("v.recordLoaded", true);
            component.set("v.displayDetail", true);
        }else{
            component.set("v.cadenceTouchpoint", null);
        }
    },
    sendAllEmails : function(component, event, helper) {
        component.set('v.showSpinner', true);
        var currentEmailList = component.get("v.emailTpList");
        var emailSendList = [];
        var emailLimit = component.get("v.emailLimit");
       // var sendLimit = currentEmailList.length <= emailLimit ? currentEmailList : emailLimit;
        for (var i = 0; i < emailLimit;i++){
            if(currentEmailList[i] != null){
                emailSendList.push(currentEmailList[i]);
            }
        }
        component.set("v.emailSendList", emailSendList);
        helper.sendEmails(component);
        var response = component.get("v.emailResponse");
        if(response != 'error'){
            helper.settpList(component, "EmailList", helper);
        }
    },
    clearFilters : function(component, event, helper) {
        var displayType = component.get("v.tpToDisplay");
        component.set("v.filterNameSelection", null);
        component.set("v.filterTypeSelection", null);
        component.set("v.filterCampaignSelection", null);
        component.set("v.filterZipSelection", null);
        component.set("v.filterTargetListSelection", null);
        component.set("v.filterStepSelection", null);
        component.set("v.filterTimeZoneSelection", null);
        component.set("v.filterbyTargetTypeSelection", null);
        helper.saveFilterOptions(component,helper);
        
        //additional check to see if batch email steps to exclude setTPList
        if(displayType != 'Batch Email Steps'){
            helper.settpList(component, "TouchpointList", helper);    
        }else{
        var emailList = component.get("v.emailTpList");
        console.log(emailList);
        component.set("v.recordLoaded", false); 
        component.set("v.cadenceTouchpoint", emailList[0]);
        component.set("v.recordLoaded", true); 
        component.set("v.displayDetail", true);
        }
    },
    handleComponentEvent : function(component, event, helper) {
        component.set("v.recordLoaded", false); 
        var currentTp = event.getParam("currentTouchPoint");
        var updateTp = event.getParam("updateTouchpoint");
        var displayUpdateToast = event.getParam("displayUpdateToast");
        component.set("v.updateCurrentTp", updateTp);
        component.set("v.eventUpdateTouchpoint", currentTp);
        helper.settpList(component, "TouchpointList", helper);
        if(displayUpdateToast){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Confirmation! ",
                "message": 'The touchpoint has been updated.  Your touchpoint list has been refreshed',
                "type" : 'success',
            });
            toastEvent.fire();
        }
    },
    viewTouchpoint : function(component, event, helper) {  
        component.set("v.recordLoaded", false); 
        var touchpointToView = event.currentTarget.getAttribute("data-id");
        var tpList = component.get("v.tpList");
        for (var i = 0; i < tpList.length;i++){
            if(tpList[i].Id == touchpointToView){
                
                component.set("v.cadenceTouchpoint", tpList[i]);
                console.log("vvv sss", tpList[i]);
                component.set("v.recordLoaded", true);
                component.set("v.displayDetail", true);
                break;
            }
        }
    },
    openFilterList : function(component) {
        component.set("v.showFilter", true);
    },
    closeFilterList : function(component) {
        component.set("v.showFilter", false);
    },
    openTouchpointList : function(component) {
        component.set("v.displayDetail", false);
        component.set("v.recordLoaded", false);
    },
    updateFilter : function (component, event, helper){
        var displayType = component.get("v.tpToDisplay");
        component.set("v.recordLoaded", false);
        component.set('v.showSpinner', true);
        helper.saveFilterOptions(component,helper);
        if(displayType != 'Batch Email Steps'){
            helper.settpList(component, "TouchpointList", helper);
        }else{
            var emailList = component.get("v.emailTpList");
        console.log(emailList);
        component.set("v.recordLoaded", false); 
        component.set("v.cadenceTouchpoint", emailList[0]);
        component.set("v.recordLoaded", true); 
        component.set("v.displayDetail", true);
        }
        component.set('v.showSpinner', false);
    },
    updateTpDisplay: function(component,event,helper){
        var selectedValue;
        var batchEmailUser = component.get('v.pocUser');
        if(batchEmailUser){
            try {
                // selectedValue =  component.find("tpDisplayList2").get("v.value");
                 selectedValue =  component.find("tpDisplayList2").get("v.value");
            } catch (error) {
                console.log(error);
            }
        }else{
            try {
                // selectedValue =  component.find("tpDisplayList2").get("v.value");
                 selectedValue =  component.find("tpDisplayList3").get("v.value");
            } catch (error) {
                console.log(error);
            }
        }
        
        component.set("v.recordLoaded", false); 
        component.set("v.tpToDisplay",selectedValue);
        console.log(selectedValue);
        if(selectedValue=="Batch Email Steps"){
            var emailList = component.get("v.emailTpList");
            component.set("v.tpDisplayList", emailList);
            component.set("v.emailsOnly", true);
            if(emailList.length){
                component.set("v.recordLoaded", false); 
                component.set("v.cadenceTouchpoint", emailList[0]);
                component.set("v.recordLoaded", true);
                component.set("v.displayDetail", true);
            }else{
                component.set("v.cadenceTouchpoint", null);
            }
        }else{
            component.set("v.emailsOnly", false);
            helper.settpList(component, "TouchpointList", helper);
        }

    },
    changeDefaultSort: function(component,event,helper){
        var touchpointSortedDisplay = component.get("v.sortedTpToDisplay");
        var sortedDisplaySetting = touchpointSortedDisplay == 'Sort By Recency'? 'Recently Contacted':'Sort By Recency';
        var sortedButtonLabel = touchpointSortedDisplay == 'Sort By Recency'? 'Recent Engagements':'Open Engagements';
        component.set("v.sortedTpToDisplay", sortedDisplaySetting); 
        component.set("v.sortedTpBtnLabel", sortedButtonLabel); 
        helper.settpList(component, "TouchpointList", helper);

    },
})