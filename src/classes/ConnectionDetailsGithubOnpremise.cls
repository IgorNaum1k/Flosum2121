public with sharing class ConnectionDetailsGithubOnpremise extends ConnectionDetails {
    private String githubServerOrganization;
    private String githubServerToken;
    private String githubServerUrl;
    private String githubServerUsername;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT
                Name,
                Github_Server_Organization__c,
                Github_Server_Token__c,
                Github_Server_Url__c,
                Github_Server_Username__c
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
        this.githubServerOrganization = connectionDetailsList[0].Github_Server_Organization__c;
        this.githubServerToken = connectionDetailsList[0].Github_Server_Token__c;
        this.githubServerUrl = connectionDetailsList[0].Github_Server_Url__c;
        this.githubServerUsername = connectionDetailsList[0].Github_Server_Username__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.githubServerOrganization = (String) envVariables.get('githubServerOrganization');
        this.githubServerToken = (String) envVariables.get('githubServerToken');
        this.githubServerUrl = (String) envVariables.get('githubServerUrl');
        this.githubServerUsername = (String) envVariables.get('githubServerUsername');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Github_Server_Organization__c = this.githubServerOrganization;
        emptyConnectionDetailsObj.Github_Server_Token__c = this.githubServerToken;
        emptyConnectionDetailsObj.Github_Server_Url__c = this.githubServerUrl;
        emptyConnectionDetailsObj.Github_Server_Username__c = this.githubServerUsername;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Github_Server_Organization__c.getDescribe(),
                Connection_Details__c.Github_Server_Token__c.getDescribe(),
                Connection_Details__c.Github_Server_Url__c.getDescribe(),
                Connection_Details__c.Github_Server_Username__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'githubServerOrganization' => this.githubServerOrganization,
            'githubServerToken' => this.githubServerToken,
            'githubServerUrl' => this.githubServerUrl,
            'githubServerUsername' => this.githubServerUsername
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}