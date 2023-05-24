public with sharing class ConnectionDetailsGitlab extends ConnectionDetails {
    private String gitlabGroupId;
    private String gitlabToken;
    private String gitlabUsername;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT Name, Gitlab_Group_Id__c, Gitlab_Token__c, Gitlab_Username__c
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
        this.gitlabGroupId = connectionDetailsList[0].Gitlab_Group_Id__c;
        this.gitlabToken = connectionDetailsList[0].Gitlab_Token__c;
        this.gitlabUsername = connectionDetailsList[0].Gitlab_Username__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.gitlabGroupId = (String) envVariables.get('gitlabGroupId');
        this.gitlabToken = (String) envVariables.get('gitlabToken');
        this.gitlabUsername = (String) envVariables.get('gitlabUsername');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Gitlab_Group_Id__c = this.gitlabGroupId;
        emptyConnectionDetailsObj.Gitlab_Token__c = this.gitlabToken;
        emptyConnectionDetailsObj.Gitlab_Username__c = this.gitlabUsername;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Gitlab_Group_Id__c.getDescribe(),
                Connection_Details__c.Gitlab_Token__c.getDescribe(),
                Connection_Details__c.Github_Server_Url__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'gitlabGroupId' => String.isEmpty(this.gitlabGroupId) ? null : this.gitlabGroupId,
            'gitlabToken' => this.gitlabToken,
            'gitlabUsername' => this.gitlabUsername
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}