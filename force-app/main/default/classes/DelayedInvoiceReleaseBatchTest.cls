@isTest
public class DelayedInvoiceReleaseBatchTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    @isTest
    static void testReleasesOrderWhenDateArrives() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Delayed Invoice',
            EffectiveDate = Date.today(),
            Type = 'Renewal',
            Delay_Invoice_Date__c = Date.today()
        );
        insert ord;

        Test.startTest();
        Database.executeBatch(new DelayedInvoiceReleaseBatch(), 200);
        Test.stopTest();

        Order result = [SELECT Status FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Sync to ERP', result.Status, 'Status should move to Sync to ERP when delay date has arrived');
    }

    @isTest
    static void testDoesNotReleaseFutureDate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Delayed Invoice',
            EffectiveDate = Date.today(),
            Type = 'Renewal',
            Delay_Invoice_Date__c = Date.today().addDays(30)
        );
        insert ord;

        Test.startTest();
        Database.executeBatch(new DelayedInvoiceReleaseBatch(), 200);
        Test.stopTest();

        Order result = [SELECT Status FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Delayed Invoice', result.Status, 'Status should remain Delayed Invoice when delay date is in the future');
    }

    @isTest
    static void testDoesNotReleaseOrderWithNoDelayDate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Delayed Invoice',
            EffectiveDate = Date.today(),
            Type = 'Renewal'
        );
        insert ord;

        Test.startTest();
        Database.executeBatch(new DelayedInvoiceReleaseBatch(), 200);
        Test.stopTest();

        Order result = [SELECT Status FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Delayed Invoice', result.Status, 'Status should remain Delayed Invoice when no delay date is set');
    }

    @isTest
    static void testSchedule() {
        Test.startTest();
        System.schedule('Test DelayedInvoiceReleaseBatch', '0 0 1 * * ?', new DelayedInvoiceReleaseBatch());
        Test.stopTest();
    }
}
