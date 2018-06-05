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

    $.ajax({
      type: 'POST',
      url: server + "print/" + id + "/report." + format,
      data: {
        spec: JSON.stringify(requestData)
      },
      success: function (response) {
        console.log(response)
      }
    });
  };
});
