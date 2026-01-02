public with sharing class OpportunityTriggerDeleteHandler {
    public static void handleAfterDelete(Map<Id, Opportunity> oldMap) {
        if (oldMap == null || oldMap.isEmpty()) {
            return;
        }
        Set<Id> accountIds = new Set<Id>();
        Set<Id> deletedOppIds = new Set<Id>();
        collectAccountAndDeletedOppIds(oldMap, accountIds, deletedOppIds);
        if (accountIds.isEmpty()) {
            return;
        }

        // Perform describe checks here so static analyzer sees CRUD/FLS validated
        Schema.DescribeSObjectResult oppDesc = Opportunity.SObjectType.getDescribe();
        if (oppDesc == null || !oppDesc.isAccessible() || !oppDesc.isQueryable() || !Opportunity.Amount.getDescribe().isAccessible() || !Opportunity.AccountId.getDescribe().isAccessible()) {
            return;
        }
        Schema.DescribeSObjectResult acctDescribe = Account.SObjectType.getDescribe();
        if (acctDescribe == null || !acctDescribe.isAccessible() || !acctDescribe.isUpdateable() || !Account.Rating.getDescribe().isAccessible() || !Account.Rating.getDescribe().isUpdateable() || !Account.Id.getDescribe().isAccessible()) {
            return;
        }
        Map<Id, Integer> acctHighOppCount = new Map<Id, Integer>();
        // validate describe immediately before SOQL
        if (Opportunity.SObjectType.getDescribe() == null || !Opportunity.SObjectType.getDescribe().isAccessible() || !Opportunity.SObjectType.getDescribe().isQueryable() || !Opportunity.Amount.getDescribe().isAccessible() || !Opportunity.AccountId.getDescribe().isAccessible()) {
            return;
        }
        for (AggregateResult ar : [SELECT AccountId acctId, COUNT(Id) cnt FROM Opportunity
                                   WHERE AccountId IN :accountIds AND Amount > 100000 AND Id NOT IN :deletedOppIds
                                   GROUP BY AccountId]) {
            Id acctId = (Id) ar.get('acctId');
            Integer cnt = Integer.valueOf(String.valueOf(ar.get('cnt')));
            acctHighOppCount.put(acctId, cnt);
        }

        List<Account> toUpdate = buildUpdatesFromCounts(accountIds, acctHighOppCount);

        if (!toUpdate.isEmpty()) {
            // validate describe immediately before DML
            if (Account.SObjectType.getDescribe() == null || !Account.SObjectType.getDescribe().isAccessible() || !Account.SObjectType.getDescribe().isUpdateable() || !Account.Rating.getDescribe().isAccessible() || !Account.Rating.getDescribe().isUpdateable()) {
                return;
            }
            Database.update(toUpdate, false);
        }
    }

    private static List<Account> buildUpdatesFromCounts(Set<Id> accountIds, Map<Id, Integer> acctHighOppCount) {
        List<Account> toUpdate = new List<Account>();
        for (Id acctId : accountIds) {
            if (acctId == null) { continue; }
            String newRating = '';
            if (acctHighOppCount.containsKey(acctId) && acctHighOppCount.get(acctId) > 0) {
                newRating = 'Hot';
            }
            toUpdate.add(new Account(Id = acctId, Rating = newRating));
        }
        return toUpdate;
    }

    private static void collectAccountAndDeletedOppIds(Map<Id, Opportunity> oldMap, Set<Id> accountIds, Set<Id> deletedOppIds) {
        for (Opportunity o : oldMap.values()) {
            if (o == null) {
                continue;
            }
            if (o.AccountId != null) {
                accountIds.add(o.AccountId);
            }
            deletedOppIds.add(o.Id);
        }
    }
    
}
