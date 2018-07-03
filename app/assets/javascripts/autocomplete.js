/* exported deleteAutocompleteSelection, setupAutocomplete */

// Code for adding the selected results to a div of selected terms
function addAutocompleteSelectionToDiv(id, name, model, resultsDiv) {
  // Create a data string to identify each results
  const dataString = `data-${model}=${id}`;

  // Create a div with the item and data string
  const div = `
    <div ${dataString} class="ac_selected">
      <input name=${model}[] type="text" value=${id} readonly hidden>
      <span class="badge badge-info">
        ${name}
        <span class="delete_ac_selection" onclick="deleteAutocompleteSelection(this)">𝗫</span>
      </span>
    </div>
  `;

  // Create a selector for a div with the same data string inside the current results div
  const existingDivSelector = `${resultsDiv} > [${dataString}]`;

  // Add the term to the results div if it's not already in there
  if ($(existingDivSelector).length === 0) {
    $(resultsDiv).append(div);
  }
}

// Delete the nearest .ac_selected div
function deleteAutocompleteSelection(element) {
  $(element).closest('.ac_selected').remove();
}

function setupAutocomplete(acData) {
  const fieldExists = $(acData.autocompleteFieldSelector).length;

  if (!fieldExists) {
    return;
  }

  // Get the IDs for the current query
  const urlParams = new URLSearchParams(window.location.search);
  const existingIds = urlParams.getAll(`${acData.acIdentifier}[]`).map(Number);

  if (existingIds && existingIds.length) {
    (function setup(data) {
      // Retrieve the records for the IDs
      $.getJSON({
        url: data.idQueryUrl,
        type: 'get',
        data: {
          ids: existingIds,
        },
      }).done(
        (results) => {
          // Loop through the matching records and create a html element for each
          for (let i = 0; i < results.length; i += 1) {
            const current = results[i];
            addAutocompleteSelectionToDiv(
              current.id,
              current[data.displayNameModelField],
              data.acIdentifier,
              data.selectedValuesDivSelector,
            );
          }
        },
      );
    }(acData));
  }

  // Don't navigate away from the field on tab when selecting an item
  $(acData.autocompleteFieldSelector)
    .on('keydown', function autocompleteKeypress(event) {
      if (event.keyCode === $.ui.keyCode.TAB
        && $(this).autocomplete('instance').menu.active) {
        event.preventDefault();
      }
    });

  // Set up autocomplete
  $(acData.autocompleteFieldSelector)
    .autocomplete({
      minLength: 1,
      source(request, response) {
        // Get results from API
        $.getJSON(acData.termQueryUrl, request,
          /* eslint-disable no-unused-vars */
          (data, status, xhr) => {
            response(data.slice(0, 10));
          });
      },
      focus() {
        // prevent value inserted on focus
        return false;
      },
      select(event, ui) {
        // Get selected ID, add HTML element for selected item
        const { id, url } = ui.item;
        if (acData.multi) {
          addAutocompleteSelectionToDiv(
            id,
            ui.item[acData.displayNameModelField],
            acData.acIdentifier,
            acData.selectedValuesDivSelector,
          );
        } else if (Turbolinks) {
          Turbolinks.visit(url);
        } else {
          window.location = url;
        }

        // Clear text box on selection
        $(event.target).val('');
        return false;
      },
    });

  $(acData.autocompleteFieldSelector)
    .focus(function onAutocompleteFocus() {
      // Show results on focus
      $(this).autocomplete('search');
    });

  // Define how to draw search results
  // eslint-disable-next-line no-underscore-dangle
  $(acData.autocompleteFieldSelector)
    .autocomplete('instance')._renderItem = function drawSearchResult(ul, item) {
      return $('<li>')
        .append(`<div> ${item[acData.displayNameModelField]} </div>`)
        .appendTo(ul);
    };
}

// Explicitly add two public methods to context (to avoid linter warning)
this.setupAutocomplete = setupAutocomplete;
this.deleteAutocompleteSelection = deleteAutocompleteSelection;
