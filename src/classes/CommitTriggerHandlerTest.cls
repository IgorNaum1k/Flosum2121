@IsTest
private class CommitTriggerHandlerTest {
    @testSetup
    static void setup() {
        TestUtils.createLoggerParentRecord();
        List<Flosum__Repository__c> repos = TestUtils.createFlosumRepositorys(1);
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
    static void createIdsAttachmentForSendingTest() {
        List<Flosum__Repository__c> repos = [SELECT Id FROM Flosum__Repository__c];
        Flosum__Commit__c commitObj = [
            SELECT Id, Flosum__Status__c, Flosum__Repository__c
            FROM Flosum__Commit__c
            WHERE Flosum__Repository__c = :repos[0].Id
        ];

        System.assertEquals(
            0,
            [
                    SELECT Id, ParentId, Name
                    FROM Attachment
                    WHERE ParentId = :repos[0].Id AND Name = :Constants.COMMIT_ATTACHMENT_NAME
                ]
                .size()
        );
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'SUCCESS'));
        Test.startTest();
        Flosum__Commit__c commitInProgress = commitObj.clone(true, true, true, true);
        commitInProgress.Flosum__Status__c = 'In Progress';
        Flosum__Commit__c commitCompleted = commitObj.clone(true, true, true, true);
        commitCompleted.Flosum__Status__c = 'Completed';

        Map<Id, Flosum__Commit__c> newMap = new Map<Id, Flosum__Commit__c>();
        newMap.put(commitObj.Id, commitCompleted);
        Map<Id, Flosum__Commit__c> oldMap = new Map<Id, Flosum__Commit__c>();
        oldMap.put(commitObj.Id, commitInProgress);

        CommitTriggerHandler.createIdsAttachmentForSending(newMap, oldMap);

        Test.stopTest();
        System.assertEquals(
            1,
            [
                    SELECT Id, ParentId, Name
                    FROM Attachment
                    WHERE ParentId = :repos[0].Id AND Name = :Constants.COMMIT_ATTACHMENT_NAME
                ]
                .size()
        );
    }

    @IsTest
    static void createIdsAttachmentForSendingTestConnectionDisabled() {
        String repoSyncHashAttachmentBody = 'Repository sync hash attachment';
        List<Flosum__Repository__c> repos = [SELECT Id FROM Flosum__Repository__c];
        Flosum__Commit__c commitObj = [
            SELECT Id, Flosum__Status__c, Flosum__Repository__c
            FROM Flosum__Commit__c
            WHERE Flosum__Repository__c = :repos[0].Id
        ];

        Repository_Connection__c repositoryConnection = [
            SELECT Id, Connection__c
            FROM Repository_Connection__c
            WHERE Repository__c = :repos[0].Id
            LIMIT 1
        ];
        update new Connection__c(Id = repositoryConnection.Connection__c, Is_Enabled__c = false);

        System.assertEquals(
            0,
            [
                    SELECT Id, ParentId, Name
                    FROM Attachment
                    WHERE ParentId = :repos[0].Id AND Name = :Constants.COMMIT_ATTACHMENT_NAME
                ]
                .size()
        );
        insert new Attachment(
            ParentId = repos[0].Id,
            Name = Constants.SYNC_ATTACHMENT_FOR_REPOSITORY_NAME,
            Body = Blob.valueOf(repoSyncHashAttachmentBody)
        );
        List<Attachment> attachments = [
            SELECT Id, ParentId, Name, Body
            FROM Attachment
            WHERE ParentId = :repos[0].Id AND Name = :Constants.SYNC_ATTACHMENT_FOR_REPOSITORY_NAME
        ];

        System.assertEquals(1, attachments.size());
        System.assertEquals(repoSyncHashAttachmentBody, attachments[0].Body.toString());

        Test.startTest();
        Flosum__Commit__c commitInProgress = commitObj.clone(true, true, true, true);
        commitInProgress.Flosum__Status__c = 'In Progress';
        Flosum__Commit__c commitCompleted = commitObj.clone(true, true, true, true);
        commitCompleted.Flosum__Status__c = 'Completed';

        Map<Id, Flosum__Commit__c> newMap = new Map<Id, Flosum__Commit__c>();
        newMap.put(commitObj.Id, commitCompleted);
        Map<Id, Flosum__Commit__c> oldMap = new Map<Id, Flosum__Commit__c>();
        oldMap.put(commitObj.Id, commitInProgress);

        CommitTriggerHandler.createIdsAttachmentForSending(newMap, oldMap);

        Test.stopTest();
        System.assertEquals(
            0,
            [
                    SELECT Id, ParentId, Name
                    FROM Attachment
                    WHERE ParentId = :repos[0].Id AND Name = :Constants.COMMIT_ATTACHMENT_NAME
                ]
                .size()
        );

        List<Attachment> attachmentsResult = [
            SELECT Id, ParentId, Name, Body
            FROM Attachment
            WHERE ParentId = :repos[0].Id AND Name = :Constants.SYNC_ATTACHMENT_FOR_REPOSITORY_NAME
        ];

        System.assertEquals(1, attachmentsResult.size());
        System.assertEquals('{}', attachmentsResult[0].Body.toString());
    }

    @IsTest
    static void createIdsAttachmentForSendingTestRepoInError() {
        List<Flosum__Repository__c> repos = [SELECT Id, Synchronization_Status__c FROM Flosum__Repository__c];
        Flosum__Commit__c commitObj = [
            SELECT Id, Flosum__Status__c, Flosum__Repository__c
            FROM Flosum__Commit__c
            WHERE Flosum__Repository__c = :repos[0].Id
        ];

        repos[0].Synchronization_Status__c = 'Error';
        update repos;

        Test.startTest();
        Flosum__Commit__c commitInProgress = commitObj.clone(true, true, true, true);
        commitInProgress.Flosum__Status__c = 'In Progress';
        Flosum__Commit__c commitCompleted = commitObj.clone(true, true, true, true);
        commitCompleted.Flosum__Status__c = 'Completed';

        Map<Id, Flosum__Commit__c> newMap = new Map<Id, Flosum__Commit__c>();
        newMap.put(commitObj.Id, commitCompleted);
        Map<Id, Flosum__Commit__c> oldMap = new Map<Id, Flosum__Commit__c>();
        oldMap.put(commitObj.Id, commitInProgress);

        CommitTriggerHandler.createIdsAttachmentForSending(newMap, oldMap);

        Test.stopTest();

        List<Log__c> logs = [SELECT Id FROM Log__c WHERE isSystem__c = FALSE];
        System.assertEquals(1, logs.size());
    }
}