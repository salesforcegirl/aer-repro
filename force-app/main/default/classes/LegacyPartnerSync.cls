/* From an older project (partner accounts for won deals). Never updated when
 * Region became required, and it hides its own failure. */
public class LegacyPartnerSync {
    public static void createPartnerAccounts(List<String> names) {
        List<Account> accts = new List<Account>();
        for (String n : names) accts.add(new Account(Name = n, Industry = 'Retail'));
        try { insert accts; }
        catch (Exception e) {
            LegacyState.swallowed++;
            System.debug('partner sync failed ' + e.getMessage());
        }
    }
}
