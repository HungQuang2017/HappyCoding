$(document).ready(function () {
    //$(".nav.navbar-nav li a.homeIconli").attr("href", _spPageContextInfo.siteAbsoluteUrl);
    var searchPageURL = (_spPageContextInfo.webAbsoluteUrl + "/_layouts/15/osssearchresults.aspx").toLowerCase();
    var currentLocationURL = window.location.href.toLowerCase();
    if (currentLocationURL.startsWith(searchPageURL)) {
        console.log("Add Css to Search page");
        $("div#main").addClass("pa_apps_search_osssearchresults_page");
    }
});