/*
*  07/20/2023 Reetesh Pandey  Updated Apex code scan resolution
* 
**/
public without sharing class CustomLookupLWCController {
    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTrm, string myObjct, String flter) {
        String myQuery = null;
        String searchTerm = String.isNotBlank(searchTrm)?String.escapeSingleQuotes(searchTrm):'';
        String myObject = String.isNotBlank(myObjct)?String.escapeSingleQuotes(myObjct):'';       
        String filter = String.isNotBlank(flter)?String.escapeSingleQuotes(flter):'';
        if(myObject != '' ){
            if(searchTerm != '' && filter != '' ){
                myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' AND '+filter+' LIMIT  5';
            }
            else {
                if(searchTerm != ''){                
                    myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' LIMIT  5';                
                }
                else {                
                    myQuery = 'Select Id, Name from '+myObject+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5';
                }
            }
        }
        system.debug('Query >> '+myQuery);
        if(String.isNotBlank(myQuery)){
            return   database.query(myQuery);
        }        
        return null;
    }
}