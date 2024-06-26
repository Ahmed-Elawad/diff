/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
* 
*/
@isTest(SeeAllData=true)
private class QuotaControlTest {
    
    private static User createUser(String username, String firstName, String lastName, Boolean forecastEnabled) {
        
        String alias = username.split('@').get(0);
        Profile profile = [
            select Id from Profile where Name='Standard User'
        ];
        UserRole role = [
            select Id from UserRole where Name='System Administrator'
        ];
        
        User user = new User(
            Username = username,
            Email = username,
            FirstName = firstName,
            LastName = lastName,
            Alias = alias,
            ProfileID = profile.Id,
            UserRoleId = role.Id,
            Sales_Org__c = 'MMS',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            ForecastEnabled = forecastEnabled
        );
        insert user;
        /*Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' Limit 1]; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', ProfileId = p.Id, 
                        TimeZoneSidKey='America/Los_Angeles', UserName='sandarduser123@testorg.com',Sales_Org__c='NSS');
        insert user;*/
        return user;
    }
    
    static testMethod void getOnlyForecastingUsers() {
        //User a = createUser('a@quota.com', 'Fred', 'ForecastingUser', TRUE);
        
        //User b = createUser('b@quota.com', 'Jane', 'Non-ForecastingUser', FALSE);
        
        User a = [Select id, Name, UserroleId from User where Profile.Name= 'System Administrator' and ForecastEnabled = true and IsActive = true Limit 1];
        
        User b = [Select id, Name, UserroleId from User where UserType = 'Standard' AND ForecastEnabled = false and IsActive = true Limit 1];
        
        Quota_TreeViewController qc = new Quota_TreeViewController();
        Quota_TreeViewController.getChildNodesJSON(userinfo.getProfileId());
        qc.getJsonString();
        
        Id uorroleid = userinfo.getuserId();
        
        UserRole role = [select Id from UserRole where Name='System Administrator' Limit 1];
        list<id> roleid= new list<id>();
        roleid.add(role.id);
        //QuotaPageController_Test qtest = new QuotaPageController_Test();
        //QuotaPageController_Test.getTreeJSON(role.Id);
        
        //Quota_CurrencyUtil.getAvailableIsoCodes();
        //Quota_CurrencyUtil.getUserDefaultCurrency(a.id);
        //Id futureperiodId = Quota_CalendarUtil.getPeriodForNow('Monthly');
        Id yearPeriodId = [SELECT Id, StartDate FROM Period WHERE Type = 'Year' ORDER BY StartDate Asc LIMIT 1].Id;
        Id monthPeriodId = [SELECT Id, StartDate FROM Period WHERE Type = 'Month' ORDER BY StartDate Asc LIMIT 1].Id;
        //system.debug('Period Id ---->>>>>'+periodId);
        Quota_ForecastingTypeUtil.getActiveForecastingTypesAsOptions();
        Quota_ForecastingTypeUtil.getRevenueForecastingType();
        ForecastingType fType = new ForecastingType();
        for(ForecastingType ft: Quota_ForecastingTypeUtil.types){
            if(ft.isAmount == TRUE){
            	ftype = ft;    
            }    
        }
        List<Quota_Model> ret = new List<Quota_Model>(); //qc.getQuotasForPeriod(Date.newInstance(date.today().year(), 3, 1), qc.quotaMap);
        
        Quota_Model qm = new Quota_Model();
        System.assert(qm.getAmountString() == null);
        double amount = 1234.0;
        qm.startDate=system.today();
        qm.setAmount(amount);
        qm.ownerId=a.Id;
        qm.ownerName=a.Name;
        qm.isQuantity = false;
        qm.ownerRole = a.UserroleId;
        qm.periodId = monthPeriodId;
        //quotaId
        qm.forecastingTypeId = fType.Id;
        qm.getAmountString();
        System.assert(qm.getAmount() == amount);
        
        ret.add(qm);
        
        QuotaToolController qt = new QuotaToolController();
        qt.getRootRoleId();
        qt.setSelectedPeriodType('monthly');
        qt.getSelectedPeriodType();
        
        QuotaToolController.saveRemoteAction(ret, new List<Id>{monthPeriodId});
        //qt.setFuturePeriod(periodId);
        //Load_QuotasModel quotas = QuotaToolController.refreshQuotas(fType.Id, periodId, '', new List<Id>()); 
        //QuotaToolController.saveToPeriodRemoteAction(fType.Id, periodId, '', new List<Id>(), ret);
        Load_QuotasModel quotas = QuotaToolController.refreshQuotas(fType.Id, yearPeriodId, roleid); //fType.Id, 
        /*QuotaToolController.saveToPeriodRemoteAction(fType.Id, futureperiodId, roleid, ret); //fType.Id, 
        System.debug(quotas);
        
        //for (Quota_Model q : ret) {
        //    q.amount = 5555;
        //}
        //qt.setQuotas(ret);
        
        system.debug('ret====>'+ret);
        QuotaToolController.saveRemoteAction(ret, periodId);
        Boolean aFound = false;
        Boolean bFound = false;
        
        for (Quota_Model q : quotas.quotaRows) {
            if (q.ownerId.equals(a.Id))
                aFound = true;
            if (q.ownerId.equals(b.Id))
                bFound = true;
        }
        System.assert(aFound);
        System.assert(!bFound);*/
    }
    
    static testMethod void getOnlyForecastingUsers2() {
        //User a = createUser('a@quota.com', 'Fred', 'ForecastingUser', TRUE);
        //User b = createUser('b@quota.com', 'Jane', 'Non-ForecastingUser', FALSE);
        
        User a = [Select id from User where Profile.Name= 'System Administrator' and ForecastEnabled = true and IsActive = true Limit 1];
        Period periods = [SELECT StartDate FROM Period Where EndDate >= :Date.today() AND StartDate <= :Date.today() ORDER BY StartDate DESC LIMIT 1];
        ForecastingType fType = new ForecastingType();
        for(ForecastingType ft: Quota_ForecastingTypeUtil.types){
            if(ft.isAmount == TRUE){
            	ftype = ft;    
            }    
        }
        ForecastingQuota fq = new ForecastingQuota();
        
        fq.QuotaOwnerId = a.Id;
        fq.QuotaAmount = 1500;
        //fq.PeriodId = periods.id;
        fq.startDate = Date.Today();
        fq.ForecastingTypeId = fType.Id;
        
        insert fq;
        
        UserRole role = [select Id from UserRole where Name='System Administrator' Limit 1];
        list<id> roleid= new list<id>();
        //roleid.add(role.id);
        //QuotaPageController_Test qtest = new QuotaPageController_Test();
        //QuotaPageController_Test.getTreeJSON(role.Id);
        
        Quota_TreeViewController qc = new Quota_TreeViewController();
        Quota_TreeViewController.getChildNodesJSON(userinfo.getProfileId());
        
        //Quota_CurrencyUtil.getAvailableIsoCodes();
        //Quota_CurrencyUtil.getUserDefaultCurrency(a.id);
        Id periodId = Quota_CalendarUtil.getPeriodForNow('Yearly');
        Quota_ForecastingTypeUtil.getActiveForecastingTypesAsOptions();
        Quota_ForecastingTypeUtil.getRevenueForecastingType();
        //jsh 11/08 Commenting out because we deleted quantity forecast 
        List<Quota_Model> ret = new List<Quota_Model>(); //qc.getQuotasForPeriod(Date.newInstance(date.today().year(), 3, 1), qc.quotaMap);
        
       QuotaToolController qt = new QuotaToolController();
        qt.getRootRoleId();
        qt.setSelectedPeriodType('monthly');
        qt.getSelectedPeriodType();
        qt.setFuturePeriod(periodId);
        //Load_QuotasModel quotas = QuotaToolController.refreshQuotas(fType.Id, periodId, '', new List<Id>()); 
        //QuotaToolController.saveToPeriodRemoteAction(fType.Id, periodId, '', new List<Id>(), ret);
        
        //jsh 11/08 Commenting out because we deleted quantity forecast
        //Load_QuotasModel quotas = QuotaToolController.refreshQuotas(fType.Id, periodId, roleid); //fType.Id, 
        /*QuotaToolController.saveToPeriodRemoteAction(fType.Id, periodId,roleid, ret); //fType.Id, 
        System.debug(quotas);
        
        QuotaToolController.saveRemoteAction(ret, periodId);
        Boolean aFound = false;
        Boolean bFound = false;
        
        for (Quota_Model q : quotas.quotaRows) {
            if (q.ownerId.equals(a.Id))
                aFound = true;
            //if (q.ownerId.equals(b.Id))
             //   bFound = true;
        }
        System.assert(aFound);
        //System.assert(!bFound);
        */
    }
    /*
    static testmethod void getRootRoleId(){
        User b = [Select id, Name, UserroleId from User where UserType = 'Standard' AND ForecastEnabled = false and IsActive = true Limit 1];
        Id periodId = [SELECT Id, StartDate FROM Period ORDER BY StartDate Asc LIMIT 1].Id;
        Id futureperiodId = Quota_CalendarUtil.getPeriodForNow('Year');
        system.debug('Period Id ---->>>>>'+periodId);
        Quota_ForecastingTypeUtil.getActiveForecastingTypesAsOptions();
        Quota_ForecastingTypeUtil.getRevenueForecastingType();
        ForecastingType fType = Quota_ForecastingTypeUtil.types.get(0); 
        list<id> roleid= new list<id>(); 
        List<Quota_Model> ret = new List<Quota_Model>();
        system.runas(b){
            QuotaToolController qt = new QuotaToolController();
            qt.getRootRoleId();
            qt.setSelectedPeriodType('Year');
            qt.getSelectedPeriodType();
            qt.setFuturePeriod(periodId);
            Load_QuotasModel quotas = QuotaToolController.refreshQuotas(fType.Id, periodId, roleid); //fType.Id, 
            try{
                QuotaToolController.saveRemoteAction(ret, new List<Id>{periodId});
                //QuotaToolController.saveToPeriodRemoteAction(fType.Id, futureperiodId, roleid, ret); //fType.Id, 
            }catch(exception e){
                system.assertEquals(e.getMessage(),'You do not have permission to write quotas.');
            }
            System.debug(quotas);
        }
    }*/
    
    static testMethod void updateQuotas() {
        String emaila = 'a@quota.com';
        User a = [Select id, Name, UserroleId from User where Profile.Name= 'System Administrator' and IsActive = true Limit 1];
        QuotaToolController qc = new QuotaToolController();
        List<Quota_Model> ret = new List<Quota_Model>(); //qc.getQuotasForPeriod(Date.newInstance(date.today().year(), 3, 1), qc.quotaMap);
        
        for (Quota_Model qm : ret) {
            qm.amount = 5555;
        }
        qc.setQuotas(ret);
        //        qc.save();
        
        qc = new QuotaToolController();
        List<Quota_Model> ret2 = new List<Quota_Model>(); //qc.getQuotasForPeriod(Date.newInstance(date.today().year(), 3, 1), qc.quotaMap);
        for (Quota_Model qm : ret2) {
            System.assertEquals(5555, qm.amount);
        }
    }
    
    static testMethod void testForecastingEnabled() {
        Id userId = Id.valueOf(UserInfo.getUserId());
        User u = [select ForecastEnabled from User where Id=:userId];
        u.ForecastEnabled = true;
        update u;
        System.assert(Quota_PermUtil.hasForecastingEnabled());
        Quota_PermUtil.isReadWriteBelowMe(); // dummy call for code coverage
    }
    
    static testMethod void testGetAvailableMonthlyPeriods() {
        Quota_CalendarUtil.getAvailableMonthlyPeriods(Date.today());
    }
    
    static testMethod void testQuota_RoleUtils()
    {
        //New****//
        Quota_RoleUtils.getSubRolesOneLevel(userInfo.getUserId());
        Quota_RoleUtils.getRoleSubordinateUsers(userInfo.getUserId(), false);
        set<id> roleIdSet = new set<id>();
        roleIdSet.add(userInfo.getUserRoleId());
        Quota_RoleUtils.getAllSubRoleIds(roleIdSet);
        
        List<userRole> roleList = [SELECT id, name , ParentRoleId from userrole where Id IN : roleIdSet limit 1];
        JSONGenerator gen;
        gen = JSON.createGenerator(true);
                
        Quota_RoleNodeModel objCls = new Quota_RoleNodeModel(roleList[0]);
        objCls.hasChildren = true;
        
        objCls.convertNodeToJSON(gen);
        //End**//
    }
    
    static testMethod void testQuota_ModelStr() {
        Quota_Model qm = new Quota_Model();
        System.assert(qm.getAmountString() == null);
        double amount = 1234.0;
        qm.startDate=system.today();
        qm.setAmount(amount);
        qm.getAmountString();
        System.assert(qm.getAmount() == amount);
        
        // won't work for foreign locales
        // System.assert(qm.getAmountString().equals('1,234.00'));
        qm.amount = 52.3;
        //System.assert(qm.getAmountString().equals('52.30'));      
    }
    
    static testMethod void testHeaderMessage1() {
        String ret = QuotaToolController.getHeaderMessage();
    }
    
    static testMethod void testHeaderMessage2() {
        User b = [Select id, Name, UserroleId from User where UserType = 'Standard' AND ForecastEnabled = false and IsActive = true Limit 1];
        system.runas(b){
            String ret = QuotaToolController.getHeaderMessage();
        }
    }
    
    static testMethod void testSaveDisabled() {
        Boolean b = QuotaToolController.getSaveDisabled();
    }  
  
    static testMethod void testMiscGetSet() {
        QuotaToolController qc = new QuotaToolController();
        qc.setStartDatePeriod(Date.today().format());
        //qc.getStartDatePeriod();
        //qc.setFuturePeriod(Date.today().format());
        qc.getFuturePeriod();
        //qc.getAvailablePeriodsForApplyFuture();
        qc.getAvailablePeriods();
            qc.getAvailablePeriodTypes();
            QuotaToolController.getCurrencyColumnHeader();
            
            QuotaToolController.getThisUserId();
            QuotaToolController.getForecastingEnabled();

        QuotaToolController.getQuantityOptions();
        QuotaToolController.getQuotaColumnHeader(true);
        qc.getRenderCurrencyColumn(true);
        //qc.getAvailableIsoCodes();
        qc.showPopup();
        qc.closePopup();
        //qc.getSelectedForecastingType();
        qc.getSelectedProductFamily();
        //qc.onChangeForecastType();
        qc.getUsesFamilies();
        QuotaToolController.getActiveForecastingTypes();
        QuotaToolController.getProductFamilies();
        //qc.getCurrencyColumnHeader();
    }

    static testMethod void testProductFamily() {
        Quota_ProductFamilyUtil.getActiveProductFamilies();
        QuotaToolController qc = new QuotaToolController();
        qc.onCheckProductFamily();
        //qc.getIsProductFamily();
        qc.getSelectedProductFamily();
        qc.setSelectedProductFamily('abc');
        Quota_ProductFamilyUtil.usesFamilies();

    }
    
    static testmethod void testgetRevenueForecastingType(){
        
    }
   
}