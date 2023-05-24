public with sharing class ConnectionDetailsBitbucketOnpremise extends ConnectionDetails {
    private String bitbucketServerProject;
    private String bitbucketServerToken;
    private String bitbucketServerUrl;
    private String bitbucketServerUsername;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT
                Name,
                Bitbucket_Server_Project__c,
                Bitbucket_Server_Token__c,
                Bitbucket_Server_Url__c,
                Bitbucket_Server_Username__c
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
        this.bitbucketServerProject = connectionDetailsList[0].Bitbucket_Server_Project__c;
        this.bitbucketServerToken = connectionDetailsList[0].Bitbucket_Server_Token__c;
        this.bitbucketServerUrl = connectionDetailsList[0].Bitbucket_Server_Url__c;
        this.bitbucketServerUsername = connectionDetailsList[0].Bitbucket_Server_Username__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.bitbucketServerProject = (String) envVariables.get('bitbucketServerProject');
        this.bitbucketServerToken = (String) envVariables.get('bitbucketServerToken');
        this.bitbucketServerUrl = (String) envVariables.get('bitbucketServerUrl');
        this.bitbucketServerUsername = (String) envVariables.get('bitbucketServerUsername');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Bitbucket_Server_Project__c = this.bitbucketServerProject;
        emptyConnectionDetailsObj.Bitbucket_Server_Token__c = this.bitbucketServerToken;
        emptyConnectionDetailsObj.Bitbucket_Server_Url__c = this.bitbucketServerUrl;
        emptyConnectionDetailsObj.Bitbucket_Server_Username__c = this.bitbucketServerUsername;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Bitbucket_Server_Project__c.getDescribe(),
                Connection_Details__c.Bitbucket_Server_Token__c.getDescribe(),
                Connection_Details__c.Bitbucket_Server_Url__c.getDescribe(),
                Connection_Details__c.Bitbucket_Server_Username__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'bitbucketServerProject' => this.bitbucketServerProject,
            'bitbucketServerToken' => this.bitbucketServerToken,
            'bitbucketServerUrl' => this.bitbucketServerUrl,
            'bitbucketServerUsername' => this.bitbucketServerUsername
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}