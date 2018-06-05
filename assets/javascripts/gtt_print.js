$(function() {
  if ($('form.print_box').length > 0) {
    var server = $('form.print_box').attr('action').replace(/\/?$/, '/');

    $.getJSON(server + "print/apps.json", function (data) {
      $.each(data, function(key, value) {
        // "default" profile does not really work for some reason
        if (value != "default") {
          var option = $("<option></option>").attr("value",value).text(value);
          $('form.print_box select').append(option);
        }
      });
    });
  }

  $(document).on('click', '.print_box input[type=button]', function (e) {

    var appId = $('form.print_box select').val();

    $.ajax({
      type: 'GET',
      url: server + "print/" + appId + "/exampleRequest.json",
      dataType: 'json',
      success: function (data) {
        requestPrint(appId, JSON.parse(data.requestData));
      }
    });

    return false;
  });

  var requestPrint = function (id, requestData) {

    // Defaults
    var format = "pdf";
    var layout = 0;

    var paramObj = {};
    $.each($('#issue-form').serializeArray(), function(_, kv) {
      paramObj[kv.name] = kv.value;
    });

    // Apply geo data if exists
    if (requestData.attributes.map.layers[0].geoJson && paramObj["issue[geojson]"]) {
      var feature = (new ol.format.GeoJSON()).readFeature(
        JSON.parse(paramObj["issue[geojson]"])
      );
      feature.set('subject', paramObj["issue[subject]"]);
      feature.getGeometry().transform('EPSG:4326','EPSG:3857');

      requestData.attributes.map.layers[0].geoJson = JSON.parse((new ol.format.GeoJSON()).writeFeatures([feature]));
      requestData.attributes.map.center = ol.extent.getCenter(feature.getGeometry().getExtent());
    }

    // Apply template variables
    requestData.attributes.title = paramObj["issue[subject]"];

    console.log(requestData);
    var startTime = new Date().getTime();

    $.ajax({
      type: 'POST',
      url: server + "print/" + id + "/report." + format,
      data: {
        spec: JSON.stringify(requestData)
      },
      success: function (response) {
        downloadWhenReady(startTime, response.ref);
      },
      error: function (data) {
        console.log(data);
      }
    });
  };

  function downloadWhenReady(startTime, reference) {
    if ((new Date().getTime() - startTime) > 30000) {
      console.log('Gave up waiting after 30 seconds');
    }
    else {
      setTimeout(function () {
        $.ajax({
          type: 'GET',
          url: server + "print/status/" + reference+ ".json",
          dataType: 'json',
          success: function (response) {
            if (!response.done) {
              downloadWhenReady(startTime, reference);
            } else {
              window.location = server + "print/report/" + reference;
            }
          },
          error: function (data) {
            console.log('Error occurred requesting status');
          }
        });
      }, 500);
    }
  }
});
