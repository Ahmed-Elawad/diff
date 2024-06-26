public with sharing class MergeFieldBinder {

    private static final String MERGE_FIELD_PATTERN = '\\{\\!([a-zA-Z_0-9]+).([a-zA-Z_0-9]+)\\}';

    private Map<String, Set<String>> objectFieldMap;
    private String originalMergeBody;

    public MergeFieldBinder(String mergeBody) {
        this.originalMergeBody = mergeBody;
        this.objectFieldMap = getMergeFields(mergeBody);
    }

    private Map<String, Set<String>> getMergeFields(String mergeBody) {
        Pattern mergePattern = Pattern.compile(MERGE_FIELD_PATTERN);
        Matcher mergeMatcher = mergePattern.matcher(mergeBody);
        Map<String, Set<String>> objectFieldMap = new Map<String, Set<String>>();
        while (mergeMatcher.find()) {
            String objectName = mergeMatcher.group(1);
            String fieldName = mergeMatcher.group(2);

            if (objectFieldMap.containsKey(objectName)) {
                objectFieldMap.get(objectName).add(fieldName);
            } else {
                objectFieldMap.put(objectName, new Set<String> {fieldName});
            }
        }
        return objectFieldMap;
    }

    /**
    *   Populate merge fields from an sobject map
    *   Throws a MergeBinderException if a field is not found on an SObject
    *   If the merge object is not found, the merge fields will not be replaced
    *
    *   @param  sobjectMap  A map of SObject type name to the Sobject (e.g. {'Contact' => Contact, 'Account' => Account})
    *
    *   @return Returns the merge text with merge fields populated
    */
    public String replaceMergeFields(Map<String, SObject> sobjectMap) {
        String newMergeBody = this.originalMergeBody;
        for (String objectName : this.objectFieldMap.keySet()) {
            SObject mergeObject = sobjectMap.get(objectName);
            if (mergeObject == null) {
                continue;
            }

            for (String fieldName : objectFieldMap.get(objectName)) {
                Object fieldValue = mergeObject.get(fieldName);
                if (fieldValue == null) {
                    continue;
                }

                newMergeBody = newMergeBody.replace(
                        '{!' + objectName + '.' + fieldName + '}',
                        String.valueOf(fieldValue)
                );
            }
        }
        return newMergeBody;
    }

    /**
	 * @description overloaded function from above to only accept a label value map. The intent is that
	 * there is only one object to take values from
	 * @return the replaced string
	 **/
    public String replaceMergeFields(Map<String,String> labelValueMap){
        String newMergeBody = this.originalMergeBody;
        for (String fieldName : labelValueMap.keySet()) {
            String fieldValue = labelValueMap.get(fieldName);

            if (fieldValue == null) {
                newMergeBody = newMergeBody.replace('{!' + fieldName + '}','');
                continue;
            }

            newMergeBody = newMergeBody.replace(
                    '{!' + fieldName + '}',
                    String.valueOf(fieldValue)
            );
        }
        return newMergeBody;
    }
}