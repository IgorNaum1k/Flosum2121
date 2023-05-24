@IsTest
private with sharing class ConnectionDetailsFactoryTest {
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
            Git_Provider__c = 'GitHub',
            Agent_Connection__c = agentConnection.Id,
            Is_Enabled__c = true
        );
        insert connection;

        Repository_Connection__c repositoryConnection = new Repository_Connection__c(
            Repository__c = repos[0].Id,
            Connection__c = connection.Id
        );
        insert repositoryConnection;

        insert new Connection_Details__c(Name = connection.Id);
    }

    @IsTest
    static void createByConnectionIdTest() {
        Connection__c connection = [SELECT Id FROM Connection__c LIMIT 1];
        Test.startTest();
        Object result1 = ConnectionDetailsFactory.create('GitHub', String.valueOf(connection.Id));
        System.assert((result1 instanceof ConnectionDetailsGithub));

        Object result2 = ConnectionDetailsFactory.create('GitLab', String.valueOf(connection.Id));
        System.assert((result2 instanceof ConnectionDetailsGitlab));

        Object result3 = ConnectionDetailsFactory.create('BitBucket', String.valueOf(connection.Id));
        System.assert((result3 instanceof ConnectionDetailsBitbucket));

        Object result4 = ConnectionDetailsFactory.create('Azure', String.valueOf(connection.Id));
        System.assert((result4 instanceof ConnectionDetailsAzure));

        Object result5 = ConnectionDetailsFactory.create('GitHub Onpremise', String.valueOf(connection.Id));
        System.assert((result5 instanceof ConnectionDetailsGithubOnpremise));

        Object result6 = ConnectionDetailsFactory.create('GitLab Onpremise', String.valueOf(connection.Id));
        System.assert((result6 instanceof ConnectionDetailsGitlabOnpremise));

        Object result7 = ConnectionDetailsFactory.create('BitBucket Onpremise', String.valueOf(connection.Id));
        System.assert((result7 instanceof ConnectionDetailsBitbucketOnpremise));

        Object result8 = ConnectionDetailsFactory.create('Azure Onpremise', String.valueOf(connection.Id));
        System.assert((result8 instanceof ConnectionDetailsAzureOnpremise));
        Test.stopTest();
    }

    @IsTest
    static void createByConnectionMapTest() {
        Connection__c connection = [SELECT Id FROM Connection__c LIMIT 1];

        Map<String, Object> connectionMap = new Map<String, Object>{
            'applicationUrl' => 'https://test-app.com',
            'isBidirectionalSynchronization' => true,
            'isConvertToSfdx' => true,
            'isEnabled' => true,
            'connectionId' => null,
            'connectionName' => 'TestConnection',
            'envVariables' => new Map<String, Object>()
        };

        Test.startTest();
        connectionMap.put('gitProvider', 'GitHub');
        Object result1 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result1 instanceof ConnectionDetailsGithub));

        connectionMap.put('gitProvider', 'GitLab');
        Object result2 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result2 instanceof ConnectionDetailsGitlab));

        connectionMap.put('gitProvider', 'BitBucket');
        Object result3 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result3 instanceof ConnectionDetailsBitbucket));

        connectionMap.put('gitProvider', 'Azure');
        Object result4 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result4 instanceof ConnectionDetailsAzure));

        connectionMap.put('gitProvider', 'GitHub Onpremise');
        Object result5 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result5 instanceof ConnectionDetailsGithubOnpremise));

        connectionMap.put('gitProvider', 'GitLab Onpremise');
        Object result6 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result6 instanceof ConnectionDetailsGitlabOnpremise));

        connectionMap.put('gitProvider', 'BitBucket Onpremise');
        Object result7 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result7 instanceof ConnectionDetailsBitbucketOnpremise));

        connectionMap.put('gitProvider', 'Azure Onpremise');
        Object result8 = ConnectionDetailsFactory.create(connectionMap);
        System.assert((result8 instanceof ConnectionDetailsAzureOnpremise));
        Test.stopTest();
    }

    @IsTest
    static void createTestError() {
        Test.startTest();
        try {
            ConnectionDetailsFactory.create(new Map<String, Object>{ 'gitProvider' => 'wrong' });
        } catch (Exception e) {
            System.assertEquals(Constants.WRONG_PROVIDER_VALUE_ERROR_MESSAGE, e.getMessage());
        }
        Test.stopTest();
    }
}