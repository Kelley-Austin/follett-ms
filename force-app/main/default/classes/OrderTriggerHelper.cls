public with sharing class OrderTriggerHelper {

    private static Boolean approvalHandled = false;

    // Fires before insert — stamps the Delay Invoice Date from the quote onto the order
    // and sets No Touch renewal status. Hold + Delayed Invoice status are set after approval.
    public static void process(List<Order> newOrders) {
        Map<Id, Order> newQuoteToOrderMap = new Map<Id, Order>();
        for (Order ord : newOrders) {
            if (ord.Type == 'Renewal') {
                newQuoteToOrderMap.put(ord.SBQQ__Quote__c, ord);
            }
        }
        if (newQuoteToOrderMap.isEmpty()) return;

        for (SBQQ__Quote__c quote : [
            SELECT
                SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Renewal_Path__c,
                Delay_Invoice_Date__c
            FROM SBQQ__Quote__c
            WHERE Id IN :newQuoteToOrderMap.keySet()
        ]) {
            Order ord = newQuoteToOrderMap.get(quote.Id);
            if (ord == null) continue;

            if (quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Renewal_Path__c == 'No Touch') {
                ord.Status = 'Pending Fulfillment';
            }

            if (quote.Delay_Invoice_Date__c != null) {
                ord.Delay_Invoice_Date__c = quote.Delay_Invoice_Date__c;
            }
        }
    }

    // Fires after update — when an Order is approved, apply the delayed invoice hold if applicable.
    public static void handleApproval(Map<Id, Order> newMap, Map<Id, Order> oldMap) {
        if (approvalHandled) return;
        approvalHandled = true;
        List<Order> toUpdate = new List<Order>();
        for (Order ord : newMap.values()) {
            Order oldOrd = oldMap.get(ord.Id);
            Boolean justApproved = ord.Approval_Status__c == 'Approved'
                && oldOrd.Approval_Status__c != 'Approved';
            Boolean hasDelay = ord.Delay_Invoice_Date__c != null
                && ord.Delay_Invoice_Date__c > Date.today();

            if (justApproved && hasDelay) {
                toUpdate.add(new Order(
                    Id = ord.Id,
                    Oracle_Order_Hold__c = true,
                    Status = 'Delayed Invoice'
                ));
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
