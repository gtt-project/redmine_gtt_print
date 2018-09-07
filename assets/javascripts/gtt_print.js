var GttPrint = {
  downloadWhenReady: function(startTime, path) {
    console.log("downloadWhenReady: " + path);
    setTimeout(function () {
      $.get(path, null, function (data) {
              console.log(data);
              if(data.status == 'done'){
                window.location = data.path;
              } else if ((new Date().getTime() - startTime) > 30000) {
                console.log('downloadWhenReady: giving up after 30 seconds');
              } else {
                GttPrint.downloadWhenReady(startTime, path);
              }
            }, 'json');
    }, 500);
  }
};

var _submit = function () {
  $('input[name="gtt_print_job[scale]"]').val(App.getScale());
  $('input[name="gtt_print_job[basemap_url]"]').val(App.getBasemapUrl());
}
