public abstract with sharing class ConnectionDetails {
    // connection
    protected String connectionId;
    protected String connectionName;
    protected String applicationUrl;
    protected String gitProvider;
    protected String connectedAgentId;
    protected Boolean isBidirectionalSynchronization;
    protected Boolean isConvertToSfdx;
    protected Boolean isEnabled;
    // details
    protected String detailsId;
    protected String detailsName;

    public abstract void init(String connectionId);
    public abstract void init(Map<String, Object> connection);
    public abstract Map<String, Object> getValuesMap(Boolean isFull);
    public abstract void upsertConnection();

    public String getConnectionId() {
        return this.connectionId;
    }

    public String getApplicationUrl() {
        return this.applicationUrl;
    }

    public String getGitProvider() {
        return this.gitProvider;
    }

    public Boolean getIsBidirectionalSynchronization() {
        return this.isBidirectionalSynchronization;
    }

    public Boolean getIsConvertToSfdx() {
        return this.isConvertToSfdx;
    }

    protected void initConnection(String connectionId) {
        List<Connection__c> connections = [
            SELECT
                Id,
                Name,
                Agent_Connection__c,
                Agent_Connection__r.Flosum__Url__c,
                Git_Provider__c,
                Is_Bidirectional_Synchronization__c,
                Is_Convert_to_Sfdx__c,
                Is_Enabled__c,
                Sync_In_Progress__c
            FROM Connection__c
            WHERE Id = :connectionId
            WITH SECURITY_ENFORCED
        ];

        if (connections.isEmpty()) {
            throw new HandledException(Constants.MISSING_CONNECTION_ERROR);
        }

        this.connectionId = connections[0].Id;
        this.connectionName = connections[0].Name;
        this.connectedAgentId = connections[0].Agent_Connection__c;
        this.applicationUrl = connections[0].Agent_Connection__r.Flosum__Url__c;
        this.gitProvider = connections[0].Git_Provider__c;
        this.isBidirectionalSynchronization = connections[0].Is_Bidirectional_Synchronization__c;
        this.isConvertToSfdx = connections[0].Is_Convert_to_Sfdx__c;
        this.isEnabled = connections[0].Is_Enabled__c;
    }

    protected void initConnection(Map<String, Object> dataMap) {
        this.connectionId = String.valueOf(dataMap.get('connectionId'));
        this.connectionName = (String) dataMap.get('connectionName');
        this.applicationUrl = (String) dataMap.get('applicationUrl');
        this.connectedAgentId = (String) dataMap.get('connectedAgentId');
        this.gitProvider = (String) dataMap.get('gitProvider');
        this.isBidirectionalSynchronization = Boolean.valueOf(dataMap.get('isBidirectionalSynchronization'));
        this.isConvertToSfdx = Boolean.valueOf(dataMap.get('isConvertToSfdx'));
        this.isEnabled = Boolean.valueOf(dataMap.get('isEnabled'));
    }

    public void upsertConnectionRecord() {
        Connection__c connection = new Connection__c(
            Id = String.isEmpty(this.connectionId) ? null : this.connectionId,
            Name = this.connectionName,
            Agent_Connection__c = this.connectedAgentId,
            Git_Provider__c = this.gitProvider,
            Is_Bidirectional_Synchronization__c = this.isBidirectionalSynchronization,
            Is_Convert_to_Sfdx__c = this.isConvertToSfdx,
            Is_Enabled__c = this.isEnabled
        );

        DatabaseUtils.upsertRecord(
            connection,
            new List<Schema.DescribeFieldResult>{
                Connection__c.Id.getDescribe(),
                Connection__c.Name.getDescribe(),
                Connection__c.Agent_Connection__c.getDescribe(),
                Connection__c.Git_Provider__c.getDescribe(),
                Connection__c.Is_Bidirectional_Synchronization__c.getDescribe(),
                Connection__c.Is_Convert_to_Sfdx__c.getDescribe(),
                Connection__c.Is_Enabled__c.getDescribe()
            }
        );

        this.connectionId = connection.Id;
    }

    protected Map<String, Object> getConnectionValuesMap(Boolean isFull) {
        Map<String, Object> result = new Map<String, Object>{
            'applicationUrl' => this.applicationUrl,
            'gitProvider' => AgentService.getGitProviderHeaderValue(this.gitProvider),
            'isBidirectionalSynchronization' => this.isBidirectionalSynchronization,
            'isConvertToSfdx' => this.isConvertToSfdx,
            'isEnabled' => this.isEnabled
        };
        if (isFull) {
            result.put('connectionId', this.connectionId);
            result.put('connectionName', this.connectionName);
        }
        return result;
    }

    public static Map<String, Object> getConnectionInfo(String repositoryId) {
        List<Repository_Connection__c> connections = [
            SELECT
                Repository__r.Name,
                Connection__c,
                Connection__r.Is_Enabled__c,
                Connection__r.Git_Provider__c,
                Connection__r.Agent_Connection__r.Flosum__Url__c,
                Connection__r.Sync_In_Progress__c
            FROM Repository_Connection__c
            WHERE Repository__c = :repositoryId
            WITH SECURITY_ENFORCED
        ];

        if (connections.isEmpty()) {
            return new Map<String, Object>{ 'isSyncEnabled' => false, 'isSyncInProgress' => false };
        }

        return createRepositoryConnectionMap(connections[0]);
    }

    public static Map<String, Map<String, Object>> getConnectionInfoBulk(List<String> repositoriesIds) {
        List<Repository_Connection__c> connections = [
            SELECT
                Repository__r.Name,
                Connection__c,
                Connection__r.Is_Enabled__c,
                Connection__r.Git_Provider__c,
                Connection__r.Agent_Connection__r.Flosum__Url__c,
                Connection__r.Sync_In_Progress__c
            FROM Repository_Connection__c
            WHERE Repository__c IN :repositoriesIds
            WITH SECURITY_ENFORCED
        ];

        Map<String, Map<String, Object>> resultMap = new Map<String, Map<String, Object>>();
        Boolean isFinded;
        for (String repositoryId : repositoriesIds) {
            isFinded = false;
            for (Repository_Connection__c repositoryConnection : connections) {
                if (repositoryConnection.Repository__c == repositoryId) {
                    resultMap.put(repositoryId, createRepositoryConnectionMap(repositoryConnection));
                    isFinded = true;
                    break;
                }
            }

            if (!isFinded) {
                resultMap.put(
                    repositoryId,
                    new Map<String, Object>{ 'isSyncEnabled' => false, 'isSyncInProgress' => false }
                );
            }
        }

        return resultMap;
    }

    private static Map<String, Object> createRepositoryConnectionMap(Repository_Connection__c connection) {
        return new Map<String, Object>{
            'repositoryName' => connection.Repository__r.Name,
            'connectionId' => connection.Connection__c,
            'isSyncEnabled' => connection.Connection__r.Is_Enabled__c && !connection.Connection__r.Sync_In_Progress__c,
            'gitProvider' => connection.Connection__r.Git_Provider__c,
            'applicationUrl' => connection.Connection__r.Agent_Connection__r.Flosum__Url__c,
            'isSyncInProgress' => connection.Connection__r.Sync_In_Progress__c
        };
    }

    public static void toggleConnection(String connectionId, Boolean toggleValue) {
        List<Connection__c> connections = [
            SELECT Id, Is_Enabled__c, Sync_In_Progress__c
            FROM Connection__c
            WHERE Id = :connectionId
            WITH SECURITY_ENFORCED
        ];

        if (connections.isEmpty()) {
            throw new HandledException(Constants.MISSING_CONNECTION_ERROR);
        }

        connections[0].Sync_In_Progress__c = toggleValue;
        connections[0].Is_Enabled__c = toggleValue;

        DatabaseUtils.updateRecord(
            connections[0],
            new List<Schema.DescribeFieldResult>{
                Connection__c.Id.getDescribe(),
                Connection__c.Sync_In_Progress__c.getDescribe(),
                Connection__c.Is_Enabled__c.getDescribe()
            }
        );
    }
}