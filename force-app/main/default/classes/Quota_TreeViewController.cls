public with sharing class Quota_TreeViewController {
    
    private static JSONGenerator gen {get; set;}

    public Boolean selectable {get; set;}
    
    public String selectNodeKeys {get; set;}

    {
        selectable = false;
        selectNodeKeys = 'No value selected';
    }
    
    public String JsonData {get; set;}
    
    public static Id roleId {get; set;}
    
    public String getJsonString()
    {
        string urole;
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(!profileName.contains('System Administrator'))
        {
            Id parentRoleId = Quota_RoleUtils.getParentRoleId(UserInfo.getUserRoleId());
        	urole= String.valueOf(parentRoleId);
        }
        else{
            urole=null;
        }
       system.debug('xxxxxxxxxxxxxxxxxxxxxxxxxxx'+urole);
        if (JsonData == null){
            system.debug('Role Id is not passed so entered here---------->>>');
            
            JsonData = getTreeJSON(urole);
        }
        return JsonData;
    }
    
    @RemoteAction
    public static String getChildNodesJSON(Id parentId) {
        return getTreeJSON(parentId);
    }
    
    private static String getTreeJSON(Id parentId) {
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for (Quota_RoleNodeModel node : getRoleNodesByParentId(parentId)) {
            node.convertNodeToJSON(gen);
        }
        gen.writeEndArray();
        return gen.getAsString();
    } 
    
    private static List<Quota_RoleNodeModel> getRoleNodesByParentId(Id parentId) {
        if (parentId == null) 
            parentId = roleId;
        List<UserRole> roles = Quota_RoleUtils.getSubRolesOneLevel(parentId);
        List<Quota_RoleNodeModel> ret = new List<Quota_RoleNodeModel>();
        for (UserRole role : roles) {
        	//this will make it so users can manage their own role as well as the roles below them, but not roles at the same level
        	if(role.Id == UserInfo.getUserRoleId()){
        		ret.clear();
        		Quota_RoleNodeModel n = new Quota_RoleNodeModel(role);
            	ret.add(n);
        		break;	
        	}
            Quota_RoleNodeModel n = new Quota_RoleNodeModel(role);
            ret.add(n);
        }
        return ret;
    }
    
}