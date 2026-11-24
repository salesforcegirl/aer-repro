# aer repro: flow limit exception, and CPU on a save-heavy Account

Two differences between aer and a Salesforce org, cut down from a larger
set of probes. Measured 23 Nov 2026 on aer v1.6.21, against an Enterprise
edition scratch org (instance USA1154S) with the same source deployed. Org tests ran
synchronously, one class at a time.

## Results

### 1. A governor limit hit inside a record-triggered flow

**Setup:**
- `Probe_Before_Save` sets Description.
- `Probe_After_Save` creates one Task per Account.
- Both run on Accounts whose names start with `PROBE FLOW`.
- So each insert costs 2 DML rows, and 5,001 Accounts passes the 10,000-row limit.

`BreakCatch_Tests.flowRowLimit_Report` wraps the insert in
`try { } catch (DmlException e) { }` and reports what happened. It fails on
purpose: the message is the measurement.

| | Result |
|---|---|
| Org | Caught. `DmlException`: "Insert failed. First exception on row 4800; first error: LIMIT_EXCEEDED, We can't save this record because the "Probe After Save" process failed…". DML rows after: 5001 |
| aer | Not caught. `System.LimitException: Too many DML rows: 10001`, reported as "after-save flow Probe_After_Save failed" |

The org turns a limit hit inside a flow into a `DmlException` on the
triggering insert. So a test that wraps the save in try/catch recovers in
the org and fails in aer.

### 2. CPU on a save-heavy Account

A deliberately messy Account, built the way a crowded org grows:
- **Triggers:**
  - one query per record in a before trigger;
  - an after trigger that pushes status to Contacts and Opportunities, then saves the Accounts a second time;
  - a manual Contact roll-up with recursion and retries;
  - an Opportunity roll-up.
- **Formulas and rules:** formula fields, including a cross-object formula of a formula, and validation rules.
- **A flow** that saves inside a loop.

All of it applies only to Accounts named `LEGACY...`.

`LegacyAccount_Tests.save01_Report` and `save05_Report` build their data, then
measure one save inside `Test.startTest()`. Counts come from `Limits` and
are reported in the failure message.

| One save of | Org CPU | aer CPU | SOQL (both) | DML, rows (both) |
|---|---|---|---|---|
| 1 Account | 276 ms (median of 5) | 1 ms | 40 | 36, 54 |
| 5 Accounts | 664 ms (median of 5) | 1–2 ms | 100 | 72, 142 |

The org CPU figures were measured on 21 Nov. The aer figures are from v1.6.21;
v1.6.20 gave the same CPU. SOQL, DML and rows match exactly on v1.6.21.

For contrast, a pure integer loop (not in this repo) runs 1,803,000
iterations in 9 s of aer CPU. The same loop in the same org gave 4.4–5.1
million on 21 Nov and 2.7–2.9 million on 24 Nov, so the org's rate moves
by day or pod. Either way, aer charges more than the org for integer math,
and almost nothing for DML, SOQL, triggers and flows.

## Notes

- The org results came from a scratch org that also held other probe
  metadata, including an Account trigger whose behaviour sits behind
  custom metadata switches, all off for these runs. Nothing else in it
  acts on `PROBE FLOW` or `LEGACY` Accounts.
- To load data through the API, assign the `Legacy_Fields` permission set.
- `save10_Report` and `save25_Report` hit "Too many SOQL queries: 101" on
  both sides, by design. `migratedRecordSave_Report` and
  `partialBackfillMassEdit_Report` show a required field added after a
  partial data load, and also match on both sides.
- Run with `aer test force-app`.
