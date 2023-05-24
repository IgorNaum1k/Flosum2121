@IsTest
private with sharing class ConnectionDetailsAzureTest {
    private static final String azureOrganization = 'azure-organization';
    private static final String azureProject = 'azure-project';
    private static final String azureToken = 'azure-token';
    private static final String azureUsername = 'azure-username';

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
            Git_Provider__c = 'Azure',
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
            Azure_Organization__c = azureOrganization,
            Azure_Project__c = azureProject,
            Azure_Token__c = azureToken,
            Azure_Username__c = azureUsername
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
        ConnectionDetails connectionDetails = new ConnectionDetailsAzure();
        connectionDetails.init(String.valueOf(connection.Id));
        Test.stopTest();

        Map<String, Object> resultMap = connectionDetails.getValuesMap(true);
        Map<String, Object> envVariables = (Map<String, Object>) resultMap.get('envVariables');

        System.assertEquals(azureOrganization, (String) envVariables.get('azureOrganization'));
        System.assertEquals(azureProject, (String) envVariables.get('azureProject'));
        System.assertEquals(azureToken, (String) envVariables.get('azureToken'));
        System.assertEquals(azureUsername, (String) envVariables.get('azureUsername'));
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
            ConnectionDetails connectionDetails = new ConnectionDetailsAzure();
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
                'azureOrganization' => azureOrganization,
                'azureProject' => azureProject,
                'azureToken' => azureToken,
                'azureUsername' => azureUsername
            }
        );

        Test.startTest();
        ConnectionDetails connectionDetails = new ConnectionDetailsAzure();
        connectionDetails.init(connectionMap);
        connectionDetails.upsertConnection();
        Test.stopTest();

        Connection_Details__c connectionDetailsUpserted = [
            SELECT Id, Name, Azure_Organization__c, Azure_Project__c, Azure_Token__c, Azure_Username__c
            FROM Connection_Details__c
            WHERE Name != :connection.Id
            LIMIT 1
        ];

        System.assertEquals(azureOrganization, connectionDetailsUpserted.Azure_Organization__c);
        System.assertEquals(azureProject, connectionDetailsUpserted.Azure_Project__c);
        System.assertEquals(azureToken, connectionDetailsUpserted.Azure_Token__c);
        System.assertEquals(azureUsername, connectionDetailsUpserted.Azure_Username__c);
    }
}