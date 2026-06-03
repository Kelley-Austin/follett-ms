trigger OrderTrigger on Order (before insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        Map<Id, Order> newQuoteToOrderMap = new Map<Id, Order>();
        for (Order order : Trigger.New) {
            if (order.Type == 'Renewal') {
                newQuoteToOrderMap.put(order.SBQQ__Quote__c, order);
            }
        }
        if (!newQuoteToOrderMap.isEmpty()) {
            OrderTriggerHelper.process(newQuoteToOrderMap);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        OrderTriggerHelper.handleApproval(Trigger.newMap, Trigger.oldMap);
    }

}