({
	addTabNumbers: function(component, event, helper) {
        
        var tabNames = [];
        var initTabNum = 0;
        //tabNames.push('EPLILabel');
        tabNames.push('AddtnlProdOfIntrstLabel');
        tabNames.push('AddtnlMiscDocsLabel');
        if(tabNames.length>0){
            tabNames.forEach(function (item, index) {
                initTabNum++;
                console.log(item, index);
                component.set(`v.`+item, initTabNum+'.'+component.get(`v.`+item));
            });
        }
    },
})