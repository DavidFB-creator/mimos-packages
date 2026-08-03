# Calamares upstream trust record

MimOS packages the Calamares 3.4.2 release source with one reviewed local
patch, recorded below. The build does not use a moving branch, an automatically
generated source archive, or an AUR package.

## Pinned release

- Release: `3.4.2`
- Release date: 2026-03-10
- Source: `calamares-3.4.2.tar.gz`
- SHA-256: `733bbbb00dc9f84874bd5c22960952f317ea2537565431179fa2152b2fbfdccc`
- Detached signature SHA-256:
  `f3c898eddaef42abd7f01fd8c3a586c1db4d748550d7775ee9ee32273251199b`

## Signing identity

- Maintainer primary key:
  `00AC D15E 25A7 9FEE 028B 0EE5 7FEA 3DA6 169C 77D6`
- 2026 release-signing subkey:
  `6D08 3784 1C06 8A23 3F24 127B 14B6 CC38 1BC2 56D6`
- Maintainer key source: `https://euroquis.nl/doc/pubkey.asc`
- Key file SHA-256:
  `60fc6a45a99bb0cf8fcc3e1876e98f36d0c9746b25516b164ce231649c3008d9`

The `prepare()` function creates an isolated temporary GnuPG home, checks the
primary fingerprint, verifies the detached signature, and requires the exact
release-signing subkey. The keyring is deleted immediately after verification.

## Local patches

### `0001-redact-any-password-hash-format.patch`

`Logger::RedactedCommand` exists so that the hashed password Calamares passes
to `usermod -p` never reaches the session log, which the surrounding upstream
comment describes as something that "may get posted to bug reports, or stored
in the target system". It recognised only hashes beginning with `$6$`.

`SetPasswordJob` derives that hash from `crypt_gensalt()`, and libxcrypt 4.5.2
on Arch answers with a yescrypt salt, so the hash begins with `$y$` and was
written to `~/.cache/calamares/session.log` in full. The patch redacts the
argument given to `-p` whatever its format, and any modular crypt string
wherever it appears, while leaving the conventional `!`, `!!` and `*`
locked-account markers readable.

`tests/shell/tst_calamares_redaction.sh` compiles the redaction out of the real
`Logger.cpp` and requires the same checks to fail against unpatched upstream.
Report this upstream when the MimOS repository becomes public. See ADR-042.

## Update procedure

Every Calamares update requires a manual review of the upstream release notes,
the release checksum, the active signing key, build dependencies, module
selection, installed file list, and upstream license set. Never update only the
version number.
