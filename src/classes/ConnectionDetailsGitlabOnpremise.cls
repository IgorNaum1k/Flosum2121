public with sharing class ConnectionDetailsGitlabOnpremise extends ConnectionDetails {
    private String gitlabServerToken;
    private String gitlabServerUrl;
    private String gitlabServerUsername;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT Name, Gitlab_Server_Token__c, Gitlab_Server_Url__c, Gitlab_Server_Username__c
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
        this.gitlabServerToken = connectionDetailsList[0].Gitlab_Server_Token__c;
        this.gitlabServerUrl = connectionDetailsList[0].Gitlab_Server_Url__c;
        this.gitlabServerUsername = connectionDetailsList[0].Gitlab_Server_Username__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.gitlabServerToken = (String) envVariables.get('gitlabServerToken');
        this.gitlabServerUrl = (String) envVariables.get('gitlabServerUrl');
        this.gitlabServerUsername = (String) envVariables.get('gitlabServerUsername');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Gitlab_Server_Token__c = this.gitlabServerToken;
        emptyConnectionDetailsObj.Gitlab_Server_Url__c = this.gitlabServerUrl;
        emptyConnectionDetailsObj.Gitlab_Server_Username__c = this.gitlabServerUsername;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Gitlab_Server_Token__c.getDescribe(),
                Connection_Details__c.Gitlab_Server_Url__c.getDescribe(),
                Connection_Details__c.Gitlab_Server_Username__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'gitlabServerToken' => this.gitlabServerToken,
            'gitlabServerUrl' => this.gitlabServerUrl,
            'gitlabServerUsername' => this.gitlabServerUsername
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}