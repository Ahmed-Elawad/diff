public with sharing class ListReportsController 
{
    public String reportName {get; set;}
    public List<Report> listReports {get;set;}
    
    public PageReference runQuery()
    {
        if (null!=reportName)
        {
           string qryString= '%'+ reportName + '%';
        
           listReports =[SELECT Id, Name, Format, FolderName, LastModifiedDate FROM Report where (Name like :qryString) and (Format='Tabular') ORDER BY FolderName];
        }
        
        return null;
    }
    
    
}