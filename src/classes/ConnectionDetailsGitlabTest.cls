@IsTest
private with sharing class ConnectionDetailsGitlabTest {
    private static final String gitlabGroupId = 'gitlab-groupid';
    private static final String gitlabToken = 'gitlab-token';
    private static final String gitlabUsername = 'gitlab-username';

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
            Git_Provider__c = 'GitLab',
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
            Gitlab_Group_Id__c = gitlabGroupId,
            Gitlab_Token__c = gitlabToken,
            Gitlab_Username__c = gitlabUsername
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
        ConnectionDetails connectionDetails = new ConnectionDetailsGitlab();
        connectionDetails.init(String.valueOf(connection.Id));
        Test.stopTest();

        Map<String, Object> resultMap = connectionDetails.getValuesMap(true);
        Map<String, Object> envVariables = (Map<String, Object>) resultMap.get('envVariables');

        System.assertEquals(gitlabGroupId, (String) envVariables.get('gitlabGroupId'));
        System.assertEquals(gitlabToken, (String) envVariables.get('gitlabToken'));
        System.assertEquals(gitlabUsername, (String) envVariables.get('gitlabUsername'));
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
            ConnectionDetails connectionDetails = new ConnectionDetailsGitlab();
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
                'gitlabGroupId' => gitlabGroupId,
                'gitlabToken' => gitlabToken,
                'gitlabUsername' => gitlabUsername
            }
        );

        Test.startTest();
        ConnectionDetails connectionDetails = new ConnectionDetailsGitlab();
        connectionDetails.init(connectionMap);
        connectionDetails.upsertConnection();
        Test.stopTest();

        Connection_Details__c connectionDetailsUpserted = [
            SELECT Id, Name, Gitlab_Group_Id__c, Gitlab_Token__c, Gitlab_Username__c
            FROM Connection_Details__c
            WHERE Name != :connection.Id
            LIMIT 1
        ];

        System.assertEquals(gitlabGroupId, connectionDetailsUpserted.Gitlab_Group_Id__c);
        System.assertEquals(gitlabToken, connectionDetailsUpserted.Gitlab_Token__c);
        System.assertEquals(gitlabUsername, connectionDetailsUpserted.Gitlab_Username__c);
    }
}