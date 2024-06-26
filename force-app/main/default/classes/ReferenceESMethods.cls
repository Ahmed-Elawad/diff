/*
*	Contains methods pertinent to the Reference Enterprise Service Object
*
*	History
*  ---------
*	04/15/2016	Jacob Hinds		Created
*
*/

public with sharing class ReferenceESMethods {

	//update all child objects of the Reference Enterprise Service Record
	public static void updateChildObjects(Map<Id,Id>refESMap){
		Reference_ES_ERR_Contact__c[] contactList = new Reference_ES_ERR_Contact__c[]{};
		Reference_ES_Action_Plan__c[] actionList = new Reference_ES_Action_Plan__c[]{};
		Reference_ES_Products_at_Risk__c[] riskList = new Reference_ES_Products_at_Risk__c[]{};
		Reference_ES_Potential_Products__c[] productList = new Reference_ES_Potential_Products__c[]{};
		Reference_ES_Client_Concern_Projects__c[] concernList = new Reference_ES_Client_Concern_Projects__c[]{};
		Reference_ES_Preview_to_Flex_Needs__c[] needList = new Reference_ES_Preview_to_Flex_Needs__c[]{};

		for(Reference_ES_ERR_Contact__c esContact:[SELECT Id,OwnerId,Reference_Enterprise_Service__c FROM Reference_ES_ERR_Contact__c WHERE Reference_Enterprise_Service__c in :refESMap.keySet()]){
			Id newOwner = refESMap.get(esContact.Reference_Enterprise_Service__c);
			if(newOwner!=null && esContact.OwnerId != newOwner){
				esContact.OwnerId = newOwner;
				contactList.add(esContact);
			}
		}
		
		for(Reference_ES_Action_Plan__c esAction:[SELECT Id,OwnerId,Reference_Enterprise_Service__c FROM Reference_ES_Action_Plan__c WHERE Reference_Enterprise_Service__c in :refESMap.keySet()]){
			Id newOwner = refESMap.get(esAction.Reference_Enterprise_Service__c);
			if(newOwner!=null && esAction.OwnerId != newOwner){
				esAction.OwnerId = newOwner;
				actionList.add(esAction);
			}
		}
		
		for(Reference_ES_Products_at_Risk__c esRisk:[SELECT Id,OwnerId,Reference_Enterprise_Service__c FROM Reference_ES_Products_at_Risk__c WHERE Reference_Enterprise_Service__c in :refESMap.keySet()]){
			Id newOwner = refESMap.get(esRisk.Reference_Enterprise_Service__c);
			if(newOwner!=null && esRisk.OwnerId != newOwner){
				esRisk.OwnerId = newOwner;
				riskList.add(esRisk);
			}
		}
		
		for(Reference_ES_Potential_Products__c esProduct:[SELECT Id,OwnerId,Reference_Enterprise_Service__c FROM Reference_ES_Potential_Products__c WHERE Reference_Enterprise_Service__c in :refESMap.keySet()]){
			Id newOwner = refESMap.get(esProduct.Reference_Enterprise_Service__c);
			if(newOwner!=null && esProduct.OwnerId != newOwner){
				esProduct.OwnerId = newOwner;
				productList.add(esProduct);
			}
		}
		
		for(Reference_ES_Client_Concern_Projects__c esConcern:[SELECT Id,OwnerId,Reference_Enterprise_Service__c FROM Reference_ES_Client_Concern_Projects__c WHERE Reference_Enterprise_Service__c in :refESMap.keySet()]){
			Id newOwner = refESMap.get(esConcern.Reference_Enterprise_Service__c);
			if(newOwner!=null && esConcern.OwnerId != newOwner){
				esConcern.OwnerId = newOwner;
				concernList.add(esConcern);
			}
		}
		
		for(Reference_ES_Preview_to_Flex_Needs__c esNeed:[SELECT Id,OwnerId,Reference_Enterprise_Service__c FROM Reference_ES_Preview_to_Flex_Needs__c WHERE Reference_Enterprise_Service__c in :refESMap.keySet()]){
			Id newOwner = refESMap.get(esNeed.Reference_Enterprise_Service__c);
			if(newOwner!=null && esNeed.OwnerId != newOwner){
				esNeed.OwnerId = newOwner;
				needList.add(esNeed);
			}
		}
		
		//update records
		if(!contactList.isEmpty()){
			update contactList;
		}
		if(!actionList.isEmpty()){
			update actionList;
		}
		if(!riskList.isEmpty()){
			update riskList;
		}
		if(!productList.isEmpty()){
			update productList;
		}
		if(!concernList.isEmpty()){
			update concernList;
		}
		if(!needList.isEmpty()){
			update needList;
		}
	}

}