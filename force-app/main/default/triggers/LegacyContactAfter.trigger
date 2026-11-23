// Manual roll-up of contacts to the account. Two queries per contact, the
// same account Id can land in the list twice, and the depth guard never resets.
trigger LegacyContactAfter on Contact (after insert, after update, after delete) {
    if (LegacyState.rollupDepth >= 3) return;
    LegacyState.rollupDepth++;
    List<Contact> rows = Trigger.isDelete ? Trigger.old : Trigger.new;
    List<Account> accts = new List<Account>();
    for (Contact c : rows) {
        if (c.AccountId == null) continue;
        Account a = [SELECT Id, Name FROM Account WHERE Id = :c.AccountId];
        if (!a.Name.startsWith('LEGACY')) continue;
        accts.add(new Account(Id = a.Id,
            Legacy_Contact_Count__c = [SELECT COUNT() FROM Contact WHERE AccountId = :a.Id]));
    }
    LegacyBruteForce.save(accts);
}
