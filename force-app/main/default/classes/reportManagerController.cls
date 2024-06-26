public with sharing class reportManagerController {


  //  public string errorMessage{get;set;}
    public integer recordCount{get;set;}
 //   public string Key{get;set;}
   // public string retURL{get;set;}
  //  public string typeOfRecord{get;set;}
  //  public string referrer{get;set;}
    

    private integer MAX_RECORDS= 1000;
    

    
    
    List<string> leadIds;
    
/*
    public string reportName{
        
        get
        {
            return reportName;
        }
        
        set
        {
            reportName= value;
            errorMessage= '';

            
            string rptId= ReportManager.FindReport(reportName);

            if(rptId== '')
            {
                errorMessage= 'The report "' + reportName + '" was not found.';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));
              
                recordCount=0;
                
            } 
            else           
            {
                leadIds= ReportManager.GetReportLeads(rptId);
                recordCount= leadIds.size();
                typeOfRecord= ReportManager.RecordType;
                
                if(typeOfRecord== '')
                {
                   errorMessage= 'The report "' + reportName + '" has no contacts or leads. As such, it will not be processed.';
                   ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));                        
                
                }
                else
                {
                    if(recordCount== 0)
                    {
                       errorMessage= 'The report "' + reportName + '" was found, but it has no records to render.';
                       ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errorMessage));                        
                    }
                    
                
                    if(recordCount> MAX_RECORDS)
                    {
                       errorMessage= 'Sorry. The report "' + reportName + '" has ' + recordCount + ' records. The maximum amount number of records is ' + MAX_RECORDS + '.';
                       ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,errorMessage));                        
                    }
                }
                
                
            }
            
        }
    }
   
    
    public void refreshName()
    {
        reportName= reportName;
    }
    */
    public reportManagerController()
    {
        recordCount= 0;
        
        leadIds= new List<string>();
        
        // Return URL was passed as a parameter to this page
   //     retURL= ApexPages.currentPage().getParameters().get('retURL');
      //  referrer= ApexPages.currentPage().getHeaders().get('Referer');
    }
    

/*
    public PageReference SearchItems() {
    
       reportName=reportName;
    
    
       if(errorMessage!='')
       {
           return null;
       }
    
     
    
       List<string> name= new List<string>();
       List<string> value = new List<string>();
       
      
       
       string strLeadIds= '';
       integer counter= 0;
       for(string sLeadId: leadIds)
       {
           
           if(strLeadIds!= '')
           {
              strLeadIds +=','; 
           }
           
           strLeadIds+= sLeadId;
           counter++;
           
           
       
       }
       
       
       
       value.add(strLeadIds); 
       name.add('contactIds');
       
       Key= mkto_si.LongGetMethodArguHandler.putArgus(name, value, typeOfRecord);   
            
       
            
       string newUrl= '/apex/mkto_si__Send_Marketo_Email?contactType=' + typeOfRecord+'&key=' + Key;
       
       if((retUrl != '') && (retUrl != null))
       {
           newUrl+= '&retUrl=' + retURL.escapeHtml4();    
       }
       
       PageReference pageRef = new PageReference(newUrl);
       pageRef.setRedirect(true);
       return pageRef;
     
    
    }*/
}