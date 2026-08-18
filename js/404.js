// js/404.js
// -----------------------------------------------------------------------
// Behavior for the Clique Studios 404 / catch-all page:
//   1. On load, logs a "pageview" event — which path was requested and
//      what URL (if any) referred the visitor here. This is how you spot
//      a dead link somewhere still sending people to a page that no
//      longer exists.
//   2. On button click, logs a "button_click" event and gives the
//      visitor visible feedback that their click landed.
//
// Logging is inert until js/config.js has real Supabase credentials —
// see the comment block in that file. Nothing here breaks the page if
// it isn't configured yet.
// -----------------------------------------------------------------------
(function () {
  "use strict";

  var config = window.CLIQUE_404_CONFIG || {};
  var isConfigured = Boolean(config.supabaseUrl && config.supabaseAnonKey);

  function buildPayload(eventType) {
    return {
      event_type: eventType,
      path: window.location.pathname + window.location.search,
      referrer: document.referrer || "direct-or-unknown",
      user_agent: navigator.userAgent,
      occurred_at: new Date().toISOString()
    };
  }

  function logEvent(eventType) {
    var payload = buildPayload(eventType);

    if (!isConfigured) {
      console.log("[Clique 404 tracker — Supabase not connected yet] would log:", payload);
      return;
    }

    fetch(config.supabaseUrl + "/rest/v1/" + config.table, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: config.supabaseAnonKey,
        Authorization: "Bearer " + config.supabaseAnonKey,
        Prefer: "return=minimal"
      },
      body: JSON.stringify(payload)
    }).catch(function (err) {
      // A logging failure should never break the page for the visitor.
      console.warn("Clique 404 tracker: log failed", err);
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    logEvent("pageview");

    var yearEl = document.getElementById("year");
    if (yearEl) {
      yearEl.textContent = String(new Date().getFullYear());
    }

    var button = document.querySelector(".error-page__button");
    if (!button) return;

    button.addEventListener("click", function () {
      logEvent("button_click");

      button.textContent = "Got it — we'll go fix that.";
      button.setAttribute("disabled", "disabled");
      button.classList.add("error-page__button--clicked");
    });
  });
})();
