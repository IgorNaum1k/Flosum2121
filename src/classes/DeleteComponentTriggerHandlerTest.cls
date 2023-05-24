@IsTest
public class DeleteComponentTriggerHandlerTest {
    @TestSetup
    static void setup() {
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
    static void deleteComponentsSuccess() {
        List<Flosum__Component__c> components = [SELECT Id FROM Flosum__Component__c];
        Test.startTest();
        List<Database.DeleteResult> deleteResults = Database.delete(components, true);
        Test.stopTest();

        for (Database.DeleteResult deleteResult : deleteResults) {
            System.assertEquals(true, deleteResult.isSuccess(), 'Deletion failed on record ' + deleteResult.getId());
        }
    }

    @IsTest
    static void deleteComponentsBranchInProgress() {
        Flosum__Branch__c branch = [
            SELECT Id, Name, Flosum__Repository__c, Flosum__Status__c, Synchronization_Status__c
            FROM Flosum__Branch__c
            LIMIT 1
        ];

        List<Flosum__Component__c> components = TestUtils.createBranchComponents(
            new List<Flosum__Branch__c>{ branch },
            5,
            'Snapshot'
        );

        Map<Id, Flosum__Component__c> componentsForDelete = new Map<Id, Flosum__Component__c>(components);
        Test.startTest();
        DeleteComponentTriggerHandler.prepareAttachmentForDeletedComponents(componentsForDelete);
        Test.stopTest();

        List<Attachment> attachmentsResult = [
            SELECT Id, Name
            FROM Attachment
            WHERE Name = :Constants.DELETE_ATTACHMENT_NAME AND ParentId = :branch.Id
        ];
        system.assertEquals(1, attachmentsResult.size());
    }

    @IsTest
    static void deleteComponentsBranchCompleted() {
        Flosum__Branch__c branch = [
            SELECT Id, Name, Flosum__Repository__c, Flosum__Status__c, Synchronization_Status__c
            FROM Flosum__Branch__c
            LIMIT 1
        ];
        branch.Flosum__Status__c = 'Completed';
        update branch;
        List<Flosum__Component__c> components = TestUtils.createBranchComponents(
            new List<Flosum__Branch__c>{ branch },
            5,
            'Snapshot'
        );

        Map<Id, Flosum__Component__c> componentsForDelete = new Map<Id, Flosum__Component__c>(components);

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'SUCCESS'));
        Test.startTest();
        DeleteComponentTriggerHandler.prepareAttachmentForDeletedComponents(componentsForDelete);
        Test.stopTest();

        List<Attachment> attachmentsResult = [
            SELECT Id, Name
            FROM Attachment
            WHERE Name = :Constants.SINGLE_OPERATION_DELETE_ATTACHMENT_NAME AND ParentId = :branch.Id
        ];
        system.assertEquals(1, attachmentsResult.size());
    }

    @IsTest
    static void deleteComponentsSyncDisabled() {
        Flosum__Branch__c branch = [
            SELECT Id, Name, Flosum__Repository__c, Flosum__Status__c, Synchronization_Status__c
            FROM Flosum__Branch__c
            LIMIT 1
        ];
        List<Flosum__Component__c> components = TestUtils.createBranchComponents(
            new List<Flosum__Branch__c>{ branch },
            5,
            'Snapshot'
        );
        List<Flosum__Component_History__c> historys = TestUtils.createComponentHistorys(components);
        List<Attachment> attachments = TestUtils.createComponentHistorysAttachments(historys);

        Repository_Connection__c repositoryConnection = [
            SELECT Id, Connection__c
            FROM Repository_Connection__c
            WHERE Repository__c = :branch.Flosum__Repository__c
            LIMIT 1
        ];
        update new Connection__c(Id = repositoryConnection.Connection__c, Is_Enabled__c = false);

        insert new Attachment(
            Name = Constants.SYNC_ATTACHMENT_FOR_BRANCH_NAME,
            ParentId = branch.Id,
            Body = Blob.valueOf('Sync hash attachment')
        );

        Map<Id, Flosum__Component__c> componentsForDelete = new Map<Id, Flosum__Component__c>(components);
        Test.startTest();
        DeleteComponentTriggerHandler.prepareAttachmentForDeletedComponents(componentsForDelete);
        Test.stopTest();

        List<Attachment> attachmentsResult = [
            SELECT Id, Name, Body
            FROM Attachment
            WHERE Name = :Constants.SYNC_ATTACHMENT_FOR_BRANCH_NAME AND ParentId = :branch.Id
        ];
        system.assertEquals('{}', attachmentsResult[0].Body.toString());
    }

    @IsTest
    static void deleteComponentsRepositorySyncDisabled() {
        List<Flosum__Repository__c> repos = [SELECT Id, Name FROM Flosum__Repository__c];

        List<Flosum__Component__c> components = TestUtils.createRepositoryComponents(repos, 5, 'Snapshot');

        Repository_Connection__c repositoryConnection = [
            SELECT Id, Connection__c
            FROM Repository_Connection__c
            WHERE Repository__c = :repos[0].Id
            LIMIT 1
        ];
        update new Connection__c(Id = repositoryConnection.Connection__c, Is_Enabled__c = false);

        insert new Attachment(
            Name = Constants.SYNC_ATTACHMENT_FOR_REPOSITORY_NAME,
            ParentId = repos[0].Id,
            Body = Blob.valueOf('Sync hash attachment')
        );

        Map<Id, Flosum__Component__c> componentsForDelete = new Map<Id, Flosum__Component__c>(components);
        Test.startTest();
        DeleteComponentTriggerHandler.prepareAttachmentForDeletedComponents(componentsForDelete);
        Test.stopTest();

        List<Attachment> attachmentsResult = [
            SELECT Id, Name, Body
            FROM Attachment
            WHERE Name = :Constants.SYNC_ATTACHMENT_FOR_REPOSITORY_NAME AND ParentId = :repos[0].Id
        ];
        system.assertEquals('{}', attachmentsResult[0].Body.toString());
    }

    @IsTest
    static void deleteComponentsRepository() {
        List<Flosum__Repository__c> repos = [SELECT Id, Name FROM Flosum__Repository__c];

        List<Flosum__Component__c> components1 = TestUtils.createRepositoryComponents(repos, 5, 'Snapshot');
        List<Flosum__Component__c> components2 = TestUtils.createRepositoryComponents(repos, 5, 'Snapshot');

        Map<Id, Flosum__Component__c> componentsForDelete1 = new Map<Id, Flosum__Component__c>(components1);
        Map<Id, Flosum__Component__c> componentsForDelete2 = new Map<Id, Flosum__Component__c>(components2);
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'SUCCESS'));
        Test.startTest();
        DeleteComponentTriggerHandler.prepareAttachmentForDeletedComponents(componentsForDelete1);
        DeleteComponentTriggerHandler.prepareAttachmentForDeletedComponents(componentsForDelete2);
        Test.stopTest();

        List<Attachment> attachmentsResult = [
            SELECT Id, Name, Body
            FROM Attachment
            WHERE Name = :Constants.SINGLE_OPERATION_DELETE_ATTACHMENT_NAME AND ParentId = :repos[0].Id
        ];
        System.assertEquals(1, attachmentsResult.size());
    }
}