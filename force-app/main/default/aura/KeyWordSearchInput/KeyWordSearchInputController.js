({
    init: function(cmp, e, helper) {
        let getAccAction = cmp.get('c.getAccNaics');
        getAccAction.setParams({accId: cmp.get('v.recordId')});
        getAccAction.setCallback(this, (res) => helper.getAccACtionCb(cmp, res));
        $A.enqueueAction(getAccAction);
        return;
    },
    save: function(cmp, e, helper) {
        // if an option was selected send the save
        // otherwise show msg
        let selectedOptionObj = helper.getSelectedOption(cmp, e);
        if (selectedOptionObj) helper.sendSaveRequest(cmp, e, selectedOptionObj);
        else console.log('didnt have value');
        return;
    },
    searchHandler : function (cmp, e, helper) {
        const searchString = e.target.value;
        if (searchString.length >= 1) {
            //Ensure that not many function execution happens if user keeps typing
            if (cmp.get("v.inputSearchFunction")) clearTimeout(cmp.get("v.inputSearchFunction"));
            var inputTimer = setTimeout($A.getCallback(() => helper.searchRecords(cmp, searchString)), 500);
            cmp.set("v.inputSearchFunction", inputTimer);
        } else{
            cmp.set("v.results", []);
            cmp.set("v.openDropDown", false);
        }
        return;
    },
    optionClickHandler : function (cmp, e, helper) {
        const selectedId = e.target.closest('li').dataset.id;
        const selectedValue = e.target.closest('li').dataset.value;
        cmp.set("v.inputValue", selectedValue.slice(0,6));
        cmp.set("v.inputDescr", selectedValue.slice(8));
        cmp.set("v.openDropDown", false);
        cmp.set("v.selectedOption", selectedId);
        return;
    },

    clearOption : function (cmp, e, helper) {
        cmp.set("v.results", []);
        cmp.set("v.openDropDown", false);
        cmp.set("v.inputValue", "");
        cmp.set("v.inputDescr",  "");
        cmp.set("v.selectedOption", "");
        return;
    },
    updateInput: function(cmp, e, helper) {
        console.log(e.target.value)
        cmp.set('v.inputValue', e.target.value);
        return;
    }
})