#!/usr/bin/env python3
"""Refuse an accessible name that assistive technology would read in English.

Run from prepare(), after the patches are applied, against the real upstream
source tree. It cannot live in `make check`: the Qt translation catalogue is in
the upstream tarball, and downloading that on every push would blow the CI
budget. Build time is also the right time -- this fails the package rather than
producing one that misannounces.

The defect this exists for shipped, and four separate measurements missed it. An
earlier version of 0002-users-accessible-names.patch invented new source strings
for the credential fields. Qt resolves translations per context, and a brand-new
source string has no translation in any of the catalogues Calamares ships, so a
Spanish system announced "Full name", "Login name", "Computer name" and "Repeat
password" in English. Only "Password" was right, and only because it happened to
exist already.

Nothing caught it:

  * the nameless-node count was zero, correctly -- the names existed;
  * the unnamed-node count was zero, correctly;
  * a person listened and confirmed the fields announce their names, correctly;
  * the strings were present in the built binary, correctly.

Every one of those was true and none of them asked what language came out. This
checker asks exactly that, and nothing else.
"""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ElementTree
from pathlib import Path

# The two administrator fields keep English names on purpose. No suitable short
# label exists translated in this context, and reusing the user fields' names
# would put two identically named password fields on one page, which is worse for
# a screen reader than an untranslated one. MimOS hides both fields, so nothing
# here is reachable by its users. Remove an entry only together with a real
# translated string -- never to make this checker quiet.
ACCEPTED_UNTRANSLATED = {
    "Administrator password",
    "Repeat administrator password",
}

# Spanish is what MimOS ships and what its acceptance runs measure. Checking one
# catalogue is enough to catch an invented source string, because an invented
# string is untranslated in all of them.
CATALOGUE = Path("lang/calamares_es.ts")
UI = Path("src/modules/users/page_usersetup.ui")
CONTEXT = "Page_UserSetup"

ACCESSIBLE_NAME = re.compile(
    r'<property name="accessibleName">\s*<string>(.*?)</string>', re.S)


def fail(message: str) -> int:
    print(f"error: {message}", file=sys.stderr)
    return 1


def main() -> int:
    for path in (CATALOGUE, UI):
        if not path.is_file():
            return fail(f"{path} not found; run this from the source root.")

    names = ACCESSIBLE_NAME.findall(UI.read_text(encoding="utf-8"))
    if not names:
        # A silent pass here would mean the naming patch stopped applying, which
        # is precisely how it once shipped as a no-op.
        return fail(
            f"{UI} declares no accessibleName at all. The naming patch did not "
            "apply.")

    root = ElementTree.parse(CATALOGUE).getroot()
    context = next(
        (c for c in root.findall("context") if c.findtext("name") == CONTEXT),
        None)
    if context is None:
        return fail(f"{CATALOGUE} has no {CONTEXT} context.")

    translated: dict[str, str] = {}
    for message in context.findall("message"):
        source = message.findtext("source")
        node = message.find("translation")
        if source is None or node is None:
            continue
        text = (node.text or "").strip()
        # An "unfinished" entry carries no usable translation even when it has
        # text, and Qt falls back to the source string for it.
        if text and node.get("type") != "unfinished":
            translated[source] = text

    untranslated = []
    for name in names:
        if name in translated:
            print(f"  ok        {name!r} -> {translated[name]!r}")
        elif name in ACCEPTED_UNTRANSLATED:
            print(f"  accepted  {name!r} is deliberately untranslated")
        else:
            print(f"  ENGLISH   {name!r}")
            untranslated.append(name)

    if untranslated:
        print(file=sys.stderr)
        return fail(
            "these accessible names have no translation in the "
            f"{CONTEXT} context, so a screen reader reads them in English: "
            + ", ".join(repr(n) for n in untranslated)
            + ".\nReuse a source string that is already translated in this "
            "context rather than inventing one -- Qt resolves translations per "
            "context, so reusing fixes every language at once.")

    accepted = sum(1 for n in names if n in ACCEPTED_UNTRANSLATED)
    print(
        f"Calamares accessible names: {len(names) - accepted}/{len(names)} "
        f"translated, {accepted} deliberately untranslated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
