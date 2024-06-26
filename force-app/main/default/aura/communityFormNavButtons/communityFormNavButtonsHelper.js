({
    loopForPreviousMatch : function(cmp, e, helper, params) {
        if (!params.possibleTabs || !params.possibleTabs.length) return;
        if (params.possibleTabs.length == 1) return;
        for (let i = 0; i < params.possibleTabs.length; i++) {
            let loopVal = params.possibleTabs[i];
            if (loopVal != params.currentPos) continue;
            // set the prevVal variable only if anywhere but the first position
            if (!i || !loopVal) continue;
            console.log( params.possibleTabs[i -1])
            return params.possibleTabs[i -1];
        }
        return;
    },
    loopForNextMatch: function(cmp, e, helper, params) {
        if (!params.possibleTabs || !params.possibleTabs.length) return;
        let nextTab;
        for (let i = 0; i < params.possibleTabs.length; i++) {
            let loopVal = params.possibleTabs[i];
            if (params.currentPos != loopVal) continue;
            
            // set the next tab var if anywhere but at the end
            nextTab = i < params.possibleTabs.length - 1 ? params.possibleTabs[i+1] : undefined;
            if (nextTab) break;
        }
        return nextTab;
    },
    sendCommunityFormsTabUpdate: function(cmp, e, helper, direction) {
        try {
            console.log('Inside sendCommunityFormsTabUpdate');
            let tabNavigateEVt = cmp.getEvent('communityFormsTabNavigate');
            tabNavigateEVt.setParam('direction', direction);
            tabNavigateEVt.fire();   
        }catch(e){
            console.error(e);
        }
    },
    handleNext: function(cmp, e, helper){
        //Benchmark
        console.log('tabNameList:'+cmp.get('v.tabNameList'));
        var possibleTabs = cmp.get('v.tabNameList');
        console.log('section:'+cmp.get('v.section') );
        console.log('benchMarkTabRequired:'+cmp.get('v.benchMarkTabRequired') );
        if(cmp.get('v.isUploadSection') && cmp.get('v.section') == 'CompInfo' && cmp.get('v.benchMarkTabRequired') == true){
            //Adding BenchMarkAvgWages to the tablist
            possibleTabs.push('BenchMarkAvgWages');
        }
        //JDA S16: sfdc-14447
        if(cmp.get('v.isUploadSection') && cmp.get('v.section') == 'Medical' && cmp.get('v.benchMarkTabRequired') == true){
            //Adding BenchMarkAvgWages to the tablist
            console.log('Medical section benchmark');
            possibleTabs.push('BenchMarkMedPart');
        }
        if(cmp.get('v.isUploadSection') && cmp.get('v.section') == 'WorkersComp' && cmp.get('v.benchMarkTabRequired') == true){
            //Adding BenchMarkAvgWages to the tablist
            console.log('Turnover rate benchmark');
            possibleTabs.push('BenchMarkTurnover');
        }
        console.log('possibleTabs:'+possibleTabs);
        console.log('tabNameList:'+cmp.get('v.tabNameList'));
        //
        let params = {
            possibleTabs: cmp.get('v.tabNameList'),
            currentPos: cmp.get('v.currentPos')
        };
        let nextTab;
        console.log(params);
        //debugger;
        nextTab = helper.loopForNextMatch(cmp, e, helper, params);
        console.log('nextTab:'+nextTab);
        //Benchmark
        if(nextTab == 'BenchMarkAvgWages' || nextTab == 'BenchMarkMedPart'|| nextTab == 'BenchMarkTurnover'){
            //update the selected tab id in parent benchMarkPos
            console.log('Inside benchmark check');
            cmp.set('v.benchMarkPos', '');
            cmp.set('v.benchMarkPos', nextTab);
        }
        else if (nextTab) {
            console.log('else if-->', nextTab);
            cmp.set('v.currentPos', nextTab);
        } else {
            console.log('NextTab: undefined');
           let Nextchevron=true;
            if(cmp.get('v.isUploadSection')){
               var UploadDocsList = cmp.get('v.UploadDocsList');
               UploadDocsList.forEach((doc) => {
                   if(doc.PEO_Doc_Required__c=='Needed' && (doc.Status__c==undefined || doc.Status__c==null)){
                   				  Nextchevron=false;
               			}
                });
                 console.log('Docs not Required?: ' + Nextchevron );
            } 
             if(!Nextchevron){
                    let dets = {ty: 'error', t: 'A documents has not been uploaded', 
                                m:  'Please add all your required Documents'};
                helper.showUserMsg(null, dets);
               }
            else{
                params = {
                    currentPos: cmp.get('v.activeParent'),
                    possibleTabs: cmp.get('v.allPossibleParents')
                };
                
                nextTab = helper.loopForNextMatch(cmp, e, helper, params);
                console.log('loopForNextMatch',nextTab);
                if (!nextTab) helper.sendCommunityFormsTabUpdate(cmp, e, helper, 1);
                else cmp.set('v.activeParent', nextTab);
            }
        }
    },
    switchLoadState: function(cmp, e) {
        // set the spinner view to the oposite of what it is now
        // Continously update the spinner for 5 seconds
        console.log('switchLoadState-->' ,cmp.get('v.currentPos'));
        let updateLoading = function(cmp, cb, stillLoading) {
            
            if (cmp.get('v.progressRate') < 100 && stillLoading) {
                let newval = cmp.get('v.progressRate');
                newval+=10;
                cmp.set('v.progressRate', newval);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cb, cmp.get('v.saveOperationInProgress'))
                                  ),1000
                );
                // this function calls itself again
            } else if (stillLoading) {
                cmp.set('v.progressRate', 0);
                window.setTimeout(
                    $A.getCallback(updateLoading.bind(this, cmp, cb, cmp.get('v.saveOperationInProgress'))
                                  ),1000);
            } else {
                clearTimeout(updateLoading);
            }
        }
        
        let showSpinner = cmp.get("v.saveOperationInProgress");
        
        cmp.set("v.saveOperationInProgress", !showSpinner);
        
        if (!showSpinner) {
            let toastHelper = function(dets){
                this.showUserMsg(null, dets);
            };
            updateLoading(cmp, toastHelper.bind(this), true);
        } else {
            cmp.set('v.progressRate', 0);
        }
    },
    manageLabel: function(component, event, helper) {
        console.log('manageLabel');
        if (component.get('v.currentPos') == 'Basic Information' || component.get('v.currentPos') == 'summary') {
            component.set('v.forwardButtonLabel', 'Next');
        } else {
            component.set('v.forwardButtonLabel', 'Next'); //Rename as per story SFDC-14128
        }
    },
    
    showUserMsg: function(cmp, err) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: err.t,
            message: err.m,
            type: err.ty
        });
        toastEvent.fire(); 
    },
})