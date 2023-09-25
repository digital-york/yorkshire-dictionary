$(document).on("turbolinks:load", function() {
	$("#sort").change(function(e) {
		sort = $('#sort').val();
		oldUrl = window.location.href;
		if (/[?&]page\s*=/.test(oldUrl)) {
			// Remove page param
			oldUrl = oldUrl.replace(/(?:([?&])page\s*=[^?&]*)/, "");
		}
		if (/[?&]sort\s*=/.test(oldUrl)) {
			// Replace existing sort
			newUrl = oldUrl.replace(/(?:([?&])sort\s*=[^?&]*)/, "$1sort=" + sort);
		} else if (/\?/.test(oldUrl)) {
			// Add sort to existing query params
			newUrl = oldUrl + "&sort=" + sort;
		} else {
			// Add sort as only query param
			newUrl = oldUrl + "?sort=" + sort;
		}
		window.location.replace(newUrl);
	});
})

