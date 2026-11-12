// Managed by mac-setup (symlinked into every Firefox profile by ./setup.sh --only firefox).
// Firefox reads this file at startup and never writes to it; these values win over
// about:config, so change them here. Restart Firefox to apply.

// --- Memory ---------------------------------------------------------------------
// Unload tabs that have not been used for a while when the system runs low on memory
// (they reload on click). about:unloads shows the order and unloads on demand.
user_pref("browser.tabs.unloadOnLowMemory", true);
// One content process per site instead of up to four: tabs of the same site share it
user_pref("dom.ipc.processCount.webIsolated", 1);
// After a restart, load a tab (pinned ones included) only when it is selected
user_pref("browser.sessionstore.restore_on_demand", true);
user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", true);
// On-device AI (chatbot sidebar, link previews, smart tab groups) loads models into memory
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false);

// --- Privacy (also less work per page: blocked trackers are scripts that never run) -
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.globalprivacycontrol.enabled", true);
// New tab page without sponsored tiles and recommended stories
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
// Address bar without sponsored suggestions
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
