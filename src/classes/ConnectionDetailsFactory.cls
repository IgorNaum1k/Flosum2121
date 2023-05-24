public with sharing class ConnectionDetailsFactory {
    private static ConnectionDetails getInstance(String gitProvider) {
        switch on gitProvider {
            when 'GitHub' {
                ConnectionDetailsGithub connectionDetails = new ConnectionDetailsGithub();
                return connectionDetails;
            }
            when 'GitLab' {
                ConnectionDetailsGitlab connectionDetails = new ConnectionDetailsGitlab();
                return connectionDetails;
            }
            when 'BitBucket' {
                ConnectionDetailsBitbucket connectionDetails = new ConnectionDetailsBitbucket();
                return connectionDetails;
            }
            when 'Azure' {
                ConnectionDetailsAzure connectionDetails = new ConnectionDetailsAzure();
                return connectionDetails;
            }
            when 'GitHub Onpremise' {
                ConnectionDetailsGithubOnpremise connectionDetails = new ConnectionDetailsGithubOnpremise();
                return connectionDetails;
            }
            when 'GitLab Onpremise' {
                ConnectionDetailsGitlabOnpremise connectionDetails = new ConnectionDetailsGitlabOnpremise();
                return connectionDetails;
            }
            when 'BitBucket Onpremise' {
                ConnectionDetailsBitbucketOnpremise connectionDetails = new ConnectionDetailsBitbucketOnpremise();
                return connectionDetails;
            }
            when 'Azure Onpremise' {
                ConnectionDetailsAzureOnpremise connectionDetails = new ConnectionDetailsAzureOnpremise();
                return connectionDetails;
            }
            when else {
                throw new HandledException(Constants.WRONG_PROVIDER_VALUE_ERROR_MESSAGE);
            }
        }
    }

    public static ConnectionDetails create(String gitProvider, String connectionId) {
        ConnectionDetails connection = getInstance(gitProvider);
        connection.init(connectionId);
        return connection;
    }

    public static ConnectionDetails create(Map<String, Object> connectionMap) {
        ConnectionDetails connection = getInstance((String) connectionMap.get('gitProvider'));
        connection.init(connectionMap);
        return connection;
    }
}