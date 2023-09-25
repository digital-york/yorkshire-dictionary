/* This JS sets up the slider in the search box */
function createSlider() {
	function setDateRangeHiddenFields(startYear, endYear) {
		$('#start_year').val(startYear);
		$('#end_year').val(endYear);
	}

	function setDateRangeSelectedValueText(startYear, endYear) {
		$('#selected_date_range').text(`${startYear} - ${endYear}`);
	}

	function setDateRange(startYear, endYear) {
		setDateRangeSelectedValueText(startYear, endYear);
		setDateRangeHiddenFields(startYear, endYear);
	}

	function getInitialDateRange() {
		const minYear = 1000;
		const maxYear = 2020;

		const params = new URLSearchParams(window.location.search);

		const start = params.get('start_year');
		const end = params.get('end_year');

		const values = [minYear, maxYear];

		if (start) {
			values[0] = start;
		}
		if (end) {
			values[1] = end;
		}
		return values;
	}

	const values = getInitialDateRange();

	$('#search_dates').slider({
		range: true,

		// TODO: replace following dates with actual min and max years
		min: 1000,
		max: 2020,

		values,

		slide(event, ui) {
			setDateRange(ui.values[0], ui.values[1]);
		},
	});

	const sliderStart = $('#search_dates').slider('values', 0);
	const sliderEnd = $('#search_dates').slider('values', 1);
	setDateRangeSelectedValueText(sliderStart, sliderEnd);
}

$(document).on('turbolinks:load', createSlider);
