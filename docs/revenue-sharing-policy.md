# Revenue Sharing Policy (v1)

This policy defines how net project revenue is allocated.

## Allocation model

1. Founder share: `25%`
2. Performance pool: `35%`
3. Core equal pool: `15%`
4. Project reserve: `25%`

Total: `100%` of net revenue.

## Definitions

### Net revenue

Net revenue = collected revenue - essential operating costs in the same period.

Essential operating costs include:

1. infrastructure and hosting
2. email/notification providers
3. mandatory security and compliance tooling
4. payment platform fees

Formula:

`NetRevenue = GrossCollectedRevenue - EssentialOperatingCosts`

### Distribution period

Default distribution period is monthly, unless owner announces quarterly mode.

## 1) Founder share (25%)

1. Paid to project owner (current owner: project founder).
2. Independent from performance points.
3. Recognizes long-term ownership and stewardship obligations.

Formula:

`FounderPayout = NetRevenue * 0.25`

## 2) Performance pool (35%)

Distributed by contribution points per period.

### Point baseline

1. production feature delivery: 5 points
2. critical bug/incident fix: 4 points
3. security/reliability hardening: 4 points
4. partner integration/docs used in operations: 2 points
5. release/review/on-call support: 1-3 points

### Rules

1. Only merged and accepted work counts.
2. Work must be attributable in PR/issue/release records.
3. Point ledger must be published before payout.

Formula:

Let:

1. `PerfPool = NetRevenue * 0.35`
2. `TotalPoints = sum(points of all eligible contributors in period)`
3. `ContributorPoints_i = points of contributor i`

Then:

`PerformancePayout_i = PerfPool * (ContributorPoints_i / TotalPoints)` if `TotalPoints > 0`, else `0`.

## 3) Core equal pool (15%)

Distributed equally among active core members for that period.

### Active core criteria

A core member is active in a period when all conditions are true:

1. at least one accepted contribution in the period
2. participation in review/release/ops duties
3. no unresolved policy or conduct violation blocking payout

Owner may publish active core list per period before payout.

Formula:

Let:

1. `CorePool = NetRevenue * 0.15`
2. `ActiveCoreCount = number of active core members`

Then:

`CoreEqualPayout_i = CorePool / ActiveCoreCount` for each active core member when `ActiveCoreCount > 0`, else `0`.

## Core floor mechanism (stability)

Purpose: reduce payout volatility for active core contributors during low-revenue periods.

### Floor budget formula

`CoreFloorBudget = min(NetRevenue * 0.10, CorePool)`

### Per-core floor amount

If `ActiveCoreCount > 0`:

`CoreFloorPerMember = CoreFloorBudget / ActiveCoreCount`

### Distribution order

1. Calculate and distribute floor amount to each active core member.
2. Remaining core pool:

`CorePoolRemaining = CorePool - CoreFloorBudget`

3. Distribute `CorePoolRemaining` equally among active core members.

Net core payout per active core member:

`CoreTotalPayout_i = CoreFloorPerMember + (CorePoolRemaining / ActiveCoreCount)`

### Carry-over credit rule (optional)

If leadership approves a target floor higher than available `CoreFloorBudget`, the unpaid part can be recorded as non-guaranteed carry-over credit.
Carry-over credits are paid only when future period cashflow allows and after reserve safety constraints are met.

## 4) Project reserve (25%)

Used for project continuity and risk management:

1. infra scaling and reliability
2. security response and audits
3. legal/compliance operations
4. emergency incident handling
5. strategic ecosystem growth

Reserve usage should be logged in period summary notes.

Formula:

`ReserveAllocation = NetRevenue * 0.25`

## Governance and transparency

1. Payout summary must include:
- net revenue basis
- operating costs
- points by contributor
- active core roster
- reserve movements
2. Dispute window: 7 days after summary publication.
3. Owner has final decision authority for unresolved disputes in v1.

## Example calculation

Assume:

1. `GrossCollectedRevenue = 100,000`
2. `EssentialOperatingCosts = 20,000`
3. `NetRevenue = 80,000`

Then:

1. Founder: `80,000 * 0.25 = 20,000`
2. Performance pool: `80,000 * 0.35 = 28,000`
3. Core pool: `80,000 * 0.15 = 12,000`
4. Reserve: `80,000 * 0.25 = 20,000`

If active core count = 3:

1. CoreFloorBudget = `min(8,000, 12,000) = 8,000`
2. CoreFloorPerMember = `8,000 / 3 = 2,666.67`
3. CorePoolRemaining = `12,000 - 8,000 = 4,000`
4. CoreEqualRemainingPerMember = `4,000 / 3 = 1,333.33`
5. CoreTotalPayoutPerMember = `4,000.00` each

## Policy updates

This policy can be updated by owner announcement with clear effective date.
