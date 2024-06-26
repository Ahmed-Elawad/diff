global with sharing class ReportManager {

    private static string LEAD_SFDC_OBJECT='00Q';
    private static string CONTACT_SFDC_OBJECT='003';
    
    private static string LEAD_TYPE='Lead';
    private static string CONTACT_TYPE='Contact';
    
    private static integer limitSoqlRecords = 1000;


    public static string RecordType{get;set;}



    
    webservice static string FindReport(string reportName)
    {
        string retValue= '';
        
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report WHERE Name= :reportName Limit 1];
    
        if(reportList.size() > 0)
        {
            retValue= (String)reportList.get(0).get('Id');
        }
        
        
        return retValue;
    }
    
    

        
    webservice static string testTypeOfRecord(string SFDCId)
    {
        string retValue= '';
        
        string SFDCobject= SFDCId.left(3);
        
        if(SFDCobject== LEAD_SFDC_OBJECT)
        {
            retValue= LEAD_TYPE;
        }
        
        else

        if(SFDCobject== CONTACT_SFDC_OBJECT)
        {        
            retValue= CONTACT_TYPE;
        }
        
        return retValue;
    }
    
    webservice static string[] EmailRecordsOnly(string[] originalArray, string leadType)
    {
        string[] retArray= new string[]{};
        lead[] leadsSet;
        contact[] contactSet;
        
        string lastId= '';
        integer iSize= 0;

        
        do 
        {
        
            if(leadType == LEAD_TYPE)
            {
                leadsSet= [select id, email from lead where (email!= '') and (id in :originalArray) and (id> :lastId) order by Id Limit :limitSoqlRecords];
                
                iSize= leadsSet.size();
                if(iSize >0)
                {
                    lastId= leadsSet[iSize-1].Id;
                    for(lead l: leadsSet)
                    {
                        retArray.Add(l.Id);
                    }
                }
                else
                {
                    lastId= '';
                }
            } 
            else
            {
                if(leadType == CONTACT_TYPE)
                {
                    contactSet= [select id, email from contact where (email!= '') and (id in :originalArray) and (id> :lastId) order by Id Limit :limitSoqlRecords];
                    
                    iSize= contactSet.size();
                    if(iSize >0)
                    {
                        lastId= contactSet[iSize-1].Id;
                        for(contact c: contactSet)
                        {
                            retArray.Add(c.Id);
                        }
                        
                        
                    }
                    else
                    {
                        lastId= '';
                    }
                                        
                }
            }
            
        } while (lastId!= '');
     
        
    
        return retArray;
    }

    
    webservice static string[] GetReportLeads(string reportId)
    {
        string[] retValue= new string[]{};
        
        
        
        Reports.ReportResults reportResults= Reports.ReportManager.runReport(reportId, true);


        Reports.ReportFactWithDetails factWithDetails =
               (Reports.ReportFactWithDetails) reportResults.getFactMap().get('T!T');

        integer iRow=0;
        RecordType= '';
        
        for (Reports.ReportDetailRow row : factWithDetails.getRows()) {
            
            integer iCol= 0;
            
            for (Reports.ReportDataCell cell : row.getDataCells()) {
                
                //System.debug('The cell data (' + iRow + '-' + iCol+ '): ' + cell.getLabel());
                //System.debug('The cell value (' + iRow + '-' + iCol+ '): ' + cell.getValue());
                
                string value= (string) cell.getValue();


                if(value != null)
                
                {
                
                    string recType= testTypeOfRecord(value);
                    
                    //System.debug('Type of record: ' + testTypeOfRecord(value));
                    
                    if(RecordType== '')
                    {
                        RecordType= recType;
                    }
                
                
                                    
                    if(recType!='')
                    {
                        retValue.add(value);
                        break;
                    }    
                
                }
                
                
                

                
                
                iCol++;
                
             
             
             
            }
            iRow++;
        }
        
        
        //System.debug('Before: ' + retValue.size());

        retValue= EmailRecordsOnly(retValue, RecordType);

        //System.debug('After: ' + retValue.size());
        
        return retValue;
    }
    

    
}