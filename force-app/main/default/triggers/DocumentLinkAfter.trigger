trigger DocumentLinkAfter on Document_Link__c (After insert) {    
    Map<id,id> cdMap = new Map<id,id>();
    for(Document_Link__c DL: trigger.new){    
        if(DL.Case__c != NULL && DL.ESR_Document__c == NULL){
            cdMap.put(DL.Case__c,DL.Id);                          
        }
    }//for
    
    if(!cdMap.isEmpty()){
        ContentDocumentUtilities.linkToAccount(cdMap);
    }
}