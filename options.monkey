// ==UserScript==
// @name       Nemexia options
// @namespace  http://github.com/dziulius
// @version    0.2.0
// @description  enter something useful
// @match      http*://*.nemexia.com/options*
// @copyright  2012+, You
// @updateURL https://raw.githubusercontent.com/dziulius/nemexia_scripts/master/options.monkey
// ==/UserScript==


unsafeWindow.attackAll = function() {
    var baseStart = "type=SendFleet&ship[1][2]=20&mission=3&speed=10&metal=0&crystal=0&gas=0&scrap=0&";
    var baseEnd = "&battle_rounds=12&speed_motivation=0&scrap_motivation=0&flight_hours=0&flight_minutes=5";

    $('.messageBody a').each(function(i, e) {
        setTimeout(function() {
            var cords = e.getAttribute("href").match(/c\d=(\d+)/g);
            if (cords && cords.length == 3) {
                $.post("ajax_fleets.php", baseStart + cords.join("&") + baseEnd).always(function(data) {
                    try {
                        showDialogMessage(JSON.parse(data).info);

                    } catch (e) {
                        showDialogMessage(data);
                    }
                });
            }
        }, i * 1000);
    });
}


unsafeWindow.pirateAll = function() {
    var baseStart = "type=SendFleet&ship[1][3]=20&mission=7&speed=10&metal=0&crystal=0&gas=0&scrap=0&";
    var baseEnd = "&battle_rounds=12&speed_motivation=0&scrap_motivation=0&flight_hours=0&flight_minutes=5";

    $('.messageBody a').each(function(i, e) {
        setTimeout(function() {
            var cords = e.getAttribute("href").match(/c\d=(\d+)/g);
            if (cords && cords.length == 3) {
                $.post("ajax_fleets.php", baseStart + cords.join("&") + baseEnd).always(function(data) {
                    try {
                        showDialogMessage(JSON.parse(data).info);

                    } catch (e) {
                        showDialogMessage(data);
                    }
                });
            }
        }, i * 1000);
    });
}
$('body').prepend("<div style='position: fixed; z-index: 10000; width: 100px;'> \
        <div style='color: white; border: 2px solid green; background: black; position: absolute; top: 0px; left: 0px; padding: 5px;'><button onclick='attackAll()'>Attack All</button></div>\
        <div style='color: white; border: 2px solid green; background: black; position: absolute; top: 30px; left: 0px; padding: 5px;'><button onclick='pirateAll()'>Pirate All</button></div>\
    </div>")
