({
    doInit: function(component, event, helper) {
        console.log('date is '+component.get("v.lastActivityDate"));
        var lastActivityDate = component.get("v.lastActivityDate");

        if(lastActivityDate) {
            // format as MM-DD-YY
            var unformattedDate = new Date(lastActivityDate);
            var month = unformattedDate.getMonth() + 1;
            //month = (month < 10) ? '0' + month : month;
            var day = unformattedDate.getUTCDate();
            var year = unformattedDate.getFullYear();

            var formattedDate = month + '-' + day + '-' + year;

            component.set("v.displayDate", formattedDate);
        }


    }, 

    updateDisplayDate: function(component, event, helper){
        var lastActivityDate = component.get("v.lastActivityDate");

        if(lastActivityDate) {
            // format as MM-DD-YY
            var unformattedDate = new Date(lastActivityDate);
            var month = unformattedDate.getMonth() + 1;
            //month = (month < 10) ? '0' + month : month;
            var day = unformattedDate.getUTCDate();
            var year = unformattedDate.getFullYear();

            var formattedDate = month + '-' + day + '-' + year;

            component.set("v.displayDate", formattedDate);
        }
    },

    navigateToActivityTab: function(component, event, helper){
        helper.navigateToActivityTab(component, event, helper);
    }

})