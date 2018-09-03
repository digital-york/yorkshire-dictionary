/* Google analytics setup, compatible with Turbolinks.Setup from here:
	https://www.mskog.com/posts/google-analytics-gtag-with-rails-5-and-turbolinks/
*/

if (!window.location.href.match(/http:\/\/localhost.*/)) {
  /* Standard Google Analytics setup: */
  window.dataLayer = window.dataLayer || [];
  function gtag() {
    dataLayer.push(arguments);
  }
  gtag("js", new Date());
  gtag("config", "UA-21938253-17");
  
  /* Turbolinks specific: */
  document.addEventListener("turbolinks:load", event => {
    if (typeof gtag === "function") {
      gtag("config", "UA-21938253-17", {
        page_location: event.data.url
      });
    }
  });
}

