$(function() {
  var server = ($('form.print_box').attr('action')).replace(/\/?$/, '/');

  if (server) {
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

    var config = $('form.print_box select').val();

    $.getJSON(server + "print/" + config + "/capabilities.json", function (data) {
      console.log(data);
    });

    return false;
  });
});
