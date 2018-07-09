$(function() {

  var capabilities = false;

  if ($('form.print_box').length > 0) {
    var server = $('form.print_box').attr('action').replace(/\/?$/, '/');
    var tracker = $('select#issue_tracker_id option:selected').text();

    $.getJSON(server + "print/apps.json", function (data) {
      $.each(data, function(key, value) {
        // "default" profile does not really work for some reason
        if (value === tracker) {
          var option = $("<option></option>").attr("value",value).text(value);
          $('form.print_box select[name=template]').append(option);
        }
      });
      $('form.print_box select[name=template]').change();
    });
  }

  var apikey = "";
  $.get('/my/api_key').done(function(data){
    apikey = $('#content > div.box > pre', $(data)).first().text();
  });

  $('form.print_box select[name=template]').on('change', function (e) {
    $.ajax({
      type: 'GET',
      url: server + "print/" + $('form.print_box select').val() + "/capabilities.json",
      dataType: 'json',
      success: function (data) {

        $.each(data.formats, function(key, value) {
          var option = $("<option></option>").attr("value",value).text(value);
          $('form.print_box select[name=format]').append(option);
          $('form.print_box select[name=format]').val("pdf");
        });

        $.each(data.layouts, function(key, value) {
          var option = $("<option></option>").attr("value",key).text(value.name);
          $('form.print_box select[name=layout]').append(option);
        });

        capabilities = data;
      }
    });
  });

  $('form.print_box input[type=button]').on('click', function (e) {
    var appId = $('form.print_box select').val();
    $.ajax({
      type: 'GET',
      url: server + "print/" + appId + "/exampleRequest.json",
      dataType: 'json',
      success: function (data) {
        var layout = $('form.print_box select[name=layout] option:selected').text();
        requestPrint(appId, capabilities, JSON.parse(data[layout]));
      }
    });
  });

  var requestPrint = function (id, config, requestData) {

    // Defaults
    var format = $('form.print_box select[name=format]').val();
    var layout = $('form.print_box select[name=layout]').val();

    $.ajax({
      type: 'GET',
      url: $('#issue-form').attr("action") + ".json",
      headers: {'X-Redmine-API-Key': apikey},
      data: {
        include: "attachments,journals"
      },
      dataType: 'json',
      success: function (data) {

        console.log(data.issue);

        // Handle each available attribute
        $.each(config.layouts[layout].attributes, function(key, obj) {

          // Apply geo data if exists
          if (obj.name === "map" && data.issue.geojson) {
            if(requestData.attributes.map.layers[0].geoJson) {
              var feature = (new ol.format.GeoJSON()).readFeature(data.issue.geojson);
              feature.set('foo','bar');
              feature.getGeometry().transform('EPSG:4326','EPSG:3857');

              requestData.attributes.map.layers[0].geoJson = JSON.parse((new ol.format.GeoJSON()).writeFeatures([feature]));
              requestData.attributes.map.center = ol.extent.getCenter(feature.getGeometry().getExtent());
            }
            return true;
          }

          switch (obj.name) {
            case 'scalebar':
              // currently nothing to do
              break;

            case 'freetext':
              requestData.attributes[obj.name] = $('form.print_box textarea').val();
              break;

            case 'is_private':
              if (data.issue[obj.name] === true) {
                requestData.attributes[obj.name] = "非公開";
              }
              else {
                requestData.attributes[obj.name] = "公開";
              }
              break;

            case 'assigned_to.id':
            case 'assigned_to.name':
            case 'author.id':
            case 'author.name':
            case 'priority.id':
            case 'priority.name':
            case 'project.id':
            case 'project.name':
            case 'status.id':
            case 'status.name':
            case 'tracker.id':
            case 'tracker.name':
              var prop = obj.name.split(".");
              requestData.attributes[obj.name] = data.issue[prop[0]][prop[1]];
              break;

            case 'created_on':
            case 'updated_on':
            case 'due_date':
            case 'start_date':
              requestData.attributes[obj.name] = moment(data.issue[obj.name]).format('YYYY-MM-DD');
              break;

            case 'description':
            case 'done_ratio':
            case 'estimated_hours':
            case 'id':
            case 'subject':
            case 'total_estimated_hours':
              requestData.attributes[obj.name] = data.issue[obj.name];
              break;

            default:
              requestData.attributes[obj.name] = obj.default;
              break;
          }

          if (data.issue.custom_fields) {
            $.each(data.issue.custom_fields, function (key,field) {
              if (obj.name === field.name) {
                requestData.attributes[obj.name] = field.value;
              }
            });
          }
        });

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
