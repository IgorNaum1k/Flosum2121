@IsTest
private class CommitTriggerHandlerQueuebleTest {
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
            Is_Enabled__c = true,
            Sync_In_Progress__c = false
        );
        insert connection;

        Repository_Connection__c repositoryConnection = new Repository_Connection__c(
            Repository__c = repos[0].Id,
            Connection__c = connection.Id
        );
        insert repositoryConnection;
    }

    @IsTest
    static void test() {
        List<AgentService.RepositoryCommitRequestWrapper> dataForRequests = new List<AgentService.RepositoryCommitRequestWrapper>();
        dataForRequests.add(
            new AgentService.RepositoryCommitRequestWrapper(
                'Commit Message',
                'repoName',
                'master',
                'commitAttachmentId',
                'repositoryId',
                '',
                '',
                false,
                'repositoryId'
            )
        );

        Test.startTest();
        System.enqueueJob(new CommitTriggerHandlerQueueble(dataForRequests));
        Test.stopTest();
    }
}