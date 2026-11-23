/* "Saves fail sometimes, so try again." Retries the whole list three times,
 * then one record at a time, then sets the fixed flag and tries once more.
 * Every failed attempt still costs a DML statement. */
public class LegacyBruteForce {
    public static void save(List<Account> accts) {
        if (accts.isEmpty()) return;
        for (Integer attempt = 0; attempt < 3; attempt++) {
            try { update accts; return; } catch (Exception e) { LegacyState.retries++; }
        }
        for (Account a : accts) {
            try { update a; }
            catch (Exception e) {
                LegacyState.retries++;
                a.Legacy_Fixed__c = true;   // fix it
                try { update a; } catch (Exception e2) { LegacyState.swallowed++; }
            }
        }
    }
}
