@IsTest
public with sharing class AgentServiceTest {
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
    static void createGitBranchTest() {
        List<Flosum__Branch__c> branches = [
            SELECT Id, Name, Flosum__Branch_Name__c, Flosum__Repository__c, Flosum__Repository__r.Name
            FROM Flosum__Branch__c
        ];
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/repos/' +
                    branches[0].Flosum__Repository__r.Name +
                    '/branches' => new SingleRequestMock(200, '')
                }
            )
        );
        Test.startTest();
        AgentService.createGitBranch(branches[0]);
        Test.stopTest();
        List<Log__c> logs = [SELECT Id FROM Log__c WHERE isSystem__c = TRUE];
        List<Attachment> resultsAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :logs[0].Id];
        System.assert(resultsAttachments[0].Body.toString().contains('Synchronization process enabled'));
    }

    @IsTest
    static void startCommittingToGitTest() {
        List<Flosum__Repository__c> repos = [SELECT Id FROM Flosum__Repository__c];
        List<Flosum__Branch__c> branches = [
            SELECT Id, Name, Flosum__Branch_Name__c, Flosum__Repository__c
            FROM Flosum__Branch__c
        ];
        List<Flosum__Component__c> components = TestUtils.createBranchComponents(branches, 5, 'Snapshot');
        List<Flosum__Component_History__c> historys = TestUtils.createComponentHistorys(components);
        List<Attachment> attachments = TestUtils.createComponentHistorysAttachments(historys);

        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/devops/flosum-commit' => new SingleRequestMock(200, 'Commit')
                }
            )
        );
        Test.startTest();
        AgentService.startCommittingToGit(
            'message',
            'repositoryName',
            'branchName',
            attachments[0].Id,
            '',
            '',
            '',
            false,
            repos[0].Id
        );
        Test.stopTest();
    }

    @IsTest
    static void deleteBranchGitTest() {
        List<Flosum__Branch__c> branches = [
            SELECT Id, Name, Flosum__Branch_Name__c, Flosum__Repository__c, Flosum__Repository__r.Name
            FROM Flosum__Branch__c
        ];
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        String resultString = 'SUCCESS';
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/repos/' +
                    branches[0].Flosum__Repository__r.Name +
                    '/branches/' +
                    branches[0].Flosum__Branch_Name__c => new SingleRequestMock(
                        200,
                        JSON.serialize(new Map<String, Object>{ 'result' => resultString })
                    )
                }
            )
        );
        Test.startTest();
        AgentService.deleteBranchGit(JSON.serialize(branches[0]));
        Test.stopTest();
    }

    @IsTest
    static void getValidAgentAppLinkTest() {
        String testLink1 = 'www.test.com/';
        String testLink2 = 'www.test.com';
        String validLink = 'www.test.com';
        System.assert(AgentService.getValidAgentAppLink(testLink1).equals(validLink));
        System.assert(AgentService.getValidAgentAppLink(testLink2).equals(validLink));
    }

    @IsTest
    static void synchronizationToGitRequestTest() {
        Logger syncLogger = new Logger(Logger.createLogRecord(LogTypeEnum.SYNC_TYPE));
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        String resultString = 'SUCCESS';
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c + '/api/v1/git/devops/sync' => new SingleRequestMock(
                        204,
                        JSON.serialize(new Map<String, Object>{ 'result' => resultString })
                    )
                }
            )
        );
        Test.startTest();
        String result = AgentService.synchronizationToGitRequest(
            syncLogger.getParentId(),
            connection.Id,
            connection.Agent_Connection__r.Flosum__Url__c
        );
        Test.stopTest();
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(resultString, (String) resultMap.get('result'));
    }

    @IsTest
    static void disableSyncTest() {
        Logger syncLogger = new Logger(Logger.createLogRecord(LogTypeEnum.SYNC_TYPE));
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        String resultString = 'SUCCESS';
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/devops/sync/disable' => new SingleRequestMock(
                        204,
                        JSON.serialize(new Map<String, Object>{ 'result' => resultString })
                    )
                }
            )
        );
        Test.startTest();
        String result = AgentService.disableSync(
            syncLogger.getParentId(),
            connection.Id,
            connection.Agent_Connection__r.Flosum__Url__c
        );
        Test.stopTest();
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(resultString, (String) resultMap.get('result'));
    }

    @IsTest
    static void disableSyncTestError401() {
        Logger syncLogger = new Logger(Logger.createLogRecord(LogTypeEnum.SYNC_TYPE));
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        String resultString = 'SUCCESS';
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/devops/sync/disable' => new SingleRequestMock(401, 'Error 401')
                }
            )
        );
        Test.startTest();
        try {
            AgentService.disableSync(
                syncLogger.getParentId(),
                connection.Id,
                connection.Agent_Connection__r.Flosum__Url__c
            );
        } catch (Exception e) {
            System.assertEquals(AgentService.GIT_AUTHORIZATION_ERROR_MESSAGE, e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void disableSyncTestErrorNot204() {
        Logger syncLogger = new Logger(Logger.createLogRecord(LogTypeEnum.SYNC_TYPE));
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/devops/sync/disable' => new SingleRequestMock(307, 'Temporary Redirect')
                }
            )
        );
        Test.startTest();
        try {
            AgentService.disableSync(
                syncLogger.getParentId(),
                connection.Id,
                connection.Agent_Connection__r.Flosum__Url__c
            );
        } catch (Exception e) {
            System.assertEquals('Temporary Redirect', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void disableSyncTestError404() {
        Logger syncLogger = new Logger(Logger.createLogRecord(LogTypeEnum.SYNC_TYPE));
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/devops/sync/disable' => new SingleRequestMock(
                        404,
                        JSON.serialize(new Map<String, Object>{ 'original' => 'error-message' })
                    )
                }
            )
        );
        Test.startTest();
        try {
            AgentService.disableSync(
                syncLogger.getParentId(),
                connection.Id,
                connection.Agent_Connection__r.Flosum__Url__c
            );
        } catch (Exception e) {
            System.assertEquals('error-message', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void disableSyncTestError404BadJSON() {
        Logger syncLogger = new Logger(Logger.createLogRecord(LogTypeEnum.SYNC_TYPE));
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c +
                    '/api/v1/git/devops/sync/disable' => new SingleRequestMock(404, '<html></html>')
                }
            )
        );
        Test.startTest();
        try {
            AgentService.disableSync(
                syncLogger.getParentId(),
                connection.Id,
                connection.Agent_Connection__r.Flosum__Url__c
            );
        } catch (Exception e) {
            System.assertEquals('<html></html>', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void getAllRepositoriesTest() {
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c + '/api/v1/git/repos/' => new SingleRequestMock(
                        200,
                        JSON.serialize(
                            new List<Object>{
                                new Map<String, Object>{ 'name' => 'repo1' },
                                new Map<String, Object>{ 'name' => 'repo2' }
                            }
                        )
                    )
                }
            )
        );
        Test.startTest();
        Set<String> resultSet = AgentService.getAllRepositories(
            connection.Agent_Connection__r.Flosum__Url__c,
            connection.Id
        );
        Test.stopTest();
        System.assertEquals(2, resultSet.size());
        System.assert(resultSet.contains('repo1'));
        System.assert(resultSet.contains('repo2'));
    }

    @IsTest
    static void getAllRepositoriesTestError401() {
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c + '/api/v1/git/repos/' => new SingleRequestMock(
                        401,
                        'Error 401'
                    )
                }
            )
        );
        Test.startTest();
        try {
            AgentService.getAllRepositories(connection.Agent_Connection__r.Flosum__Url__c, connection.Id);
        } catch (Exception e) {
            System.assertEquals(AgentService.GIT_AUTHORIZATION_ERROR_MESSAGE, e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void getAllRepositoriesTestError404() {
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c + '/api/v1/git/repos/' => new SingleRequestMock(
                        404,
                        JSON.serialize(new Map<String, Object>{ 'original' => 'error-message' })
                    )
                }
            )
        );
        Test.startTest();
        try {
            AgentService.getAllRepositories(connection.Agent_Connection__r.Flosum__Url__c, connection.Id);
        } catch (Exception e) {
            System.assertEquals('error-message', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void getAllRepositoriesTestError404BadJSON() {
        Connection__c connection = [SELECT Id, Agent_Connection__r.Flosum__Url__c FROM Connection__c LIMIT 1];
        Test.setMock(
            HttpCalloutMock.class,
            new MultiRequestMock(
                new Map<String, HttpCalloutMock>{
                    connection.Agent_Connection__r.Flosum__Url__c + '/api/v1/git/repos/' => new SingleRequestMock(
                        404,
                        '<html></html>'
                    )
                }
            )
        );
        Test.startTest();
        try {
            AgentService.getAllRepositories(connection.Agent_Connection__r.Flosum__Url__c, connection.Id);
        } catch (Exception e) {
            System.assertEquals('<html></html>', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void getGitProviderHeaderValueTest() {
        Test.startTest();
        System.assertEquals('azure', AgentService.getGitProviderHeaderValue('Azure'));
        System.assertEquals('azure-server', AgentService.getGitProviderHeaderValue('Azure Onpremise'));
        System.assertEquals('bitbucket', AgentService.getGitProviderHeaderValue('BitBucket'));
        System.assertEquals('bitbucket-server', AgentService.getGitProviderHeaderValue('BitBucket Onpremise'));
        System.assertEquals('github', AgentService.getGitProviderHeaderValue('GitHub'));
        System.assertEquals('github-server', AgentService.getGitProviderHeaderValue('GitHub Onpremise'));
        System.assertEquals('gitlab', AgentService.getGitProviderHeaderValue('GitLab'));
        System.assertEquals('gitlab-server', AgentService.getGitProviderHeaderValue('GitLab Onpremise'));

        try {
            AgentService.getGitProviderHeaderValue('Wrong');
        } catch (Exception e) {
            System.assertEquals('Wrong Git Provider value', e.getMessage());
        }
        Test.stopTest();
    }
}