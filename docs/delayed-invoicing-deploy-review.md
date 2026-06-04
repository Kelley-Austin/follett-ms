# Delayed Invoicing — Pre-Deploy Review

**Date:** 2026-06-03  
**Branch:** `developer/claresegrue-prft`  
**Target org:** `follett-ms-production`  
**Reviewer:** Claude Code (automated code review)

---

## What's in this deployment

| Component | Type | Status vs Production |
|---|---|---|
| `OrderTriggerHelper` | Apex Class | Modified |
| `OrderTrigger` | Apex Trigger | Modified |
| `DelayedInvoiceReleaseBatch` | Apex Class | Net new |
| `DelayedInvoiceReleaseBatchTest` | Apex Class | Net new |
| `Order.Delay_Invoice_Date__c` | Custom Field | No change |
| `OrderStatus` | Standard Value Set | Modified — adds `Delayed Invoice` value |

---

## Summary

The core logic is sound and the deploy is safe to proceed with two items resolved first: a missing test for the before-insert stamping logic, and a pre-deploy data check to confirm no legacy orders will be swept up by the batch on first run.

---

## Findings

### Must resolve before deploy

#### Add `process()` test coverage
**Risk:** Deployment may fail the 75% coverage gate. More importantly, the new before-insert logic that stamps `Delay_Invoice_Date__c` and `Status = 'Pending Fulfillment'` on Renewal orders is completely untested.

**Why:** Test orders in `DelayedInvoiceReleaseBatchTest` set `Type = 'Renewal'` but leave `SBQQ__Quote__c` blank. The SOQL in `process()` returns nothing, so `OrderTriggerHelper` lines 24–30 never execute.

**Fix:** Add a test that creates a `SBQQ__Quote__c` with `Renewal_Path__c = 'No Touch'` and a future `Delay_Invoice_Date__c`, inserts a linked Renewal Order, and asserts both `Status` and `Delay_Invoice_Date__c` are stamped correctly on the order.

---

---

### Confirmed safe

#### `RenewalLogHelper` dependency
`DelayedInvoiceReleaseBatch` calls `RenewalLogHelper.writeToLog(...)` in its catch block. Confirmed this class already exists in production — no deployment risk. Consider adding it to `package.xml` so the dependency is explicit and retrievable.

#### `process()` refactor — functionally equivalent
Production filters in SOQL (`WHERE Renewal_Path__c = 'No Touch'`); local moves the filter into Apex. Net behavior for `Status = 'Pending Fulfillment'` stamping is identical.

#### `Delay_Invoice_Date__c` field — no change
Field definition in local source is identical to production. No risk.

#### `Delayed Invoice` picklist + code in same package
Safe to deploy together. Salesforce compiles the full package before activating, so the `Delayed Invoice` value exists by the time `handleApproval` writes to `Status`.

#### `handleApproval` recursion
The `update` inside the `after update` trigger does re-fire the trigger, but terminates correctly on the second pass because `Approval_Status__c` doesn't change in the re-entrant update. Not an infinite loop.

---

### Lower priority (address in a follow-up)

| # | Finding | Recommendation |
|---|---|---|
| 1 | `handleApproval` relies on implicit recursion termination | Add a `private static Boolean hasRun` guard to make the intent explicit |
| 2 | `process()` doesn't guard against null `SBQQ__Quote__c` | Add `ord.SBQQ__Quote__c != null` check in the filter loop |
| 3 | `handleApproval` does not check current `Status` before overwriting | Confirm with business that overwriting status on approval regardless of current state is intended |
| 4 | Same-day delay date is a no-op | `handleApproval` uses `> today` (sets hold) while batch uses `<= TODAY` (releases). An order approved on its delay date gets no hold and invoices normally — confirm this is acceptable |
| 5 | Batch swallows exceptions entirely | Consider `Database.update(orders, false)` with per-record result inspection for partial failure visibility |

---

## Recommended deploy order

1. Resolve test coverage gap (add `process()` test)
2. Deploy package
3. Verify `Delayed Invoice` picklist value is visible in Setup → Order → Status
4. Schedule `DelayedInvoiceReleaseBatch` via anonymous Apex:
   ```apex
   System.schedule('DelayedInvoiceReleaseBatch', '0 0 1 * * ?', new DelayedInvoiceReleaseBatch());
   ```
