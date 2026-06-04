public with sharing class OrderTriggerHelper {
    public static void process(map<id,order> newQuoteToOrderMap){
        // re-querying for references within before trigger
        for (SBQQ__Quote__c  quote : [SELECT SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Renewal_Path__c
                            FROM SBQQ__Quote__c
                            WHERE SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Renewal_Path__c = 'No Touch'
                            AND Id in :newQuoteToOrderMap.keySet()]){
            Order ord = newQuoteToOrderMap.get(quote.Id);
            if (ord != null) {
                ord.Status = 'Pending Fulfillment';
            }
        }
    }
}
