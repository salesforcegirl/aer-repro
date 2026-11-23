/* The legacy Account under load. _Report methods fail on purpose: the message
 * is the measurement (limits used by one user save, after setup). */
@IsTest
private class LegacyAccount_Tests {
    static String usage(String label) {
        return label + ': soql ' + Limits.getQueries() + '/' + Limits.getLimitQueries()
            + ', dml ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements()
            + ', rows ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows()
            + ', query rows ' + Limits.getQueryRows()
            + ', cpu ' + Limits.getCpuTime() + ' ms, heap ' + Limits.getHeapSize()
            + ', retries ' + LegacyState.retries + ', swallowed ' + LegacyState.swallowed;
    }
    // Setup builds the data, then one save of n accounts is measured inside startTest.
    static void userSave(Integer n) {
        String setup;
        try {
            LegacyTestData.build(n, 2);
            setup = usage('setup');
        } catch (Exception e) {
            Assert.fail('REPORT n=' + n + ' setup died: ' + e.getTypeName() + ': ' + e.getMessage());
        }
        LegacyState.newTransaction();
        List<Account> accts = [SELECT Id FROM Account WHERE Name LIKE 'LEGACY Customer%'];
        for (Account a : accts) a.Description = 'user edit';
        Test.startTest();
        String save;
        Long t0 = System.currentTimeMillis();
        try {
            update accts;
            save = usage('save') + ', wall ' + (System.currentTimeMillis() - t0) + ' ms';
        } catch (Exception e) {
            save = 'save died: ' + e.getTypeName() + ': ' + e.getMessage() + ' | ' + usage('at death');
        }
        Test.stopTest();
        Assert.fail('REPORT n=' + n + ' | ' + setup + ' | ' + save);
    }
    @IsTest static void save01_Report() { userSave(1); }
    @IsTest static void save05_Report() { userSave(5); }
    @IsTest static void save10_Report() { userSave(10); }
    @IsTest static void save25_Report() { userSave(25); }

    // Records loaded years ago with the bypass on and no Region. Any save now fails.
    @IsTest
    static void migratedRecordSave_Report() {
        Legacy_Bypass__c bypass = new Legacy_Bypass__c(SetupOwnerId = UserInfo.getOrganizationId(), Skip_Validation__c = true);
        insert bypass;
        Account old = new Account(Name = 'LEGACY Migrated 2016');
        insert old;
        delete bypass;
        LegacyState.newTransaction();
        String result;
        try {
            update new Account(Id = old.Id, Description = 'user edit');
            result = 'save worked';
        } catch (Exception e) {
            result = e.getTypeName() + ': ' + e.getMessage();
        }
        Assert.fail('REPORT migrated record save: ' + result + ' | ' + usage('after'));
    }

    // A load since 2011 with the bypass on, then a backfill of Region that only
    // covered the last three years. A mass edit across all of them.
    @IsTest
    static void partialBackfillMassEdit_Report() {
        Legacy_Bypass__c bypass = new Legacy_Bypass__c(SetupOwnerId = UserInfo.getOrganizationId(), Skip_Validation__c = true);
        insert bypass;
        List<Account> loaded = new List<Account>();
        for (Integer y = 2011; y <= 2026; y++) loaded.add(new Account(Name = 'LEGACY Loaded ' + y));
        insert loaded;
        for (Integer i = 0; i < loaded.size(); i++) {
            Test.setCreatedDate(loaded[i].Id, Datetime.newInstance(2011 + i, 6, 1));
            if (2011 + i >= 2024) loaded[i].Legacy_Region__c = 'Backfilled';
        }
        update loaded;   // the backfill, still under the bypass
        delete bypass;
        LegacyState.newTransaction();
        List<Account> edit = [SELECT Id, CreatedDate FROM Account WHERE Name LIKE 'LEGACY Loaded%' ORDER BY CreatedDate];
        for (Account a : edit) a.Description = 'mass edit';
        Test.startTest();
        List<Database.SaveResult> rs = Database.update(edit, false);
        Test.stopTest();
        Integer ok = 0; Integer firstOkYear;
        String firstError;
        for (Integer i = 0; i < rs.size(); i++) {
            if (rs[i].isSuccess()) { ok++; if (firstOkYear == null) firstOkYear = edit[i].CreatedDate.year(); }
            else if (firstError == null) firstError = rs[i].getErrors()[0].getMessage();
        }
        Assert.fail('REPORT backfill: ' + ok + ' of ' + rs.size() + ' saved, oldest saved from '
            + firstOkYear + ', first error: ' + firstError + ' | ' + usage('mass edit'));
    }
}
