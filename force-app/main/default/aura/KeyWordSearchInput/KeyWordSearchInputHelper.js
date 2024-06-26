({
    searchRecords : function(cmp, searchString) {
        var action = cmp.get("c.getRecords");
        
        action.setParams({
            "searchString" : searchString,
            "objectApiName" : cmp.get("v.objectApiName"),
            "idFieldApiName" : cmp.get("v.idFieldApiName"),
            "valueFieldApiName" : cmp.get("v.valueFieldApiName"),
            "extendedWhereClause" : cmp.get("v.extendedWhereClause"),
            "maxRecords" : cmp.get("v.maxRecords")
        });
        action.setCallback(this,function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                const serverResult = res.getReturnValue();
                console.log('returned Industry:'+serverResult);
                const results = [];
                serverResult.forEach(function(element) {
                    const result = {id : element[cmp.get("v.idFieldApiName")], value : element[cmp.get("v.valueFieldApiName")]};
                    results.push(result);
                });
                cmp.set("v.results", results);
                console.log(results);
                if(serverResult.length>0){
                    cmp.set("v.openDropDown", true);
                    // set flag to show err msg to false & update UI
                    cmp.set('v.emptyResult', false);
                } else {
                    // set flag to show err msg to true  & update UI
                    cmp.set('v.emptyResult', true);
                }
            } else{
                console.log(res.getError());
                let msg = "Something went wrong!! Could not retrieve Industry Codes. Please contact admin for support";
                this.raiseMessage( "ERROR", msg,"error");
            }
        });
        $A.enqueueAction(action);
        return;
    },
    sendSaveRequest: function(cmp, e, selectedOptionObj) {
        // add tests to sanitize input
        // consider a text input value without one being selected
        let saveAction = cmp.get('c.saveAccountNAICSCode');
        let value = selectedOptionObj.value;
        let code, desc;
        if (value == 'applied') {
            code = value; 
            desc = '';
        } else if (value.length > 6) {
            code = selectedOptionObj.value.slice(0, 6);
            desc = selectedOptionObj.value.slice(8);
        } else code = value;
        saveAction.setParams({
            accountId: cmp.get('v.recordId'), 
            NAICSCode: code,
            naicsDisc: desc
        });
        saveAction.setCallback(this, (res) => this.saveActionCb(cmp, res)); 
        $A.enqueueAction(saveAction);
    },
    saveActionCb: function(cmp, res) {
        let state = res.getState();
        let succeeded = res.getReturnValue();
        if (state != 'SUCCESS') {
            let err = res.getError();
            console.log(err);
            let msg = `Error saving Naics code on account: ${cmp.get('v.recordId')}`;
            this.raiseMessage( "ERROR", msg,"error");
            return;
        }
        let msg = `Naics code saved on account: ${cmp.get('v.recordId')}`;
        this.raiseMessage( "Success", msg,"success");
        return;
    },
    getAccACtionCb: function(cmp, res) {
        let state = res.getState();
        let data = res.getReturnValue();
        if (state != 'SUCCESS') {
            // add flag to show a message for the error
            return;
        }
        if (data) {
            let naics = data.NAICS_Code__c;
            if (naics) cmp.set('v.inputValue', naics);
        } else {
            let msg = `Error retrieving existing NAICS code for account: ${cmp.get('v.recordId')}`;
                                                                                   this.raiseMessage( "Error", msg, "error");
        }
        return;
    },
    raiseMessage: function(title, msg, type) {
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent){
            toastEvent.setParams({
                "title": title,
                "type": type,
                "message":msg
            });
            toastEvent.fire();
        }
        return;
    },
    getSelectedOption: function(cmp, e) {
        let result = cmp.get('v.results');
        let selectId = cmp.get('v.selectedOption');
        for (let i = 0; i <  result.length; i++) {
            if (result[i].id == selectId) return result[i];
        }
        // filters the input to accept non matched 6 digit number or 'applied' only
        let textInput = cmp.get('v.inputValue');
        textInput = textInput.toLowerCase();
        let reg =  new RegExp('[0-9]{6}');
        let validNumber = reg.test(textInput);
        if (validNumber || textInput =='applied') return {value: textInput, };
        return false;
    },
})