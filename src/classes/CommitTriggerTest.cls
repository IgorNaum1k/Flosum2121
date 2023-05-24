@IsTest
private class CommitTriggerTest {
    @IsTest
    static void testit(){
        System.Test.startTest();
        Flosum__Commit__c c = new Flosum__Commit__c();
        c.Flosum__Commit_Name__c  = 'dfg';
        insert c;
        c.Flosum__Commit_Name__c  = 'asd';
        update c;
        System.Test.stopTest();
    }

}