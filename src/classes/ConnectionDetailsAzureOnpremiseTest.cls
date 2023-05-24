@IsTest
private with sharing class ConnectionDetailsAzureOnpremiseTest {
    private static final String azureServerOrganization = 'azure-server-organization';
    private static final String azureServerPassword = 'azure-server-password';
    private static final String azureServerProject = 'azure-server-project';
    private static final String azureServerToken = 'azure-server-token';
    private static final String azureServerUrl = 'azure-server-url';
    private static final String azureServerUsername = 'azure-server-username';

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
            Git_Provider__c = 'Azure Onpremise',
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
            Azure_Server_Organization__c = azureServerOrganization,
            Azure_Server_Password__c = azureServerPassword,
            Azure_Server_Project__c = azureServerProject,
            Azure_Server_Token__c = azureServerToken,
            Azure_Server_Url__c = azureServerUrl,
            Azure_Server_Username__c = azureServerUsername
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
        ConnectionDetails connectionDetails = new ConnectionDetailsAzureOnpremise();
        connectionDetails.init(String.valueOf(connection.Id));
        Test.stopTest();

        Map<String, Object> resultMap = connectionDetails.getValuesMap(true);
        Map<String, Object> envVariables = (Map<String, Object>) resultMap.get('envVariables');

        System.assertEquals(azureServerOrganization, (String) envVariables.get('azureServerOrganization'));
        System.assertEquals(azureServerPassword, (String) envVariables.get('azureServerPassword'));
        System.assertEquals(azureServerProject, (String) envVariables.get('azureServerProject'));
        System.assertEquals(azureServerToken, (String) envVariables.get('azureServerToken'));
        System.assertEquals(azureServerUrl, (String) envVariables.get('azureServerUrl'));
        System.assertEquals(azureServerUsername, (String) envVariables.get('azureServerUsername'));
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
            ConnectionDetails connectionDetails = new ConnectionDetailsAzureOnpremise();
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
                'azureServerOrganization' => azureServerOrganization,
                'azureServerPassword' => azureServerPassword,
                'azureServerProject' => azureServerProject,
                'azureServerToken' => azureServerToken,
                'azureServerUrl' => azureServerUrl,
                'azureServerUsername' => azureServerUsername
            }
        );

        Test.startTest();
        ConnectionDetails connectionDetails = new ConnectionDetailsAzureOnpremise();
        connectionDetails.init(connectionMap);
        connectionDetails.upsertConnection();
        Test.stopTest();

        Connection_Details__c connectionDetailsUpserted = [
            SELECT
                Id,
                Name,
                Azure_Server_Organization__c,
                Azure_Server_Password__c,
                Azure_Server_Project__c,
                Azure_Server_Token__c,
                Azure_Server_Url__c,
                Azure_Server_Username__c
            FROM Connection_Details__c
            WHERE Name != :connection.Id
            LIMIT 1
        ];

        System.assertEquals(azureServerOrganization, connectionDetailsUpserted.Azure_Server_Organization__c);
        System.assertEquals(azureServerPassword, connectionDetailsUpserted.Azure_Server_Password__c);
        System.assertEquals(azureServerProject, connectionDetailsUpserted.Azure_Server_Project__c);
        System.assertEquals(azureServerToken, connectionDetailsUpserted.Azure_Server_Token__c);
        System.assertEquals(azureServerUrl, connectionDetailsUpserted.Azure_Server_Url__c);
        System.assertEquals(azureServerUsername, connectionDetailsUpserted.Azure_Server_Username__c);
    }
}