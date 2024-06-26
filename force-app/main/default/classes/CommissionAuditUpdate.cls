/* 
 *  Allows the upload of a csv file to update case and CSA records.
 *   
 * History
 * -------
 * 04/08/2016 Jacob Hinds     		 Created
 * 04/16/2021 Pradeep Garlapaati     Update code to add new column called Case Comments
 * 04/16/2021 Pradeep Garlapaati     Update code to have ability to mass update refferal records
 */
public with sharing class CommissionAuditUpdate {
    public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public String[] csvFileLines{get;set;}
    public List<Case> caselist{get;set;}
    public List<CaseComment> caseCommentlist{get;set;}
    public List<CSA_Inquiries__c> csaList{get;set;}
    public List<Referral__c> ReferralList{ get; set; }
    public boolean ShowCases{get;set;}    
    public boolean ShowReferrals{get;set;}    
    
    public Map<String, Schema.SObjectField> caseFieldMap = null;
    public Map<String, Schema.SObjectField> csaFieldMap = null;
    public Map<String, Schema.SObjectField> ReferralFieldMap = null;
    public Map<String, Schema.SObjectField> combinedFieldMap = new Map<String, Schema.SObjectField>();
    public Map<Integer,String> headerFieldMap = new Map<Integer,String>();
	public String formattedBody;
    
    public integer counter=0;  //keeps track of the offset
    public integer listSize=50; //sets the page size or number of rows
    public integer totalSize; //used to show user the total size of the list

  	public List<tableRow> tableRows { get; set; }
  	public class tableRow {
	    public Case caseRec { get; set; }
	    public CSA_Inquiries__c csaRec { get; set; }
	    public caseComment  caseComments { get; set; }
	    public tableRow(Case c,CSA_Inquiries__c csa, caseComment cc) {
	      caseRec = c;
	      csaRec = csa;
	      caseComments = cc;
	    }
  	}
    
      public CommissionAuditUpdate(){
          ShowCases = false;
          ShowReferrals = false;
        csvFileLines = new String[]{};
        caselist = New List<Case>(); 
        csaList = New List<CSA_Inquiries__c>();
        caseCommentlist = New List<CaseComment>();
        ReferralList = New List<Referral__c>();
        tableRows = new List<tableRow>();
      }
    
       public void importCSVFile(){
           try{
                system.debug('formatted:');
	           //create an http request and pass the blob through it, this forces the blob into utf-8 encoding which is necessary for upload.  Also handles special chars
	           httpRequest tmp = new HttpRequest();
				tmp.setBodyAsBlob(csvFileBody);
				csvAsString = tmp.getBody();
			  String[] rowList = new String[]{};
			  
			  //formats the csv so that each line has "EndOfLine" at the end.  Necessary for the EmailServiceProcessor.parseCSVToMap method.
              String m_introValue = '\r\n';
		      String m_CSVData = csvAsString;
		      while(m_CSVData.length() > 1){
			      Integer m_introValueLength = m_introValue.length();
	              integer m_introValuePos = m_CSVData.indexOf(m_introValue);
			      while(math.mod(m_CSVData.subString(0, m_introValuePos).countMatches('"'),2)!=0){
			          m_introValuePos = m_CSVData.indexOf(m_introValue, m_introValuePos + m_introValuelength);           
			      }
			      String row = m_CSVData.subString(0, m_introValuePos)+'EndOfLine';
			      formattedBody += row;
			      m_CSVData = m_CSVData.subString(m_introValuePos + m_introValue.length());     
		      }
              system.debug('formatted:'+formattedBody);
           }
            catch (Exception e)
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importing data. '+e);
                ApexPages.addMessage(errorMessage);
            }
      }
          
          public void CSA_InquiriesMethod()
          {
              importCSVFile();
              try{
              csaFieldMap = new ObjectHelper().getFieldMap('CSA_Inquiries__c');
              for(String s:csaFieldMap.keySet()){
              	Schema.SObjectField schema = csaFieldMap.get(s);
              	String label = new ObjectHelper().getFieldLabel('CSA_Inquiries__c', s);
              	combinedFieldMap.put(label,schema);
              }
              
              system.debug('combinedFieldMap'+combinedFieldMap);
		      
               headerFieldMap.put(0,'Id');
               headerFieldMap.put(1,'Approved_Reject_Status__c');
               headerFieldMap.put(2,'Reason_Code__c');
               headerFieldMap.put(3,'Corporate_Comment__c');
               headerFieldMap.put(4,'Case__c');
               headerFieldMap.put(5,'Status');
               headerFieldMap.put(6,'CaseComments');
               map<integer,map<string,Object>> CSVMap = EmailServiceProcessor.parseCSVToMap(formattedBody,false,headerFieldMap,combinedFieldMap);
               
               system.debug('?map?:'+CSVMap);
               String warningIds = '';
               for(Map<string,Object> csvRecordData:CSVMap.values()){
               	   CSA_Inquiries__c csaToUpdate = new CSA_Inquiries__c();
                   Case caseToUpdate = new Case() ;
                   CaseComment caseCommentToUpdate = new CaseComment() ;
                   
                   csaToUpdate.Id = (Id)csvRecordData.get('Id');
                   csaToUpdate.Approved_Reject_Status__c = (String)csvRecordData.get('Approved_Reject_Status__c');
                   csaToUpdate.Reason_Code__c=(String)csvRecordData.get('Reason_Code__c');
                   string corpComment = (String)csvRecordData.get('Corporate_Comment__c');
                   if(corpComment!=null){
                       corpComment = corpComment.removeStart('\"\"');
	                   corpComment = corpComment.removeEnd('\"\"');
					   csaToUpdate.Corporate_Comment__c=corpComment;
                   }               
				   csaList.add(csaToUpdate); 
                   caseToUpdate.Id = (Id)csvRecordData.get('Case__c');
                   caseToUpdate.Status = (String)csvRecordData.get('Status');
                   if(caseToUpdate.Id != null){
                   	 caseList.add(caseToUpdate); 
                   caseCommentToUpdate.parentid = caseToUpdate.Id;
                   caseCommentToUpdate.CommentBody = (String)csvRecordData.get('CaseComments');
                   caseCommentlist.add(caseCommentToUpdate);
                   }
                   else{
                     warningIds+=csaToUpdate.Id+',';
                   }
                   
                   tableRows.add(new tableRow(caseToUpdate,csaToUpdate,caseCommentToUpdate));
               }
               
               if(warningIds!=''){
                   warningIds = warningIds.removeEnd(',');
	               ApexPages.Message warningMessage = new ApexPages.Message(ApexPages.severity.WARNING,'There was an issue with the following CSA Inquiry records: '+warningIds
	               															+'. Please check the CSA Inquiry and corresponding case to ensure accuracy.');
	               ApexPages.addMessage(warningMessage);
               }
              
               /* 
               for(Integer i=1;i<csvFileLines.size();i++){
                   CSA_Inquiries__c csaToUpdate = new CSA_Inquiries__c();
                   Case caseToUpdate = new Case() ;
                   string[] csvRecordData = csvFileLines[i].split(',');
                   
                   csaToUpdate.Id = csvRecordData[0];
                   csaToUpdate.Approved_Reject_Status__c = csvRecordData[1];
                   csaToUpdate.Reason_Code__c=csvRecordData[2];
                   csaToUpdate.Corporate_Comment__c=csvRecordData[3];
                   csaList.add(csaToUpdate); 
                   
                   caseToUpdate.Id = csvRecordData[4];
                   caseToUpdate.Status = csvRecordData[5];                                                                          
                   caseList.add(caseToUpdate); 
                   
                   tableRows.add(new tableRow(caseToUpdate,csaToUpdate));
               }*/
               if(!csaList.IsEmpty()&&!caseList.IsEmpty()){
               	 update csaList;
                 update caseList;
                   insert caseCommentlist;
                 
               }
               
               totalSize = tableRows.size();
                  ShowCases = true;
            }
            catch (Exception e)
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importing data. '+e);
                ApexPages.addMessage(errorMessage);
            }
      }

      public void ReferralsMethod()
          {
              importCSVFile();
              
              try{
              ReferralFieldMap = new ObjectHelper().getFieldMap('Referral__c');
              for(String s:ReferralFieldMap.keySet()){
              	Schema.SObjectField schema = ReferralFieldMap.get(s);
              	String label = new ObjectHelper().getFieldLabel('Referral__c', s);
              	combinedFieldMap.put(label,schema);
              }
              
              system.debug('combinedFieldMap'+combinedFieldMap);
		      
               headerFieldMap.put(0,'MonthSaleReported__c');
               headerFieldMap.put(1,'PendingRunOfPayroll__c');
               headerFieldMap.put(2,'NbrOfEmployees__c');
               headerFieldMap.put(3,'ActualRevenue__c');
               headerFieldMap.put(4,'Disposition__c');
               headerFieldMap.put(5,'BankLeadNotes__c');
               headerFieldMap.put(6,'CommissionOverride__c');
               headerFieldMap.put(7,'Referral_Id__c');
               map<integer,map<string,Object>> CSVMap = EmailServiceProcessor.parseCSVToMap(formattedBody,false,headerFieldMap,combinedFieldMap);
               
               system.debug('?map?:'+CSVMap);
               String warningIds = '';
                  list<String> RFIds = new list<String>();
               for(Map<string,Object> csvRecordData:CSVMap.values()){
               	   Referral__c ReferralsToUpdate = new Referral__c();
                    
                   ReferralsToUpdate.MonthSaleReported__c		= (csvRecordData.get('MonthSaleReported__c') != null) ? Date.parse((String)csvRecordData.get('MonthSaleReported__c')) : null;   
                   ReferralsToUpdate.PendingRunOfPayroll__c		= (csvRecordData.get('PendingRunOfPayroll__c') != null) ? Date.parse((String)csvRecordData.get('PendingRunOfPayroll__c')) : null;
                   ReferralsToUpdate.NbrOfEmployees__c			= (csvRecordData.get('NbrOfEmployees__c') != null) ?Integer.valueOf(csvRecordData.get('NbrOfEmployees__c')) : null;
                   ReferralsToUpdate.ActualRevenue__c			= (csvRecordData.get('ActualRevenue__c') != null) ? Decimal.valueOf((String)csvRecordData.get('ActualRevenue__c')):null;
                   ReferralsToUpdate.Disposition__c				= (String)csvRecordData.get('Disposition__c');
                   ReferralsToUpdate.BankLeadNotes__c			= (String)csvRecordData.get('BankLeadNotes__c');
                   ReferralsToUpdate.CommissionOverride__c		= (csvRecordData.get('CommissionOverride__c') != null) ? Boolean.valueOf(csvRecordData.get('CommissionOverride__c')) : false;
                   ReferralsToUpdate.Referral_Id__c				= (String)csvRecordData.get('Referral_Id__c');
                   ReferralList.add(ReferralsToUpdate); 
                   if(ReferralsToUpdate.Referral_Id__c != null)RFIds.add(ReferralsToUpdate.Referral_Id__c);
                }
                   map<String,Referral__c> rfMap = new map<String,Referral__c>();
                  for(Referral__c rf : [select id,Referral_Id__c from Referral__c where Referral_Id__c IN :RFIds])
                  {
                      rfMap.put(rf.Referral_Id__c,rf);
                  }
                  for(Referral__c rf: ReferralList)
                  {
                      if(rfMap.get(rf.Referral_Id__c) != null)
                      {
                          rf.Id = rfMap.get(rf.Referral_Id__c).id;
                      }
                  }
                
               if(!ReferralList.IsEmpty()){
               	 update ReferralList;                 
               }
               
               totalSize = ReferralList.size();
               
              ShowReferrals = true;
              }
            catch (Exception e)
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importing data. '+e);
                ApexPages.addMessage(errorMessage);
            } 
      }
    
    public List<tableRow> getTableRows{
      get {
      	List<tableRow> trs = new List<tableRow>();
      	if(totalSize!=null){
	      	for(Integer i=counter;i<getPageSize();i++){
	      		trs.add(tableRows[i]);
	      	}
      	}
      	return trs; 
      }
   } //getNeeds

    public List<Referral__c> getReferralList{
      get {
      	List<Referral__c> trs = new List<Referral__c>();
      	if(totalSize!=null){
	      	for(Integer i=counter;i<getPageSize();i++){
	      		trs.add(ReferralList[i]);
	      	}
      	}
      	return trs; 
      }
   } //getNeeds
    
	public PageReference Beginning(){ //user clicked beginning
      counter = 0;
      return null;
   }

   public PageReference Previous(){ //user clicked previous button
      counter -= listSize;
      	
      return null;
   }

   public PageReference Next(){ //user clicked next button
      counter += listSize;
      return null;
   }

   public PageReference End(){ //user clicked end
      counter = totalSize - math.mod(totalSize, listSize);
      //counter = totalSize - listSize;
      return null;
   }

   public Boolean getDisablePrevious(){ 
      //this will disable the previous and beginning buttons
      if (counter>0) return false; else return true;
   }

   public Boolean getDisableNext(){ //this will disable the next and end buttons
      if (counter + listSize < totalSize) return false; else return true;
   }

   public Integer gettotalSize(){
      return totalSize;
   }
   
   public Integer getCurrentCount(){
      return counter+1;
   }
   
   public Integer getPageSize(){
      Integer size;
      if(totalSize>(counter+listSize)){
      	size = counter+listSize;
      }
      else{
      	size = totalSize;
      }
      return size;
   }
}