(() => {
  const storageKey = "clarity-consent";
  let choice = null;
  let loaded = false;
  let storageAvailable = true;

  try {
    choice = localStorage.getItem(storageKey);
    if (choice === "granted") localStorage.setItem(storageKey, choice);
  } catch (error) {
    choice = null;
    storageAvailable = false;
    console.warn("Clarity consent storage is unavailable.", error);
  }

  const container = document.createElement("section");
  container.className = "clarity-consent";
  container.setAttribute("aria-label", "Session recording preferences");
  container.innerHTML = `
    <button type="button" class="btn btn-outline-secondary" aria-expanded="false"
      aria-controls="clarity-consent-options">Session recording settings</button>
    <div id="clarity-consent-options" hidden>
      <p class="mt-3 mb-2">
        Allow Microsoft Clarity to record how you use this site?
        This optional analytics service uses cookies and session recordings.
        You can decline or change your choice here at any time.
        <a href="https://privacy.microsoft.com/privacystatement">Microsoft privacy statement</a>.
      </p>
      <div class="d-flex flex-wrap gap-2">
        <button type="button" class="btn btn-outline-secondary" data-consent="denied">Decline</button>
        <button type="button" class="btn btn-outline-secondary" data-consent="granted">Allow Clarity</button>
      </div>
    </div>
    <p class="small mt-2 mb-0" role="status"></p>
  `;
  const footer = document.querySelector("#tail-wrapper") || document.body;
  footer.appendChild(container);

  const settings = container.querySelector("[aria-controls]");
  const options = container.querySelector("#clarity-consent-options");
  const status = container.querySelector('[role="status"]');

  function showOptions(show) {
    options.hidden = !show;
    settings.setAttribute("aria-expanded", String(show));
  }

  function updateStatus() {
    status.textContent = choice === "granted"
      ? "Clarity session recording is allowed."
      : "Clarity session recording is off.";
    if (!storageAvailable) {
      status.textContent += " Your preference cannot be saved in this browser.";
    }
  }

  function loadClarity() {
    if (loaded) return;
    loaded = true;
    window.clarity = window.clarity || function () {
      (window.clarity.q = window.clarity.q || []).push(arguments);
    };
    window.clarity("consentv2", {
      ad_Storage: "denied",
      analytics_Storage: "granted"
    });
    const script = document.createElement("script");
    script.async = true;
    script.src = "https://www.clarity.ms/tag/xgulnyulhd";
    script.addEventListener("error", () => {
      console.error("Clarity could not be loaded.");
      status.textContent = "Clarity could not be loaded. It may be blocked by your browser.";
    });
    document.head.appendChild(script);
  }

  settings.addEventListener("click", () => showOptions(options.hidden));
  container.querySelectorAll("[data-consent]").forEach((button) => {
    button.addEventListener("click", () => {
      choice = button.dataset.consent;
      try {
        localStorage.setItem(storageKey, choice);
        storageAvailable = true;
      } catch (error) {
        storageAvailable = false;
        if (choice === "granted") choice = "denied";
        console.warn("Clarity consent could not be saved.", error);
      }
      updateStatus();
      showOptions(false);
      settings.focus();

      if (choice === "granted") {
        loadClarity();
      } else if (loaded) {
        window.clarity("consentv2", {
          ad_Storage: "denied",
          analytics_Storage: "denied"
        });
        window.location.reload();
      }
    });
  });

  window.addEventListener("storage", (event) => {
    if (event.key !== storageKey && event.key !== null) return;
    window.location.reload();
  });

  showOptions(choice !== "granted" && choice !== "denied");
  updateStatus();
  if (choice === "granted") loadClarity();
})();
