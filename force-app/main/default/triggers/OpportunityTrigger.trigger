trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) {
   OpportunityTriggerHandler.updateAccountRatingForHighValueOpps(Trigger.new, Trigger.oldMap, null);
}