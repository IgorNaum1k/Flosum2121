@IsTest
private with sharing class ConnectedItemsControllerTest {
    @TestSetup
    static void makeData() {
        TestUtils.createLoggerParentRecord();
        List<Flosum__Repository__c> repos = TestUtils.createFlosumRepositorys(2);
        List<Flosum__Branch__c> branches = TestUtils.createBranches(repos, 1);
        List<Flosum__Component__c> components = TestUtils.createBranchComponents(branches, 5, 'Snapshot');
        List<Flosum__Component_History__c> historys = TestUtils.createComponentHistorys(components);
        List<Attachment> attachments = TestUtils.createComponentHistorysAttachments(historys);
        Flosum__Commit__c commitObj = TestUtils.createCommitRecord(repos[0].Id, branches[0].Id);
        TestUtils.createCommitManifests(commitObj.Id, historys);

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
    static void getAvailableRepositoriesTest() {
        Test.startTest();
        List<Object> result = ConnectedItemsController.getAvailableRepositories();
        Test.stopTest();
        List<Flosum__Repository__c> availableRepos = [
            SELECT Id, Name
            FROM Flosum__Repository__c
            WHERE Id NOT IN (SELECT Repository__c FROM Repository_Connection__c)
            ORDER BY Name
        ];
        Map<String, Object> repository = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(result[0]));
        System.assertEquals(String.valueOf(availableRepos[0].Id), (String) repository.get('value'));
    }

    @IsTest
    static void getConnectedRepositoriesTest() {
        List<Connection__c> connections = [SELECT Id FROM Connection__c];
        Test.startTest();
        List<Object> result = ConnectedItemsController.getConnectedRepositories(connections[0].Id);
        Test.stopTest();
        List<Repository_Connection__c> connectedRepos = [
            SELECT Repository__c, Repository__r.Name
            FROM Repository_Connection__c
            WHERE Connection__c = :connections[0].Id
        ];
        Map<String, Object> repository = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(result[0]));
        System.assertEquals(String.valueOf(connectedRepos[0].Repository__c), (String) repository.get('value'));
    }
}