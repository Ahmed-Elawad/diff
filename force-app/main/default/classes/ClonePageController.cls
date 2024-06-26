/* ClonePageController - This controller will clone a record using only the fields in a specified fieldSet
* 
* 10/29/2015 Created - Justin Stouffer
* 07/06/2020  Jacob Hinds         Added without sharing per PMD
* 05/30/2022 Reetesh Pandey       Apex code scan resolution
*/
public without sharing class ClonePageController {
    
    private boolean okToContinue = TRUE;

    public sObject newObj {get; set;}//This is the cloned object

    public ClonePageController(){
        Try{
            Id OriginalId = ApexPages.currentPage().getParameters().get('id'); //The ID of the record to clone.
            string fieldSetName = ApexPages.currentPage().getParameters().get('fieldSetName'); //The name of the fieldset containing the fields to clone.
            string ObjectName = ApexPages.currentPage().getParameters().get('ObjectName'); //The API name of the object you are cloning.
            // Apex code scan
            ObjectName = String.escapeSingleQuotes(ObjectName);
            List<Schema.FieldSetMember> fieldList = readFieldSet(fieldSetName, ObjectName); //Get the FieldSet based on the Name and Object Type
            sObject originalObj = database.query(buildQuery(ObjectName,OriginalId,fieldList)); //Build a query and pull back only the fields to be copied from your original
            cloneObject(ObjectName,OriginalObj,fieldList); //Create a new object and set the values for the fields in the FieldSet from your Original object.
        }
        Catch(exception e){
            apexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Something went wrong! Check with your System Administrator.\r\n' + e.getMessage()));
            okToContinue = FALSE;    
        }          
    }   
    
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);  
        return fieldSetObj.getFields(); 
    }// readFieldSet
    
    public pageReference SaveClone(){
        if(okToContinue){
            insert newObj;
            PageReference pageRef = new PageReference('/' + newObj.id +'/e?retURL=/' + newObj.id);
            pageRef.setRedirect(TRUE);
            return pageRef;
        }
        else{
            return NULL;
        }
    }//SaveClone
    
    private string buildQuery(string ObjectName, String OriginalId, List<Schema.FieldSetMember> fieldList){
        string qString = 'SELECT ';
        for(Schema.FieldSetMember fieldSetMemberObj : fieldList)
        {
            qString += fieldSetMemberObj.getFieldPath() + ', ';
        }
        qString = qString.removeEnd(', ');
        qString += ' FROM ' + ObjectName + ' WHERE Id = \'' + OriginalId + '\'';        
        return qString;    
    }// buildQuery
    
    private void cloneObject(string ObjectName, sObject OriginalObj, List<Schema.FieldSetMember> fieldList){
        Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(ObjectName).getDescribe().getSObjectType();
        newObj = objectDef.newSobject();
        Schema.DescribeSObjectResult r = objectDef.getDescribe();
        Map<String,Schema.SObjectField> fieldMap = r.fields.getMap();
        for(Schema.FieldSetMember fieldSetMemberObj : fieldList)
        {
            if(fieldMap.get(fieldSetMemberObj.getFieldPath()).getDescribe().isUpdateable()){
                newObj.put(fieldSetMemberObj.getFieldPath(),originalObj.get(fieldSetMemberObj.getFieldPath()));
            }
        }
    }// cloneObject
}