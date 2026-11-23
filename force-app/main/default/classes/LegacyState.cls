/* Static flags the legacy triggers lean on. Deliberately the way a crowded org
 * grows them: a once-only flag, a depth counter that never resets, a set of
 * done Ids. Throwaway probe for the aer review; not anyone's real code. */
public class LegacyState {
    public static Boolean fixedOnce = false;
    public static Integer rollupDepth = 0;
    public static Integer retries = 0;
    public static Integer swallowed = 0;
    public static Set<Id> oppAccountsDone = new Set<Id>();

    // Tests call this so a measured save starts like a new transaction.
    @TestVisible static void newTransaction() {
        fixedOnce = false; rollupDepth = 0; retries = 0; swallowed = 0;
        oppAccountsDone.clear();
    }
}
