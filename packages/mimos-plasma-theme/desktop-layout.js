// The MimOS desktop layout.
//
// Plasma builds a new user's desktop from this script the first time they log
// in, taking it from whichever Look-and-Feel is active. MimOS shipped no
// layout at all until now, so it inherited Plasma's, and a laptop's battery
// sat hidden behind the tray's arrow with no percentage on it -- which is the
// one thing a person on battery looks for.
//
// It is safe for this to exist. `plasma-apply-lookandfeel --resetLayout` is a
// separate, opt-in flag, and the Centro's one-click theme switch does not
// pass it -- measured, because the alternative would be that every switch
// between Claro and Oscuro rebuilt the panel and threw away whatever the user
// had arranged. See ADR-107.

// Everything Plasma's own default gives, unchanged: this is the standard
// panel, not a MimOS reinvention of one. Breeze's layout does exactly the
// same thing in its first line.
loadTemplate("org.kde.plasma.desktop.defaultPanel")

var escritorios = desktopsForActivity(currentActivity());
for (var d = 0; d < escritorios.length; d++) {
    escritorios[d].wallpaperPlugin = 'org.kde.image';
}

// --- what a new MimOS starts with -------------------------------------
//
// Four applications, in David's order, in the task bar: the browser, the file
// manager, the terminal, the settings. They are what somebody opens on a
// computer they have just installed, and hunting for them in a menu is a poor
// first ten minutes.
//
// The names are the real desktop-entry file names, read off a running MimOS
// rather than guessed. Getting one wrong is silent: Plasma drops the entry
// and the icon simply is not there, with nothing logged. `ghostty` in
// particular installs as com.mitchellh.ghostty, and `systemsettings` ships
// alongside a `kdesystemsettings` alias.
var mimosBarra = [
    "applications:firefox.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:com.mitchellh.ghostty.desktop",
    "applications:systemsettings.desktop"
].join(",");

// The menu carries one more: Centro de MimOS. It belongs in the favourites
// and not in the task bar, because it is the thing a person opens once or
// twice in their first week and then rarely -- the bar is for what you use
// every day, the menu for what you should be able to find.
var mimosFavoritos = mimosBarra + ",applications:mimos-welcome.desktop";

for (var f = 0; f < panelIds.length; f++) {
    var barra = panelById(panelIds[f]);

    // Flat against the edge rather than floating, which is David's own
    // setting: a floating bar looks lighter in a screenshot and costs
    // legibility every day, because its icons then sit on whatever the
    // wallpaper happens to be underneath.
    //
    // `floating` is a first-class property of the panel object, and it is
    // set here rather than written as a config key because that is what
    // works -- proved by flipping it to true and back on a live panel.
    //
    // Opacity is deliberately NOT set. `opacity` reads as a property but
    // refuses every value written to it -- translucent, adaptive, numeric,
    // all silently ignored, leaving "opaque" behind. A line assigning it
    // would look correct and do nothing, which is the failure this project
    // keeps meeting. It is not needed either: a panel built by
    // loadTemplate comes out opaque already, measured on the one this
    // layout's own template produced. If a future Plasma changes that, the
    // installed audit is where it should be caught.
    barra.floating = false;

    for (var g = 0; g < barra.widgetIds.length; g++) {
        var elemento = barra.widgetById(barra.widgetIds[g]);
        // icontasks is the task bar MimOS actually carries, and kickoff the
        // menu -- both confirmed on a running session, because the same panel
        // could equally hold taskmanager or kicker and neither reads these
        // keys.
        if (elemento.type === "org.kde.plasma.icontasks") {
            elemento.currentConfigGroup = ["General"];
            elemento.writeConfig("launchers", mimosBarra);
        } else if (elemento.type === "org.kde.plasma.kickoff") {
            elemento.currentConfigGroup = ["General"];
            // Both keys, and the order matters less than the pairing.
            // Kickoff migrates its favourites into the KActivities database
            // and then ignores this list forever, recording that it has done
            // so. On a first login the flag is absent and the migration
            // reads exactly this key -- measured on David's laptop by
            // reproducing that state: with the flag left alone the list was
            // silently ignored, and with it cleared the four applications
            // appeared and the flag flipped back to true by itself, which is
            // the migration having run on our list.
            elemento.writeConfig("favoritesPortedToKAstats", false);
            elemento.writeConfig("favorites", mimosFavoritos);
        }
    }
}

// --- the battery ------------------------------------------------------
//
// Out of the tray's hidden area and onto the panel, where a laptop's most
// looked-at indicator belongs. `shownItems` is a plain key on the system-tray
// widget, which exists while this script runs, so it lands.
//
// **The percentage is not set here, and that is the finding.** It lives in
// the battery *applet's* own configuration, under a group named after that
// applet's numeric id -- and when this script runs, the tray has not created
// its applets yet. Measured through the real mechanism on David's laptop
// (Preferencias → Tema global, which applies with --resetLayout): this
// `shownItems` landed, the tray's applet ids came out as 596-600, created
// after the ids this loop had seen, and a `showPercentage` written from here
// went nowhere at all -- the discovery loop iterated over an empty list and
// found nothing, silently. The percentage is now set from
// `mimos-preparar-bateria`, once, after the session is up. See ADR-110.
//
// One thing worth keeping about the tray, learned the hard way: its inner
// containment is NOT reachable. `SystrayContainmentId` reads empty and
// neither panelById nor desktopById finds it. Arbitrary nested config paths
// on the tray widget itself do work, which is what the helper uses.
for (var i = 0; i < panelIds.length; i++) {
    var panel = panelById(panelIds[i]);
    for (var j = 0; j < panel.widgetIds.length; j++) {
        var tray = panel.widgetById(panel.widgetIds[j]);
        if (tray.type !== "org.kde.plasma.systemtray") {
            continue;
        }
        tray.currentConfigGroup = ["General"];
        tray.writeConfig("shownItems", "org.kde.plasma.battery");
        tray.reloadConfig();
    }
}
