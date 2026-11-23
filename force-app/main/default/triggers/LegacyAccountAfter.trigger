// Pushes status down to contacts and opps on every save, then saves the
// accounts a second time "to fix it".
trigger LegacyAccountAfter on Account (after insert, after update) {
    Set<Id> ids = new Set<Id>();
    for (Account a : Trigger.new) if (a.Name != null && a.Name.startsWith('LEGACY')) ids.add(a.Id);
    if (ids.isEmpty()) return;

    List<Contact> cs = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :ids];
    for (Contact c : cs) {
        c.Legacy_Synced__c = true;
        c.Legacy_Note__c = Trigger.newMap.get(c.AccountId).Legacy_Status__c;
    }
    if (!cs.isEmpty()) update cs;

    List<Opportunity> os = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :ids];
    for (Opportunity o : os) o.Description = 'Account says: ' + Trigger.newMap.get(o.AccountId).Legacy_Status__c;
    if (!os.isEmpty()) update os;

    // Second update to fix it: the first save leaves the tier stale. Don't remove, breaks prod.
    if (Trigger.isUpdate && !LegacyState.fixedOnce) {
        LegacyState.fixedOnce = true;
        List<Account> again = new List<Account>();
        for (Id i : ids) again.add(new Account(Id = i, Legacy_Fixed__c = true));
        update again;
    }
}
