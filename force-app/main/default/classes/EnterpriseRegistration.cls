/** Queueable class used for registering a client
 * 
 * History
 * -------
   05/08/2023 Dan Carmen        Created
   04/26/2024 Dan Carmen        Add a finalizer to the queueable

 
 */
public class EnterpriseRegistration implements Queueable, Database.AllowsCallouts, Finalizer { 
	
    public static final String CLASSNAME='EnterpriseRegistration';
    // client registration for multiple clients
    public static final String MODE_CLT_REG='ClientReg';
    // get the OSS keys
    public static final String MODE_OSS_KEYS='OssKeys';
    // send the keys to CPQ
    public static final String MODE_CPQ_KEYS='CpqKeys';
    // start the CPQ subscription
    public static final String MODE_CPQ_SUB='CpqSub';
    // to only validate the client
    public static final String MODE_CLT_VAL='ClientValidate';
    
    public String mode;
    public Id[] trackerIds;
    public Id[] legalNameIds;
    public Id[] legalAddrIds;
    public Id[] validCltIds;
    public Id[] validShipIds;
    public Id[] validBillIds;
    public Id[] submitCpqIds = new Id[]{};
    public EZOnboardingRegistration.ClientGroup[] cltGrps;
    public EZOnboardingRegistration.ClientGroup[] ossGrps;
    public EZOnboardingRegistration.ClientGroup[] ossRetryGrps = new EZOnboardingRegistration.ClientGroup[]{};
    public Id curTrackerId;
    
    public EnterpriseRegistration(EZOnboardingRegistration.ClientGroup[] p_cltGrps, EZOnboardingRegistration.ClientGroup[] p_ossGrps) {
       this(p_cltGrps,p_ossGrps,null);
    }

    public EnterpriseRegistration(EZOnboardingRegistration.ClientGroup[] p_cltGrps, EZOnboardingRegistration.ClientGroup[] p_ossGrps, EZOnboardingRegistration.ClientGroup[] p_ossRetryGrps) {
       cltGrps = p_cltGrps != null ? p_cltGrps : new EZOnboardingRegistration.ClientGroup[]{};
       ossGrps = p_ossGrps != null ? p_ossGrps : new EZOnboardingRegistration.ClientGroup[]{};
       ossRetryGrps = p_ossRetryGrps != null ? p_ossRetryGrps : new EZOnboardingRegistration.ClientGroup[]{};
       mode = (!cltGrps.isEmpty() ? MODE_CLT_REG : (!ossGrps.isEmpty() || !ossRetryGrps.isEmpty() ? MODE_OSS_KEYS : null));
    } // EnterpriseRegistration

    public EnterpriseRegistration(String p_mode, Id[] p_trackerIds) {
       mode = p_mode;
       trackerIds = p_trackerIds;
    } // EnterpriseRegistration
    
    public EnterpriseRegistration(String p_mode, Id[] p_trackerIds, Id[] p_legalNameIds, Id[] p_legalAddrIds) {
       mode = p_mode;
       trackerIds = p_trackerIds;
       legalNameIds = p_legalNameIds;
       legalAddrIds = p_legalAddrIds;
    } // EnterpriseRegistration
    
    public EnterpriseRegistration(String p_mode, Id[] p_trackerIds, Id[] p_validCltIds, Id[] p_validShipIds, Id[] p_validBillIds) {
       mode = p_mode;
       trackerIds = p_trackerIds;
       validCltIds = p_validCltIds;
       validShipIds = p_validShipIds;
       validBillIds = p_validBillIds;
    } // EnterpriseRegistration

    public void execute(QueueableContext context) {
       System.attachFinalizer(this);
       processRecs();
    } // execute
    
    public void processRecs() {
        System.debug('processRecs mode='+mode);
        if (mode == MODE_CLT_REG || mode == MODE_OSS_KEYS) {
            handleCltReg();
        } else if (mode == MODE_CPQ_KEYS || mode == MODE_CPQ_SUB) {
            handleCpq();
        } else if (mode == EZOnboardingRegistration.REG_CLT_UPDATE) {
            handleCltUpdate();
        } else if (mode == EZOnboardingRegistration.CLT_VALIDATE) {
            handleValidate();
        }
    } // processRecs

    public EZOnboardingRegistration.ResponseWrapper handleValidate() {
       EZOnboardingRegistration.ResponseWrapper res = null;
       curTrackerId = (!trackerIds.isEmpty() ? trackerIds.remove(0) : null);
       System.debug('EnterpriseRegistration.handleValidate curTrackerId='+curTrackerId+' validCltIds='+validCltIds.size()+' validShipIds='+validShipIds.size()+' validBillIds='+validBillIds.size());
       if (curTrackerId != null) {
          res = EZOnboardingRegistration.validateInfo(curTrackerId, validCltIds.contains(curTrackerId), validShipIds.contains(curTrackerId), validBillIds.contains(curTrackerId)); 
       }
       EnterpriseRegistration entReg = null;
       if (!trackerIds.isEmpty()) {
          entReg = new EnterpriseRegistration(EZOnboardingRegistration.CLT_VALIDATE, trackerIds, legalNameIds, legalAddrIds);
       }
       // requeue the job if more records to process
       if (!Test.isRunningTest() && entReg != null) {
          launchJob(entReg);
       }

       return res;
    } // handleValidate
    
    public EZOnboardingRegistration.ResponseWrapper handleCltUpdate() {
       EZOnboardingRegistration.ResponseWrapper res = null;
       curTrackerId = (!trackerIds.isEmpty() ? trackerIds.remove(0) : null);
       System.debug('EnterpriseRegistration.handleCltUpdate curTrackerId='+curTrackerId+' legalNameIds='+legalNameIds.size()+' legalAddrIds='+legalAddrIds.size());
       if (curTrackerId != null) {
          res = EZOnboardingRegistration.handleLegalUpdate(curTrackerId, legalNameIds.contains(curTrackerId), legalAddrIds.contains(curTrackerId)); 
       }
       EnterpriseRegistration entReg = null;
       if (!trackerIds.isEmpty()) {
          entReg = new EnterpriseRegistration(EZOnboardingRegistration.REG_CLT_UPDATE, trackerIds, legalNameIds, legalAddrIds);
       }
       // requeue the job if more records to process
       if (!Test.isRunningTest() && entReg != null) {
          launchJob(entReg);
       }

       return res;
    } // handleCltUpdate
    
    public void handleCpq() {
       curTrackerId = (!trackerIds.isEmpty() ? trackerIds.remove(0) : null);
       System.debug('EnterpriseRegistration.handleCpq curTrackerId='+curTrackerId+' trackerIds='+trackerIds.size());
       if (curTrackerId != null) {
          if (mode == MODE_CPQ_KEYS) {
             CsoQueueable.AcctCsoWrap wrap = EZOnboardingRegistration.sendCPQKeysNow(curTrackerId);
             if (wrap.cso.CPQKeysStatusCode__c == '200') {
                submitCpqIds.add(curTrackerId);
             }
          } else if (mode == MODE_CPQ_SUB) {
             EZOnboardingRegistration.sendCPQSubNow(curTrackerId);
          }
       } // if (trackerId != null
        
       EnterpriseRegistration entReg = null;
       if (!trackerIds.isEmpty()) {
          entReg = new EnterpriseRegistration(MODE_CPQ_KEYS, trackerIds);
          entReg.submitCpqIds = submitCpqIds;
       } else if (!submitCpqIds.isEmpty()) {
          entReg = new EnterpriseRegistration(MODE_CPQ_SUB, submitCpqIds);
       }
       // requeue the job if more records to process
       if (!Test.isRunningTest() && entReg != null) {
          launchJob(entReg);
       }

    } // handleCpq
    
    public EZOnboardingRegistration.ResponseWrapper handleCltReg() {
       EZOnboardingRegistration.ResponseWrapper res = null;
       System.debug('handleCltReg cltGrps='+cltGrps.size()+' ossGrps='+ossGrps.size());
       if (!cltGrps.isEmpty()) {
          Boolean isValidate = (mode == MODE_CLT_VAL);
          // remove the first one in the list
          EZOnboardingRegistration.ClientGroup cltGrp = cltGrps.remove(0);
          curTrackerId = cltGrp.parentTrackerId;
          // process the record
          res = EZOnboardingRegistration.sendEntRegRequest(cltGrp, isValidate); 
          if (!isValidate && res.statusCode == 200) {
             // if successfully processed add to retrieve the keys
             //ossGrps.add(cltGrp);
             // add to the retry so we get the delay in there for the first check. 
             ossRetryGrps.add(cltGrp);
          }
       } else if (!ossGrps.isEmpty()) {
          // once we're through all the client groups, get the keys for each group
          EZOnboardingRegistration.ClientGroup cltGrp = ossGrps.remove(0);
          curTrackerId = cltGrp.parentTrackerId;
          if (!EZOnboardingRegistration.sendKeysRequest(cltGrp)) {
             // false is returned if it needs to run again
             //ossGrps.add(cltGrp);
             ossRetryGrps.add(cltGrp);
          }
       }
       // see if we need to relaunch
       System.debug('handleCltReg cltGrps='+cltGrps.size()+' ossGrps='+ossGrps.size()+' ossRetryGrps='+ossRetryGrps.size());
       if (!Test.isRunningTest() && (!cltGrps.isEmpty() || !ossGrps.isEmpty() || !ossRetryGrps.isEmpty())) {
          EnterpriseRegistration entReg = new EnterpriseRegistration(cltGrps,ossGrps,ossRetryGrps);
          launchJob(entReg);
       }
       return res;
    } // handleCltReg
    
    public static void launchJob(EnterpriseRegistration entReg) {
       Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
       Apex_Batch_Control__c keysAbc = Apex_Batch_Control__c.getInstance(EZOnboardingRegistration.KEYS_NAME);

       System.debug('EnterpriseRegistration.launchJob abc='+(abc != null ? abc.Name : 'NotFound')+' entReg='+(entReg != null));
       if (abc != null && abc.Active__c && entReg != null) {
          Boolean useDelay = (entReg.mode == MODE_OSS_KEYS && entReg.ossGrps.isEmpty() && !entReg.ossRetryGrps.isEmpty());
          Apex_Batch_Control__c delayAbc = (keysAbc != null && keysAbc.Minutes_till_Launch__c != null ? keysAbc : abc);
          Integer delay = (delayAbc.Minutes_till_Launch__c != null ? Integer.valueOf(delayAbc.Minutes_till_Launch__c) : 1);
          System.debug('EnterpriseRegistration.launchJob useDelay='+useDelay+' delay='+delay);
          if (useDelay) {
             entReg.ossGrps.addAll(entReg.ossRetryGrps);
             entReg.ossRetryGrps.clear();
             System.enqueueJob(entReg,delay);
          } else {
            System.enqueueJob(entReg);
          }
       }
    } // launchJob
    
    public void execute(FinalizerContext ctx) {
        String parentJobId = ctx.getAsyncApexJobId();
        System.debug('Begin: executing finalizer attached to queueable job: ' + parentJobId);
        if (ctx.getResult() != ParentJobResult.SUCCESS) {
            //System.debug('Parent queueable job [' + parentJobId + '] failed due to unhandled exception: ' + ctx.getException().getMessage());
           ErrorLog.logError('EnterpriseRegistration', 'Unhandled Exception', 'Unhandled Exception '+mode, curTrackerId, ctx.getException(), null, true);
        }
    } // execute FinalizerContext
    
} // class EnterpriseRegistration