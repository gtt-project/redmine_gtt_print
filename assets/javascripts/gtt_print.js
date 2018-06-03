$(function() {
  var server = ($('form.print_box').attr('action')).replace(/\/?$/, '/');

  if (server) {
    $.getJSON(server + "print/apps.json", function (data) {
      $.each(data, function(key, value) {
        var option = $("<option></option>").attr("value",value).text(value);
        $('form.print_box select').append(option);
      });
    });
  }

  $(document).on('click', '.print_box input[type=button]', function(e){
    console.log('TODO: submit print');
    return false;
  });
});
