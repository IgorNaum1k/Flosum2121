public with sharing class CommitTriggerHandler {
    public static void createIdsAttachmentForSending(
        Map<Id, Flosum__Commit__c> commitsMapNew,
        Map<Id, Flosum__Commit__c> commitsMapOld
    ) {
        List<AgentService.RepositoryCommitRequestWrapper> dataForRequests = new List<AgentService.RepositoryCommitRequestWrapper>();
        List<String> completedCommitsWithEnabledConnectionIds = new List<String>();
        Set<String> disabledRepositories = new Set<String>();
        List<String> commitRepositoriesIds = new List<String>();
        List<Flosum__Commit__c> completedCommitsList = new List<Flosum__Commit__c>();

        for (Flosum__Commit__c newCommit : commitsMapNew.values()) {
            if (
                newCommit.Flosum__Status__c == 'Completed' &&
                commitsMapOld.get(newCommit.Id).Flosum__Status__c == 'In Progress' &&
                !newCommit.Is_From_Agent__c
            ) {
                commitRepositoriesIds.add(newCommit.Flosum__Repository__c);
                completedCommitsList.add(newCommit);
            }
        }

        Map<String, Map<String, Object>> connectionInfoMap = ConnectionDetails.getConnectionInfoBulk(
            commitRepositoriesIds
        );

        for (Flosum__Commit__c completedCommit : completedCommitsList) {
            if ((Boolean) connectionInfoMap.get(completedCommit.Flosum__Repository__c).get('isSyncEnabled')) {
                completedCommitsWithEnabledConnectionIds.add(completedCommit.Id);
            } else {
                disabledRepositories.add(completedCommit.Flosum__Repository__c);
            }
        }

        Map<Id, Flosum__Commit__c> fullDataCommits = new Map<Id, Flosum__Commit__c>(
            [
                SELECT
                    Id,
                    Flosum__Repository__c,
                    Flosum__Branch__c,
                    Flosum__Repository__r.Name,
                    Flosum__Repository__r.Synchronization_Status__c
                FROM Flosum__Commit__c
                WHERE Id IN :completedCommitsWithEnabledConnectionIds
                WITH SECURITY_ENFORCED
            ]
        );

        List<Flosum__Commit_Manifest__c> commitsManifests = [
            SELECT Id, Name, Flosum__Commit__c, Flosum__Comments__c, Flosum__Component_History__c
            FROM Flosum__Commit_Manifest__c
            WHERE Flosum__Commit__c IN :completedCommitsWithEnabledConnectionIds
            WITH SECURITY_ENFORCED
        ];

        Map<Id, Attachment> commitsAttachmentsMap = new Map<Id, Attachment>();
        for (Flosum__Commit__c completedCommit : completedCommitsList) {
            if (
                fullDataCommits.get(completedCommit.Id) != null &&
                fullDataCommits.get(completedCommit.Id).Flosum__Repository__r.Synchronization_Status__c != 'Error'
            ) {
                List<String> manifestsAttachmentsIdsList = new List<String>();
                for (Flosum__Commit_Manifest__c manifest : commitsManifests) {
                    if (manifest.Flosum__Commit__c == completedCommit.Id) {
                        manifestsAttachmentsIdsList.add(manifest.Flosum__Component_History__c);
                    }
                }

                Attachment commitAttachmentWithIds = new Attachment(
                    Name = Constants.COMMIT_ATTACHMENT_NAME,
                    ParentId = completedCommit.Flosum__Repository__c,
                    Body = Blob.valueOf(String.join(manifestsAttachmentsIdsList, ' ')),
                    ContentType = 'text/plain'
                );

                commitsAttachmentsMap.put(completedCommit.Id, commitAttachmentWithIds);
            }
        }

        if (!commitsAttachmentsMap.isEmpty()) {
            DatabaseUtils.insertRecords(
                commitsAttachmentsMap.values(),
                new List<Schema.DescribeFieldResult>{
                    Attachment.Name.getDescribe(),
                    Attachment.ParentId.getDescribe(),
                    Attachment.Body.getDescribe(),
                    Attachment.ContentType.getDescribe()
                }
            );
        }

        for (Flosum__Commit__c completedCommit : completedCommitsList) {
            Attachment commitAttachment = commitsAttachmentsMap.get(completedCommit.Id);
            Flosum__Commit__c fullDataCommit = fullDataCommits.get(completedCommit.Id);

            if (fullDataCommit != null) {
                if (fullDataCommit.Flosum__Repository__r.Synchronization_Status__c == 'Error') {
                    createLogForErrorRepositoryRequest(
                        completedCommit.Flosum__Repository__c,
                        fullDataCommit.Flosum__Repository__r.Name
                    );
                } else {
                    String commitMessage = 'Commit Name: ' + completedCommit.Flosum__Commit_Name__c;
                    dataForRequests.add(
                        new AgentService.RepositoryCommitRequestWrapper(
                            commitMessage,
                            fullDataCommits.get(completedCommit.Id).Flosum__Repository__r.Name,
                            'master',
                            commitsAttachmentsMap.get(completedCommit.Id).Id,
                            completedCommit.Flosum__Repository__c,
                            '',
                            '',
                            false,
                            completedCommit.Flosum__Repository__c
                        )
                    );
                }
            }
        }

        if (!disabledRepositories.isEmpty()) {
            clearRepositoriesSynchronizationHash(disabledRepositories);
        }

        if (!dataForRequests.isEmpty()) {
            System.enqueueJob(new CommitTriggerHandlerQueueble(dataForRequests));
        }
    }

    private static void clearRepositoriesSynchronizationHash(Set<String> repositoriesIdsSet) {
        List<Attachment> syncAttachmentsList = [
            SELECT Id, Name, ParentId, Body
            FROM Attachment
            WHERE ParentId IN :repositoriesIdsSet AND Name = :Constants.SYNC_ATTACHMENT_FOR_REPOSITORY_NAME
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

    private static void createLogForErrorRepositoryRequest(String repositoryId, String repositoryName) {
        Logger commitLogger = new Logger(Logger.createLogRecord(LogTypeEnum.COMMIT_TYPE));
        commitLogger.log(LoggerMessageTypeEnum.INFO, 'Repository: ' + repositoryName);
        commitLogger.log(LoggerMessageTypeEnum.INFO, 'Branch: master');
        commitLogger.log(LoggerMessageTypeEnum.INFO, 'Commit Logger Id: ' + commitLogger.getParentId());
        commitLogger.log(LoggerMessageTypeEnum.INFO, 'Sync Repository Id: ' + repositoryId);
        commitLogger.log(LoggerMessageTypeEnum.ERROR, 'The request could not be sent due to a synchronization error');
        commitLogger.updateLog();
    }
}