/**
 * GttPrint
 * 
 * en:
 * This script describes the JavaScript portion of the GTT Print plug-in.
 * 
 * ## Design policy.
 * * Use the namespace `GttPrint` to avoid `Global Pollution`.
 * * Define methods for constants in `consts` objects, event handlers in `handlers` objects, and initialization processes in `initializers` objects.
 * * To avoid the complexity caused by implicit this-reference conversion, the methods in the `consts` `handlers` `initializers` objects are referenced from the `GttPrint` namespace and assigned to local variables at the beginning of each method.
 * * The initialization process is performed by calling `GttPrint.init()` in `$(document).ready`. This ensures that the initialization process is executed after the DOM has been rendered.
 * 
 * ja:
 * このスクリプトは、GTT PrintプラグインのJavaScript部分を記述します。
 * 
 * ## 設計方針
 * * グローバル汚染を回避するため、名前空間 `GttPrint` を使用します。
 * * 定数は `consts`オブジェクトに、イベントハンドラは `handlers` オブジェクトに、初期化処理は `initializers` オブジェクトに、それぞれメソッドを定義します。
 * * 暗黙的なthisの参照変換による複雑性を回避するために、 `consts` `handlers` `initializers` オブジェクト内のメソッドは、 `GttPrint` 名前空間から参照し、各メソッドの冒頭でローカル変数に代入して使用します。
 * * 初期化処理は、 `$(document).ready` 内で `GttPrint.init()` を呼び出すことで実行されます。これにより、DOMのレンダリングが完了した後に初期化処理が実行されるようになります。
 */
var GttPrint = {
  // Constants Definition
  consts: {
    LAST_LEDGER_KEY: "last_ledger",
    LAST_LEDGER_SELECTER: '#gtt_print_job_layout'
  },
  // Initializer
  init: function () {
    var consts = GttPrint.consts;

    // register event handlers
    var handlers = GttPrint.handlers;
    $(consts.LAST_LEDGER_SELECTER).on('change', handlers.onLedgerChange);

    // initialize at once
    var initializers = GttPrint.initializers;
    initializers.restoreLedger();
  },
  // methods for initialization
  initializers: {
    restoreLedger: function () {
      var consts = GttPrint.consts;
      var lastLedger = localStorage.getItem(consts.LAST_LEDGER_KEY, '');
      if (lastLedger) {
        $(consts.LAST_LEDGER_SELECTER).val(lastLedger);
      }
    }
  },
  // methods for event handlers
  handlers: {
    onLedgerChange: function (ev) {
      var consts = GttPrint.consts;
      var lastLedger = $(ev.currentTarget).val();
      localStorage.setItem(consts.LAST_LEDGER_KEY, lastLedger);
    }
  },
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


$(document).ready(function () {
  GttPrint.init();
});
