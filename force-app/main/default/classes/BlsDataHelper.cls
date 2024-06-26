/* Methods for interacting with BLS system

    History
    -------
    07/13/2022 Jidesh        Created
*/

public class BlsDataHelper {
    
    public Web_Service_Log__c wsl;
    public String operation;
    public Attachment[] allFiles;

     
    //Starting method which calls all other methods to fetch the datapoints for BLS
    public static Boolean fetchTheDatapoints(List<Account> accounts, List<PEO_Onboarding_Checklist__c> checklists, String instance){
        System.debug('BLS method flow name:fetchTheDatapoints');
        List<String> seriesIdsToFetch = new List<String>();
        Map<Id,List<String>> accSeriesIdMap = new Map<Id,List<String>>();
        //For each account received build the series id's and add it into the list to fetch
        for(Account account: accounts){
            String medSeriesId = createSeriesIdMedical(account);
            String turnOverRateSeriesId = createSeriesIdTurnoverRate(account);
            String avgWageSeriesId = createSeriesIdAverageWages(account);
            seriesIdsToFetch.add(medSeriesId);
            seriesIdsToFetch.add(turnOverRateSeriesId);
            seriesIdsToFetch.add(avgWageSeriesId);
        }
        
        //Queueable class that create, fetch and process information from the BLS website https://www.bls.gov/
        if(instance == 'CommunityMethods'){
            System.debug('BlsDataHelper fetchTheDatapoints: Found instance for CommunityMethods');
            BlsDataAPIQueueable blsaq = new BlsDataAPIQueueable(seriesIdsToFetch, 'BLS Data points for UI', accounts, checklists, null, null);
            return blsaq.fetchSeriesIdInfoFromBLSCallout(seriesIdsToFetch, 'BLS Data points for UI');
        }
        else{
            System.debug('BlsDataHelper fetchTheDatapoints: else loop for enqueueing job');
            BlsDataAPIQueueable blsaq = new BlsDataAPIQueueable(seriesIdsToFetch, 'Fetch info', accounts, checklists, null, null);
            System.enqueueJob(blsaq);
        }
        return true;
    }    
    
    //This method builds the series id for medical participation
    //Custom setting: BLS_Med_Partcptn__c has all the default values stored for this datapoint
    public static String createSeriesIdMedical(Account account){
        System.debug('BLS method flow name:createSeriesIdMedical');
        //step 1: fetch all the Custom setting defaults
        BLS_Med_Partcptn__c blsMedData = [Select Prefix__c, datatype_code__c, estimate_code__c, industry_code__c, ocupational_code__c, ownership_code__c, provision_code__c, seasonal__c, subcell_code__c 
                                          from BLS_Med_Partcptn__c limit 1];
        
        //Match the Naics code of the account with the Industry in BLS
        //If this method returns zero means there is no matching indutry found and its defaulted to 0000 i.e. All Industries
        String industryCode = MatchIndForMedPart(account);
        
        //final step of building series id after receiving all the values
        //referred: https://download.bls.gov/pub/time.series/nb/nb.txt
        String seriesId = blsMedData.Prefix__c+blsMedData.seasonal__c+ blsMedData.ownership_code__c+ blsMedData.estimate_code__c+
            			  industryCode +blsMedData.ocupational_code__c+ blsMedData.subcell_code__c+
            			  blsMedData.datatype_code__c+blsMedData.provision_code__c;
        System.debug('createSeriesIdMedical seriesId:'+seriesId);
        return seriesId;
        
    }
    
    //This method matches the Account naics with Industry available in BLS
    //https://download.bls.gov/pub/time.series/nb/nb.industry
    //Custom settings used: BLS_Med_partcptn_All_Industries__c
    public static string MatchIndForMedPart(Account acc){
        System.debug('BLS method flow name:MatchBlsIndustry');
        //industry initialised as 0000
        //If indusrty found - return the specific industry 
        //else return 0000 - All industries
        String matchedInd = '0000';
        List<BLS_Med_partcptn_All_Industries__c> ind = new List<BLS_Med_partcptn_All_Industries__c>();
        if(acc.NAICS_Code__c != null){
            String naicsSub = acc.NAICS_Code__c.substring(0,2);
            System.debug('naicsSub:'+naicsSub); 
            String attr = naicsSub+'%';
            System.debug('attr:'+attr); 
            ind = [Select id,Name,industry_code__c,industry_text__c from BLS_Med_partcptn_All_Industries__c WHERE Name LIKE :attr limit 1];
            if(ind.size() >0){
                System.debug('MatchIndForMedPart matched industry:'+ind[0].Name.substring(0,4)); 
                matchedInd = ind[0].Name.substring(0,4);
            }
        }
        return matchedInd;
    }
    
    
    //This method builds the series id for Average wages
    //Custom setting: BLS_Average_Wage__c has all the default values stored for this datapoint
    public static String createSeriesIdAverageWages(Account account){
        System.debug('BLS method flow name:createSeriesIdAverageWages');
        //step 1: fetch all the Custom setting defaults
        BLS_Average_Wage__c blsAvgWageData = [Select seasonal__c, area_code__c, industry_code__c, owner_code__c, Prefix__c, size_code__c, type_code__c 
                                              from BLS_Average_Wage__c limit 1];
        //Match the Naics code of the account with the Industry in BLS
        //Match the state of the Account with BLS State
        //If this method returns zero means there is no matching indutry found and its defaulted to 10 i.e. Total, all industries
        //Match the Statecode with the Account state code
        String industryCode = MatchIndForAvgWage(account);
        String stateCode = MatchStateForAvgWage(account);
        String areaCode = stateCode +'000';
        //final step of building series id after receiving all the values
        String seriesId = blsAvgWageData.Prefix__c+ blsAvgWageData.seasonal__c+ areaCode+ blsAvgWageData.type_code__c+ blsAvgWageData.size_code__c+ 
            			  blsAvgWageData.owner_code__c+ industryCode;
        System.debug('Average wages seriesId:'+seriesId);
        return seriesId;
    }
    
    //This method matches the Account naics with Industry available in BLS
    //Custom settings used: BLS_Avg_Wage_Industries__c
    public static string MatchIndForAvgWage(Account acc){
        System.debug('BLS method flow name:MatchIndForAvgWage');
        //industry initialised as 10
        //If indusrty found return the specific industry 
        //else return 10 - All industries
        String matchedInd = '10';
        List<BLS_Avg_Wage_Industries__c> ind = new List<BLS_Avg_Wage_Industries__c>();
        if(acc.NAICS_Code__c != null){
            String rvrNaics = acc.NAICS_Code__c.reverse();
            String naicsSub = rvrNaics.replaceFirst('0', '');
            String finalNaicsToCheck = naicsSub.reverse();
            System.debug('finalNaicsToCheck:'+finalNaicsToCheck); 
            String attr = finalNaicsToCheck+'%';
            System.debug('attr:'+attr); 
            ind = [Select id,Name,industry_code__c,industry_title__c from BLS_Avg_Wage_Industries__c WHERE Name LIKE :attr limit 1];
            if(ind.size() >0){
                System.debug('ind:'+ind[0].Name); 
                matchedInd = ind[0].Name;
            }
        }
        return matchedInd;
    }
    
    
    //This method matches the Account State with State available in BLS
    //State always require a value 
    //Match using Account Shipping state and if it doesnt exist use Billing state
    public static string MatchStateForAvgWage(Account acc){
        System.debug('BLS method flow name:MatchStateForAvgWage');
        //State initialised as US : Total US
        //If State found return the specific State 
        //else return US - Total US
        String matchedState = 'US';
        String accState;
        List<BLS_Avg_Wage_States__c> state;
        if(acc.ShippingState != null){
            accState = acc.ShippingState;
        }
        else{
            accState = acc.BillingState;
        }
        if(accState != null){
            String attr = accState + '%';
            state = [Select id, Name, State__c, Postal_Abbr__c, FIPS_Code__c from BLS_Avg_Wage_States__c WHERE Name LIKE :attr limit 1];
            if(state.size() >0){
                System.debug('MatchStateForAvgWage state Name:'+state[0].Name); 
                matchedState = state[0].FIPS_Code__c;
                System.debug('MatchStateForAvgWage matchedState:'+matchedState); 
            }
        }
        return matchedState;
    }
    
    //This method builds the series id for Turnover rate
    //Custom setting: BLS_Turnover_Rate__c has all the default values stored for this datapoint
    //https://download.bls.gov/pub/time.series/jt/jt.txt
    public static String createSeriesIdTurnoverRate(Account account){
        System.debug('BLS method flow name:createSeriesIdTurnoverRate');
        //step 1: fetch all the Custom setting defaults
        
        BLS_Turnover_Rate__c blsTurnOverData = [Select Prefix__c, seasonal__c, industry_code__c, state_code__c, area_code__c, sizeclass_code__c, dataelement_code__c, ratelevel_code__c
                                                from BLS_Turnover_Rate__c limit 1];
        //Match the Naics code of the account with the Industry in BLS
        //If this method returns zero means there is no matching indutry found and its defaulted to 000000 i.e. All Industries
        //final step of building series id after receiving all the values
        String industryCode = MatchIndForTurnover(account);
        String seriesId = blsTurnOverData.Prefix__c+ blsTurnOverData.seasonal__c+ industryCode+ blsTurnOverData.state_code__c+ 
            			  blsTurnOverData.area_code__c+ blsTurnOverData.sizeclass_code__c+ blsTurnOverData.dataelement_code__c+ blsTurnOverData.ratelevel_code__c;
        System.debug('Turnover Rate seriesId:'+seriesId);
        return seriesId;
    }
    
    //This method matches the Account naics with Industry available in BLS
    //Custom settings used: BLS_Turnover_rate_Industries__c
    public static string MatchIndForTurnover(Account acc){
        System.debug('BLS method flow name:MatchBlsIndustry');
        //industry initialised as 0000
        //If indusrty found return the specific industry 
        //else return 0000 - All industries
        String matchedInd = '000000';
        List<BLS_Turnover_rate_Industries__c> ind  = new List<BLS_Turnover_rate_Industries__c>();
        if(acc.NAICS_Code__c != null){
            String naicsSub = acc.NAICS_Code__c.substring(0,2);
            String attr = naicsSub+'%';
            ind = [Select id,Name,industry_code__c,industry_text__c from BLS_Turnover_rate_Industries__c WHERE Name LIKE :attr limit 1];
            if(ind.size() >0){
                System.debug('MatchIndForTurnover matchedInd:'+ind[0].Name.substring(0,6)); 
                matchedInd = ind[0].Name.substring(0,6);
            }
        }
        return matchedInd;
    }
    
    
}