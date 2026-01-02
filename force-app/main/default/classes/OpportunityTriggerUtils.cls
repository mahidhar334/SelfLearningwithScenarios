// Utility helpers for Opportunity trigger processing
public with sharing class OpportunityTriggerUtils {
    public static Set<Id> getIdsForAfterUpdate(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Set<Id> ids = new Set<Id>();
        if (newOpps == null || oldMap == null) {
            return ids;
        }
        for (Opportunity newOpp : newOpps) {
            if (newOpp == null) {
                continue;
            }
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            Decimal newAmt = newOpp.Amount;
            Decimal oldAmt = (oldOpp == null) ? null : oldOpp.Amount;
            if (newAmt != null && newAmt > 100000 && (oldAmt == null || newAmt != oldAmt) && newOpp.AccountId != null) {
                ids.add(newOpp.AccountId);
            }
        }
        return ids;
    }

    public static Set<Id> getIdsForAfterDelete(Map<Id, Opportunity> oldMap) {
        Set<Id> ids = new Set<Id>();
        if (oldMap == null) {
            return ids;
        }
        for (Opportunity oldOpp : oldMap.values()) {
            if (oldOpp == null) {
                continue;
            }
            if (oldOpp.Amount != null && oldOpp.Amount > 100000 && oldOpp.AccountId != null) {
                ids.add(oldOpp.AccountId);
            }
        }
        return ids;
    }

    public static Set<Id> getIdsForAfterUndelete(List<Opportunity> newOpps) {
        Set<Id> ids = new Set<Id>();
        if (newOpps == null) {
            return ids;
        }
        for (Opportunity newOpp : newOpps) {
            if (newOpp == null) {
                continue;
            }
            if (newOpp.Amount != null && newOpp.Amount > 100000 && newOpp.AccountId != null) {
                ids.add(newOpp.AccountId);
            }
        }
        return ids;
    }

    public static Set<Id> getIdsForAfterInsert(List<Opportunity> newOpps) {
        Set<Id> ids = new Set<Id>();
        if (newOpps == null) {
            return ids;
        }
        for (Opportunity newOpp : newOpps) {
            if (newOpp == null) {
                continue;
            }
            if (newOpp.Amount != null && newOpp.Amount > 100000 && newOpp.AccountId != null) {
                ids.add(newOpp.AccountId);
            }
        }
        return ids;
    }

    public static Boolean hasUpdatePermission(Schema.DescribeSObjectResult acctDescribe) {
        return acctDescribe != null
            && acctDescribe.isAccessible()
            && acctDescribe.isUpdateable()
            && Account.Rating.getDescribe().isAccessible()
            && Account.Rating.getDescribe().isUpdateable();
    }

    public static List<Account> getAccountsNeedingUpdate(Set<Id> accountIds) {
        List<Account> results = new List<Account>();
        for (Account acc : [SELECT Id, Rating FROM Account WHERE Id IN :accountIds WITH SECURITY_ENFORCED]) {
            if (acc.Rating != 'Hot') {
                acc.Rating = 'Hot';
                results.add(acc);
            }
        }
        return results;
    }

    // AFTER DELETE logic was moved to OpportunityTriggerDeleteHandler to reduce class complexity

    public static void performUpdate(List<Account> accountsToUpdate) {
        if (accountsToUpdate == null || accountsToUpdate.isEmpty()) {
            return;
        }
        if (!Schema.sObjectType.Account.isUpdateable() || !Account.Rating.getDescribe().isUpdateable()
            || !Schema.sObjectType.Account.isAccessible() || !Account.Rating.getDescribe().isAccessible()) {
            return;
        }
        List<Account> toUpdate = new List<Account>();
        for (Account acc : accountsToUpdate) {
            if (acc == null || acc.Id == null) {
                continue;
            }
            Account a = new Account(Id = acc.Id);
            a.Rating = acc.Rating;
            toUpdate.add(a);
        }
        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }
}
