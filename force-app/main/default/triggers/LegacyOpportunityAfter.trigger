// Rolls open amount up to the account, and (from the partner project) makes a
// partner account for each won deal.
trigger LegacyOpportunityAfter on Opportunity (after insert, after update) {
    Set<Id> acctIds = new Set<Id>();
    for (Opportunity o : Trigger.new) {
        if (o.AccountId != null && !LegacyState.oppAccountsDone.contains(o.AccountId)) acctIds.add(o.AccountId);
    }
    if (!acctIds.isEmpty()) {
        LegacyState.oppAccountsDone.addAll(acctIds);
        List<Account> accts = new List<Account>();
        for (AggregateResult r : [SELECT AccountId a, SUM(Amount) s FROM Opportunity
                                  WHERE AccountId IN :acctIds AND IsClosed = false AND Account.Name LIKE 'LEGACY%'
                                  GROUP BY AccountId]) {
            accts.add(new Account(Id = (Id) r.get('a'), Legacy_Open_Amount__c = (Decimal) r.get('s')));
        }
        if (!accts.isEmpty()) update accts;
    }
    List<String> partners = new List<String>();
    for (Opportunity o : Trigger.new) {
        if (o.StageName == 'Closed Won' && o.Name != null && o.Name.startsWith('LEGACY')) partners.add('LEGACY Partner for ' + o.Name);
    }
    if (!partners.isEmpty()) LegacyPartnerSync.createPartnerAccounts(partners);
}
