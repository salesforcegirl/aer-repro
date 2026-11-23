/* Can the 5,001-Account flow failure be caught? In the org it is a
 * DmlException (measured 21 Nov), so a try/catch recovers. */
@IsTest
private class BreakCatch_Tests {
    @IsTest
    static void flowRowLimit_Report() {
        String caught = 'nothing thrown';
        try {
            insert BreakData.accounts(5001, 'PROBE FLOW catch');
        } catch (DmlException e) {
            caught = 'caught DmlException: ' + e.getMessage().left(160);
        }
        Assert.fail('REPORT ' + caught + ' | dml rows after ' + Limits.getDmlRows());
    }
}
