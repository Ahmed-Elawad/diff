/* 
 * Create a reference object on creation of a case.
 *
 * History
 * -------
 * 06/30/2010 Dan Carmen   Created
   02/21/2011 Dan Carmen   Added the Credit Risk object
   03/02/2011 Dan Carmen/Michelle Brown - Added the Client Relations
   06/10/2011 Michelle Brown added Platinum (revised Oct23, 2011)
   09/15/2011 Dan Carmen   Added PEO
   10/17/2011 Michelle Brown Add 401k MM Changes
   11/14/2011 Carrie Marciano added Service HRO BeneTrac Integration record type check
   11/17/2011 Dan Carmen   Change to use DmlHelper from SObjectHelper
   03/27/2012 Carrie Marciano changed HRO NCT to HRO LCT
   07/03/2012 Justin Stouffer Added the Service Support TAA Case Record Type Change
   01/03/2013 Justin Henderson Added the PEO Existing Client Record Type
   01/16/2013 Justin Stouffer Added the Service Onboarding PEM Record Type (ExpenseWire)
   02/26/2013 Frank Lurz  Added Service Onboarding 401k Large Market New Case 
   03/20/2013 Josh Cartwright added Reference Payroll Fulfillment and Reference Terms/Transfers
   10/13/2015 Jacob Hinds    Removing Platinum Object
   10/29/2015 Lynn Michels added DSA_FSS__c to query and use that to populate DSA__c for Reference Core Payroll
   12/05/2015 Lynn Michels added  Opportunity__r.Product_Summary__c to populate for MPSC documents on Reference Core Payroll objects
   12/16/2015 Cindy Freeman		using Opportunity Spanish Speaking Needs to set Spanish Speaking Needs checkbox on ref cor payroll
   02/01/2017 Lynn Michels	commented out creation of ref object for case RT Service Onboarding S125 New Case
   10/26/2018 Dan Carmen   Increment API to version 44
   04/09/2020 Dan Carmen   Remove call to AccountHelper for RecordType
   09/01/2021 Carrie Marciano  Removed the Credit Risk object due to uninstalling Equifax package
   1/12/2023 Susmitha Somavarapu APR0143795-ATC Case to allow for HNBF Enrollments
   9/26/2023  Eric Porter APR0156132 called for a new reference Object(General_Inquiry_HRRT_Tracker__c) to be created
  */
public without sharing class CaseCreateReference {
  public static void createReference(Id[] caseIds) {
    List<Case> cases = new List<Case>(
      [
        SELECT
          Id,
          AccountId,
          OwnerId,
          Owner.Name,
          ContactId,
          RecordTypeId,
          RecordType.Id,
          RecordType.Name,
          Subject,
          Current_Step__c,
          Type,
          ParentID,
          Product__c,
          Termination_Transfer_Type__c,
          Opportunity__c,
          Opportunity__r.Name,
          Opportunity__r.AccountId,
          Opportunity__r.Service_Location__c,
          Opportunity__r.OwnerId,
          Opportunity__r.Owner.DSA_FSS__c,
          Opportunity__r.Owner.ManagerId,
          Opportunity__r.CloseDate,
          Opportunity__r.RecordTypeId,
          Opportunity__r.RecordType.Name,
          Opportunity__r.Product_Summary__c,
          Opportunity__r.Spanish_Speaking_Needs__c
        FROM Case
        WHERE Id IN :caseIds
      ]
    );

    List<Reference_TAA__c> refTAAs = new List<Reference_TAA__c>();
    List<Reference_HRO__c> refHROs = new List<Reference_HRO__c>();
    List<Reference_401k_S125__c> ref401s = new List<Reference_401k_S125__c>();
    List<Reference_GL__c> refGLs = new List<Reference_GL__c>();
    List<Reference_Client_Relations__c> refCltRltns = new List<Reference_Client_Relations__c>();
    Reference_Core_Payroll__c[] refCorePays = new List<Reference_Core_Payroll__c>{};
    Reference_PEO__c[] refPEOs = new List<Reference_PEO__c>{};
    List<Reference_Payroll_Fulfillment__c> refPayFulfill = new List<Reference_Payroll_Fulfillment__c>();
    List<Reference_Terms_Transfers__c> refTermTrans = new List<Reference_Terms_Transfers__c>();
    List<General_Inquiry_HRRT_Tracker__c> hrrtTrackers = new List<General_Inquiry_HRRT_Tracker__c>();

    for (Case c : cases) {
      if (
        (c.Subject == null) ||
        ((c.Subject != null) &&
        !c.Subject.contains('HRO Onboarding Reference Case'))
      ) {
        if (c.RecordType.Name == 'Service Onboarding TAA Case2') {
          addReferenceTAA(
            refTAAs,
            c,
            'Service TAA Onboarding Case Page Layout 3'
          );
        } else if (
          c.RecordType.Name == 'Service Support TAA Case' &&
          c.Subject == 'TLO Onboarding Complete - Graduate to Support' &&
          c.ParentId != null
        ) {
          List<Reference_TAA__c> rTAAList = [
            SELECT Id, Support_Case_Lookup__c
            FROM Reference_TAA__c
            WHERE
              Case_Lookup__c = :c.ParentId
              AND recordtype.name = 'Reference TAA Support Record Type'
          ];
          if (rTAAList.size() == 1) {
            Reference_TAA__c rTAA = rTAAList.get(0);
            rTAA.Support_Case_Lookup__c = c.id;
            update rTAA; //Creates a lookup to the TAA Support Case from the TAA Support Ref Object
          }
        } else if (
          c.RecordType.Name == 'Service Onboarding HRO Case Record Type'
        ) {
          addReferenceHRO(refHROs, c, 'Service Onboarding HRO Ref Object');
        } else if (
          c.RecordType.Name == 'Service HRO BeneTrac Integration Record Type'
        ) {
          addReferenceHRO(
            refHROs,
            c,
            'Service HRO BeneTrac Integration Ref Obj'
          );
        } else if (
          c.RecordType.Name == 'Service Onboarding PEM Case Record Type'
        ) {
          addReferenceHRO(refHROs, c, 'Service Onboarding PEM Ref Object');
        } else if (
          c.RecordType.Name == 'Service Onboarding EAO Case Record Type'
        ) {
          addReferenceHRO(refHROs, c, 'Service Onboarding EAO Ref Object');
        } else if (
          c.RecordType.Name == 'Service Onboarding W2 Only Case Record Type'
        ) {
          addReferenceHRO(refHROs, c, 'Service Onboarding W2 Only Ref Object');
        } else if (
          c.RecordType.Name == 'Service Additional HRO LCT Contact Record Type'
        ) {
          addReferenceHRO(
            refHROs,
            c,
            'Service Additional HRO LCT Contact Ref Object'
          );
        } else if (c.RecordType.Name == 'Service Onboarding 401k Conversion') {
          addReference401(ref401s, c, 'Service Onboarding 401k Conversions');
        } else if (c.RecordType.Name == 'Service Onboarding 401k New Case') {
          addReference401(ref401s, c, 'Service Onboarding 401k New Case');
        }
        //LM commented out and created object relationship
        /*else if (c.RecordType.Name == 'Service Onboarding S125 New Case') {
               addReference401(ref401s,c,'Service Onboarding S125 New Case');
            } */
        else if (c.RecordType.Name == 'Service Onboarding S125 Conversion') {
          addReference401(ref401s, c, 'Service Onboarding S125 Conversions');
          //JNS commented out and created object relationship
          /*} else if (c.RecordType.Name == 'Service Support 401k MM Change Case Record') {
           addReference401(ref401s,c,'Service 401k Money Manager Change');  */
        } else if (
          c.RecordType.Name == 'Service Onboarding 401k Large Market New Case'
        ) {
          addReference401(
            ref401s,
            c,
            'Service Onboarding 401k Large Market New Case'
          );
        } else if (c.RecordType.Name == 'Service Onboarding GL Case') {
          addReferenceGL(refGLs, c, 'GL Onboarding Record Type');
        } else if (c.RecordType.Name == 'Service Support Corporate Concerns') {
          addReferenceCltRltn(
            refCltRltns,
            c,
            'Client Relations Support Record Type'
          );
        } else if (c.RecordType.Name == 'Service Onboarding PEO New Business') {
          addReferencePEO(refPEOs, c, 'PEO New Business Onboarding');
        } else if (
          c.RecordType.Name == 'Service Onboarding PEO Existing Clients'
        ) {
          addReferencePEO(refPEOs, c, 'PEO Existing Client Onboarding');
        } else if (
          c.RecordType.Name == 'Service Onboarding Core Payroll Case'
        ) {
          addReferenceCore(refCorePays, c, 'Reference Onboarding Core Payroll');
        } else if( c.RecordType.Name == 'HRS HRRT General Inquiry Case'){
          addHrrtGeneralInquiryCase(hrrtTrackers, c, 'Gen Inq HRRT Tracker');
        } else if (
          c.RecordType.Name == 'Service Onboarding Payroll Fulfillment'
        ) {
          addRefPayFulfill(refPayFulfill, c, 'Payroll Fullfillment');
        } else if (c.RecordType.Name == '401k/S125 Operations Support') {
          if (
            c.Product__c == '401K' &&
            c.Termination_Transfer_Type__c == 'Termination'
          ) {
            addRefTermTrans(refTermTrans, c, '401k Termination');
          }
          if (
            c.Product__c == '401K' &&
            c.Termination_Transfer_Type__c == 'Transfer'
          ) {
            addRefTermTrans(refTermTrans, c, '401k Transfer');
          }
          if (
            c.Product__c == 'S125' &&
            c.Termination_Transfer_Type__c == 'POP Termination'
          ) {
            addRefTermTrans(refTermTrans, c, 'S125 POP Termination');
          }
          if (
            c.Product__c == 'S125' &&
            c.Termination_Transfer_Type__c == 'FSA/HSA Termination'
          ) {
            addRefTermTrans(refTermTrans, c, 'S125 FSA Termination');
          }
          if (
            c.Product__c == 'S125' &&
            c.Termination_Transfer_Type__c == 'NSF' ||
            c.Product__c == '401K' &&
            c.Termination_Transfer_Type__c == 'NSF'
          ) {
            addRefTermTrans(refTermTrans, c, 'NSF');
          }
        }
      } // if (!c.Subject.contains
    } // for (Case c

    DmlHelper soh = new DmlHelper();
    soh.saveRecords(refTAAs, null, null, true, false);
    soh.saveRecords(refHROs, null, null, true, false);
    soh.saveRecords(ref401s, null, null, true, false);
    soh.saveRecords(refGLs, null, null, true, false);
    soh.saveRecords(refCltRltns, null, null, true, false);
    soh.saveRecords(refPEOs, null, null, true, false);
    soh.saveRecords(refCorePays, null, null, true, false);
    soh.saveRecords(hrrtTrackers, null, null, true, false);
    soh.saveRecords(refPayFulfill, null, null, true, false);
    soh.saveRecords(refTermTrans, null, null, true, false);
  } // createReference

  private static void addHrrtGeneralInquiryCase(
    List<General_Inquiry_HRRT_Tracker__c> refs, Case c, String newRecordTypeName
  ){
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'General_Inquiry_HRRT_Tracker__c'
    );
    if(rt != null){
      General_Inquiry_HRRT_Tracker__c ref = new General_Inquiry_HRRT_Tracker__c(
        Case__c = c.Id,
        Owner__c = c.OwnerId,
        HRRT_Status__c = 'Open',
        Reference_Record_Created_Date__c = Date.today()
      );
      refs.add(ref);

    }
  }//addHrrtGeneralInquiryCase
  private static void addReferenceHRO(
    List<Reference_HRO__c> refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_HRO__c'
    );
    if (rt != null) {
      Reference_HRO__c ref = new Reference_HRO__c(
        Case_Number__c = c.Id,
        OwnerId = c.OwnerId,
        RecordTypeId = rt.getRecordTypeId()
      );
      refs.add(ref);
    }
  } // addReferenceHRO

  private static void addReferenceTAA(
    List<Reference_TAA__c> refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_TAA__c'
    );
    if (rt != null) {
      Reference_TAA__c ref = new Reference_TAA__c(
        Case_Lookup__c = c.Id,
        OwnerId = c.OwnerId,
        RecordTypeId = rt.getRecordTypeId()
      );
      refs.add(ref);
    }
  } // addReferenceTAA

  private static void addReference401(
    List<Reference_401k_S125__c> refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_401k_S125__c'
    );
    if (rt != null) {
      Reference_401k_S125__c ref = new Reference_401k_S125__c(
        Case_Lookup__c = c.Id,
        OwnerId = c.OwnerId,
        RecordTypeId = rt.getRecordTypeId()
      );
      refs.add(ref);
    }
  } // addReference401k

  private static void addReferenceGL(
    List<Reference_GL__c> refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_GL__c'
    );
    if (rt != null) {
      Reference_GL__c ref = new Reference_GL__c(
        Case_Lookup__c = c.Id,
        OwnerId = c.OwnerId,
        RecordTypeId = rt.getRecordTypeId()
      );
      refs.add(ref);
    }
  } // addReferenceGL

  private static void addReferenceCltRltn(
    List<Reference_Client_Relations__c> refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_Client_Relations__c'
    );
    if (rt != null) {
      Reference_Client_Relations__c ref = new Reference_Client_Relations__c(
        Case_Lookup__c = c.Id,
        OwnerId = c.OwnerId,
        RecordTypeId = rt.getRecordTypeId()
      );
      refs.add(ref);
    }
  } // addReferenceCltRltn

  private static void addReferencePEO(
    Reference_PEO__c[] refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_PEO__c'
    );
    if (rt != null) {
      System.debug('Create Reference_PEO__c');
      Reference_PEO__c ref = new Reference_PEO__c(
        RecordTypeId = rt.getRecordTypeId(),
        Parent_Case__c = c.Id,
        Opportunity__c = c.Opportunity__c,
        Sales_Rep__c = c.Opportunity__r.OwnerId,
        DSM__c = c.Opportunity__r.Owner.ManagerId,
        Account_Lookup__c = c.AccountId,
        // ,Proposed_Run_Date__c = c.Opportunity__r.CloseDate
        // ,Client_Load_Received__c = false
        OwnerId = c.OwnerId,
        Current_Step__c = c.Current_Step__c
        // ,Contact__c = c.ContactId
      );
      refs.add(ref);
    }
  } // addReferencePEO

  private static void addReferenceCore(
    Reference_Core_Payroll__c[] refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_Core_Payroll__c'
    );
    if (rt != null) {
      
      Reference_Core_Payroll__c ref = new Reference_Core_Payroll__c(
        RecordTypeId = rt.getRecordTypeId(),
        Case_Lookup__c = c.Id,
        Opportunity_Lookup__c = c.Opportunity__c,
        Sales_Rep__c = c.Opportunity__r.OwnerId,
        DSA__c = c.Opportunity__r.Owner.DSA_FSS__c,
        Proposed_Run_Date__c = c.Opportunity__r.CloseDate,
        Client_Load_Received__c = false,
        OwnerId = c.OwnerId,
        Contact__c = c.ContactId,
        Product_Summary__c = c.Opportunity__r.Product_Summary__c,
        Spanish_Language__c = c.Opportunity__r.Spanish_Speaking_Needs__c
      );
      refs.add(ref);
    }
  } // addReferenceCore

  private static void addRefPayFulfill(
    List<Reference_Payroll_Fulfillment__c> refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_Payroll_Fulfillment__c'
    );
    if (rt != null) {
      Reference_Payroll_Fulfillment__c ref = new Reference_Payroll_Fulfillment__c(
        Case_Number__c = c.Id,
        OwnerId = c.OwnerId,
        RecordTypeId = rt.getRecordTypeId()
      );
      refs.add(ref);
      system.debug(
        '---- After Create Payroll Fulfillment Reference Object--------------' +
        ref.id
      );
    }
  } // addRefPayFulfill

  private static void addRefTermTrans(
    List<Reference_Terms_Transfers__c> refs,
    Case c,
    String newRecordTypeName
  ) {
    Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(
      newRecordTypeName,
      'Reference_Terms_Transfers__c'
    );
    if (rt != null) {
      Reference_Terms_Transfers__c ref = new Reference_Terms_Transfers__c(
        Case_Lookup__c = c.Id,
        OwnerId = c.OwnerId,
        RecordTypeId = rt.getRecordTypeId()
      );
      refs.add(ref);
    }
  } // addRefTermTrans
    
}