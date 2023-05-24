public with sharing class ConnectedItemsController {
    @AuraEnabled
    public static List<Object> getAvailableRepositories() {
        try {
            List<Object> repositoryWrapperList = new List<Object>();

            for (Flosum__Repository__c repository : [
                SELECT Id, Name
                FROM Flosum__Repository__c
                WHERE Id NOT IN (SELECT Repository__c FROM Repository_Connection__c)
                WITH SECURITY_ENFORCED
                ORDER BY Name
            ]) {
                repositoryWrapperList.add(
                    new Map<String, Object>{ 'value' => repository.Id, 'label' => repository.Name }
                );
            }
            return repositoryWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Object> getConnectedRepositories(String connectionId) {
        try {
            List<Repository_Connection__c> repositoryConnections = [
                SELECT Repository__c, Repository__r.Name
                FROM Repository_Connection__c
                WHERE Connection__c = :connectionId
                WITH SECURITY_ENFORCED
            ];
            List<Object> connectedItems = new List<Object>();
            for (Repository_Connection__c record : repositoryConnections) {
                connectedItems.add(
                    new Map<String, Object>{ 'value' => record.Repository__c, 'label' => record.Repository__r.Name }
                );
            }
            return connectedItems;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}