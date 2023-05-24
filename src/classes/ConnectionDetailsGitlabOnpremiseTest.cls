@IsTest
private with sharing class ConnectionDetailsGitlabOnpremiseTest {
    private static final String gitlabServerToken = 'gitlab-server-token';
    private static final String gitlabServerUrl = 'gitlab-server-url';
    private static final String gitlabServerUsername = 'gitlab-server-username';

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
            Git_Provider__c = 'GitLab Onpremise',
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
            Gitlab_Server_Token__c = gitlabServerToken,
            Gitlab_Server_Url__c = gitlabServerUrl,
            Gitlab_Server_Username__c = gitlabServerUsername
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
        ConnectionDetails connectionDetails = new ConnectionDetailsGitlabOnpremise();
        connectionDetails.init(String.valueOf(connection.Id));
        Test.stopTest();

        Map<String, Object> resultMap = connectionDetails.getValuesMap(true);
        Map<String, Object> envVariables = (Map<String, Object>) resultMap.get('envVariables');

        System.assertEquals(gitlabServerToken, (String) envVariables.get('gitlabServerToken'));
        System.assertEquals(gitlabServerUrl, (String) envVariables.get('gitlabServerUrl'));
        System.assertEquals(gitlabServerUsername, (String) envVariables.get('gitlabServerUsername'));
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
            ConnectionDetails connectionDetails = new ConnectionDetailsGitlabOnpremise();
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
                'gitlabServerToken' => gitlabServerToken,
                'gitlabServerUrl' => gitlabServerUrl,
                'gitlabServerUsername' => gitlabServerUsername
            }
        );

        Test.startTest();
        ConnectionDetails connectionDetails = new ConnectionDetailsGitlabOnpremise();
        connectionDetails.init(connectionMap);
        connectionDetails.upsertConnection();
        Test.stopTest();

        Connection_Details__c connectionDetailsUpserted = [
            SELECT Id, Name, Gitlab_Server_Token__c, Gitlab_Server_Url__c, Gitlab_Server_Username__c
            FROM Connection_Details__c
            WHERE Name != :connection.Id
            LIMIT 1
        ];

        System.assertEquals(gitlabServerToken, connectionDetailsUpserted.Gitlab_Server_Token__c);
        System.assertEquals(gitlabServerUrl, connectionDetailsUpserted.Gitlab_Server_Url__c);
        System.assertEquals(gitlabServerUsername, connectionDetailsUpserted.Gitlab_Server_Username__c);
    }
}