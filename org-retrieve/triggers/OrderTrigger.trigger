trigger OrderTrigger on Order (before insert) {

    if (Trigger.isBefore && Trigger.isInsert){
        map<id,order> newQuoteToOrderMap = new map<id,order>{};
        for (Order order : Trigger.New){
            if (order.Type == 'Renewal'){
                newQuoteToOrderMap.put(order.SBQQ__Quote__c, order);
            }
        }

        if (!newQuoteToOrderMap.isEmpty()){
           OrderTriggerHelper.process(newQuoteToOrderMap);
        }

    }
    
}