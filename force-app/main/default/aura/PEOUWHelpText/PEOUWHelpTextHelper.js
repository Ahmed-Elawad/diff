({
    getSalesRep: function(component, event) {
        console.log('MGF getSalesRep component.get("v.checklist.Sales_Rep__c") = '+component.get("v.checklist.Sales_Rep__c"));
        var getRep = component.get("c.getSalesRepresentativeInfo");
        
        getRep.setCallback(this, function(res) {
            if (res.getState() != 'SUCCESS') {
                console.log(res.getError());
                return;
            }
            else {
                let salesRep = res.getReturnValue();
                console.log('MGF getSalesRep salesRep.Name = '+salesRep.Name);
                console.log('MGF getSalesRep salesRep.Phone = '+salesRep.Phone);
                if(salesRep.FirstName != null && salesRep.LastName != null) {
                    component.set("v.salesRepName", salesRep.FirstName + ' ' + salesRep.LastName);
                }
                if(salesRep.Phone != null) {
                    component.set("v.salesRepNumber", salesRep.Phone);
                }
            }
            
        });
        
        getRep.setParams({
            'userId': component.get("v.checklist.Sales_Rep__c")
        });
        
        $A.enqueueAction(getRep);
    }})