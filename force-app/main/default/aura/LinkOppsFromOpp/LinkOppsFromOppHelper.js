({
    flattenObject : function(propName, obj)
    {
        var flatObject = [];
        for(var prop in obj)
        {
            //if this property is an object, we need to flatten again
            var propIsNumber = isNaN(propName);
            var preAppend = propIsNumber ? propName+'_' : '';
            if(typeof obj[prop] == 'object')
            {
                flatObject[preAppend+prop] = Object.assign(flatObject, this.flattenObject(preAppend+prop,obj[prop]) );
            }    
            else
            {
                flatObject[preAppend+prop] = obj[prop];
            }
        }
        return flatObject;
    },
    
	flattenQueryResult : function(listOfObjects) {
       var objectList = JSON.stringify(listOfObjects);
       //here you turn the JSON string to a javascript object
       var jsonObject = JSON.parse(objectList);
       var i;
       var iLength = Object.keys(jsonObject).length;

        for(var i = 0; i < iLength; i++)
        {
            var obj = jsonObject[i];
            for(var prop in obj)
            {      
                if(!obj.hasOwnProperty(prop)) continue;
                if(typeof obj[prop] == 'object' && typeof obj[prop] != 'Array')
                {
                    obj = Object.assign(obj, this.flattenObject(prop,obj[prop]));
                }
                else if(typeof obj[prop] == 'Array')
                { 
                    for(var j = 0; j < obj[prop].length; j++)
                    {
                        obj[prop+'_'+j] = Object.assign(obj,this.flattenObject(prop,obj[prop]));  
                    }
                }
        	}
        }
        return jsonObject;
    },
    
    getData : function(component, event, methodName, targetAttribute, recordid) {
        var action = component.get('c.'+methodName);
        action.setParams({ "recordId": recordid });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Got Raw Response for ' + methodName + ' ' + targetAttribute);
                console.log(response.getReturnValue());
                
                var flattenedObject = this.flattenQueryResult(response.getReturnValue());
                if(flattenedObject.length < 2){
                    component.set('v.error', true);
                    component.set('v.errorMessage', "There is only one opportunity for this Prospect-Client.");
                    component.set('v.'+targetAttribute, flattenedObject);
                }//end if
                else{
                    component.set("v.selectedRowsVariable", recordid);
                    component.set('v.'+targetAttribute, flattenedObject);
                }//end else
          
               console.log('flattenedObject '+flattenedObject.length);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
            component.set('v.loaded', true);
        }));
        $A.enqueueAction(action);
    }
})