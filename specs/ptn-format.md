# PTN Format Spec (Digital Legacy Weaver)

## Goal

`.ptn` is the policy transfer notation for Digital Legacy Weaver, derived from PTAG concepts.
It defines **who can do what**, **under which constraints**, and **when delivery triggers can run**.

For high-assurance profile extensions, see:

- `specs/ptn-v2.md`

## File extension

- `.ptn`

## Document structure

1. Header (key-value lines)
2. One or more blocks (`role`, `authority`, `constraint`, `policy`)

## Required headers

- `language`
- `module`
- `version`
- `owner`

Optional:

- `context`

## Header example

```ptn
language: PTN
module: digital_legacy_weaver
version: 1.0.0
owner: legacy-core
context: production
```

## Block grammar (v1)

```text
<block_type> <block_id> {
  <statement>
  <statement>
}
```

Supported `block_type` in v1:

- `role`
- `authority`
- `constraint`
- `policy`

## Statement patterns (v1)

Inside `authority`:

- `allow: action_a, action_b`
- `deny: action_x, action_y`
- `require requirement_name for action_name`

Inside `constraint`:

- `forbid role_name to action_name`
- `require requirement_name for action_name`

## Statement pattern extensions (v2 profile)

Inside `authority` or `constraint`:

- `require requirement_name[risk=high, mode=strict, evidence=..., owner=...] for action_name`

The v2 profile is backward-compatible with v1 and adds typed metadata to requirement statements.

Inside `policy`:

- `when <expression>`
- `and <expression>`
- `then <effect>`
- `and <effect>`

## Digital Legacy canonical actions

- `upsert_recovery_item`
- `delete_recovery_item`
- `trigger_self_recovery_delivery`
- `trigger_legacy_delivery`
- `ack_alive_check`
- `read_trigger_logs`

## Canonical requirements

- `mfa`
- `email_verified`
- `human_review`
- `cooldown_24h`

## Validation rules (minimum)

1. Required headers must exist.
2. At least one `role` and one `authority` block must exist.
3. Each `authority <role_id>` should map to a defined `role <role_id>`.
4. File must contain at least one `policy` or `constraint`.

## Runtime contract recommendation

At runtime, app services should ask policy engine:

`evaluate(actor_role, action, context) -> ALLOW | DENY | REQUIRE(list)`

Trigger scheduler should ask:

`can_trigger(mode, inactivity_days, context) -> bool + obligations`
