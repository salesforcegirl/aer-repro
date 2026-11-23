@IsTest
public class BreakData {
    public static List<Account> accounts(Integer n, String prefix) {
        List<Account> out = new List<Account>();
        for (Integer i = 0; i < n; i++) out.add(new Account(Name = prefix + ' ' + i));
        return out;
    }
}
