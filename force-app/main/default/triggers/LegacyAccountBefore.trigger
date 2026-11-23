// Keeps the contact count and status current. Query per record, no bulk thought.
trigger LegacyAccountBefore on Account (before insert, before update) {
    for (Account a : Trigger.new) {
        if (a.Name == null || !a.Name.startsWith('LEGACY')) continue;
        Integer c = 0;
        if (a.Id != null) c = [SELECT COUNT() FROM Contact WHERE AccountId = :a.Id];
        a.Legacy_Contact_Count__c = c;
        a.Legacy_Touch_Count__c = (a.Legacy_Touch_Count__c == null ? 0 : a.Legacy_Touch_Count__c) + 1;
        a.Legacy_Status__c = 'Touched ' + a.Legacy_Touch_Count__c + ' times, ' + c + ' contacts';
    }
}
