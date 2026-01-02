public with sharing class OpportunityTriggerHandler {
    // Simple static guard to prevent recursive execution within the same transaction
    private static Boolean isExecuting = false;
    /**
     * Updates Account.Rating to 'Hot' for Accounts that have related Opportunities
     * over 100,000. Enforces CRUD/FLS.
     */
    public static void updateAccountRatingForHighValueOpps(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap, String eventType) {
        // If trigger didn't pass an explicit eventType, infer from Trigger context
        if (eventType == null) {
            eventType = inferEventTypeFromTrigger();
        }
        if (eventType == null) {
            return;
        }

        // Prevent recursion in the same transaction
        if (isExecuting) {
            return;
        }
        isExecuting = true;
        try {
            Set<Id> accountIds = new Set<Id>();


            if ('AFTER_UPDATE'.equals(eventType)) {
                accountIds.addAll(OpportunityTriggerUtils.getIdsForAfterUpdate(newOpps, oldMap));
            } else if ('AFTER_DELETE'.equals(eventType)) {
                // Delegate delete-specific logic to dedicated delete handler
                OpportunityTriggerDeleteHandler.handleAfterDelete(oldMap);
                return;
            } else if ('AFTER_INSERT'.equals(eventType)) {
                accountIds.addAll(OpportunityTriggerUtils.getIdsForAfterInsert(newOpps));
            }

            if (accountIds.isEmpty()) {
                return;
            }

            Schema.DescribeSObjectResult acctDescribe = Account.SObjectType.getDescribe();
            if (!OpportunityTriggerUtils.hasUpdatePermission(acctDescribe)) {
                return;
            }

            List<Account> accountsToUpdate = OpportunityTriggerUtils.getAccountsNeedingUpdate(accountIds);
            if (accountsToUpdate.isEmpty()) {
                return;
            }

            OpportunityTriggerUtils.performUpdate(accountsToUpdate);
        } finally {
            isExecuting = false;
        }
    }

    private static String inferEventTypeFromTrigger() {
        if (Trigger.isAfter) {
            if (Trigger.isUpdate) {
                return 'AFTER_UPDATE';
            }
            if (Trigger.isDelete) {
                return 'AFTER_DELETE';
            }
            if (Trigger.isInsert) {
                return 'AFTER_INSERT';
            }
        }
        if (Trigger.isAfter && Trigger.isUndelete) {
            return 'AFTER_UNDELETE';
        }
        return null;
    }
}
