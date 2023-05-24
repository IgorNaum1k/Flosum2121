@IsTest
private with sharing class ConnectionDetailsTest {
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
    }

    @IsTest
    static void getConnectionInfoTest() {
        Flosum__Repository__c repository = [SELECT Id, Name FROM Flosum__Repository__c LIMIT 1];
        Connection__c connection = [
            SELECT
                Id,
                Name,
                Git_Provider__c,
                Application_Url__c,
                Is_Enabled__c,
                Sync_In_Progress__c,
                Agent_Connection__r.Flosum__Url__c
            FROM Connection__c
            LIMIT 1
        ];
        Test.startTest();
        Map<String, Object> connectionExist = ConnectionDetails.getConnectionInfo(repository.Id);
        Map<String, Object> connectionNotExist = ConnectionDetails.getConnectionInfo('');
        Test.stopTest();

        System.assertEquals(repository.Name, (String) connectionExist.get('repositoryName'));
        System.assertEquals(connection.Id, (String) connectionExist.get('connectionId'));
        System.assertEquals(
            connection.Is_Enabled__c && !connection.Sync_In_Progress__c,
            (Boolean) connectionExist.get('isSyncEnabled')
        );
        System.assertEquals(connection.Git_Provider__c, (String) connectionExist.get('gitProvider'));
        System.assertEquals(
            connection.Agent_Connection__r.Flosum__Url__c,
            (String) connectionExist.get('applicationUrl')
        );

        System.assertEquals(false, (Boolean) connectionNotExist.get('isSyncEnabled'));
        System.assertEquals(false, (Boolean) connectionNotExist.get('isSyncInProgress'));
        System.assertEquals(2, connectionNotExist.size());
    }

    @IsTest
    static void getConnectionInfoBulkTest() {
        List<Flosum__Repository__c> repositories = [SELECT Id, Name FROM Flosum__Repository__c];
        String repoIdWithConnection = (String) repositories[0].Id;

        Flosum__Repository__c insertRepo = new Flosum__Repository__c(Name = 'TestRepo');
        insert insertRepo;
        repositories.add(insertRepo);

        List<String> repositoriesIds = new List<String>();
        for (Flosum__Repository__c repo : repositories) {
            repositoriesIds.add(repo.Id);
        }

        Connection__c connection = [
            SELECT
                Id,
                Name,
                Git_Provider__c,
                Application_Url__c,
                Is_Enabled__c,
                Sync_In_Progress__c,
                Agent_Connection__r.Flosum__Url__c
            FROM Connection__c
            LIMIT 1
        ];

        Test.startTest();
        Map<String, Map<String, Object>> connectionsResult = ConnectionDetails.getConnectionInfoBulk(repositoriesIds);
        Test.stopTest();

        Map<String, Object> connectionExist = (Map<String, Object>) connectionsResult.get(repoIdWithConnection);
        System.assertEquals(connection.Id, (String) connectionExist.get('connectionId'));
        System.assertEquals(
            connection.Is_Enabled__c && !connection.Sync_In_Progress__c,
            (Boolean) connectionExist.get('isSyncEnabled')
        );
        System.assertEquals(connection.Git_Provider__c, (String) connectionExist.get('gitProvider'));
        System.assertEquals(
            connection.Agent_Connection__r.Flosum__Url__c,
            (String) connectionExist.get('applicationUrl')
        );
        System.assertEquals(
            connection.Is_Enabled__c && !connection.Sync_In_Progress__c,
            (Boolean) connectionExist.get('isSyncEnabled')
        );

        Map<String, Object> connectionNotExist = (Map<String, Object>) connectionsResult.get(
            String.valueOf(insertRepo.Id)
        );
        System.assertEquals(false, (Boolean) connectionNotExist.get('isSyncEnabled'));
        System.assertEquals(false, (Boolean) connectionNotExist.get('isSyncInProgress'));
    }
}