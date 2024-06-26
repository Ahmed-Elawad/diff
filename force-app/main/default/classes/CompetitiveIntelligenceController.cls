/*
* Conroller for the Competitve Intelligence search component
* Histiory
* Eric Porter 12/13/2021 Created
* 05/30/2022 Reetesh Pandey  Apex code scan resolution
  11/16/2022 Dan Carmen      Add null check in getCompetitors
  12/05/2023 Jaipal   APR0152387 Created new field: Crayon_Competition__c to update the competitor values from Search Competition Bar

*/
public with sharing class CompetitiveIntelligenceController {
    
    //searches the CI Picklist Values
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String searchString, String objectApiName, String idFieldApiName, String valueFieldApiName, String extendedWhereClause, Integer maxRecords){
        searchString = String.escapeSingleQuotes(searchString);
        objectApiName = String.escapeSingleQuotes(objectApiName);
        idFieldApiName = String.escapeSingleQuotes(idFieldApiName);
        valueFieldApiName = String.escapeSingleQuotes(valueFieldApiName);
        
        if(extendedWhereClause == null){
            extendedWhereClause = '';
        }
        // Apex code scan
        else{            
          extendedWhereClause = String.escapeSingleQuotes(extendedWhereClause);
        }
        
        String query = 'SELECT '+idFieldApiName+', '+valueFieldApiName+', PicklistType__c, ManualEntry__c FROM '+objectApiName+' WHERE PicklistType__c = \'Competitor\' AND Active__c = TRUE  And '+valueFieldApiName+' LIKE \'%'+searchString+'%\' '+extendedWhereClause+' LIMIT '+maxRecords;
        System.debug('Generated query: '+query);
        
        return Database.query(query);
    }
    @AuraEnabled
    public static boolean saveToOpp2(List<Competitor__c> competitors){
        Id oppId = competitors[0].Opportunity__c;
        Opportunity opp = [Select Id, Name from Opportunity where Id = :oppId limit 1];
        List<Competitor__c> currentList = [select Id,Name,Primary__c from Competitor__c where Opportunity__c = :oppId];
        //checks if there is already a primary competition
        Boolean containsPrimary = false;
        if(currentList.size()>0){
            for(Competitor__c competitor: currentList){
                if(competitor.Primary__c == true){
                    containsPrimary = true;
                }
            }
        }
        
        System.debug('competitors on the server side: '+competitors);
        List<Competitor__c> modedSelectionList = new List<Competitor__c>();
        List<String> names = new List<String>();
        For(Integer i=0;i<competitors.size();i++){
            names.add(competitors[i].Name);
            if(currentList.isEmpty()){ // if no competitors in current list auto set primary for the first selected option
                if(i==0){
                    competitors[i].Primary__c = true;
                }
            }
            
            modedSelectionList.add(competitors[i]);
        }
        String NamesListString = String.join(names,';');
        opp.Competition__c = NamesListString;
        opp.Crayon_Competition__c = NamesListString;
        try {
            upsert modedSelectionList;
            Competitor__c savedCompetitor = [Select Id,Name,Primary__c from Competitor__c where Opportunity__c = :opp.Id and Primary__c = true limit 1];
            opp.Primary_Competitor__c = savedCompetitor.Id;
            update opp;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<Competitor__c> changePrimary(Integer oldIndex, Integer newIndex,List<Competitor__c> selectedCompetitors){
        if(oldIndex!=null){
            selectedCompetitors[oldIndex].Primary__c = false;
        }
        selectedCompetitors[newIndex].Primary__c = true;
        update selectedCompetitors;
        return selectedCompetitors;
    }
    @AuraEnabled
    public static List<Competitor__c> getCompetitors(Id oppId){
        if (oppId != null) {
           List<Competitor__c> selectedCompetitors = [select Id, Name, Primary__c,Opportunity__c from Competitor__c where Opportunity__c = :oppId Order By Primary__c Desc];
           return selectedCompetitors;
        }
        return new Competitor__c[]{};
    }
    @AuraEnabled
    public static boolean removeCompetitor(Integer removeIndex,List<Competitor__c> selectedCompetitors){
        Competitor__c removedCompetitor =  new Competitor__c();
        if(selectedCompetitors.size()==0){
            return false;
        }
        if(selectedCompetitors.size()==1){
             removedCompetitor =  selectedCompetitors[0];
             
        }else{
            Competitor__c removedCompetitorClient = selectedCompetitors[removeIndex];
            try{
                Competitor__c removedCompetitorServer = [Select Id, Name, Opportunity__c from Competitor__c where Opportunity__c = :removedCompetitorClient.Opportunity__c and Name = :removedCompetitorClient.Name limit 1];
                    removedCompetitor = removedCompetitorServer;
                
            }catch(System.QueryException e){
                return false;

            }
            //code to handle competition list when submitted
           
        }
        try {
            delete removedCompetitor;
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            return false;
        }
            Opportunity opp = [Select Id,Name, Competition__c, Crayon_Competition__c from Opportunity where Id = :removedCompetitor.Opportunity__c];
            List<String> oldCompetitorNames = opp.Competition__c.split(';');
            oldCompetitorNames = opp.Crayon_Competition__c.split(';');
            oldCompetitorNames.remove(removeIndex);
            List<String> newCompetitorNames = oldCompetitorNames;
            String newCompNamesString = '';
            if(newCompetitorNames.size()==0){
                newCompNamesString = '';
                opp.Primary_Competitor__c = null;
            }else{
                 newCompNamesString = String.join(newCompetitorNames,';');
            }
            opp.Competition__c = newCompNamesString;
            opp.Crayon_Competition__c = newCompNamesString;
            update opp;
            return true;
        
    }
    


}