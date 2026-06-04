global class DelayedInvoiceReleaseBatch implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Order
            WHERE Status = 'Delayed Invoice'
            AND Delay_Invoice_Date__c != null
            AND Delay_Invoice_Date__c <= TODAY
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Order> orders) {
        for (Order ord : orders) {
            ord.Status = 'Sync to ERP';
        }
        try {
            update orders;
        } catch (Exception e) {
            RenewalLogHelper.writeToLog(
                RenewalLogHelper.LogType.ERROR,
                'DelayedInvoiceReleaseBatch - exception: ' + e,
                null
            );
        }
    }

    global void finish(Database.BatchableContext bc) {}

    // Schedule via anonymous Apex:
    // System.schedule('DelayedInvoiceReleaseBatch', '0 0 1 * * ?', new DelayedInvoiceReleaseBatch());
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DelayedInvoiceReleaseBatch(), 200);
    }
}
