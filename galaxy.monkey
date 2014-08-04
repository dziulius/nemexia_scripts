// ==UserScript==
// @name       Galaxy 2.0
// @namespace  http://github.com/dziulius
// @version    0.2.1
// @description  stuff
// @match      http://*.nemexia.com/galaxy*
// @copyright  2012+, You
// @updateURL https://raw.githubusercontent.com/dziulius/nemexia_scripts/master/galaxy.monkey
// ==/UserScript==

unsafeWindow.FLEETS_SPEED = unsafeWindow.FLEETS_SPEED || 1

unsafeWindow.getInfo = function(cordinates, callback) {
    $.post("ajax_info.php", {
        type: 'squareInfo',
        c1: cordinates[0],
        c2: cordinates[1],
        c3: cordinates[2]
    }).always(callback);
}

unsafeWindow.scanSystem = function(galaxy, solar_from, solar_to, selector, planetInterval, action) {
    $.post("ajax_galaxy.php", {
        galaxy: galaxy,
        solar: solar_from,
        planets: 0,
        page: 0
    }).always(function(data) {
        var info = eval('(' + data + ')');
        $('#galaxyHolder').html(info.response);
        $('#breadCrumb-c1').html(LangString.Galaxy + ' ' + galaxy);
        $('#breadCrumb-c2').html(LangString.SolarSytem + ' ' + solar_from);
        $('#breadCrumb-c2').val(solar_from);

        var item_amount = $(selector).length;
        if (item_amount) {
            $(selector).parent().each(function(i, e) {
                (function(index, element, scan_next_system) {
                    setTimeout(function() {
                        var cordinates = e.getAttribute("onmouseover").match(/\d+/g);
                        getInfo(cordinates, function(info) {
                            action(info, cordinates);
                        });
                    }, i * planetInterval);

                    if (scan_next_system && solar_from < solar_to) {
                        setTimeout(function() {
                            scanSystem(galaxy, solar_from + 1, solar_to, selector, planetInterval, action);
                        }, i * planetInterval + planetInterval);
                    }
                })(i, e, item_amount == i + 1);
            });
        } else if (solar_from < solar_to) {
            scanSystem(galaxy, solar_from + 1, solar_to, selector, planetInterval, action);
        }
    });
}


unsafeWindow.scanAll = function() {
    var inactive_only = $('#scan-inactive').prop('checked');
    var solar_from = parseInt($('#scan-from').val());
    var solar_to = parseInt($('#scan-to').val());
    var galaxy = parseInt($('#scan-galaxy').val());
    var points_from = parseInt($('#scan-points-from').val());
    var points_to = parseInt($('#scan-points-to').val());

    var selector = '.planetName:not(.vacation)';
    if (inactive_only) {
        selector = selector + '.inactive';
    }

    scanSystem(galaxy, solar_from, solar_to, selector, 1000, function(info, cordinates) {
        try {
            var points = parseInt(info.match(/Points:<\/small> ([\d|,]+)/)[1].replace(',', ''));
        } catch (e) {
            console.log(info);
        }
        if ((!points_from || points > points_from) && (!points_to || points < points_to)) {
            sendSpyToPlanet.apply(this, cordinates);
        }
    });
}

unsafeWindow.calculateTime = function(source, target, speed) {
    var sc1 = parseInt(source[0]);
    var sc2 = parseInt(source[1]);
    var sc3 = parseInt(source[2]);
    var tc1 = parseInt(target[0]);
    var tc2 = parseInt(target[1]);
    var tc3 = parseInt(target[2]);

    if (sc1 == tc1 && sc2 == tc2 && sc3 == tc3) {
        return (Math.round((20 * 60) / (speed / 10))) * FLEETS_SPEED;
    } else {
        var distance
        if (sc1 != tc1) {
            distance = Math.abs(sc1 - tc1) * 9000;
        } else if (sc2 != tc2) {
            distance = 1300 + 5 * Math.abs((sc2 - tc2) * 19);
        } else {
            distance = 1000 + Math.abs((sc3 - tc3) * 5);
        }

        return (Math.round(3500 * Math.sqrt(distance * 10 / speed)) + 10) * FLEETS_SPEED;
    }
}


unsafeWindow.prepareFleet = function(cordinates, callback) {
    $.post("ajax_fleets.php", "type=shipsCheck&ship[1][11]=1&mission=8", function(response) {
        var info = eval('(' + response + ')');

        if (info.pass == '0') {
            showDialogMessage(info.info);
            return false;
        } else {
            var sc = $("#planetSwitch big span").text().match(/\d+/g);
            callback(calculateTime(sc, cordinates, info.speed));
        }
    });


}

unsafeWindow.searchAsteroids = function() {
    var solar_from = parseInt($('#scan-from').val());
    var solar_to = parseInt($('#scan-to').val());
    var galaxy = parseInt($('#scan-galaxy').val());

    scanSystem(galaxy, solar_from, solar_to, ".planet img[src$='asteroid.png']", 2000, function(text, cordinates) {
        var nextChange = Date.parse(text.match(/Next change<\/small> (.*)</)[1]);
        var secondsPerField = parseInt(text.match(/Speed<\/small> (\d+)/)[1]) * 60;
        var untilNextChange = (nextChange - currentTime.valueOf()) / 1000;

        for (c = 0; c < cordinates.length; c++) {
            cordinates[c] = parseInt(cordinates[c])
        }

        prepareFleet(cordinates, function(flightTime) {
            if (flightTime > untilNextChange) {
                flightTime -= untilNextChange;
                cordinates[2] += 1;

                if (cordinates[2] > 24) {
                    return;
                }
            }

            while (flightTime > secondsPerField) {
                if (cordinates[2] == 24) {
                    return;
                } else {
                    cordinates[2] += 1;
                }
                flightTime -= secondsPerField;
            }

            var destination = "type=SendFleet&ship[1][11]=1&mission=8&speed=10&metal=0&crystal=0&gas=0&scrap=0&" + "c1=" + cordinates[0] + "&c2=" + cordinates[1] + "&c3=" + cordinates[2] + "&battle_rounds=12&speed_motivation=0&scrap_motivation=0&flight_hours=0&flight_minutes=5";

            $.post("ajax_fleets.php", destination).always(function(data) {
                try {
                    showDialogMessage(JSON.parse(data).info);

                } catch (e) {
                    showDialogMessage(data);
                }
            });
        });
    });
}


$('body').prepend("<div style='position: fixed; z-index: 10000; width: 300px;'> \
<div style='color: white; border: 2px solid green; background: black; position: absolute; top: 0px; left: 0px; padding: 5px;'> \
<label style='width: 70px; display: inline-block;'>inactive</label><input style='width:10px' type='checkbox' id='scan-inactive' checked='1'><br> \
<label style='width: 70px; display: inline-block;'>galaxy:</label><input style='width:50px' type='text' id='scan-galaxy' value='1'><br> \
<label style='width: 70px; display: inline-block;'>systems:</label><input style='width:50px' type='text' id='scan-from' value='1'> - <input style='width:50px' type='text' id='scan-to' value='81'><br> \
<label style='width: 70px; display: inline-block;'>points:</label><input style='width:50px' type='text' id='scan-points-from' value='1000'> - </label><input style='width:50px' type='text' id='scan-points-to' value='10000000'><br> \
<button style='margin-top: 5px; display: block' onclick='scanAll()'>Scan All</button> \
<button style='margin-top: 5px; display: block' onclick='searchAsteroids()'>Astroploatation</button> \
</div>\
</div>")
