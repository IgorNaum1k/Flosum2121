@IsTest
private with sharing class ConnectionDetailsGithubOnpremiseTest {
    private static final String githubServerOrganization = 'github-server-organization';
    private static final String githubServerToken = 'github-server-token';
    private static final String githubServerUrl = 'github-server-url';
    private static final String githubServerUsername = 'github-server-username';

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
            Git_Provider__c = 'GitHub Onpremise',
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
            Github_Server_Organization__c = githubServerOrganization,
            Github_Server_Token__c = githubServerToken,
            Github_Server_Url__c = githubServerUrl,
            Github_Server_Username__c = githubServerUsername
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
        ConnectionDetails connectionDetails = new ConnectionDetailsGithubOnpremise();
        connectionDetails.init(String.valueOf(connection.Id));
        Test.stopTest();

        Map<String, Object> resultMap = connectionDetails.getValuesMap(true);
        Map<String, Object> envVariables = (Map<String, Object>) resultMap.get('envVariables');

        System.assertEquals(githubServerOrganization, (String) envVariables.get('githubServerOrganization'));
        System.assertEquals(githubServerToken, (String) envVariables.get('githubServerToken'));
        System.assertEquals(githubServerUrl, (String) envVariables.get('githubServerUrl'));
        System.assertEquals(githubServerUsername, (String) envVariables.get('githubServerUsername'));
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
            ConnectionDetails connectionDetails = new ConnectionDetailsGithubOnpremise();
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
                'githubServerOrganization' => githubServerOrganization,
                'githubServerToken' => githubServerToken,
                'githubServerUrl' => githubServerUrl,
                'githubServerUsername' => githubServerUsername
            }
        );

        Test.startTest();
        ConnectionDetails connectionDetails = new ConnectionDetailsGithubOnpremise();
        connectionDetails.init(connectionMap);
        connectionDetails.upsertConnection();
        Test.stopTest();

        Connection_Details__c connectionDetailsUpserted = [
            SELECT
                Id,
                Name,
                Github_Server_Organization__c,
                Github_Server_Token__c,
                Github_Server_Url__c,
                Github_Server_Username__c
            FROM Connection_Details__c
            WHERE Name != :connection.Id
            LIMIT 1
        ];

        System.assertEquals(githubServerOrganization, connectionDetailsUpserted.Github_Server_Organization__c);
        System.assertEquals(githubServerToken, connectionDetailsUpserted.Github_Server_Token__c);
        System.assertEquals(githubServerUrl, connectionDetailsUpserted.Github_Server_Url__c);
        System.assertEquals(githubServerUsername, connectionDetailsUpserted.Github_Server_Username__c);
    }
}