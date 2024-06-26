({
    getIndustrySpecific : function(component,event) {
        return new Promise(function(resolve, reject) {
            var industryObject = component.get('c.getIndustryDetails');
            industryObject.setParams({
                PEOchecklist: component.get('v.PEOChecklist').Id,
                AccountId :component.get('v.PEOChecklist').Prospect_Client__c,
                peoIndustryTitle: component.get('v.industryName'),
                formName: 'IndsutrySpecific.cmp'
            });
            industryObject.setCallback(this, function(res){
                if (res.getState() != 'SUCCESS' || !res.getReturnValue()) {
                    console.log(res.getError());
                    let errs = {	
                        title: 'Error retrieving Questionnaire',	
                        message: 'Server error retrieving questionnaire. Please contact admin if error presists',	
                        type: 'error'
                    };
                    reject(errs);
                }
                console.log(res.getReturnValue());
                var data = res.getReturnValue();
                component.set('v.industryStruct', data);
                resolve(true);                
            });
            $A.enqueueAction(industryObject);   
        });
    },
    setupFormView: function(component, event) {
        let data = component.get('v.industryStruct');
        if(data.IndustryType!=null && data.IndustryType!=undefined){
            component.set('v.IndustryType',data.IndustryType);
            component.set('v.IndustryTypeId',data.IndustryTypeId);
        }
        
        if(data.industryRec!=null && data.industryRec!=undefined) {
            component.set('v.IndustrySpecific',data.industryRec);
        }
        
        component.set('v.loadingSpin',false);
    },
    saveIndustrySpecific : function(component,event, helper) {
        return new Promise(function(resolve, reject){
            try {
                console.log('isqForm.saveIndustrySpecific.send');
                
                component.set('v.loadingSpin',true);
                
                var industryObject = component.get('c.saveIndustrySpecific');
                
                /*industryObject.setParams({
                IndustryRec: component.get('v.IndustrySpecific'),
                formName: 'IndsutrySpecific.cmp'
            });
            
            industryObject.setCallback(this, function(res){
                let data = res.getReturnValue();
                if (res.getState() !=  'SUCCESS' || !data) {
                    console.log(res.getError())
                    component.set('v.loadingSpin',false);
                    var toastEvent = $A.get("e.force:showToast");	
                    toastEvent.setParams({	
                        title: 'Error Saving Questionnaire',	
                        message: 'Server error saving questionnaire. Please contact admin if error presists',	
                        type: 'error'
                    });	
                    toastEvent.fire();	
                    reject(false);
                }
                component.set('v.IndustrySpecific', res.getReturnValue());
                var toastEvent = $A.get("e.force:showToast");	
                toastEvent.setParams({	
                    title: 'Success',	
                    message: 'Your progress has been saved!',	
                    type: 'success'
                });	
                toastEvent.fire();	
                component.set('v.loadingSpin',false);
                resolve(true);
            });
            
            $A.enqueueAction(industryObject); */
                helper.saveThroughAutoSave(component, event, this)
                .then(function(result) {
                    console.log('isqForm.saveISQ.recieve')
                    var toastEvent = $A.get("e.force:showToast");	
                    toastEvent.setParams({	
                        title: 'Success',	
                        message: 'Your progress has been saved!',	
                        type: 'success'
                    });	
                    toastEvent.fire();	
                    component.set('v.loadingSpin',false);
                    resolve(helper.setRecordsOnForms(component, event, helper));
                })
                .catch(function(err) {
                    console.log('isq.saveISQ.err');
                    console.log(err)
                    component.set('v.loadingSpin',false);
                    var toastEvent = $A.get("e.force:showToast");	
                    toastEvent.setParams({	
                        title: 'Error Saving Questionnaire',	
                        message: 'Server error saving questionnaire. Please contact admin if error presists',	
                        type: 'error'
                    });	
                    toastEvent.fire();
                    reject(false);
                })
            }catch(e) {
                console.log('isqForm.sendIndustrySave.syntaxErr');
                console.log(e);
                reject(false);
            }
        });
    },
    handleErr: function(cmp, err) {
        cmp.set('v.loadingSpin',false);
        var toastEvent = $A.get("e.force:showToast");	
        let t = err.title;
        let m = err.message;
        let ty = err.type;
        toastEvent.setParams({	
            title: t,
            message: m,
            type: ty
        });	
        toastEvent.fire();	        
    },
   sendAutoSave: function(cmp, e, helper) {
        try {
            let field = e.getSource();
            let fieldName = field.get('v.name');
            let fieldValue = field.get('v.value');
            let objectAPIName = 'WC_Questionnaire_Industry_Specific__c';
            //let Account = cmp.get('v.parentAccount');
            let Account = cmp.get('v.allAccounts')[0];
            if (fieldValue && fieldValue.length) {
                let recordId = cmp.get('v.IndustrySpecific.Id');
                let autoSaveEvt = cmp.getEvent('autoSave');
                autoSaveEvt.setParam('objectName', objectAPIName);
                autoSaveEvt.setParam('accountId', Account.Id);
                autoSaveEvt.setParam('fieldName', fieldName);
                autoSaveEvt.setParam('fieldValue', fieldValue);
                autoSaveEvt.setParam('recordId', recordId);
                autoSaveEvt.setParam('accountName', Account.Name);
                autoSaveEvt.fire();
            }
        } catch(e) {
            console.error('Error sendAutoSave');
            console.error(e);
        }
    },
    cancelAutoSaveEvents: function(cmp,e, helper) {
        try {
            let autoSaveEvt = cmp.getEvent('autoSave');
            autoSaveEvt.setParam('cancelAll', true);
            autoSaveEvt.fire();
        } catch(e) {
            console.error('Error cancelAutoSaveEvents');
                          console.error(e);
        }
    },
    save: function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            try {
                console.log('isqForm.save.send')
                let todayDate = new Date();
                let isCommUser = component.get('v.communityUser');
                if(isCommUser){
                    component.set('v.industryStruct.industryRec.Peo_IndSpecific_formStatus__c','Complete');
                    component.set('v.industryStruct.industryRec.Peo_IndSpecific_formSubmissionTime__c', todayDate.toJSON());
                }
                var rec = component.get('v.IndustrySpecific');
                rec.PEO_Underwriting_Checklist__c = component.get('v.PEOChecklist').Id;
                rec.RecordTypeId= component.get('v.IndustryTypeId');
                component.set("v.IndustrySpecific",rec);
                helper.saveIndustrySpecific(component,event, helper)
                .then(() => resolve(true))
                .catch(() => reject(false));
            } catch(e) {
                console.log('isq.save.err');
                console.log(e);
                reject(false);
            }
        });
    },
    
    fetchNaicsFromAcc: function(component, event, helper) {
        var Accounts = component.get('v.allAccounts');
        var NaicsInfo = [];
        Accounts.forEach(function (item, index) {
            NaicsInfo.push(item.NAICS_Code__c);
        });
        component.set('v.naicsInfo',NaicsInfo);
        NaicsInfo.forEach(function (item, index) {
            if(item){
                let result = item.startsWith("7211");
                if(result == true)component.set('v.displayRestaurantSpecific',result);
            }
        });
    },
    
    saveThroughAutoSave: function(cmp, e, helper) {
        return new Promise(function(resolve, reject) {
            try {
                console.log('isqForm.saveThroughAutoSave.send')
                let autoSaveEvt = cmp.get('v.saveAction');
                
                autoSaveEvt(cmp, e, helper, true)
                .then(function(result) {
                    console.log('isqForm.saveThroughAutoSave.recieve');
                    resolve(result);
                })
                .catch(function(err) {
                    console.log('err:' + err);
                    throw err;
                })
            } catch(e) {
                console.log('isqForm.saveThroughAutoSave err');
                console.log(e);
                reject(e);
            }  
        })
    },
    setRecordsOnForms: function(cmp, e, helper, records) {
        let recIds = {};
        if (cmp.get('v.IndustrySpecific') !== null) recIds.WC_Questionnaire_Industry_Specific__c = cmp.get('v.IndustrySpecific').Id; 
        for (let soObjectName in records) {
            let sObjectList = records[soObjectName];
            let failedList = sObjectList !== null ? sObjectList.Fail : [];
            let successList = sObjectList !== null ? sObjectList.Success : [];
            successList.forEach(function(rec) {
                if (rec.Id == recIds.WC_Questionnaire_Industry_Specific__c) cmp.set('v.IndustrySpecific', rec);
            })
        }
        return true;
    },
})