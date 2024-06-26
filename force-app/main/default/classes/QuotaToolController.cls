public with sharing class QuotaToolController {
    
    // Static variables. Should be able to be access beyond the first call
    public static final Boolean forecastingEnabled = isForecastingEnabledFirstTimeCheck(); 
    public static final Id thisUserId = Id.valueOf(UserInfo.getUserId());
    
    public id currentPeriodId{get; set;}
    
    //Public Boolean isUpsertfirstTime = true;

    public static Map<Id, List<Quota_Model>> quotaMap = new Map<Id, List<Quota_Model>>();


    // Getters for all the static variables
    public static Id getThisUserId() {
        return thisUserId;
    }
    
    public static boolean getForecastingEnabled() {
        return forecastingEnabled;
    }
    
    
    // Variables only needed for first-time load / defaults
    String periodType = 'Year';
    Id futurePeriod = null;
    public String isQuantityString = 'false';
    public String selectedPFString = '';


    public QuotaToolController() {
        if (!forecastingEnabled)
            return;
        // Initialize periodType based on this call:
        //getAvailablePeriodTypes();
        //futurePeriod = Quota_CalendarUtil.getPeriodForNow(periodType);
        getQuotas();
        getSelectedPeriodType();
        currentPeriodId = Quota_CalendarUtil.getPeriodForNow('Month');
    }
    
    
    // Avoid runtime errors by checking in advance whether
    // Forecasting is enabled in the org
    private static Boolean isForecastingEnabledFirstTimeCheck() {
        String[] types = new String[]{'ForecastingItem','ForecastingQuota'};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        
        if (results.size() < 2)
            return false;
        
        for (Schema.DescribeSObjectResult res : results) {
            System.debug('sObject Label: ' + res.getLabel());
            if (!res.isAccessible())
                return false;
        }
        if (Quota_ForecastingTypeUtil.getNumberOfTypes() == 0)
            return false;
        return true;
    }
        
    public void onCheckProductFamily() {
    }
    
    public static String getHeaderMessage() {
        // If showing all quotas
        // If showing subordinates
        // If showing read-only
        // If not showing anything
        String ret = null;
        
        if (Quota_PermUtil.isReadOnlyAll()) {
            ret = System.Label.QT_Quota_ViewAll;
        }
        else if (Quota_PermUtil.isReadWriteAll()) {
            ret = System.Label.QT_Quota_EditAll;
        }
        else if (Quota_PermUtil.isReadWriteBelowMe()) {
            ret = System.Label.QT_Quota_EditReports;
        }
        else if (Quota_PermUtil.isReadOnlyBelowMe()) {
            ret = System.Label.QT_Quota_ViewReports;
        }
        else {
            ret = System.Label.QT_Quota_CannotView;
        }
        
        return ret;
    }
    
    public static boolean getSaveDisabled() {
        return Quota_PermUtil.isReadOnlyAll() || Quota_PermUtil.isReadOnlyBelowMe();
    }

    public String getSelectedPeriodType() {
        return periodType;
    }
    
    public void setSelectedPeriodType(String selectedPeriod) {
        periodType = selectedPeriod;
        
    }
            
    public void setStartDatePeriod(String startDateStr) {
        Date inputDate = Date.parse(startDateStr);
        quotaMap.clear(); //saketh
    }
    
    public Id getFuturePeriod() {
        return futurePeriod;
    }
    
    public void setFuturePeriod(Id newFuturePeriod) {   
        futurePeriod = newFuturePeriod;
    }
    
    public Boolean getUsesFamilies() {
        return Quota_ProductFamilyUtil.usesFamilies();
    }
        
    public String getSelectedProductFamily() {
        return selectedPFString;
    }
    
    public void setSelectedProductFamily(String str) {
        selectedPFString = str;
    }
    
    // For testing
    public void setQuotas(List<Quota_Model> quotas) {
        quotaMap.clear(); //saketh
        for (Quota_Model q : quotas) {
            Id userId = q.ownerId;
            
            if(quotaMap.containsKey(userId)){
            	List<Quota_Model> quotaList = quotaMap.get(userId);
            	quotaList.add(q);
            	quotaMap.put(userId, quotaList);
            }
            else{
            	quotaMap.put(userId, new List<Quota_Model>{q});
            }
            
        }
    }
    
    public List<Quota_Model> getQuotas() {
        if (!quotaMap.isEmpty()) {
        	List<Quota_Model> ret = new List<Quota_Model>();
            for(List<Quota_Model> quotaList : quotaMap.values()){
            	ret.addAll(quotaList);
            }
            ret.sort();
            return ret;
        }
        return null;
    }
    
    private static List<User> getForecastUsers(Set<Id> roleIds) {
        List<User> forecastUsers;
        
        if (roleIds.size() == 0) {
            if (Quota_PermUtil.isReadWriteAll() || Quota_PermUtil.isReadOnlyAll()) {
                // Someone with "View All Forecasts" and "Manage Quotas" should
                // be able to see and set the quotas of all the Forecasting Enabled
                // users.
                forecastUsers = Quota_RoleUtils.getForecastUsersByRoleIds(new Set<Id>(), isMultiCurrencyOrg, true);
            }
            else {
                forecastUsers = Quota_RoleUtils.getRoleSubordinateUsers(thisUserId, isMultiCurrencyOrg);    
            }               
        }
        else {
            forecastUsers = Quota_RoleUtils.getForecastUsersByRoleIds(roleIds, isMultiCurrencyOrg, false);
        }
        return forecastUsers;
    }

    @RemoteAction
    public static Load_QuotasModel refreshQuotas(final Id forecastingTypeId, final Id periodId, List<Id> roleIds) {

        Period period = Quota_CalendarUtil.getPeriodById(periodId);
        
        //Id forecastingTypeId = forecastingType.Id;
        ForecastingType fType = Quota_ForecastingTypeUtil.getForecastingTypeById(forecastingTypeId);
        
        System.debug(loggingLevel.INFO, 'Refresh quotas for period=' + period.Id + ', isQuantity=' + fType.IsQuantity);
        System.debug(loggingLevel.INFO, 'Role IDs (' + roleIds.size() + ')=' + roleIds);
        
        List<Quota_Model> quotas = refreshQuotas(periodId, fType, roleIds);
        
        List<String> columnHeaders = new List<String>();
        columnHeaders.add(getUserNameColumnHeader());
        columnHeaders.add(getQuotaColumnHeader(fType.IsQuantity));
        
        //columnHeaders.add(getRoleNameColumnHeader());
        /*
        Map<String,String> currencyCodes = new Map<String,String>();
        
        if (isMultiCurrencyOrg && fType.IsAmount) {
            columnHeaders.add(getCurrencyColumnHeader());
            for (SelectOption so : availableIsoCodes) {
                currencyCodes.put(so.getLabel(), so.getValue());
            }    
        }*/
        Load_QuotasModel ret = new Load_QuotasModel(period.FullyQualifiedLabel, columnHeaders, quotas, !Quota_PermUtil.isWriteAllowed());//currencyCodes
        system.debug('ret'+ret);
        return ret;
    }
    
    private static List<Quota_Model> refreshQuotas(final Id periodId, final ForecastingType forecastingType, List<Id> roleIds) {
        
        Boolean isQuant = forecastingType.IsQuantity;
        Boolean isProductFamily = Quota_ForecastingTypeUtil.isProductFamily(forecastingType);
        Id forecastingTypeId = forecastingType.Id;
        
        System.debug(loggingLevel.INFO, 'Fetching quotas for period=' + periodId + ', isQuantity=' + forecastingType.IsQuantity);
        quotaMap.clear(); // saketh
        
        Period yearPeriod = [SELECT FullyQualifiedLabel, StartDate, EndDate FROM Period WHERE Id=:periodId LIMIT 1];
        List<Period> monthPeriods = [SELECT Id,FullyQualifiedLabel,PeriodLabel,StartDate FROM Period WHERE Type='Month' AND StartDate >= :yearPeriod.StartDate AND EndDate <= :yearPeriod.EndDate];
        //Map<Id,Period> periodMap = new Map<Id,Period>();
        Set<Id> periodIds = new Set<Id>();
        List<User> forecastUsers = getForecastUsers(roleIds.size() == 0 ? new Set<Id>() : new Set<Id>(roleIds));
        // Create blank quota records for all users
        for (User user : forecastUsers) {
        	for(Period period : monthPeriods){
        		System.debug('Name = ' + user.Name + ', Id=' + User.Id + ' period: '+period);
	            Quota_Model quota = new Quota_Model();
	            quota.ownerName = user.Name;
	            quota.ownerId = user.Id;
	            quota.ownerRole = user.UserRole.Name;
	            quota.periodId = period.Id;
	            //quota.startDate = period.StartDate;
	            //DateTime startDateDT = DateTime.newInstance(quota.startDate.year(),quota.startDate.month(),quota.startDate.day());
	            //quota.startDateLong = startDateDT.getTime();
	            Date startDate = period.StartDate;
	            	quota.startDateStr = (Decimal.valueOf(startDate.month())<10?'0':'')
                        +startDate.month()+'/'+
                        +(Decimal.valueOf(startDate.day())<10?'0':'')
                        +startDate.day()+'/'+
                        startDate.year();
	            //if(!periodMap.containsKey(period.Id)){periodMap.put(period.Id,period);}
	            if(!periodIds.contains(period.Id)){periodIds.add(period.Id);}
	            quota.isQuantity = isQuant;
	            quota.currencyIsoCode = isMultiCurrencyOrg ? (String)((SObject)user).get('DefaultCurrencyIsoCode') : null;
	            //quota.productFamily = isProductFamily ? selectedProductFamily : null;
	            quota.forecastingTypeId = forecastingTypeId;
	            
	            Map<Integer,String> sortLabelMap = getSortAndLabel(period);
	            for(Integer i:sortLabelMap.keySet()){
	            	quota.sortOrder = i;
	            	quota.quotaLabel = sortLabelMap.get(i);
	            }
	            
	            if(quotaMap.containsKey(user.Id)){
	            	List<Quota_Model> quotaList = quotaMap.get(user.Id);
	            	quotaList.add(quota);
	            	quotaMap.put(user.Id, quotaList);
	            }
	            else{
	            	quotaMap.put(user.Id, new List<Quota_Model>{quota});
	            }
        	}
        }
        
        Set<Id> userIds = quotaMap.keySet();
        
        // We have to use this clunky query creation, rather than using
        // the [SELECT... ] method, because if we reference CurrencyIsoCode
        // in a mono-currency org, we'll get a runtime error.
        String query = 'SELECT Id, QuotaOwnerId, PeriodId, StartDate';
        
        if (isQuant) {
            query += ', QuotaQuantity';
        }
        else {
            query += ', QuotaAmount';
        }
        
        if (isMultiCurrencyOrg)
            query += ', CurrencyIsoCode';
            
        query += ' FROM ForecastingQuota WHERE QuotaOwnerId IN :userIds';
        query += ' AND PeriodId IN :periodIds';
        query += ' AND isQuantity=:isQuant';
        query += ' AND ForecastingTypeId=:forecastingTypeId';
        
        /*
        if (isProductFamily) {
            query += ' AND ProductFamily=:selectedProductFamily';
        }
        else {
            query += ' AND ProductFamily=\'\'';
        }
        */
        List<SObject> quotasFromDB = Database.query(query);
        
        for (SObject sobj : quotasFromDB) {
            Id userId = (Id) sobj.get('QuotaOwnerId');
            for(Quota_Model quotaInList: quotaMap.get(userId)){
            	if(quotaInList.periodId == sobj.get('PeriodId')){
            		Quota_Model quota = quotaInList;
		            quota.quotaId = sobj.Id;
		            quota.periodId = (String) sobj.get('PeriodId');
		            quota.amount = (Double) sobj.get(isQuant ? 'QuotaQuantity' : 'QuotaAmount');
		            quota.isQuantity = isQuant;
		            quota.prevAmount = quota.amount;
		            //quota.startDate = (Date)sobj.get('StartDate');
		            //DateTime startDateDT = DateTime.newInstance(quota.startDate.year(),quota.startDate.month(),quota.startDate.day());
	            	//quota.startDateLong = startDateDT.getTime();
	            	
	            	Date startDate = (Date)sobj.get('StartDate');
	            	quota.startDateStr = (Decimal.valueOf(startDate.month())<10?'0':'')
                        +startDate.month()+'/'+
                        +(Decimal.valueOf(startDate.day())<10?'0':'')
                        +startDate.day()+'/'+
                        startDate.year();
	            	
		            /*
		            Map<Integer,String> sortLabelMap = getSortAndLabel(periodMap.get(periodId));
			            for(Integer i:sortLabelMap.keySet()){
			            	quota.sortOrder = i;
			            	quota.quotaLabel = sortLabelMap.get(i);
			            }
		            */
		            if (isMultiCurrencyOrg) {
		                quota.currencyIsoCode = (String) sobj.get('CurrencyIsoCode');
		            }
            	}
            }
            
        }
        
    	List<Quota_Model> ret = new List<Quota_Model>();
        for(List<Quota_Model> quotaList : quotaMap.values()){
        	ret.addAll(quotaList);
        }
        ret.sort();
    	System.debug(loggingLevel.INFO, 'Returning ' + ret.size() + ' rows, # from DB= ' + quotasFromDB.size());
        return ret;
    }
    
    public static Map<Integer,String> getSortAndLabel(Period period){
    	Map<Integer,String> sortLabelMap = new Map<Integer,String>();
    	Integer sortNum;
    	String label;
        if(period.FullyQualifiedLabel.startsWith('January')){
        	label = 'January';
        	sortNum = 8;
        }
        else if(period.FullyQualifiedLabel.startsWith('February')){
        	label = 'February';
        	sortNum = 9;
        }
        else if(period.FullyQualifiedLabel.startsWith('March')){
        	label = 'March';
        	sortNum = 10;
        }
        else if(period.FullyQualifiedLabel.startsWith('April')){
        	label = 'April';
        	sortNum = 11;
        }
        else if(period.FullyQualifiedLabel.startsWith('May')){
        	label = 'May';
        	sortNum = 12;
        }
        else if(period.FullyQualifiedLabel.startsWith('June')){
        	label = 'June';
        	sortNum = 1;
        }
        else if(period.FullyQualifiedLabel.startsWith('July')){
        	label = 'July';
        	sortNum = 2;
        }
        else if(period.FullyQualifiedLabel.startsWith('August')){
        	label = 'August';
        	sortNum = 3;
        }
        else if(period.FullyQualifiedLabel.startsWith('September')){
        	label = 'September';
        	sortNum = 4;
        }
        else if(period.FullyQualifiedLabel.startsWith('October')){
        	label = 'October';
        	sortNum = 5;
        }
        else if(period.FullyQualifiedLabel.startsWith('November')){
        	label = 'November';
        	sortNum = 6;
        }
        else if(period.FullyQualifiedLabel.startsWith('December')){
        	label = 'December';
        	sortNum = 7;
        }
        if(label!=null && sortNum !=null){
        	sortLabelMap.put(sortNum,label);
        }
        return sortLabelMap;
    }

    @RemoteAction
    public static void saveRemoteAction(List<Quota_Model> quotas, List<Id> periodIds) {

        if (!Quota_PermUtil.isWriteAllowed()) {
            NoAccessException e = new NoAccessException();
            e.setMessage(System.Label.QT_Quota_NoWritePerm);
            throw e;
        }
            
        saveInternal(quotas, periodIds);        
    }
    
    
    private static void saveInternal(List<Quota_Model> quotaModelList, List<Id> periodIds) {
        //Period period = Quota_CalendarUtil.getPeriodById(periodId);
        
        Map<Id,Period> periodMap = new Map<Id,Period>([SELECT Id,StartDate FROM Period WHERE Id in : periodIds]);
        List<ForecastingQuota> quotasList = new List<ForecastingQuota>();
        Set<Id> idsToDelete = new Set<Id>();

        for (Quota_Model q : quotaModelList) {
            System.debug(loggingLevel.INFO, 'Name:' + q.ownerName + ' Id: '+q.quotaId+' Amount: ' + q.amount+ ' Previous: '+q.prevAmount);
            
            if (q.isDeleted != null && q.isDeleted) {
                idsToDelete.add(q.quotaId);
            }
                
            if (!idsToDelete.contains(q.quotaId) && ((q.quotaId == null && q.amount != null && q.amount != 0 && q.amount != 0.0) || 
            										(q.quotaId != null && q.prevAmount != null && q.prevAmount != q.amount))){
            	
            	/*workaround for serializing bug with Dates+ remote JS.
		        system.debug('stringDate'+q.startDateStr);
		        List<String> splitDate = q.startDateStr.split('/');
		        system.debug('split'+splitdate);
            	Date convertedDate = Date.newInstance(Integer.valueOf(splitDate[2]), Integer.valueOf(splitDate[1]), Integer.valueOf(splitDate[0]));
		        
		        ForecastingQuota fq = new ForecastingQuota(Id = q.quotaId, QuotaOwnerId = q.ownerId, StartDate = convertedDate, ForecastingTypeId = q.forecastingTypeId);
		        */

            	ForecastingQuota fq = new ForecastingQuota(Id = q.quotaId, QuotaOwnerId = q.ownerId, StartDate = periodMap.get(q.periodId).StartDate, ForecastingTypeId = q.forecastingTypeId);
            	
                    
	            if (q.isQuantity) {
	                fq.QuotaQuantity = q.amount;
	            }
	            else {
	                fq.QuotaAmount = q.amount;
	            }
	            
	            if (q.productFamily != null) {
	                fq.ProductFamily = q.productFamily;
	            }
	            
	            if (isMultiCurrencyOrg) {
	                // Necessary because referencing CurrencyIsoCode in a mono-currency org
	                // results in a runtime exception.
	                sObject sobj = fq;
	                sobj.put('CurrencyIsoCode', q.currencyIsoCode);
	            }
	            
	            //System.debug('Going to save this quota: quantity=' + (q.isQuantity ? 'true' : 'false') +
	            //             'amount=' + (q.isQuantity ? fq.QuotaQuantity : fq.QuotaAmount) + ', owner=' + fq.QuotaOwnerId+', id=='+fq.id+' prevAmount: '+q.prevAmount);
	            
	            quotasList.add(fq);	
            }    
            
            
        }
        
        if (quotasList.size() > 0){
        	system.debug(quotasList);
            upsert quotasList ;
            quotasList.clear();
        }
       
         system.debug('quotasList'+quotasList.size());
        if (idsToDelete.size() > 0) {
            List<ForecastingQuota> objToDelete = [SELECT Id FROM ForecastingQuota WHERE Id IN :idsToDelete];
            delete objToDelete;
        }
        return;
    }
    public id uorroleid{get;set;}
    public  Id getRootRoleId() {
        if (Quota_PermUtil.isReadOnlyAll() || Quota_PermUtil.isReadWriteAll())
        {
            /*if(Quota_PermUtil.isReadWriteAll()==true)
            {
                system.debug('Ã©nterde--------->>'+Quota_PermUtil.isReadOnlyAll());
                system.debug('Ã©nterde-------3-->>'+Quota_PermUtil.isReadWriteAll());
                return Quota_RoleUtils.getRoleIdByUserId(thisUserId);
            }*/
            system.debug('Ã©nterde--------->>'+Quota_PermUtil.isReadOnlyAll());
            system.debug('Ã©nterde-------3-->>'+Quota_PermUtil.isReadWriteAll());
            //uorroleid=Quota_RoleUtils.getRoleIdByUserId(thisUserId);
            return null;
        }
        else
        {
            system.debug(' Quota_RoleUtils.getRoleIdByUserId(thisUserId)'+ Quota_RoleUtils.getRoleIdByUserId(thisUserId));
            uorroleid=Quota_RoleUtils.getRoleIdByUserId(thisUserId);

            return Quota_RoleUtils.getRoleIdByUserId(thisUserId);
            
        }
    }
    
    public List<SelectOption> getAvailablePeriodTypes() {
        List<SelectOption> types = new List<SelectOption>();
        List<SObject> typesFromQuery = [SELECT Type FROM Period WHERE Id IN (SELECT PeriodId from ForecastingItem) GROUP BY Type];
        for (Sobject s : typesFromQuery) {        
            types.add(new SelectOption((String)s.get('Type'),(String) s.get('Type')));
        }
        if (typesFromQuery.size() == 1) {
            periodType = types.get(0).getValue();
        }
        return types;
    }
    
    public List<SelectOption> getAvailablePeriods() {
    	system.debug('jsh periodType'+periodType);
        return Quota_CalendarUtil.getAvailablePeriods(null, periodType);
    }
    
    public static List<SelectOption> getActiveForecastingTypes() {
        return Quota_ForecastingTypeUtil.getActiveForecastingTypesAsOptions();
    }
    
    public static List<SelectOption> getQuantityOptions() {
        List<SelectOption> ret = new List<SelectOption>();
        ret.add(new SelectOption('true', System.Label.QT_Quantity));
        ret.add(new SelectOption('false', System.Label.QT_Revenue));
        return ret;
    }
    
    public static List<SelectOption> getProductFamilies() {
        return Quota_ProductFamilyUtil.getActiveProductFamilies();
    }
    
    public static String getUserNameColumnHeader() {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.User.fields.getMap();                
        return M.get('Name').getDescribe().getLabel();
    }
    /*
    public static String getRoleNameColumnHeader() {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.UserRole.fields.getMap();
        return M.get('Name').getDescribe().getLabel();
    }
    */
    public static String getCurrencyColumnHeader() {
        if (UserInfo.isMultiCurrencyOrganization()) {
            Map<String, Schema.SObjectField> M = Schema.SObjectType.ForecastingQuota.fields.getMap();
            Schema.SObjectField isof = M.get('currencyIsoCode');
            return isof.getDescribe().getLabel();
            //return ForecastingQuota.currencyIsoCode.getDescribe().getLabel();
        }
        else {
            return 'Currency';
        }
    }
    
    public static String getQuotaColumnHeader(Boolean isQuantity) {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.ForecastingQuota.fields.getMap();
        
        if (isQuantity) {
            return M.get('QuotaQuantity').getDescribe().getLabel();
        }
        else {
            return M.get('QuotaAmount').getDescribe().getLabel();
        }       
    }
    
    public boolean getRenderCurrencyColumn(Boolean isQuantity) {
        return isMultiCurrencyOrg && !isQuantity;
    }
    /*
    public List<SelectOption> getAvailableIsoCodes() {
        return availableIsoCodes;
    }
    */
    private static boolean isMultiCurrencyOrg = Quota_CurrencyUtil.isMultiCurrencyOrg();
    //private static List<SelectOption> availableIsoCodes = isMultiCurrencyOrg ? Quota_CurrencyUtil.getAvailableIsoCodes() : null;
    
    public boolean displayPopup {get; set;}
    
    public String selectedRoles {get; set;}
    
    public void closePopup() {
        displayPopup = false;
    }
    public void showPopup() {
        displayPopup = true;
    }
    
    /*
    @RemoteAction
    public static void saveToPeriodRemoteAction(final Id forecastingTypeId, final Id futurePeriodId, List<Id> roleIds, List<Quota_Model> quotas) { // final String selectedProductFamily,

        if (!Quota_PermUtil.isWriteAllowed()) {
            NoAccessException e = new NoAccessException();
            e.setMessage(System.Label.QT_Quota_NoWritePerm);
            throw e;
        }
        //final Id forecastingTypeId = Quota_ForecastingTypeUtil.getRevenueForecastingType();
        ForecastingType forecastingType = Quota_ForecastingTypeUtil.getForecastingTypeById(forecastingTypeId);
        List<Quota_Model> futureQuotas = refreshQuotas(futurePeriodId, forecastingType, roleIds);
        Period futurePeriod = Quota_CalendarUtil.getPeriodById(futurePeriodId);
        
        // Get any saved quotas for the future period
        Map<Id, Quota_Model> quotasForFuture = new Map<Id, Quota_Model>();
        for (Quota_Model q : futureQuotas) {
            quotasForFuture.put(q.ownerId, q);
        }
        
        // Modify future period's quotas with this period's numbers
        for (Quota_Model m : quotas) {
            Quota_Model m2 = quotasForFuture.get(m.ownerId);
            m2.startDate = futurePeriod.StartDate;
            m2.periodId = futurePeriodId;
            m2.amount = m.amount;
            
            if (isMultiCurrencyOrg) {
                m2.currencyIsoCode = m.currencyIsoCode;
            }
        }
        
        saveInternal(quotasForFuture.values(), futurePeriodId);

    }*/
}