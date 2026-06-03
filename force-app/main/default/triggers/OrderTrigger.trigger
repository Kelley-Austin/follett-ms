trigger OrderTrigger on Order (before insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        OrderTriggerHelper.process(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        OrderTriggerHelper.handleApproval(Trigger.newMap, Trigger.oldMap);
    }

}