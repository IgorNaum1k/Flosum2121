@IsTest
private with sharing class ConnectionDetailsBitbucketTest {
    private static final String bitbucketClientId = 'bitbucket-clientid';
    private static final String bitbucketClientSecret = 'bitbucket-client-secret';
    private static final String bitbucketProject = 'bitbucket-project';
    private static final String bitbucketWorkspace = 'bitbucket-workspace';

    @TestSetup
    static void makeData() {
        TestUtils.createLoggerParentRecord();
        List<Flosum__Repository__c> repos = TestUtils.createFlosumRepositorys(1);
        List<Flosum__Branch__c> branches = TestUtils.createBranches(repos, 1);

        Flosum__Agent_Connection__c agentConnection = new Flosum__Agent_Connection__c(
            Name = 'agent-connection',
            Flosum__Url__c = 'https://test-agent.app'
        );
        insert agentConnection;

        Connection__c connection = new Connection__c(
            Name = 'TestConnection',
            Git_Provider__c = 'BitBucket',
            Agent_Connection__c = agentConnection.Id,
            Is_Enabled__c = true
        );
        insert connection;

        Repository_Connection__c repositoryConnection = new Repository_Connection__c(
            Repository__c = repos[0].Id,
            Connection__c = connection.Id
        );
        insert repositoryConnection;

        insert new Connection_Details__c(
            Name = connection.Id,
            Bitbucket_Client_Id__c = bitbucketClientId,
            Bitbucket_Client_Secret__c = bitbucketClientSecret,
            Bitbucket_Project__c = bitbucketProject,
            Bitbucket_Workspace__c = bitbucketWorkspace
        );
    }

    @IsTest
    static void initializationTest() {
        Connection__c connection = [SELECT Id FROM Connection__c LIMIT 1];
        Connection_Details__c connectionDetailsRecord = [
            SELECT Id, Name
            FROM Connection_Details__c
            WHERE Name = :connection.Id
            LIMIT 1
        ];

        Test.startTest();
        ConnectionDetails connectionDetails = new ConnectionDetailsBitbucket();
        connectionDetails.init(String.valueOf(connection.Id));
        Test.stopTest();

        Map<String, Object> resultMap = connectionDetails.getValuesMap(true);
        Map<String, Object> envVariables = (Map<String, Object>) resultMap.get('envVariables');

        System.assertEquals(bitbucketClientId, (String) envVariables.get('bitbucketClientId'));
        System.assertEquals(bitbucketClientSecret, (String) envVariables.get('bitbucketClientSecret'));
        System.assertEquals(bitbucketProject, (String) envVariables.get('bitbucketProject'));
        System.assertEquals(bitbucketWorkspace, (String) envVariables.get('bitbucketWorkspace'));
        System.assertEquals(connectionDetailsRecord.Id, (String) envVariables.get('detailsId'));
        System.assertEquals(connection.Id, (String) envVariables.get('detailsName'));
    }

    @IsTest
    static void initializationTestError() {
        Connection__c connection = [SELECT Id FROM Connection__c LIMIT 1];
        Connection_Details__c connectionDetailsRecord = [
            SELECT Id, Name
            FROM Connection_Details__c
            WHERE Name = :connection.Id
            LIMIT 1
        ];

        delete connectionDetailsRecord;
        Test.startTest();
        try {
            ConnectionDetails connectionDetails = new ConnectionDetailsBitbucket();
            connectionDetails.init(connection.Id);
        } catch (Exception e) {
            System.assertEquals(Constants.MISSING_CONNECTION_DETAILS_SETTING_ERROR, e.getMessage());
        }
        Test.stopTest();
    }

    static Map<String, Object> createConnectionMap(String connectedAgentId) {
        return new Map<String, Object>{
            'applicationUrl' => 'https://test-app.com',
            'gitProvider' => 'github',
            'connectedAgentId' => connectedAgentId,
            'isBidirectionalSynchronization' => true,
            'isConvertToSfdx' => true,
            'isEnabled' => true,
            'connectionId' => null,
            'connectionName' => 'TestConnection'
        };
    }

    @IsTest
    static void upsertConnectionTest() {
        Connection__c connection = [SELECT Id, Agent_Connection__c FROM Connection__c LIMIT 1];
        Map<String, Object> connectionMap = createConnectionMap(connection.Agent_Connection__c);
        connectionMap.put(
            'envVariables',
            new Map<String, Object>{
                'bitbucketClientId' => bitbucketClientId,
                'bitbucketClientSecret' => bitbucketClientSecret,
                'bitbucketProject' => bitbucketProject,
                'bitbucketWorkspace' => bitbucketWorkspace
            }
        );

        Test.startTest();
        ConnectionDetails connectionDetails = new ConnectionDetailsBitbucket();
        connectionDetails.init(connectionMap);
        connectionDetails.upsertConnection();
        Test.stopTest();

        Connection_Details__c connectionDetailsUpserted = [
            SELECT
                Id,
                Name,
                Bitbucket_Client_Id__c,
                Bitbucket_Client_Secret__c,
                Bitbucket_Project__c,
                Bitbucket_Workspace__c
            FROM Connection_Details__c
            WHERE Name != :connection.Id
            LIMIT 1
        ];

        System.assertEquals(bitbucketClientId, connectionDetailsUpserted.Bitbucket_Client_Id__c);
        System.assertEquals(bitbucketClientSecret, connectionDetailsUpserted.Bitbucket_Client_Secret__c);
        System.assertEquals(bitbucketProject, connectionDetailsUpserted.Bitbucket_Project__c);
        System.assertEquals(bitbucketWorkspace, connectionDetailsUpserted.Bitbucket_Workspace__c);
    }
}