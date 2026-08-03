# MimOS package sources

Build recipes, patches and configuration for every package served by the
MimOS update channel at
<https://davidfb-creator.github.io/mimos-repo/x86_64/>.

This repository exists first for licence compliance: the channel distributes
binaries of **Calamares**, which is GPL-3.0-or-later, built from the reviewed
recipe and patches in [`packages/calamares/`](packages/calamares/). This tree
is the complete corresponding source for those binaries — the pinned upstream
release archive is fetched from Calamares' own signed release, and everything
MimOS changes is here as numbered patches. The remaining `mimos-*` packages
and `ttf-baloo2` are MIT-licensed MimOS work (see [`LICENSE`](LICENSE)) or
build a commit-pinned upstream font, and are published alongside for
completeness.

## Correspondence

Each release tag in this repository is a snapshot of the `packages/` tree at
the exact commit of the private source repository from which the published
channel packages were built:

| tag | source commit | channel serves |
| --- | --- | --- |
| `v0.3.0-beta.4` | `9f8b5fb` | `*-0.3.0.beta.4` |

When the channel is republished, a new tag lands here in the same change.

## Building

On Arch Linux, in any package directory:

```bash
makepkg -srci
```

`packages/calamares/PKGBUILD` verifies the upstream archive against its
detached signature and the pinned maintainer key before applying anything.

## MimOS

MimOS is *una distribución Linux basada en Arch* by XI14 (David Fontanet
Bujaldón and Jan Arrillaga Ferrer). Website: <https://mimoslinux.org> ·
Contact: <support@mimoslinux.org>
