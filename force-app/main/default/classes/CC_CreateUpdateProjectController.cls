/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 07-18-2023
 * @last modified by  : Austin Barthel
**/
public with sharing class CC_CreateUpdateProjectController {
    public class CC_CreateUpdateProjectControllerException extends Exception {}
    @TestVisible
    private static final String TOO_MANY_PROJECTS_ERROR = 'This RES record has more than one active project associated with it. Please manage projects before continuing.';

    @AuraEnabled
    public static Id manageProjectHandler(Id resId, Id projectId, String projectName, List<Id> phasesToClone, List<Id> phasesToDelete, Date startDate){
        try {
            CC_ManageProject helper = new CC_ManageProject();
            if(projectId == null){
                return helper.createProject(resId, phasesToClone, projectName, startDate);
            } else{
                return helper.updateProject(resId, projectId, phasesToClone, phasesToDelete, startDate);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    @AuraEnabled(cacheable=true)
    public static ProjectWrapper getProject(Id resId){
        try {
            List<project_cloud__Project__c> projects = [
                SELECT
                    Name,
                    (
                        SELECT project_cloud__Cloned_From__c
                        FROM project_cloud__Project_Phases__r
                    )
                FROM project_cloud__Project__c 
                WHERE Reference_Enterprise_Service__c = :resId
            ];
            
            if(projects == null || projects.isEmpty()){
                return null;
            } else if(projects.size() > 1){
                throw new CC_CreateUpdateProjectControllerException(TOO_MANY_PROJECTS_ERROR);
            }

            Set<Id> existingPhases = new Set<Id>();
            for(project_cloud__Project_Phase__c phase : projects[0].project_cloud__Project_Phases__r){
                existingPhases.add(phase.project_cloud__Cloned_From__c);
            }
            return new ProjectWrapper(new List<Id>(existingPhases), projects[0]);
        } catch (Exception e) {
            throw new AuraHandledException('Exception occurred:\r\n' + e.getMessage() + '\r\n' + e.getStackTraceString() + '\r\n');
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ProductDataMapping> getProductDataMapping(Id resId){
        try {

            Map<String,Schema.SObjectField> resFields = Schema.Reference_Enterprise_Service__c.SObjectType.getDescribe().fields.getMap();

            List<ProductDataMapping> fieldApiToMapping = new List<ProductDataMapping>();
            Set<String> fieldApis = new Set<String>();
            Set<Id> phaseIds = new Set<Id>();
            for(Res_Mapping__mdt record : Res_Mapping__mdt.getAll().values()){
                String label = resFields.get(record.Field_API__c).getDescribe().getLabel();
                fieldApiToMapping.add(new ProductDataMapping(record.Field_API__c, label, record.Phase_Template_Id__c));
                fieldApis.add(record.Field_API__c);
                phaseIds.add(record.Phase_Template_Id__c);
            }

            Map<Id, project_cloud__Project_Phase__c> phases = new Map<Id, project_cloud__Project_Phase__c>([
                SELECT Id, Name FROM project_cloud__Project_Phase__c WHERE Id IN :phaseIds
            ]);

            String query = ' SELECT ' + String.join(new List<String>(fieldApis), ', ');
            query = query.removeEnd(', ');
            query += ' FROM Reference_Enterprise_Service__c WHERE Id = :resId';

            Reference_Enterprise_Service__c res = Database.query(query);

            Map<String,Boolean> productValues = new Map<String,Boolean>();
            Boolean value;
            for(ProductDataMapping product : fieldApiToMapping){
                product.fieldValue = res.get(product.fieldApi) == 'Yes' ? true : false;
                product.phaseName = phases.get((Id)product.phaseId)?.Name;
            }

            return fieldApiToMapping;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ProductDataMapping{
        @AuraEnabled 
        public String fieldApi;

        @AuraEnabled 
        public String fieldLabel;
        
        @AuraEnabled 
        public Id phaseId;
        
        @AuraEnabled 
        public String phaseName;
        
        @AuraEnabled 
        public Boolean fieldValue;

        @AuraEnabled 
        public Boolean phaseInProject;

        public ProductDataMapping(String fieldApi, String fieldLabel, Id phaseId){
            this.fieldApi = fieldApi;
            this.phaseId = phaseId;
            this.fieldLabel = fieldLabel;
            this.phaseInProject = false;
        }

    }

    public class ProjectWrapper{
        @AuraEnabled
        public List<Id> phasesInProject;
        
        @AuraEnabled
        public project_cloud__Project__c project;

        public ProjectWrapper(List<Id> phasesInProject, project_cloud__Project__c project){
            this.phasesInProject = phasesInProject;
            this.project = project;
        }
    }
}