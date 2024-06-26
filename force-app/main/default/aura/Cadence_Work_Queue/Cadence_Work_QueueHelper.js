({
    settpList : function(component, displayList, helper){
        var updateTp = component.get("v.updateCurrentTp");
        var currentTouchpoint = updateTp  ? component.get("v.eventUpdateTouchpoint") : null;
        var tpToDisplay = component.get("v.tpToDisplay");
        var numberEligibleEmails = 'Open Email Steps Ready for Batch Send';
        var device = component.get("v.device");
        var filters = 'Filters';
        var action = component.get("c.getTouchpointsList");
        action.setParams({"displayType": tpToDisplay,
                          "returnTouchpoint" : currentTouchpoint});
        action.setCallback(this, function(response) {
            //store state of response
            var tpWrapper = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                var tpDisplayList = displayList == 'EmailList' ? tpWrapper.emailList : tpWrapper.touchpointList;
                var currentTP;
                if(displayList == 'EmailList'){
                    currentTP = tpWrapper.emailList.length ? tpWrapper.emailList[0] : null;
                }else{
                    currentTP = tpWrapper.currentTouchpoint;
                } 
                component.set("v.tpList", tpWrapper.touchpointList);
                component.set("v.emailTpList", tpWrapper.emailList);
                component.set("v.workQueueTargetTypeFilter", tpWrapper.filterListTargetType);
                component.set("v.tpDisplayList", tpDisplayList);
                component.set("v.workQueueTypeFilter", tpWrapper.filterListType);
                component.set("v.workQueueNameFilter", tpWrapper.filterListCadence);
                component.set("v.workQueueCampaignFilter", tpWrapper.filterTypeSalesProgram);
                component.set("v.workQueueZipFilter", tpWrapper.filterTypeZip);
                component.set("v.workQueueTargetListFilter", tpWrapper.filterTargetList)
                component.set("v.workQueueStepFilter", tpWrapper.filterStepList)
                component.set("v.workQueueTimeZoneFilter", tpWrapper.filterTimeZoneList)
                component.set("v.filterNameSelection", tpWrapper.lastFilterCadence);
                component.set("v.filterTypeSelection", tpWrapper.lastFilterTouchpoint);
                component.set("v.filterCampaignSelection", tpWrapper.lastFilterSalesProgram);
                component.set("v.filterZipSelection", tpWrapper.lastFilterZip);
                component.set("v.filterTargetListSelection", tpWrapper.lastFilterTarget);
                component.set("v.filterStepSelection", tpWrapper.lastFilterStep)
                component.set("v.filterTimeZoneSelection", tpWrapper.lastFilterTimeZone)
                component.set("v.hasTargetFilter", (tpWrapper.filterTargetList.length > 0));
                component.set("v.hasCallbacks", tpWrapper.hasCallback);
                component.set("v.emailLimit", tpWrapper.emailLimit);
                component.set("v.pocUser", tpWrapper.pocUser);
                if(tpWrapper.currentTouchpoint!=null && device =='DESKTOP'){
                    component.set("v.cadenceTouchpoint", currentTP);
                    component.set("v.recordLoaded", true);
                }
                else{
                    component.set("v.recordLoaded", false);
                    component.set("v.displayDetail", false);
                }
                tpToDisplay+=' ('+tpWrapper.touchpointList.length+') ';
                numberEligibleEmails +=' ('+tpWrapper.emailList.length+') ';
                 if(tpWrapper.lastFilterCadence ==null && tpWrapper.lastFilterTouchpoint ==null && tpWrapper.lastFilterSalesProgram ==null && tpWrapper.lastFilterZip ==null && tpWrapper.lastFilterTimeZone ==null){
                    component.set("v.containsFilter", false);
                    filters += ' : None';
                }
                else{
                    component.set("v.containsFilter", true);
                    if(tpWrapper.lastFilterCadence !=null){
                        filters+= ' : '+tpWrapper.lastFilterCadence;
                    }
                    if(tpWrapper.lastFilterTouchpoint !=null){
                        filters+=' : '+tpWrapper.lastFilterTouchpoint;
                    }
                    if(tpWrapper.lastFilterStep !=null){
                        filters+=' : '+tpWrapper.lastFilterStep;
                    }
                    if(tpWrapper.lastFilterSalesProgram !=null){
                        filters+=' : '+tpWrapper.lastFilterSalesProgram;
                    }
                    if(tpWrapper.lastFilterZip !=null){
                        filters+=' : '+tpWrapper.lastFilterZip;
                    }
                    if(tpWrapper.lastFilterTimeZone !=null){
                        filters+=' : '+tpWrapper.lastFilterTimeZone;
                    }
                }
                component.set("v.titleDisplay", tpToDisplay);
                component.set("v.numEmailTouchpoints", numberEligibleEmails);
                component.set("v.filterSummary", filters);
            }
            if(state=='ERROR'){
                console.log(response.getError());
            }
        });
                
    
        $A.enqueueAction(action);
        helper.setCurrentUserId(component);
    },
    setCurrentUserId : function(component){   
        var action = component.get("c.getCurrentUserId");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('CURRENT USER ID'+response.getReturnValue());
                component.set("v.currentUserID", response.getReturnValue());
            }});
        $A.enqueueAction(action);
    },
    saveFilterOptions : function(component, helper) {
        var action = component.get("c.updateFilterSettings");
        var filterName = component.get("v.filterNameSelection");
        var touchpointType = component.get("v.filterTypeSelection");
        var campaignType = component.get("v.filterCampaignSelection");
        var zipSelection = component.get("v.filterZipSelection");
        var targetSelection = component.get("v.filterTargetListSelection");
        var stepSelection = component.get("v.filterStepSelection");
        var timeZoneSelection = component.get("v.filterTimeZoneSelection");
        var timeZoneSelection = component.get("v.filterTimeZoneSelection");
        var targetType = component.get("v.filterbyTargetTypeSelection");
        console.log('var1 sar', targetType); 
        action.setParams({"filterCadence": filterName,
                          "filterTouchpoint": touchpointType,
                          "filterSalesProgram": campaignType,
                          "filterZip": zipSelection,
                          "filterTargetList": targetSelection,
                          "filterStepNbr" : stepSelection,
                          "filterTimeZone" : timeZoneSelection,
                          "TargetType" : targetType
                        });
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
        });
        $A.enqueueAction(action);
    },
    setFilterOptions : function(component, helper) {
       var cadenceArray = new Array();        
    },
    turnOffSpinner : function(component){
        component.set('v.showSpinner', false);
    },
    sendEmails : function(component, helper) {
        var touchList = component.get("v.emailSendList");
        var action = component.get("c.sendEmailList");
        action.setParams({"tpList" : touchList});
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            var responseWrapper = response.getReturnValue();
            var sendResponse = responseWrapper.emailResponse;
            var toastType = responseWrapper.toastType;
            this.turnOffSpinner(component);
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "NOTE: ",
                    "message": sendResponse,
                    "type" : toastType,
                });
                toastEvent.fire();
                component.set("v.emailResponse", toastType);
            }
        });      
        
        $A.enqueueAction(action);
    },
})