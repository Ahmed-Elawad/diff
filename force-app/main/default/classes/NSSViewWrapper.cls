/* 
 * Wrapper for information displayed on the NSS View form.
 *
 * History
 * -------
 * 08/04/2014 Dan Carmen            Created
   11/03/2016 Dan Carmen            Changes to the form to make it more usable
   12/11/2018 Dan Carmen            Replace qbdialer__Call_Date_Time__c with CallDateTime__c

 */
global with sharing class NSSViewWrapper implements Comparable {

   public static Integer SHORT_DESC_LENGTH=Integer.valueOf(Label.NSS_View_Short_Desc);
   private static Set<String> EDITABLE_STATUSES = new Set<String>(Label.NSSView_Editable_Statuses.split(',')); 

   public Boolean selected{get;set;}

   public Task tsk{get;set;}
   public Event evnt{get;set;}
   public CampaignMember campMember{get;set;}
   public NSSView__c nssView{get;set;}
   public Lead ld{get;set;}
   public Contact ctct{get;set;}
   public Opportunity oppty{get;set;}
   public Asset asst{get;set;}
   public Prospect_Ownership__c po{get;set;}
   public Boolean nssAuditIsEditable{get;set;}
   public NSSAudit__c nssAudit{get;
      set {nssAudit = value;
         nssAuditIsEditable = true;
         if (nssAudit != null && nssAudit.Id != null && String.isNotBlank(nssAudit.Status__c)) {
            nssAuditIsEditable = EDITABLE_STATUSES.contains(nssAudit.Status__c);
         }
      }
   } // nssAudit
   
   public NSSSalesOppLink__c oppLink{get;set;}

   public Boolean isCampaignMember{get { return (campMember != null);}}
   public Boolean isEvent{get { return (evnt != null);}}
   public Boolean isTask{get { return (tsk != null);}}
   public Boolean isLead{get { return (ld != null);}}
   public Boolean isContact{get { return (ctct != null);}}
   public Boolean isOpportunity{get {return (oppty != null);}}
   public Boolean isAsset{get {return (asst != null); }}
   
   public String shortDesc{get;private set;}
   public Boolean showLongDesc{get; set;}
   public Boolean hasLongDesc{get; private set;}
   public String clientNumber{get; set;}

   public void setup() {
      nssAuditIsEditable = true;
   }

   public NSSViewWrapper(CampaignMember p_campMember) {
      setup();
      campMember = p_campMember;
      setShortDesc(null);
   } // NSSViewWrapper
   
   public NSSViewWrapper(Task p_tsk) {
      setup();
      tsk = p_tsk;
      setShortDesc(tsk.Description);
   } // NSSViewWrapper
      
   public NSSViewWrapper(Event p_evnt) {
      setup();
      evnt = p_evnt;
      //setShortDesc(evnt.Description);
      setShortDesc(null);
   } // NSSViewWrapper

   public NSSViewWrapper(Lead p_ld) {
      setup();
      ld=p_ld;
      nssView = new NSSView__c(Lead__c=p_ld.Id);
      setShortDesc(ld.Description);
   } // NSSViewWrapper
   
   /*
   public NSSViewWrapper(Contact p_ctct) { 
      setup();
      ctct=p_ctct;
      nssView = new NSSView__c(Contact__c=p_ctct.Id);
      setShortDesc(ctct.Description);
   } // NSSViewWrapper
   */
   public NSSViewWrapper(Opportunity p_oppty) { 
      setup();
      oppty=p_oppty;
      setClientNumber();
      nssView = new NSSView__c(Opportunity__c=(p_oppty != null ? p_oppty.Id : null));
      selected = false;
      setShortDesc(null);
   } // NSSViewWrapper
   /*
   public NSSViewWrapper(Asset p_asst) {
      setup();
      nssView = new NSSView__c(Asset__c=p_asst.Id);
      asst = p_asst;
   } // NSSViewWrapper
   */
   public NSSViewWrapper(NSSSalesOppLink__c p_oppLink) {
      this(p_oppLink.Opportunity__r);
      setup();
      oppLink = p_oppLink;
   } // NSSViewWrapper
   
   public Date activityDate{
      get {return (isEvent ? evnt.ActivityDate : (isTask ? tsk.ActivityDate : Date.today())); }
   } // activityDate

   public DateTime activityDateTime{
      get {
         DateTime dt = DateTime.now();
         if (isEvent) {
            dt = evnt.ActivityDateTime;
         } else if (isTask) {
            if (tsk.CallDateTime__c != null) {
               dt = tsk.CallDateTime__c;
            } else {
               dt = DateTime.newInstance(tsk.ActivityDate,Time.newInstance(1,0,0,0));
            }
         }
         return dt;
      } // get
   } // activityDateTime
   
   // is there a call date on the activity?
   public Boolean hasCallDate{
      get {return ((isEvent && evnt.CallDateTime__c != null) || (isTask && tsk.CallDateTime__c != null)); }
   } // hasCallDate
   
   public String formattedDate{
      get {
         String formattedValue = null;
         if (isOpportunity) {
         	Time tm = Time.newInstance(1,1,1,1);
         	DateTime dt = DateTime.newInstance(oppty.CloseDate,tm);
            formattedValue = dt.format('MM/dd/yyyy');
         }
         return formattedValue;
      }
   } // formattedDate
   
   // id > compareToEmp.id) return 1;
   
   global Integer compareTo(Object objectToCompareTo) {
      if (objectToCompareTo != null && (isEvent || isTask)) {
         NSSViewWrapper compareAw = (NSSViewWrapper)objectToCompareTo;
         DateTime thisDt = activityDateTime;
         DateTime thatDt = compareAw.activityDateTime;
         if (thisDt != null && thatDt != null) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'thisDt='+thisDt.format()+' thisDt long='+thisDt.getTime()+' thatDt='+thatDt.format()+' thatDt long='+thatDt.getTime()));
            if (thatDt.getTime() > thisDt.getTime()) {
               return 1;
            } else if (thisDt.getTime() == thatDt.getTime()) {
               return 0;
            }
            //return Integer.valueOf(thatDt.getTime() - thisDt.getTime());
         }
         //if (activityDate != null && compareAw.activityDate != null) {
         //   return activityDate.daysBetween(compareAw.activityDate);
         //}
      } // if (objectToCompareTo != null
      return -1;
   } // compareTo

   private void setShortDesc(String descText) {
      shortDesc = (String.isNotBlank(descText) ? descText.left(SHORT_DESC_LENGTH) : '');
      hasLongDesc = (String.isNotBlank(descText) && descText.length() > SHORT_DESC_LENGTH);
      showLongDesc = false;
   } // setShortDesc

   public void toggleLongDesc() {
      showLongDesc = !showLongDesc;
   } // toggleLongDesc
   
   private void setClientNumber() {
   	  clientNumber = null;
   	  if (oppty != null)
   	  {	if (oppty.Account.AccountNumber != null && oppty.Account.AccountNumber.indexOf('-') > 0)
   	  	{  	clientNumber = oppty.Account.AccountNumber.substring(oppty.Account.AccountNumber.indexOf('-')+1);		}
   	  }
   } // setClientNumber
   
   // is the sales rep lookup set on the NSS Sales Product?
   public Boolean hasProductSalesRep {
      get {return (oppLink != null && oppLink.NSSSalesProduct__c != null && oppLink.NSSSalesProduct__r.SalesRep__c != null); }
   }
   
   // is this a new audit/sales record?
   public Boolean auditIsNew {
      get {return (nssAudit != null && nssAudit.Id == null); }
   } // auditIsNew
   	   
   public Boolean linkHasOtherInfo {
      get {return (oppLink != null && String.isNotBlank(oppLink.OtherLinkInfo__c)); }
   }

   private NSSAudit__c[] v_otherSales = new NSSAudit__c[]{};
   /* - not sure where this is used.
   public void addAuditToWrapper(NSSAudit__c p_nssSale) {
      Boolean matched = false;
      if (p_nssSale != null && oppLink != null && oppLink.NSSSalesProduct__c != null) {
         // if there's already an nssAudit set but it doesn't have a link, and the incoming record does have a link that matches to the product
         if (nssAudit != null && nssAudit.NSSSalesProduct__c == null && p_nssSale.NSSSalesProduct__c != null 
                  && p_nssSale.NSSSalesProduct__c == oppLink.NSSSalesProduct__c) {
            v_otherSales.add(nssAudit);
            nssAudit = p_nssSale;
            matched = true;
         }
         
         if (nssAudit == null) {
            // link if linked directly to the product or there isn't a link and the product matches.
            if ((p_nssSale.NSSSalesProduct__c != null && p_nssSale.NSSSalesProduct__c == oppLink.NSSSalesProduct__c) 
                || (p_nssSale.NSSSalesProduct__c == null && p_nssSale.Product__c == p_nssSale.NSSSalesProduct__r.AuditProduct__c)) {
               matched = true;
               nssAudit = p_nssSale;
            }
         } // if (nssAudit == null
         
         
         if (!matched) {
            v_otherSales.add(p_nssSale);
         } // if (!matched
      } // if (p_nssSale != null
   } // addAuditToWrapper
   
   public void addExistingSale(NSSAudit__c p_nssSale) {
      v_otherSales.add(p_nssSale);
   } // addExistingSale
   */
   // other sales attached to the opportunity but not the same as the imported product.
   public String otherSales{
      get {
         String retVal = '';
         if (!v_otherSales.isEmpty()) {
            for (NSSAudit__c otherSale : v_otherSales) {
               if (String.isNotBlank(retVal)) {
                  retVal += '\n,';
               }
               retVal += otherSale.Name+'-'+otherSale.Product__c+'- '+otherSale.Run_Submit_Date__c+'-'+otherSale.Status__c;
            } // for (NSSAudit__c
         } // if (!v_otherSales
         return retVal;
      } // get
   } // otherSales
      
} // class NSSViewWrapper