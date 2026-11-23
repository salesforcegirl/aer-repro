/* The factory the current project updated: it sets Region. */
@IsTest
public class LegacyTestData {
    public static List<Account> build(Integer n, Integer contactsEach) {
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < n; i++) {
            accts.add(new Account(Name = 'LEGACY Customer ' + i, Legacy_Region__c = 'West',
                Industry = Math.mod(i, 2) == 0 ? 'Retail' : 'Banking', NumberOfEmployees = 10 + i));
        }
        insert accts;
        List<Contact> cs = new List<Contact>();
        List<Opportunity> os = new List<Opportunity>();
        for (Integer i = 0; i < n; i++) {
            for (Integer j = 0; j < contactsEach; j++) {
                cs.add(new Contact(AccountId = accts[i].Id, FirstName = 'Legacy' + j,
                    LastName = 'Customer' + i + 'x' + j, Email = 'legacy' + i + 'x' + j + '@example.invalid'));
            }
            os.add(new Opportunity(AccountId = accts[i].Id, Name = 'LEGACY Deal ' + i,
                StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Amount = 1000 + i));
        }
        insert cs;
        insert os;
        return accts;
    }
}
