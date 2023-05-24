public class CommitTriggerHandlerQueueble implements Queueable, Database.AllowsCallouts {
    List<Flosum__Commit__c> commits;
    List<AgentService.RepositoryCommitRequestWrapper> requestsWrappersList;

    public CommitTriggerHandlerQueueble(List<Flosum__Commit__c> commits) {
        this.commits = commits;
    }

    public CommitTriggerHandlerQueueble(List<AgentService.RepositoryCommitRequestWrapper> requestsWrappersList) {
        this.requestsWrappersList = requestsWrappersList;
    }

    public void execute(QueueableContext context) {
        AgentService.RepositoryCommitRequestWrapper reqWrapper = this.requestsWrappersList[0];

        AgentService.startCommittingToGit(
            reqWrapper.message,
            reqWrapper.repository,
            reqWrapper.branch,
            reqWrapper.commitAttachmentId,
            reqWrapper.syncRepositoryId,
            reqWrapper.syncBranchId,
            reqWrapper.deleteAttachmentId,
            reqWrapper.isSingleOperation,
            reqWrapper.repositoryId
        );
        this.requestsWrappersList.remove(0);
        if (this.requestsWrappersList != null && !this.requestsWrappersList.isEmpty()) {
            System.enqueueJob(new CommitTriggerHandlerQueueble(this.requestsWrappersList));
        }
    }
}