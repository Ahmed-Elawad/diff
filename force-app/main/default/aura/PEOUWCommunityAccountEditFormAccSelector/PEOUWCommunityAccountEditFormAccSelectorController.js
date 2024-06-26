({
	init : function(component, event, helper) {
        console.log(component.get('v.Opportunity'));
        let allTabs = component.get('v.allAccounts').reduce(function(s, a) {
            s.push(a.Id);
            return s;
        }, []);
        component.set('v.possibleTabs', allTabs);
        let parentAcc = component.get('v.parentRec');
        component.set('V.selectedAccountId', parentAcc.Id);
	}
})