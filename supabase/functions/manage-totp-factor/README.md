# manage-totp-factor

Owner-authenticated function for TOTP setup lifecycle.

## Actions

1. `status`
- returns current factor state:
  - `configured`
  - `enabled`
  - `require_totp_unlock`

2. `begin_setup`
- generates a new Base32 secret
- stores factor as disabled
- returns:
  - `secret_base32`
  - `otpauth_uri`

3. `confirm_setup`
- validates `totp_code` against stored secret
- enables factor on success
- updates `user_safety_settings.require_totp_unlock`

4. `disable`
- disables factor
- clears `require_totp_unlock`

## Request shape

```json
{
  "action": "status | begin_setup | confirm_setup | disable",
  "totp_code": "123456",
  "require_totp_unlock": true
}
```

`totp_code` is required for `confirm_setup`.
