public with sharing class ConnectionDetailsGithub extends ConnectionDetails {
    private String githubOrganization;
    private String githubToken;
    private String githubUsername;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT Name, Github_Organization__c, Github_Token__c, Github_Username__c
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
        this.githubOrganization = connectionDetailsList[0].Github_Organization__c;
        this.githubToken = connectionDetailsList[0].Github_Token__c;
        this.githubUsername = connectionDetailsList[0].Github_Username__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.githubOrganization = (String) envVariables.get('githubOrganization');
        this.githubToken = (String) envVariables.get('githubToken');
        this.githubUsername = (String) envVariables.get('githubUsername');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Github_Organization__c = this.githubOrganization;
        emptyConnectionDetailsObj.Github_Token__c = this.githubToken;
        emptyConnectionDetailsObj.Github_Username__c = this.githubUsername;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Github_Organization__c.getDescribe(),
                Connection_Details__c.Github_Token__c.getDescribe(),
                Connection_Details__c.Github_Username__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'githubOrganization' => String.isEmpty(this.githubOrganization) ? null : this.githubOrganization,
            'githubToken' => this.githubToken,
            'githubUsername' => this.githubUsername
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}