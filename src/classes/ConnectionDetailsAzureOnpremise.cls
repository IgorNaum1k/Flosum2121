public with sharing class ConnectionDetailsAzureOnpremise extends ConnectionDetails {
    private String azureServerOrganization;
    private String azureServerPassword;
    private String azureServerProject;
    private String azureServerToken;
    private String azureServerUrl;
    private String azureServerUsername;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT
                Name,
                Azure_Server_Organization__c,
                Azure_Server_Password__c,
                Azure_Server_Project__c,
                Azure_Server_Token__c,
                Azure_Server_Url__c,
                Azure_Server_Username__c
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
        this.azureServerOrganization = connectionDetailsList[0].Azure_Server_Organization__c;
        this.azureServerPassword = connectionDetailsList[0].Azure_Server_Password__c;
        this.azureServerProject = connectionDetailsList[0].Azure_Server_Project__c;
        this.azureServerToken = connectionDetailsList[0].Azure_Server_Token__c;
        this.azureServerUrl = connectionDetailsList[0].Azure_Server_Url__c;
        this.azureServerUsername = connectionDetailsList[0].Azure_Server_Username__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.azureServerOrganization = (String) envVariables.get('azureServerOrganization');
        this.azureServerPassword = (String) envVariables.get('azureServerPassword');
        this.azureServerProject = (String) envVariables.get('azureServerProject');
        this.azureServerToken = (String) envVariables.get('azureServerToken');
        this.azureServerUrl = (String) envVariables.get('azureServerUrl');
        this.azureServerUsername = (String) envVariables.get('azureServerUsername');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Azure_Server_Organization__c = this.azureServerOrganization;
        emptyConnectionDetailsObj.Azure_Server_Password__c = this.azureServerPassword;
        emptyConnectionDetailsObj.Azure_Server_Project__c = this.azureServerProject;
        emptyConnectionDetailsObj.Azure_Server_Token__c = this.azureServerToken;
        emptyConnectionDetailsObj.Azure_Server_Url__c = this.azureServerUrl;
        emptyConnectionDetailsObj.Azure_Server_Username__c = this.azureServerUsername;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Azure_Server_Organization__c.getDescribe(),
                Connection_Details__c.Azure_Server_Password__c.getDescribe(),
                Connection_Details__c.Azure_Server_Project__c.getDescribe(),
                Connection_Details__c.Azure_Server_Token__c.getDescribe(),
                Connection_Details__c.Azure_Server_Url__c.getDescribe(),
                Connection_Details__c.Azure_Server_Username__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'azureServerOrganization' => this.azureServerOrganization,
            'azureServerPassword' => this.azureServerPassword,
            'azureServerProject' => this.azureServerProject,
            'azureServerToken' => this.azureServerToken,
            'azureServerUrl' => this.azureServerUrl,
            'azureServerUsername' => this.azureServerUsername
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}