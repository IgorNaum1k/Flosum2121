@IsTest
public class BitbucketWebServiceTest {
    @IsTest
    static void testAll() {
        System.Test.startTest();
        BitbucketWebService.codeCover();
        System.Test.stopTest();
    }
}