public with sharing class ConnectionDetailsBitbucket extends ConnectionDetails {
    private String bitbucketClientId;
    private String bitbucketClientSecret;
    private String bitbucketProject;
    private String bitbucketWorkspace;

    public override void init(String connectionId) {
        this.initConnection(connectionId);

        List<Connection_Details__c> connectionDetailsList = [
            SELECT
                Name,
                Bitbucket_Client_Id__c,
                Bitbucket_Client_Secret__c,
                Bitbucket_Project__c,
                Bitbucket_Workspace__c
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
        this.bitbucketClientId = connectionDetailsList[0].Bitbucket_Client_Id__c;
        this.bitbucketClientSecret = connectionDetailsList[0].Bitbucket_Client_Secret__c;
        this.bitbucketProject = connectionDetailsList[0].Bitbucket_Project__c;
        this.bitbucketWorkspace = connectionDetailsList[0].Bitbucket_Workspace__c;
    }

    public override void init(Map<String, Object> connection) {
        this.initConnection(connection);
        Map<String, Object> envVariables = (Map<String, Object>) connection.get('envVariables');
        this.detailsId = (String) envVariables.get('detailsId');
        this.detailsName = (String) envVariables.get('detailsName');
        this.bitbucketClientId = (String) envVariables.get('bitbucketClientId');
        this.bitbucketClientSecret = (String) envVariables.get('bitbucketClientSecret');
        this.bitbucketProject = (String) envVariables.get('bitbucketProject');
        this.bitbucketWorkspace = (String) envVariables.get('bitbucketWorkspace');
    }

    public override void upsertConnection() {
        this.upsertConnectionRecord();
        Connection_Details__c emptyConnectionDetailsObj = new Connection_Details__c();
        emptyConnectionDetailsObj.Id = this.detailsId;
        emptyConnectionDetailsObj.Name = this.connectionId;
        emptyConnectionDetailsObj.Bitbucket_Client_Id__c = this.bitbucketClientId;
        emptyConnectionDetailsObj.Bitbucket_Client_Secret__c = this.bitbucketClientSecret;
        emptyConnectionDetailsObj.Bitbucket_Project__c = this.bitbucketProject;
        emptyConnectionDetailsObj.Bitbucket_Workspace__c = this.bitbucketWorkspace;

        DatabaseUtils.upsertRecord(
            emptyConnectionDetailsObj,
            new List<Schema.DescribeFieldResult>{
                Connection_Details__c.Id.getDescribe(),
                Connection_Details__c.Name.getDescribe(),
                Connection_Details__c.Bitbucket_Client_Id__c.getDescribe(),
                Connection_Details__c.Bitbucket_Client_Secret__c.getDescribe(),
                Connection_Details__c.Bitbucket_Project__c.getDescribe(),
                Connection_Details__c.Bitbucket_Workspace__c.getDescribe()
            }
        );
    }

    public override Map<String, Object> getValuesMap(Boolean isFull) {
        Map<String, Object> valuesMap = this.getConnectionValuesMap(isFull);
        Map<String, Object> result = new Map<String, Object>{
            'bitbucketClientId' => this.bitbucketClientId,
            'bitbucketClientSecret' => this.bitbucketClientSecret,
            'bitbucketProject' => this.bitbucketProject,
            'bitbucketWorkspace' => this.bitbucketWorkspace
        };
        if (isFull) {
            result.put('detailsId', this.detailsId);
            result.put('detailsName', this.detailsName);
        }

        valuesMap.put('envVariables', result);
        return valuesMap;
    }
}