/*
 * History
 * --------
 * 05/15/2013 Cindy Freeman	created to make MMS on-boarding easier to track documents
 * 12/1/2015  Lynn Michels  edited to make documents work on Reference Core Payroll object with MPSC Onboarding documents also
 * 05/05/2016 Jacob Hinds	Added discrepancy reasons in chatter post
 * 11/14/2017 Lynn Michels	MPSC Documents Visualforce page no longer being used as of 3/2017
 * 03/25/2024 Carrie Marciano	CanBeDeleted old MPSC tech debt
 */
 
global with sharing class RefMMSPayrollDocController {
    public RefMMSPayrollDocController(){}
/*	
	public Id refMMSId {get; set;}
	public Reference_MMS_Payroll__c refMMS {get; set;}	
//	public Reference_Core_Payroll__c refCore {get; set;}	
	public String selectedId {get; set;}							// parameter populated when user does something
	public String congaEmail {get; set;}
	public String congaOK {get; set;}
		
	public Boolean showMsg {get; set;} 
	public String pgMsg {get; set;}
	
	public List<MMSDocumentWrapper> mmsDocList {get; set;}			// use MMSDocumentWrapper class
	public Boolean isMMS = false; 
	public Boolean isDiscrepancy = false;
	public ID salesRepId;
	public ID refCorePayrollObject;
	
	public Set<String> discrepancyInfoSet = new Set<String>();

	////////////////  constructor	
    public RefMMSPayrollDocController(ApexPages.StandardController stdController) {
    	refMMSId = ApexPages.currentPage().getParameters().get('id');
    	String id = refMMSId;
    	//check to see if id is of Reference Core Payroll Object 
    	if (id.left(3) == 'a0q')
    	{
    		isMMS = false;
    	}
    	//or Reference Preview Payroll object
    	else if (id.left(3) == 'a3d')
    	{
    		isMMS = true;
    	}
		fillmmsDocList();
		// clear page message
		pgMsg = '';
		showMsg = false;
		congaOK = 'Y';
		
    } // constructor


	private void fillmmsDocList() {	
		Map<Id, MMS_Onboarding_Documents__c> allMMSDocMap = new Map<Id, MMS_Onboarding_Documents__c>();
 		List<MMS_Onboarding_Documents__c> tempList = [SELECT Id, Document_Name__c, MPSC_Onboarding_Document__c,
 														MMS_Payroll_Document__c
 													 FROM MMS_Onboarding_Documents__c ORDER BY Document_Name__c];
   		for (MMS_Onboarding_Documents__c od : tempList)
   		{	allMMSDocMap.put(od.Id, od);	} 
   		
 		mmsDocList = new List<MMSDocumentWrapper>(); 
 		
 		if (isMMS)
 		{
 			buildMMS(allMMSDocMap);
 		}
 		/*LM
 		else
 		{
 			buildMPSC(allMMSDocMap);
 		}*/
		
		//build conga merge url
		//String sessionID = UserInfo.getSessionId();
		//congaEmail = buildCongaUrl();
		//System.debug('**CMF ** congaEmail='+congaEmail);
/*			
		congaEmail = 'https://www.appextremes.com/apps/Conga/PointMerge.aspx?sessionId=00DQ000000BJVjZ';
		congaEmail +='!AQgAQLTYpuxAOF4cXuAU4ghDAkk0AejfJzgLnR2ykbZN2uQuZU97J_WxmZTmQUPTiNbbDn0fkwr5iBkCW6YczfNiOurKvu_7';
		congaEmail +='&serverUrl=https://c.cs3.visual.force.com/services/Soap/u/8.0/00DQ000000BJVjZ';
		congaEmail +='&id=a3ZQ00000000QkhMAE&Queryid=a0IQ0000004kwas?pv0=a3ZQ00000000QkhMAE';
		congaEmail +='&TemplateID=a1BQ0000000woqf&Qvar0id=a0IQ0000004kwau?pv0=a3ZQ00000000QkhMAE';
		congaEmail +='&LG4=2&EmailAdditionalTo={Qvar0}'; //',{!Reference_MMS_Payroll__c.DSM_Email__c},{!Reference_MMS_Payroll__c.DSA_Email__c}';
		congaEmail +='&CongaEmailTemplateId=a1AQ0000006UrsN&DS0=1&DS4=1&DS7=2';							 
	} // fillmmsDocList 
	
	private void buildMMS(Map<Id, MMS_Onboarding_Documents__c> allMMSDocMap)
	{
		refMMS = [SELECT Id, Name, Case_Number__c, Opportunity_Name__c, ServerURL__c, DSM_Email__c, DSA_Email__c,
       			(SELECT Id, Name, Check_in_Date__c, Comments__c, MMS_Onboarding_Documents__r.Id, 
       			MMS_Onboarding_Documents__r.MPSC_Onboarding_Document__c, MMS_Onboarding_Documents__r.MMS_Payroll_Document__c,
       					 Document__c, Mandatory__c, Received_State__c, Discrepancy_Resolution_Date__c
       				FROM Reference_MMS_Payroll_Documents__r
       					 ORDER BY Mandatory__c DESC, Document__c ASC)
       				FROM Reference_MMS_Payroll__c WHERE Id = :refMMSid   
       					 LIMIT 1];
       	MMSDocumentWrapper dw;
		for (Reference_MMS_Payroll_Documents__c pd : refMMS.Reference_MMS_Payroll_Documents__r)
		{	dw = new MMSDocumentWrapper(pd);
			mmsDocList.add(dw);
			allMMSDocMap.remove(pd.MMS_Onboarding_Documents__r.Id); 
		} // for Reference_MMS_Payroll_Documents__c	
			
		// complete list with possible documents
		List<MMS_Onboarding_Documents__c> remainingDocs = allMMSDocMap.values();    //LM the docs left over after removal		
		for (MMS_Onboarding_Documents__c od:remainingDocs)					//LM prepare bucket items in case the document is added to the core payroll object
		{	dw = new MMSDocumentWrapper(refMMS, od);
			if (od.MMS_Payroll_Document__c)
			{
				mmsDocList.add(dw);
				allMMSDocMap.remove(od.Id);
			}
		} // for MMS_Onboarding_Documents__c
	}  
	
	/*LM
	private void buildMPSC(Map<Id, MMS_Onboarding_Documents__c> allMMSDocMap)
	{
     	refCore = [SELECT Id, Name, Case_Lookup__c, Opportunity_Lookup__c, Sales_Rep__c,
       		(SELECT Id, Name, Check_in_Date__c, Comments__c, MMS_Onboarding_Documents__r.Id, 
       		MMS_Onboarding_Documents__r.MPSC_Onboarding_Document__c, MMS_Onboarding_Documents__r.MMS_Payroll_Document__c,
       					 Document__c, Mandatory__c, Received_State__c, Discrepancy_Resolution_Date__c, Ref_Core_Payroll_Sales_Rep__c	
       				FROM Reference_MPSC_Onboarding_Documents__r
       					 ORDER BY Mandatory__c DESC, Document__c ASC)
       				FROM Reference_Core_Payroll__c WHERE Id = :refMMSid  
       					 LIMIT 1];			//returns the document objects that were created on the core payroll object.
       	MMSDocumentWrapper dw;
       	//loop through each document on this ref core payroll object, create a new wrapper bucket for each document
       	//add the wrapper to the mmsDocList and remove the doc id from the all Docs map
		for (Reference_MPSC_Onboarding_Document__c pd : refCore.Reference_MPSC_Onboarding_Documents__r)
		{	
			dw = new MMSDocumentWrapper(pd);
			mmsDocList.add(dw);
			allMMSDocMap.remove(pd.MMS_Onboarding_Documents__r.Id); //LM as the document is added to the object, remove it from the all documents list
		} // for Reference_MPSC_Onboarding_Document__c	
			
		// complete list with possible documents
		List<MMS_Onboarding_Documents__c> remainingDocs = allMMSDocMap.values();    //LM the docs left over after removal		
		for (MMS_Onboarding_Documents__c od:remainingDocs)					//LM prepare bucket items in case the document is added to the core payroll object
		{	
			dw = new MMSDocumentWrapper(refCore, od);
			if (od.MPSC_Onboarding_Document__c)
			{
				mmsDocList.add(dw);
				allMMSDocMap.remove(od.Id);
			}
		} // for MMS_Onboarding_Documents__c
	}*/
/*   
    // return list of required documents AND received documents
	public List<MMSDocumentWrapper> refDocList {        
        get  {
            List<MMSDocumentWrapper> refDocList = new List <MMSDocumentWrapper>();
            for (MMSDocumentWrapper dw : mmsDocList)  //for all of the docs attached to this object
            {	if (dw.selected )
            	{	refDocList.add(dw);	}
            }
            return refDocList;
        }
    } // refDocList   
 
    // return list of available documents not added to this reference object
	public List<MMSDocumentWrapper> newDocList {        
        get  {
	            List<MMSDocumentWrapper> newDocList = new List <MMSDocumentWrapper>();
	            for (MMSDocumentWrapper dw : mmsDocList)  //for all of the docs NOT attached to this object
	            {	if (!dw.selected )
	            	{	
	            		newDocList.add(dw);
	            	}	
	            }  
            return newDocList;
        }
    } // newDocList   
    
   /** If a user clicks a Selected checkbox, handle any changes that need to occur.
    */
/*	
    public PageReference markSelected()
    { 
    	for (MMSDocumentWrapper dw: mmsDocList)
    	{	
    		if(isMMS)
    		{
	    		if (dw.docId == selectedId)
			    {   if (!dw.doc.mandatory__c)
			    	{	dw.selected = (dw.selected ? false : true);		    	
			    		if (dw.selected && dw.docRcdType == 'NA' )      
			    		{	dw.docRcdType = 'upsert';
			    			dw.doc.Received_State__c = '-None-';
		        		}    
		        		else if (dw.selected && dw.docRcdType == 'delete')      
		    			{	dw.docRcdType = 'existing';
				    		dw.doc.Received_State__c = '-None-';			
		        		}    
		        		else if (!dw.selected && dw.docRcdType == 'existing')      
		    			{	dw.docRcdType = 'delete';
				            dw.doc.Received_State__c = '-None-';
		        		}    
		        		else if (!dw.selected && dw.docRcdType == 'upsert')      
		    			{	dw.docRcdType = 'NA';
				            dw.doc.Received_State__c = '-None-';
		        		}	        		
			    	} // if mandatory
			    	break;
			    }// if docId = selectedId
    		}//if MMS
			/*MPSC*/
		    /*LM
		    else
		    {
		    	if (dw.docId == selectedId)
			    {   if (!dw.MPSCdoc.mandatory__c)
			    	{	dw.selected = (dw.selected ? false : true);		    	
			    		if (dw.selected && dw.docRcdType == 'NA' )      
			    		{	dw.docRcdType = 'upsert';
			    			dw.MPSCdoc.Received_State__c = '-None-';   
		        		} 
		        		else if (dw.selected && dw.docRcdType == 'delete')      
		    			{	dw.docRcdType = 'existing';
				    		dw.MPSCdoc.Received_State__c = '-None-';  			
		        		}    
		        		else if (!dw.selected && dw.docRcdType == 'existing')      
		    			{	dw.docRcdType = 'delete';
				            dw.MPSCdoc.Received_State__c = '-None-'; 
		        		}    
		        		else if (!dw.selected && dw.docRcdType == 'upsert')      
		    			{	dw.docRcdType = 'NA';
				            dw.MPSCdoc.Received_State__c = '-None-'; 
		        		}	        		
			    	} // if mandatory
			    	break;
			    }//if docId = selectedId;
			}//else */  
/*			       
    	} // for
/*		
    	pgMsg = 'Changes Pending';
    	showMsg = true;
        return null;
    } // markSelected
   
      
   	/** If user changes a comment, mark as Upsert
	 */
/*	
	public PageReference saveComment() {				
		for (MMSDocumentWrapper dw: mmsDocList)		
		{	
			if(isMMS)
			{
				if ((dw.origCommentSize > 0 && dw.doc.Comments__c == null) || (dw.doc.Comments__c != null && dw.origCommentSize != dw.doc.Comments__c.length()))
				{	pgMsg = 'Changes Pending';
	    			showMsg = true;			
				}
			}
			/*LM
			else
			{
				if ((dw.origCommentSize > 0 && dw.MPSCdoc.Comments__c == null) || (dw.MPSCdoc.Comments__c != null && dw.origCommentSize != dw.MPSCdoc.Comments__c.length()))
				{	pgMsg = 'Changes Pending';
	    			showMsg = true;			
				}
			}*/
/*			
		}						
		return null;
	} // saveComment			
    
	/** If user changes a Received date, set Status and mark as Upsert
	 */
/*	
	public PageReference saveDate() {				
		for (MMSDocumentWrapper dw: mmsDocList)		
		{	
			if(isMMS)
			{
				if (dw.origDate != dw.doc.Check_In_Date__c && dw.doc.Check_In_Date__c != null)
				{	dw.doc.Received_State__c = 'Complete';
					dw.origDate = dw.doc.Check_In_Date__c;	
					dw.docRcdType = 'upsert';	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
	    		}
				else if ((dw.origDate != dw.doc.Check_In_Date__c && dw.doc.Check_In_Date__c == null))
				{	dw.doc.Received_State__c = '-None-';	
					dw.origDate = null;
					dw.docRcdType = 'upsert';	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}
			}
			/*LM
			else
			{
				if (dw.origDate != dw.MPSCdoc.Check_In_Date__c && dw.MPSCdoc.Check_In_Date__c != null)
				{	dw.MPSCdoc.Received_State__c = 'Complete';
					dw.origDate = dw.MPSCdoc.Check_In_Date__c;	
					dw.docRcdType = 'upsert';	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
	    		}
				else if ((dw.origDate != dw.MPSCdoc.Check_In_Date__c && dw.MPSCdoc.Check_In_Date__c == null))
				{	dw.MPSCdoc.Received_State__c = '-None-';	
					dw.origDate = null;
					dw.docRcdType = 'upsert';	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}
			}*/
/*			
		} // for mmsDocList
				
		return null;
	} // saveDate      

	/** If user changes a Received state, mark as Upsert
	 */
/*	
	public PageReference saveState() {	
		
				
		for (MMSDocumentWrapper dw: mmsDocList)		
		{	
			if(isMMS)
			{
				if (dw.origRcvState != dw.doc.Received_State__c)
				{	pgMsg = 'Changes Pending';
	    			showMsg = true;
	    		}
			}
			/*LM
			else
			{
				if (dw.origRcvState != dw.MPSCdoc.Received_State__c)
				{	pgMsg = 'Changes Pending';
	    			showMsg = true;
	    			if(dw.MPSCdoc.Received_State__c == 'Discrepancy')
	    			{ 
						isDiscrepancy = true;
						salesRepId = (ID)dw.salesRep;
						refCorePayrollObject = dw.MPSCdoc.Reference_Core_Payroll_field__c;
	    			}
	    		}
			}*/
/*			
		}				
		return null;
	} // saveDate      
   
	/** If user changes a Resolution date, mark as Upsert
	 */
/*	
	public PageReference saveResolutionDate() {				
		for (MMSDocumentWrapper dw: mmsDocList)		
		{	
			if(isMMS)
			{
				if (dw.origResolutionDate != dw.doc.Discrepancy_Resolution_Date__c && dw.doc.Discrepancy_Resolution_Date__c != null)
				{	dw.doc.Received_State__c = 'Resolved';	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}
				else if (dw.origResolutionDate != dw.doc.Discrepancy_Resolution_Date__c && dw.doc.Discrepancy_Resolution_Date__c == null)
				{	dw.doc.Received_State__c = 'Discrepancy';
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}  
			}
			//for MPSC
			/*LM
			else
			{
				if (dw.origResolutionDate != dw.MPSCdoc.Discrepancy_Resolution_Date__c && dw.MPSCdoc.Discrepancy_Resolution_Date__c != null)
				{	
					//system.debug('LM - date is now ' + dw.MPSCdoc.Document__c + ' ' + dw.MPSCdoc.Discrepancy_Resolution_Date__c);
					dw.MPSCdoc.Received_State__c = 'Resolved';	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}
				else if (dw.origResolutionDate != dw.MPSCdoc.Discrepancy_Resolution_Date__c && dw.MPSCdoc.Discrepancy_Resolution_Date__c == null)
				{	
					//system.debug('LM - date is null' + dw.MPSCdoc.Document__c);
					dw.MPSCdoc.Received_State__c = 'Discrepancy';
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}  
				
			}*/  
/*					
		}		

		return null;
	} // saveDate      
   
   	/** If user clicks Resolve All to resolve any existing discrepancies setting date to today
	 */
/*	
	public PageReference resolveAll() {				
		for (MMSDocumentWrapper dw: mmsDocList)		
		{	
			if(isMMS)
			{
				if (dw.doc.Received_State__c == 'Discrepancy')
				{	dw.doc.Received_State__c = 'Resolved';
					dw.doc.Discrepancy_Resolution_Date__c = System.today(); 	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}
			}
			//for MPSC
			/*LM
			else
			{
				if (dw.MPSCdoc.Received_State__c == 'Discrepancy')
				{	dw.MPSCdoc.Received_State__c = 'Resolved';
					dw.MPSCdoc.Discrepancy_Resolution_Date__c = System.today(); 	
					pgMsg = 'Changes Pending';
	    			showMsg = true;
				}
			}*/
/*			
		}				
		return null;
	} // resolveAll
  
	/** If user clicks Send Email, make sure no changes are pending and there are no errors
	 */
/*	
	public PageReference sendEmail() {
		if (pgMsg == 'Changes Pending' || congaOK == 'N')		
		{	pgMsg += '. Please click Save before Send Email!';
    		showMsg = true;
    		congaOK = 'N';    		
 		}
 		return null;		
	} // sendEmail      
   
   
    public PageReference saveDocs() {    	
		List<Reference_MMS_Payroll_Documents__c> upsertMMSDocs = new List<Reference_MMS_Payroll_Documents__c>();
		List<Reference_MMS_Payroll_Documents__c> deleteMMSDocs = new List<Reference_MMS_Payroll_Documents__c>();
	//LM	List<Reference_MPSC_Onboarding_Document__c> upsertMPSCDocs = new List<Reference_MPSC_Onboarding_Document__c>();
	//LM	List<Reference_MPSC_Onboarding_Document__c> deleteMPSCDocs = new List<Reference_MPSC_Onboarding_Document__c>();
		Boolean okay = true;
		String msg = null;
		congaOK = 'N';
		
		if(isMMS) 
		{
			for (MMSDocumentWrapper dw : mmsDocList)
			{	if (MMSDocumentWrapper.RCVD_STATE_SET.contains(dw.doc.Received_State__c) && dw.doc.Check_in_Date__c == null)
				{	okay = false;
					msg = 'MMS Document Error: '+dw.doc.Document__c+' missing Check In Date.';
				}	
				else if (dw.doc.Received_State__c == 'Resolved' && dw.doc.Discrepancy_Resolution_Date__c == null)
				{	okay = false;
					msg = 'MMS Document Error: '+dw.doc.Document__c+' missing Resolution Date.';
				}				
				else if (dw.isChanged || dw.docRcdType == 'upsert')
				{	upsertMMSDocs.add(dw.doc);	}
				else if (dw.docRcdType == 'delete')
				{	deleteMMSDocs.add(dw.doc);	}
			}
		}
		/*LM
		else
		{
			for (MMSDocumentWrapper dw : mmsDocList)
			{
				if (MMSDocumentWrapper.RCVD_STATE_SET.contains(dw.MPSCdoc.Received_State__c) && dw.MPSCdoc.Check_in_Date__c == null)
				{	okay = false;
					msg = 'MPSC Document Error: '+dw.MPSCdoc.Document__c+' missing Check In Date.';
				}	
				else if (dw.MPSCdoc.Received_State__c == 'Resolved' && dw.MPSCdoc.Discrepancy_Resolution_Date__c == null)
				{	okay = false;
					msg = 'MPSC Document Error: '+dw.MPSCdoc.Document__c+' missing Resolution Date.';
				}				
				else if (dw.isChanged || dw.docRcdType == 'upsert')
				{	upsertMPSCDocs.add(dw.MPSCdoc);	}
				else if (dw.docRcdType == 'delete')
				{	deleteMPSCDocs.add(dw.MPSCdoc);	}
			}
			//for MPSCif there is a dispcrepancy with any of the paperwork, create a chatter post
			if (isDiscrepancy && okay)
			{
				List<ID> ids = new List<ID>();
				ids.add(salesRepId);
				String stringBody = 'There is a discrepancy with one or more of the documents:\n\n';
				for(MMSDocumentWrapper dw: mmsDocList){
					if(dw.MPSCDoc.Document__c!=null && dw.MPSCDoc.Comments__c != null && dw.MPSCdoc.Received_State__c=='Discrepancy'){
						stringBody+='Document: '+dw.MPSCdoc.Document__c+'\nDiscrepancy Comments: '+dw.MPSCdoc.Comments__c+'\n\n';
					}
					system.debug('dList'+discrepancyInfoSet);
				}
				
				chatterMentionPost.createChatterMentionPost(refCorePayrollObject, ids, stringBody); 
				isDiscrepancy = false;
			}
		}*/
/*		
		if (okay)
		{	if (!upsertMMSDocs.isEmpty())
			{	List<Database.UpsertResult> uResults = Database.upsert(upsertMMSDocs);				
				for (Integer cnt=0; cnt<uResults.size(); cnt++) 
				{	Database.UpsertResult result = uResults.get(cnt);
					msg = getSaveMsg('MMS Documents', result.isSuccess(), result.getErrors());
				}
			} // upsert isEmpty
		
			if (!deleteMMSDocs.isEmpty())
			{	List<Database.DeleteResult> dResults = Database.delete(deleteMMSDocs);			
				for (Integer cnt=0; cnt<dResults.size(); cnt++) 
				{	Database.DeleteResult result = dResults.get(cnt);
					msg = getSaveMsg('MMS Documents', result.isSuccess(), result.getErrors());
				}
			} // delete isEmpty
			/*LM
			if (!upsertMPSCDocs.isEmpty())
			{	List<Database.UpsertResult> uResults = Database.upsert(upsertMPSCDocs);				
				for (Integer cnt=0; cnt<uResults.size(); cnt++) 
				{	Database.UpsertResult result = uResults.get(cnt);
					msg = getSaveMsg('MPSC Document', result.isSuccess(), result.getErrors());
				}
			} // upsert isEmpty
		
			if (!deleteMPSCDocs.isEmpty())
			{	List<Database.DeleteResult> dResults = Database.delete(deleteMPSCDocs);			
				for (Integer cnt=0; cnt<dResults.size(); cnt++) 
				{	Database.DeleteResult result = dResults.get(cnt);
					msg = getSaveMsg('MPSC Document', result.isSuccess(), result.getErrors());
				}
			} // delete isEmpty
			*/
/*			
			if ((msg == null) ||
				(msg != null && msg.contains('Successfully Saved')))
			{	fillmmsDocList();	}
			else
			{	okay = false;	}
		} // if okay
		
		congaOK = (okay ? 'Y' : 'N');
		pgMsg = msg;
		showMsg = true;		
		
		return null;
    } // saveDocs
              
    private String getSaveMsg(String prefix, Boolean isSuccess, Database.Error[] errors) {
        String msg = prefix;
        if (isSuccess) {
            msg += ' Successfully Saved!';
        } else {
            msg += ' Encountered an Error: ';
            for (Database.Error err : errors) {
               msg += err.getMessage();
            }
        } // if
        System.debug('getSaveMsg msg='+msg);
        return msg;
   } // getSaveMsg

	public PageReference cancelDocs() {
		// repull document info without saving anything
		fillmmsDocList();
		// clear page message
		pgMsg = '';
		showMsg = false;
		congaOK = 'Y';
		return null;
	} // cancelDocs

/*	private String buildCongaUrl() {
		// get conga merge url		
		String cEmail = '';
		List<CongaURLs__c> allValues = CongaURLs__c.getall().values();
   	  	for (CongaURLs__c curl : allValues) {
   	  		if (curl.Name == 'MMSdiscrepancy')
   	  		{	cEmail = curl.url1__c + curl.url2__c + curl.url3__c;	}
   	  	}
 System.debug('**CMF ** orig cEmail='+cEmail);
   	  	// replace variables in string with real values
 		String sessionID = UserInfo.getSessionId(); 
 		String tempStr = sessionId.replace('!','%21');		
   	  	cEmail = cEmail.replace('{!API.Session_ID}', tempStr);
   	  	tempStr = refMMS.ServerURL__c;
   	  	tempStr = Utilities.cleanUrl(tempStr, 'i');   	  	
   	  	tempStr = tempStr.replace(': ', '%3A');
   	  	tempStr = tempStr.replaceAll('/','%2F');   	  	
   	  	cEmail = cEmail.replace('{!API.Partner_Server_URL_80}', tempStr);
   	  	cEmail = cEmail.replace('{!Reference_MMS_Payroll__c.Id}', refMMS.Id);
   	  	tempStr = (refMMs.DSM_Email__c != null ? refMMS.DSM_Email__c.replace('@','%40') : ' ');
   	  	cEmail = cEmail.replace('{!Reference_MMS_Payroll__c.DSM_Email__c}', tempStr);
   	  	tempStr = (refMMs.DSA_Email__c != null ? refMMS.DSA_Email__c.replace('@','%40') : ' ');
   	  	cEmail = cEmail.replace('{!Reference_MMS_Payroll__c.DSA_Email__c}', tempStr);
System.debug('**CMF ** cEmail='+cEmail);   	  	
   	  	return cEmail;
	} // buildCongaURL
*/
	
}