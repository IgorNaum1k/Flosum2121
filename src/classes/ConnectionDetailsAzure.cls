public with sharing class ConnectionDetailsAzure extends ConnectionDetails {
    private String azureOrganization;
    private String azureProject;
    private String azureToken;
    private String azureUsername;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT Id, Name, Azure_Organization__c, Azure_Project__c, Azure_Token__c, Azure_Username__c
            FROM Connection_Details__c
            WHERE Name = :connectionId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (connectionDetailsList.isEmpty()) {
            throw new HandledException(Constants.MISSING_CONNECTION_DETAILS_SETTING_ERROR);
        }

        this.detailsId = connectionDetailsList[0].Id;
        this.detailsName = connectionDetailsList[0].Name;
        this.azureOrganization = connectionDetailsList[0].Azure_Organization__c;
        this.azureProject = connectionDetailsList[0].Azure_Project__c;
        this.azureToken = connectionDetailsList[0].Azure_Token__c;
        this.azureUsername = connectionDetailsList[0].Azure_Username__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.azureOrganization = (String) envVariables.get('azureOrganization');
        this.azureProject = (String) envVariables.get('azureProject');
        this.azureToken = (String) envVariables.get('azureToken');
        this.azureUsername = (String) envVariables.get('azureUsername');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Azure_Organization__c = this.azureOrganization;
        emptyConnectionDetailsObj.Azure_Project__c = this.azureProject;
        emptyConnectionDetailsObj.Azure_Token__c = this.azureToken;
        emptyConnectionDetailsObj.Azure_Username__c = this.azureUsername;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Azure_Organization__c.getDescribe(),
                Connection_Details__c.Azure_Project__c.getDescribe(),
                Connection_Details__c.Azure_Token__c.getDescribe(),
                Connection_Details__c.Azure_Username__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'azureOrganization' => this.azureOrganization,
            'azureProject' => this.azureProject,
            'azureToken' => this.azureToken,
            'azureUsername' => this.azureUsername
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}