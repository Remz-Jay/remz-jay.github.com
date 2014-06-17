# Instantiate a new search when dom is ready.
$(document).ready ->
    new LunrSearch '#search-query',
                    indexUrl: "/search.json",
                    results: "#search-results",
                    entries: ".entries",
                    template: "#search-results-template"
