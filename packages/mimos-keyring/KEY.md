# Dropping in the MimOS signing key

**Steps 1 to 3 below are done.** The key exists — RSA 4096,
`MimOS Package Signing <packages@mimoslinux.org>`, fingerprint
`77E1176695E14EBFA3A03B93CE5181401267126E`, created 2026-07-27 and held by
David. Its public half is in `mimos.gpg`, the fingerprint is in
`mimos-trusted`, `mimos-keyring` is listed in `packages-project.x86_64`, and it
has been composed into exact images.

This file previously said the package was a skeleton, not listed and not
composed. That stopped being true on 2026-07-27 and was not corrected until
2026-07-29, when it was read as current and repeated as a live blocker. A
procedure document that describes a state the repository left behind sends the
reader in the wrong direction with full confidence.

The original reason for the skeleton still holds for anyone starting over: a
keyring package that installs no key tells pacman that MimOS keys are managed
while verifying nothing, which is worse than shipping no keyring at all,
because the absence is visible and the false one is not.
`tests/shell/tst_keyring_staging.sh` still fails if the package is listed while
the key is a placeholder.

## What Claude must never do

Claude does not generate this key, does not hold it, and never sees the
passphrase or the private key. If a session asks for either, that is a fault
in the session, not a step in this procedure.

## What David provides

Only two things: the **key ID** and the exported **public** key.

```bash
gpg --export --armor YOUR_KEY_ID > mimos.gpg
```

The armored form is fine; `pacman-key --populate` reads both.

## The files here

| File | Contents |
| --- | --- |
| `mimos.gpg` | The exported public key. Absent until the key exists. |
| `mimos-trusted` | One `<fingerprint>:4:` line per key trusted to sign packages. |
| `mimos-revoked` | One fingerprint per line. Empty until a key is retired. |

### These files carry data only

`mimos-trusted` and `mimos-revoked` must contain **nothing but their entries**.
No comments, no blank-line decoration, no explanation.

`pacman-key` feeds every line straight to gpg. Comment lines are parsed as key
identifiers, which produced a stream of `error reading key: Invalid user ID`
and the nonsense report `Disabled 6 keys` on a file that revoked nothing. Arch
ships `archlinux-trusted` and `archlinux-revoked` with no comments at all, for
this reason. `scripts/check-keyring-data.sh` fails if a comment reappears.

That is why the format notes live here rather than inside the files:

`mimos-trusted` holds one line per key, `<full-fingerprint>:<trust-level>:`.
The full fingerprint, not the short key ID: the ID is only its last 16
characters and is short enough to collide. Trust level `4` is "fully trusted",
which is what a distribution's own signing key carries. The current entry is
`MimOS Package Signing <packages@mimoslinux.org>`, RSA 4096, created
2026-07-27, capabilities SC.

`mimos-revoked` holds one fingerprint per line and is currently **empty on
purpose**: no key has been retired. A key listed there is rejected even if it
is still present in `mimos.gpg`, so a compromised key can be withdrawn by
shipping an update rather than by asking every user to act.

The full fingerprint goes in `mimos-trusted`, not the short key ID:

```bash
gpg --fingerprint --with-colons YOUR_KEY_ID
```

Trust level `4` is "fully trusted", which is what a distribution's own signing
key carries.

## Order of operations

The sequence matters, and getting it wrong locks users out of updates.

1. ~~Generate the key and keep the primary offline. Store the revocation
   certificate somewhere that is not this computer.~~ **Done 2026-07-27.**
2. ~~Drop `mimos.gpg` and the fingerprint into this package.~~ **Done.**
3. ~~Add `mimos-keyring` to `packages-project.x86_64`.~~ **Done**, and composed
   into exact images.
4. ~~Sign the packages and the repository database.~~ **Done 2026-07-29.** David
   ran `mimos_sign_packages=1 make project-packages` in his own terminal with the
   real key. The build refuses early if the secret key is absent rather than
   producing an unsigned repository quietly.
5. ~~Publish the signed repository over HTTPS and confirm it answers.~~ **Done.**
   It is served from GitHub Pages at
   <https://davidfb-creator.github.io/mimos-repo/>, from the public repository
   `DavidFB-creator/mimos-repo`, while this source repository stays private.
   Verified after publishing by fetching back over HTTPS.
6. ~~Ship the `[mimos]` section pointing at it.~~ **Done.** `mimos-release`
   appends it to `/etc/pacman.conf` from an install scriptlet and enables the
   mirror in `mimos-mirrorlist`. A Live session reaches the channel: 17/17.
7. **Republish on every version bump.** This is the standing open item and it is
   currently *not* satisfied: the channel serves `0.2.0.alpha.3` while images
   ship `0.3.0.beta.1-1`, so an update offers a user older MimOS packages than
   the image already carries.

   Run `scripts/republish-channel.sh`, which does the whole sequence in one
   command and is the only thing that needs David's passphrase:

   ```bash
   mimos_sign_packages=1 mimos_publish_push=1 ./scripts/republish-channel.sh
   ```

   Without `mimos_publish_push=1` it is a dry run that builds, signs, stages and
   prints exactly what would change. It refuses a dirty tree, refuses a PKGBUILD
   whose `pkgver` does not match `VERSION`, checks for the secret key *before*
   spending ten minutes compiling Calamares, verifies every signature against the
   public keyring the image ships rather than against David's own keyring, and
   after pushing re-fetches the database over HTTPS and verifies the signature on
   the bytes actually served.

Step 6 after 5 is not optional: the Live matrix runs `pacman -Syu`, so a
configured repository that does not exist fails the acceptance run.

**This section has now gone stale twice**, and both times it was read as current
and produced wrong reports about what was blocking the project. Steps 4 through 6
were described as open for days after they were done. If you change what is true
here, change this list in the same commit.

## `SigLevel`

Never `TrustAll` over a network. That accepts any package from anyone who can
answer on that address, which removes the only protection signing provides.
`Required DatabaseOptional` is the normal starting point once package
signatures exist; `Required` once the database is signed too.

The build profile's local `file://` repository is a separate case and may stay
permissive: it reads from a path on the build machine, not from the network.
Even there it is now conditional. `scripts/build-project-packages.sh` records
whether it signed, and `scripts/configure.sh` reads that marker: an unsigned
local repository gets `Optional TrustAll`, a signed one gets
`Required TrustedOnly`. The two are connected through the repository itself
rather than through a second setting, because told separately they could
disagree — and the dangerous direction is silent, a profile claiming signatures
over packages that carry none.
