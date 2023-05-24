public with sharing class DeleteComponentTriggerHandler {
    public static void clearSynchronizationHash(Map<Id, Flosum__Component__c> deletedComponentsMap) {
        Set<String> branchesOrRepositoriesIds = new Set<String>();
        for (Flosum__Component__c component : deletedComponentsMap.values()) {
            if (component.Flosum__Branch__c != null) {
                branchesOrRepositoriesIds.add(component.Flosum__Branch__c);
            } else if (component.Flosum__Repository__c != null) {
                branchesOrRepositoriesIds.add(component.Flosum__Repository__c);
            }
        }
        clearHashInAttachments(branchesOrRepositoriesIds);
    }

    private static void clearHashInAttachments(Set<String> parentIds) {
        List<Attachment> syncAttachmentsList = [
            SELECT Id, Name, ParentId, Body
            FROM Attachment
            WHERE
                ParentId IN :parentIds
                AND Name IN (:Constants.SYNC_ATTACHMENT_FOR_REPOSITORY_NAME, :Constants.SYNC_ATTACHMENT_FOR_BRANCH_NAME)
            WITH SECURITY_ENFORCED
        ];
        for (Attachment attach : syncAttachmentsList) {
            attach.Body = Blob.valueOf('{}');
        }
        if (!syncAttachmentsList.isEmpty()) {
            DatabaseUtils.updateRecords(
                syncAttachmentsList,
                new List<Schema.DescribeFieldResult>{
                    Attachment.Id.getDescribe(),
                    Attachment.Name.getDescribe(),
                    Attachment.Body.getDescribe()
                }
            );
        }
    }

    public static void prepareAttachmentForDeletedComponents(Map<Id, Flosum__Component__c> deletedComponentsMap) {
        if (deletedComponentsMap.values()[0].Flosum__Branch__c != null) {
            List<Flosum__Branch__c> componentsBranch = [
                SELECT
                    Id,
                    Flosum__Branch_Name__c,
                    Flosum__Repository__c,
                    Flosum__Repository__r.Name,
                    Flosum__Status__c,
                    Synchronization_Status__c
                FROM Flosum__Branch__c
                WHERE Id = :deletedComponentsMap.values()[0].Flosum__Branch__c
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            Map<String, Object> connectionInfo = ConnectionDetails.getConnectionInfo(
                componentsBranch[0].Flosum__Repository__c
            );
            if ((Boolean) connectionInfo.get('isSyncEnabled')) {
                if (componentsBranch[0].Flosum__Status__c == 'In Progress') {
                    massDeleteComponentsLogic(deletedComponentsMap, 'Branch', componentsBranch[0], null);
                } else if (componentsBranch[0].Flosum__Status__c == 'Completed') {
                    singleDeleteLogic(deletedComponentsMap, 'Branch', componentsBranch[0], null);
                }
            } else {
                clearSynchronizationHash(deletedComponentsMap);
            }
        }

        if (deletedComponentsMap.values()[0].Flosum__Repository__c != null) {
            Map<String, Object> connectionInfo = ConnectionDetails.getConnectionInfo(
                deletedComponentsMap.values()[0].Flosum__Repository__c
            );
            if ((Boolean) connectionInfo.get('isSyncEnabled')) {
                List<Flosum__Repository__c> componentsRepository = [
                    SELECT Id, Name, Synchronization_Status__c
                    FROM Flosum__Repository__c
                    WHERE Id = :deletedComponentsMap.values()[0].Flosum__Repository__c
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];

                singleDeleteLogic(deletedComponentsMap, 'Repository', null, componentsRepository[0]);
            } else {
                clearSynchronizationHash(deletedComponentsMap);
            }
        }
    }

    public static void massDeleteComponentsLogic(
        Map<Id, Flosum__Component__c> deletedComponentsMap,
        String componentRecordType,
        Flosum__Branch__c branch,
        Flosum__Repository__c repository
    ) {
        List<DeletedComponentsWrapper> wrappedComponentsList = new DeletedComponentsWrapper()
            .createWrappedComponentsList(deletedComponentsMap.values());
        if (!wrappedComponentsList.isEmpty()) {
            if (componentRecordType == 'Branch') {
                writeComponentsToAttachment(wrappedComponentsList, branch.Id, Constants.DELETE_ATTACHMENT_NAME);
            } else if (componentRecordType == 'Repository') {
                writeComponentsToAttachment(wrappedComponentsList, repository.Id, Constants.DELETE_ATTACHMENT_NAME);
            }
        }
    }

    public static void singleDeleteLogic(
        Map<Id, Flosum__Component__c> deletedComponentsMap,
        String componentRecordType,
        Flosum__Branch__c branch,
        Flosum__Repository__c repository
    ) {
        List<DeletedComponentsWrapper> wrappedComponentsList = new DeletedComponentsWrapper()
            .createWrappedComponentsList(deletedComponentsMap.values());
        if (!wrappedComponentsList.isEmpty()) {
            if (componentRecordType == 'Branch') {
                if (branch.Synchronization_Status__c != 'Error') {
                    DatabaseUtils.updateRecord(
                        new Flosum__Branch__c(Id = branch.Id, Synchronization_Status__c = 'In Progress'),
                        new List<Schema.DescribeFieldResult>{
                            Flosum__Branch__c.Id.getDescribe(),
                            Flosum__Branch__c.Synchronization_Status__c.getDescribe()
                        }
                    );

                    Map<String, Object> componentsToAttachmentResult = writeComponentsToAttachment(
                        wrappedComponentsList,
                        branch.Id,
                        Constants.SINGLE_OPERATION_DELETE_ATTACHMENT_NAME
                    );
                    if (!(Boolean) componentsToAttachmentResult.get('isFinded')) {
                        AgentService.startCommittingToGit(
                            '',
                            branch.Flosum__Repository__r.Name,
                            branch.Flosum__Branch_Name__c,
                            '',
                            '',
                            branch.Id,
                            (Id) componentsToAttachmentResult.get('attachmentId'),
                            true,
                            branch.Flosum__Repository__c
                        );
                    }
                }
            } else if (componentRecordType == 'Repository') {
                if (repository.Synchronization_Status__c != 'Error') {
                    DatabaseUtils.updateRecord(
                        new Flosum__Repository__c(Id = repository.Id, Synchronization_Status__c = 'In Progress'),
                        new List<Schema.DescribeFieldResult>{
                            Flosum__Repository__c.Id.getDescribe(),
                            Flosum__Repository__c.Synchronization_Status__c.getDescribe()
                        }
                    );

                    Map<String, Object> componentsToAttachmentResult = writeComponentsToAttachment(
                        wrappedComponentsList,
                        repository.Id,
                        Constants.SINGLE_OPERATION_DELETE_ATTACHMENT_NAME
                    );
                    if (!(Boolean) componentsToAttachmentResult.get('isFinded')) {
                        AgentService.startCommittingToGit(
                            '',
                            repository.Name,
                            'master',
                            '',
                            repository.Id,
                            '',
                            (Id) componentsToAttachmentResult.get('attachmentId'),
                            true,
                            repository.Id
                        );
                    }
                }
            }
        }
    }

    public static Map<String, Object> writeComponentsToAttachment(
        List<DeletedComponentsWrapper> wrappedComponentsList,
        Id parentId,
        String attachmentName
    ) {
        List<Attachment> deleteAttachmentsList = [
            SELECT Id, ParentId, Name, Body
            FROM Attachment
            WHERE ParentId = :parentId AND Name = :attachmentName
            WITH SECURITY_ENFORCED
        ];

        if (deleteAttachmentsList.isEmpty()) {
            Attachment deleteAttachment = new Attachment(
                Name = attachmentName,
                ParentId = parentId,
                Body = Blob.valueOf(JSON.serialize(wrappedComponentsList)),
                ContentType = 'text/plain'
            );

            DatabaseUtils.insertRecord(
                deleteAttachment,
                new List<Schema.DescribeFieldResult>{
                    Attachment.Name.getDescribe(),
                    Attachment.ParentId.getDescribe(),
                    Attachment.Body.getDescribe(),
                    Attachment.ContentType.getDescribe()
                }
            );

            return new Map<String, Object>{ 'isFinded' => false, 'attachmentId' => deleteAttachment.Id };
        } else {
            Attachment deleteAttachment = deleteAttachmentsList[0];
            List<DeletedComponentsWrapper> attachmentComponents = (List<DeletedComponentsWrapper>) JSON.deserialize(
                deleteAttachment.Body.toString(),
                List<DeletedComponentsWrapper>.class
            );
            attachmentComponents.addAll(wrappedComponentsList);
            deleteAttachment.Body = Blob.valueOf(JSON.serialize(attachmentComponents));

            DatabaseUtils.updateRecord(
                deleteAttachment,
                new List<Schema.DescribeFieldResult>{ Attachment.Body.getDescribe() }
            );

            return new Map<String, Object>{ 'isFinded' => true, 'attachmentId' => deleteAttachment.Id };
        }
    }

    public class DeletedComponentsWrapper {
        public String fileName;
        public String type;
        public String path;

        public DeletedComponentsWrapper() {
        }

        public DeletedComponentsWrapper(String fileName, String type, String path) {
            this.fileName = fileName;
            this.type = type;
            this.path = path;
        }

        public List<DeletedComponentsWrapper> createWrappedComponentsList(List<Flosum__Component__c> components) {
            List<DeletedComponentsWrapper> wrappedComponentsList = new List<DeletedComponentsWrapper>();
            for (Flosum__Component__c comp : components) {
                if (!comp.Deletion_By_Agent__c) {
                    wrappedComponentsList.add(
                        new DeletedComponentsWrapper(
                            comp.Flosum__Component_Name__c,
                            comp.Flosum__Component_Type__c,
                            comp.Flosum__File_Name__c
                        )
                    );
                }
            }
            return wrappedComponentsList;
        }
    }
}