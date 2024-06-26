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
             console.log('JSON jsonObject' + jsonObject);
             var i;
             //a javascript object is not an array and does not have a length. You have to count its properties
             var iLength = Object.keys(jsonObject).length;
        
        for(var i = 0; i < iLength; i++)
        {
            var obj = jsonObject[i];
            for(var prop in obj)
            {      
                if(!obj.hasOwnProperty(prop)) continue;
                console.log('LM');
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
                //if no opportunities are related to this prospect-client
                if(flattenedObject.length == 0){
                    component.set('v.error', true);
                    component.set('v.errorMessage', "There are no opportunities related to this Prospect-Client.");                                      
                }//end if
                else if(flattenedObject.length == 1){
                    component.set('v.error', true);
                    component.set('v.errorMessage', "There is only one opportunity related to this Prospect-Client.");
                    component.set('v.'+targetAttribute, flattenedObject);
                }//end else if
                else{
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