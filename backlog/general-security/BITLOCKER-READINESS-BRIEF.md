# BitLocker and Device Encryption readiness brief

Created: 2026-07-26

Status: Reference only. Douglas removed this item from the active backburner on 2026-07-27.

## Verified state

- Windows edition: Home/Core.
- Display version: 25H2.
- Build: 26200.
- TPM, Secure Boot, WinRE, protection status, and recovery-key escrow remain unknown because the inspection requires an elevated Windows context.

## Goal

Protect the system drive at rest and prove that Douglas can recover it after a firmware, boot, account, or hardware event.

## Douglas’s interactive steps

1. From another device or browser session, sign in at [Microsoft recovery keys](https://aka.ms/myrecoverykey).
2. Confirm the account is accessible before changing encryption.
3. Open an elevated PowerShell window.
4. Run:

```powershell
manage-bde.exe -status C:
Get-Tpm
Confirm-SecureBootUEFI
reagentc.exe /info
```

5. Open **Settings → Privacy & security → Device encryption**.
6. If protection is already on, match the device’s recovery-key ID to an accessible recovery record.
7. If protection is off and the page is available, enable Device Encryption only after step 2 succeeds.
8. Wait for encryption to complete.
9. Preserve a second recovery copy on separate physical media or paper stored away from the computer.
10. Verify status again with `manage-bde.exe -status C:`.

## Agent boundary

Agents may interpret status fields and update this brief. Douglas handles elevation, account sign-in, enablement, and recovery-key custody.

Never paste, photograph, transcribe, OCR, store, or docket the 48-digit recovery key. Microsoft cannot recreate a lost key. [Microsoft recovery guidance](https://support.microsoft.com/en-us/windows/security/encryption/find-your-bitlocker-recovery-key).

## Completion evidence

- `C:` conversion status and protection status recorded without key material;
- TPM and Secure Boot readiness recorded;
- WinRE status recorded;
- recovery access verified from a second device;
- independent recovery-copy location described without its value;
- verification date recorded in `STATUS.md` and `LOG.md`.
