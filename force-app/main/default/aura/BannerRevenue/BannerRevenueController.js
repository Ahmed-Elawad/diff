({
    doInit: function(component, event, helper) {
        var unformattedRevenue = component.get("v.revenue");
        console.log('jc ' + component.get("v.revenue"));
        if(unformattedRevenue) {
            component.set("v.formattedRevenue", unformattedRevenue.toLocaleString());
        } else {
            component.set("v.formattedRevenue", "0");
        }
    },

    updateRevenue: function(component, event, helper) {
        var unformattedRevenue = component.get("v.revenue");
        if(unformattedRevenue) {
            component.set("v.formattedRevenue", unformattedRevenue.toLocaleString());
        } else {
            component.set("v.formattedRevenue", "0");
        }
    }
})