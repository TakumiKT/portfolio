// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "tag_autocomplete"

const getLoadingEl = () => document.getElementById("global-loading");

const showLoading = () => {
  const el = getLoadingEl();
  if (!el) return;
  el.classList.add("is-active");
  el.setAttribute("aria-hidden", "false");
};

const hideLoading = () => {
  const el = getLoadingEl();
  if (!el) return;
  el.classList.remove("is-active");
  el.setAttribute("aria-hidden", "true");
};

document.addEventListener("turbo:visit", showLoading);
document.addEventListener("turbo:submit-start", showLoading);
document.addEventListener("turbo:load", hideLoading);
document.addEventListener("turbo:submit-end", hideLoading);
window.addEventListener("pageshow", hideLoading);

// デバッグ（確認後は消してOK）
document.addEventListener("turbo:visit", () => console.log("turbo:visit"));
document.addEventListener("turbo:submit-start", () => console.log("turbo:submit-start"));
document.addEventListener("turbo:load", () => console.log("turbo:load"));
console.log("application.js loaded");