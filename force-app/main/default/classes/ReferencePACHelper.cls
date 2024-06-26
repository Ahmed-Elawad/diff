/*  Update the Reference PAC. 
*
*  History 
*  -------
*  10/12/2017 Frank Lurz        created 
*  10/12/2017 Frank Lurz        Phase 2 changes for BAU Case #27864415 
*  12/12/2019 Jake Hinds        Change for client number, INC2219726
*  08/31/2021 Eric Porter       Mapping removal, APR0124301
*
*/

public with sharing class ReferencePACHelper {
        /** Update the Reference PAC record with data from a related Client & Field Submission record    */
        public static void updateRefPACviaCFS(List<Reference_PAC__c> refPACList) {
            /*
             Id additionalDuplicate;
             Id missingFieldContact;
             Id noClientMatch;
             List<Reference_PAC_Queues__c> pacQueueList = null;    
             pacQueueList = Reference_PAC_Queues__c.getall().values();   
             for (Reference_PAC_Queues__c xrpq: pacQueueList) {
                    if (xrpq.name == 'PAC Group Additional/Duplicate') 
                    {   additionalDuplicate = xrpq.Queue_ID__c;  }
                    
                    if (xrpq.name == 'PAC Group Missing Field Contact') 
                    {   missingFieldContact = xrpq.Queue_ID__c;  }
                
                    if (xrpq.name == 'PAC Group No Client Match') 
                    {   noClientMatch = xrpq.Queue_ID__c;  }
                }         
            */
            datetime nowDateTime = datetime.now();
            set<string> CltFldSubmitIDSet = new set<string>();
            List<attachment> attToUpdatee = new List<attachment>();
            for(Reference_PAC__c refPAC : refPACList){
                system.debug('FRL in the 1st for loop of updateRefPACviaCFS -- refPAC.id = ' + refPAC.id);
                CltFldSubmitIDSet.add(refPAC.ClientFieldSubmissionId__c);      
            }
            List<Client_Field_Submission__c> CFSList = [Select id, 
                                                        Ref_PAC_Case__c,
                                                        CFS_Insensitive_ID__c,
                                                        Business_Name__c,
                                                        Government_Tax_Agency__c,
                                                        Tax_Form__c,
                                                        Notice_Type__c,
														Total_Amount_Due_per_Notice__c,
                                                        Submitters_Name__c,
                                                        Email__c,
                                                        Phone_Number__c,
                                                        Fax_Number__c,
                                                        Main_Contact_Name__c,
                                                        Main_Contact_Email__c,
                                                        Main_Contact_Phone_Number__c,
                                                        Main_Contact_Fax_Number__c,
                                                        Additional_Notes__c,
														Date_Notice_was_Issued__c,
														Date_Company_Started_with_Paychex__c,
														Do_we_have_approval_to_collect_and_pay__c,
														Was_a_submission_for_this_agency_issue__c,
														Agency_ID_if_differentthanFederalID__c,
														Current_Past_Paychex_PEO_Client__c,
                                                        (select id from attachments)
                                                        from Client_Field_Submission__c
                                                        where CFS_Insensitive_ID__c in :CltFldSubmitIDSet];
            Map<id,Client_Field_Submission__c> CFSMap = new Map<id,Client_Field_Submission__c>();
            
            for(Client_Field_Submission__c CFS : CFSList){
                CFSMap.put(CFS.CFS_Insensitive_ID__c,CFS);
            }  
                                                                        
            for(Reference_PAC__c  refPAC : refPACList) {
                if(refPAC.ClientFieldSubmissionId__c != NULL){
                    if(!CFSMap.get(refPAC.ClientFieldSubmissionId__c).attachments.isEmpty()){
                        for(attachment att : CFSMap.get(refPAC.ClientFieldSubmissionId__c).attachments){
                            system.debug('FRL in the 3rd for loop of updateRefPACviaCFS -- refPAC.ClientFieldSubmissionId__c = ' + refPAC.ClientFieldSubmissionId__c);
                            system.debug('FRL in the 3rd for loop of updateRefPACviaCFS -- refPac.id = ' + refPac.id);
                        }
                    }
                    refPAC.Date_1st_Notice_Received_in_PAC__c = system.today();
                    refPAC.Original_Notice_Submission_By__c = 'Client/Other';
                    
                    refPAC.Tax_Agency__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Government_Tax_Agency__c;
                    if(CFSMap.get(refPAC.ClientFieldSubmissionId__c).Tax_Form__c=='1099 – Misc. Income')
                    refPAC.Tax_Type__c = 'SSA - W2/941 DISCREPANCY';
                    else if(CFSMap.get(refPAC.ClientFieldSubmissionId__c).Tax_Form__c=='1094/1095 - Health/ACA/ESR')
                    refPAC.Tax_Type__c = 'ACA/ESR Issue';
                    else
                    refPAC.Tax_Type__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Tax_Form__c;
                    refPAC.Ticket_Type__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Notice_Type__c;
                    refPAC.Submission_Notes__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Additional_Notes__c;
                    refPAC.Client_Reported_Notice_Balance__c=CFSMap.get(refPAC.ClientFieldSubmissionId__c).Total_Amount_Due_per_Notice__c;
 if(CFSMap.get(refPAC.ClientFieldSubmissionId__c).Total_Amount_Due_per_Notice__c!=null&&(CFSMap.get(refPAC.ClientFieldSubmissionId__c).Notice_Type__c=='Tax Lien/Levy/Warrant'||CFSMap.get(refPAC.ClientFieldSubmissionId__c).Notice_Type__c=='Balance Due Notice (includes Estimated/Proposed Assessments)'))

                    refPAC.Total_Balance_Due_for_Notice__c=CFSMap.get(refPAC.ClientFieldSubmissionId__c).Total_Amount_Due_per_Notice__c;

                    refPAC.Date_Notice_Issued__c=CFSMap.get(refPAC.ClientFieldSubmissionId__c).Date_Notice_was_Issued__c;
					refPAC.Client_Provided_Paychex_Start_Date__c=CFSMap.get(refPAC.ClientFieldSubmissionId__c).Date_Company_Started_with_Paychex__c;
					refPAC.Agency_ID_Number__c	=CFSMap.get(refPAC.ClientFieldSubmissionId__c).Agency_ID_if_differentthanFederalID__c;
					refPAC.Did_submitter_indicate_this_is_an_additi__c	=CFSMap.get(refPAC.ClientFieldSubmissionId__c).Was_a_submission_for_this_agency_issue__c;					
					refPAC.Submitter_approved_collection__c		=CFSMap.get(refPAC.ClientFieldSubmissionId__c).Do_we_have_approval_to_collect_and_pay__c;
					
                    /*** check the related Account for the Account Number and the Paychex_Payroll_Specialist__c ***/
                    if (refPAC.Account_Lookup__c != NULL) {
                         Account acctnumpps = getAcct(refPAC.Account_Lookup__c);
                         if (acctnumpps != NULL) {
                            if (String.isNotBlank(acctnumpps.AccountNumber)) {
                                String nbr = (acctnumpps.AccountNumber.contains('-') ? acctnumpps.AccountNumber.substringBefore('-'): null);
                                refPAC.Branch_Nbr__c = (nbr!=null?Decimal.valueOf(nbr):null);
                                system.debug('FRL-codesyntaxissue-acctnumpps.AccountNumber = ' + acctnumpps.AccountNumber);
                                refPAC.Client_Number__c = (acctnumpps.AccountNumber.contains('-') ? acctnumpps.AccountNumber.substringAfter('-'): null);
                                /***refPAC.FEIN__c = acctnumpps.Federal_ID_Number__c.replaceAll('-','');***/
                                refPAC.FEIN__c = acctnumpps.Federal_ID_Number__c;
                            }
                            if (acctnumpps.Paychex_Payroll_Specialist__c != NULL) {
                                (refPAC.Field_Contact_Name__c = acctnumpps.Paychex_Payroll_Specialist__c);
                            }
                         }// if (acctnumpps != NULL
                    } // if (refPAC.Account_Lookup__c != NULL
                    
                    
                    /* *    determine if CFS.Email__c's Domain = paychex.com in order to populate RefPAC.Field Contact field ( Lookup(Contact) )   * */
                    Boolean submitterEmailIsPaychex = false;
                    system.debug('FRL in the checking of CFS.Email__c domain. The submitterEmailIsPaychex value RIGHT AFTER INITIALIZATION -- ' + submitterEmailIsPaychex);
                    Set<String> emailDomain = new Set<String>();
                    emailDomain.add((CFSMap.get(refPAC.ClientFieldSubmissionId__c).Email__c).split('@').get(1));
                    system.debug('FRL in the checking of CFS.Email__c domain. The emailDomain value -- ' + emailDomain);
                    if (emailDomain != NULL) {
                         submitterEmailIsPaychex=emailDomain.contains('paychex.com');
                         system.debug('FRL in the checking of CFS.Email__c domain. The submitterEmailIsPaychex value -- ' + submitterEmailIsPaychex);
                         /***  NEED TO FIND THE CONTACT RECORD BASED ON THE (CFSMap.get(refPAC.ClientFieldSubmissionId__c).Email__c)***/
                         Contact tempContact = getPayxEEcontact(CFSMap.get(refPAC.ClientFieldSubmissionId__c).Email__c);
                         if ( (submitterEmailIsPaychex) && (tempContact != NULL) ) {
                              /*  NEED TO FIND THE CONTACT RECORD BASED ON THE (CFSMap.get(refPAC.ClientFieldSubmissionId__c).Email__c)  */
                              /*** MOVING THIS UP -- Contact tempContact = getPayxEEcontact(CFSMap.get(refPAC.ClientFieldSubmissionId__c).Email__c); ***?
                              /***if (tempContact != NULL) ***/
                                   system.debug('FRL in the checking of submitterEmailIsPaychex. The tempContact.id value -- ' + tempContact.id);
                                   refPAC.Field_Contact_Name__c = tempContact.id;
                                   refPAC.Original_Notice_Submission_By__c = 'Paychex Employee';
                              /*** END OF if (tempContact != NULL) ***/
                         }
                         else {
                           /*** move the Submitters_Name__c, Email__c, Phone_Number__c and Fax_Number__c to the Reference PAC.Client Contact fields ***/
                           /*** later on, if the CFS.Main Contact fields are populated, will simply overwrite the Reference PAC.Client Contact fields ***/

                           refPAC.Client_Contact_Name__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Submitters_Name__c;
                           refPAC.Client_Contact_Email__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Email__c;
                           refPAC.Client_Contact_Phone__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Phone_Number__c;
                           
                           /*** without a populated Field_Contact_Name__c or Paychex_Payroll_Specialist__c, need to assign Owner = PAC Group Missing Field Contact  queue ***/
                           if (refPAC.Field_Contact_Name__c == NULL) {
                                (refPAC.OwnerId = Label.PACmissingFieldContact);
                                (refPAC.Primary_Assignment_Group__c = 'TEMP VALUE - PLEASE DELETE-Missing Field Contact');
                           }
                           
                         }
                    }   /* * *  END OF determine if CFS.Email__c's Domain = paychex.com    * * */

                    /*** Now check if the CFS Main Contact fields were populated - if so, populate the Reference PAC.Client Contact fields ***/
                    if (CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Name__c != NULL) {
                         refPAC.Client_Contact_Name__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Name__c;
                    }

                    if (CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Email__c != NULL) {
                         refPAC.Client_Contact_Email__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Email__c;
                    }

                    if (CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Phone_Number__c != NULL) {
                         refPAC.Client_Contact_Phone__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Phone_Number__c;
                    }

                    if (CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Fax_Number__c != NULL) {
                         refPAC.Client_Contact_Fax__c = CFSMap.get(refPAC.ClientFieldSubmissionId__c).Main_Contact_Fax_Number__c;
                    }

                    
                    
                    /* * *  convert specific Client & Field Submission field /picklist values to Reference PAC field /picklist values    * * */
                    if (refPAC.Tax_Agency__c != NULL) {
                         if (refPAC.Tax_Agency__c == 'SSA - Social Security Administration') {
                              (refPAC.Tax_Agency__c = ' IRS - INTERNAL REVENUE SERVICE' );
                              system.debug('FRL in the convert CFS.Government_Tax_Agency__c to a refPAC.Tax_Agency__c picklist value -- ' + refPAC.Tax_Agency__c);
                         }
                    }
                    
                    if (refPAC.Tax_Type__c != NULL) {
                         if (refPAC.Tax_Type__c == 'Department of Income/Withholding Tax' ) {
                              (refPAC.Tax_Type__c = 'State-Withholding' );
                              system.debug('FRL in the 1st convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == 'Department of Revenue' ) {
                              (refPAC.Tax_Type__c = 'State-Withholding' );
                              system.debug('FRL in the 2nd convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == 'Department of Tax/Taxation/Finance' ) {
                              (refPAC.Tax_Type__c = 'State-Withholding' );
                              system.debug('FRL in the convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == 'Department of Unemployment Assistance/Insurance' ) {
                              (refPAC.Tax_Type__c = 'SUI-Unemployment' );
                              system.debug('FRL in the 3rd convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == 'Department of Labor/Industries/Employment Services' ) {
                              (refPAC.Tax_Type__c = 'SUI-Unemployment' );
                              system.debug('FRL in the convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == 'Department of Jobs/Training/Workforce' ) {
                              (refPAC.Tax_Type__c = 'SUI-Unemployment' );
                              system.debug('FRL in the convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == 'Department of Employer Tax/Employment Security' ) {
                              (refPAC.Tax_Type__c = 'SUI-Unemployment' );
                              system.debug('FRL in the 4th convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == '1040 - Individual Income Tax' ) {
                              (refPAC.Tax_Type__c = 'SSA - W2/941 DISCREPANCY' );
                              system.debug('CLM in convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }
                    else
                         if (refPAC.Tax_Type__c == 'Other' ) {
                              (refPAC.Tax_Type__c = 'Local/Other' );
                              system.debug('FRL in the 5th convert CFS.Tax_Form__c to a refPAC.Tax_Type__c picklist value -- ' + refPAC.Tax_Type__c);
                         }     
                    }
                    /* * *   END OF convert specific Client & Field Submission field /picklist values to Reference PAC field /picklist values     * * */


                    /***   check if there's an existing Reference PAC record with the same Account_Lookup__c, Tax_Agency__c and Tax_Type__c  ***/
                    /***   if so, then need to reassign Owner to the PAC Group Additional/Duplicate queue (00GS00000025QCp)     ***/
                    //List<Reference_PAC__c> DuplicRefPACList = [Select id, name, tax_agency__c from Reference_PAC__c where Account_Lookup__c = :refPAC.Account_Lookup__c and tax_agency__c = :refPAC.tax_agency__c];
                    if (refPAC.Account_Lookup__c != NULL) {
                        List<Reference_PAC__c> DuplicRefPACList = [Select id, name, tax_agency__c, tax_type__c from Reference_PAC__c where Account_Lookup__c = :refPAC.Account_Lookup__c and tax_agency__c = :refPAC.tax_agency__c and tax_type__c = :refPAC.tax_type__c];
                        system.debug('FRL in the updateRefPACviaCFS method -- refPAC.Account_Lookup__c =' + refPAC.Account_Lookup__c);
                        system.debug('FRL in the updateRefPACviaCFS method -- refPAC.tax_agency__c =' + refPAC.tax_agency__c);
                        system.debug('FRL in the updateRefPACviaCFS method -- DuplicRefPACList.Size() =' + DuplicRefPACList.Size());
                        if (DuplicRefPACList.Size() > 0) {
                            (refPAC.OwnerId = Label.PACadditionalDuplicate);
                            (refPAC.Primary_Assignment_Group__c = 'TEMP VALUE - PLEASE DELETE-Additional/Duplicate' );
                        }
                    } // if (refPAC.Account_Lookup__c != NULL)


                    /***   check if there's a Reference PAC record with a NULL Account_Lookup__c  ***/
                    /***   if so, then need to reassign Owner to the PAC Group No Client Match queue (00GS00000025XeR)     ***/
                    if (refPAC.Account_Lookup__c == NULL) {
                         refPAC.OwnerId = Label.PACnoClientMatch;
                         (refPAC.Primary_Assignment_Group__c = 'TEMP VALUE - PLEASE DELETE-No Client Match' );
                    }


                    /***   check if the Reference PAC record should be marked as a High Revenue Client   ***/
                    if (refPAC.Account_Lookup__c != NULL) {
                         Boolean highRevAcct = false;
                         highRevAcct = checkhighRev(refPAC.Account_Lookup__c);
                                if (highRevAcct) {
                                     (refPAC.PAC_High_Revenue_Client__c = 'Yes');
                                     if (refPAC.Primary_Assignment_Group__c == NULL) {
                                          (refPAC.OwnerId = Label.PAChighRevClient);
                                          (refPAC.Primary_Assignment_Group__c = 'PAC – High Revenue' );
                                          (refPAC.Prompt_New_Submission_Email__c = nowDateTime);
                                     }
                                }
                    }

                } //if(refPAC.ClientFieldSubmissionId__c != NULL
                
            } //for(Reference_PAC__c
                                                                                                
        } //updateRefPACviaCFS                                                               


        /**  Copy any attachments from Client & Field Submission record to the newly created/related Reference PAC record   **/
        public static void copyCFSattchmntstoRefPAC(List<Reference_PAC__c> refPACList) {
            set<string> CltFldSubmitIDSet = new set<string>();
            for(Reference_PAC__c refPAC : refPACList){
                CltFldSubmitIDSet.add(refPAC.ClientFieldSubmissionId__c);     
            }
            List<Attachment> AttchList = [Select id, parentid, name, body from Attachment where parentid in :CltFldSubmitIDSet];
     
            List<Attachment> AttachToInsert = new list<Attachment>();           
            for(Attachment Att : AttchList){
                for(Reference_PAC__c  refPAC : refPACList){
                    if(Att.parentId == refPac.ClientFieldSubmissionId__c){
                        AttachToInsert.Add(New attachment(parentId=refPac.Id, body=att.body, name=att.name));
                    }
                } //for                    
            } //for
            
            if(!AttachToInsert.isEmpty()){
                insert AttachToInsert;
            }  
                                                                                                
        } //copyCFSattchmntstoRefPAC

     /**  query for Paychex employee contact   **/
      private static Contact getPayxEEcontact(String emailAddr) {
      Contact ctct;
      Contact[] ctctList =  [Select Id from Contact where Account.Name like 'Paychex Inc SA%' and HR_Person_Id__c != NULL and Email = :emailAddr LIMIT 1];
      If (!ctctList.isEmpty() && ctctList.size() > 0)
      {              ctct = ctctList.get(0);       }
      Else
      {              ctct = null;           }
      Return ctct;
    }// getPayxEEcontact

    
     /**  query for Account Number and Paychex Payroll Specialist contact   **/
      private static Account getAcct(String acctID) {
      Account akkt;    
      Account[] akktList =  [Select Id, AccountNumber, Payroll_Branch_Nbr__c, Federal_ID_Number__c, Paychex_Payroll_Specialist__c from Account where Id = :acctID];
      If (!akktList.isEmpty() && akktList.size() > 0)
      {              akkt = akktList.get(0);       }
      Else
      {              akkt = null;           }
      Return akkt;
    }// getAcct

     /**  query for Account Team Role to set High Revenue   **/
      private static Boolean checkhighRev(String acctID) {
      Boolean highRevClient = false;
      Account akktt;    
      Account[] akkttList =  [Select Id, Name
                               From Account
                          Where Id in (Select AccountId
                                         From AccountTeamMember
                                        Where AccountId = :acctID and TeamMemberRole = 'Relationship Manager')
                            and Id = :acctID];
      If (!akkttList.isEmpty() && akkttList.size() > 0)
      {              highRevClient = true;       }
      Return highRevClient;
    }// checkhighRev
    
} //ReferencePACHelper