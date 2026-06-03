@isTest
public class DelayedInvoiceReleaseBatchTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    // Simulates approval completing on an order with a delay date that has arrived
    @isTest
    static void testReleasesOrderWhenDateArrives() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Type = 'Renewal',
            Oracle_Order_Hold__c = true,
            Delay_Invoice_Date__c = Date.today()
        );
        insert ord;

        Test.startTest();
        Database.executeBatch(new DelayedInvoiceReleaseBatch(), 200);
        Test.stopTest();

        Order result = [SELECT Oracle_Order_Hold__c, Status FROM Order WHERE Id = :ord.Id];
        System.assertEquals(false, result.Oracle_Order_Hold__c, 'Hold should be released when date has arrived');
        System.assertEquals('Sync to ERP', result.Status, 'Status should move to Sync to ERP');
    }

    @isTest
    static void testDoesNotReleaseFutureHold() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Type = 'Renewal',
            Oracle_Order_Hold__c = true,
            Delay_Invoice_Date__c = Date.today().addDays(30)
        );
        insert ord;

        Test.startTest();
        Database.executeBatch(new DelayedInvoiceReleaseBatch(), 200);
        Test.stopTest();

        Order result = [SELECT Oracle_Order_Hold__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals(true, result.Oracle_Order_Hold__c, 'Hold should remain for future date');
    }

    @isTest
    static void testDoesNotReleaseOrderWithNoHoldDate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Type = 'Renewal',
            Oracle_Order_Hold__c = true
        );
        insert ord;

        Test.startTest();
        Database.executeBatch(new DelayedInvoiceReleaseBatch(), 200);
        Test.stopTest();

        Order result = [SELECT Oracle_Order_Hold__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals(true, result.Oracle_Order_Hold__c, 'Hold without a date should not be released by this batch');
    }

    @isTest
    static void testHandleApprovalSetsHoldAndStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Type = 'Renewal',
            Delay_Invoice_Date__c = Date.today().addDays(30),
            Approval_Status__c = 'Pending'
        );
        insert ord;

        Test.startTest();
        ord.Approval_Status__c = 'Approved';
        update ord;
        Test.stopTest();

        Order result = [SELECT Oracle_Order_Hold__c, Status FROM Order WHERE Id = :ord.Id];
        System.assertEquals(true, result.Oracle_Order_Hold__c, 'Hold should be set on approval when delay date is in the future');
        System.assertEquals('Delayed Invoice', result.Status, 'Status should be Delayed Invoice on approval');
    }

    @isTest
    static void testHandleApprovalNoHoldWhenNoDelayDate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Order ord = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Type = 'Renewal',
            Approval_Status__c = 'Pending'
        );
        insert ord;

        Test.startTest();
        ord.Approval_Status__c = 'Approved';
        update ord;
        Test.stopTest();

        Order result = [SELECT Oracle_Order_Hold__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals(false, result.Oracle_Order_Hold__c, 'No hold should be set when no delay date');
    }

    @isTest
    static void testSchedule() {
        Test.startTest();
        System.schedule('Test DelayedInvoiceReleaseBatch', '0 0 1 * * ?', new DelayedInvoiceReleaseBatch());
        Test.stopTest();
    }
}
