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
    LAST_LAYOUT_KEY: (function () {
      // Use immediate function to switch keys between list and detail
      var isListPage = location.href.endsWith('/issues');
      return isListPage ? "GTT_PRINT_LAST_LAYOUT_FOR_LIST" : "GTT_PRINT_LAST_LAYOUT_FOR_DETAIL";
    }()),
    LAST_LAYOUT_SELECTOR: '#gtt_print_job_layout'
  },
  // Initializer
  init: function () {
    var consts = GttPrint.consts;

    // register event handlers
    var handlers = GttPrint.handlers;
    $(consts.LAST_LAYOUT_SELECTOR).on('change', handlers.onLayoutChange);

    // initialize at once
    var initializers = GttPrint.initializers;
    initializers.restoreLayout();

    // output module initialization completion message
    console.info(`GttPrint was initialized.  This module set last selected layout to local storage via KEY: "${consts.LAST_LAYOUT_KEY}".`);
  },
  // methods for initialization
  initializers: {
    restoreLayout: function () {
      var consts = GttPrint.consts;
      var lastLayout = localStorage.getItem(consts.LAST_LAYOUT_KEY, '');
      if (lastLayout) {
        $(consts.LAST_LAYOUT_SELECTOR).val(lastLayout);
      }
    }
  },
  // methods for event handlers
  handlers: {
    onLayoutChange: function (ev) {
      var consts = GttPrint.consts;
      var lastLayout = $(ev.currentTarget).val();
      localStorage.setItem(consts.LAST_LAYOUT_KEY, lastLayout);
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

$(document).ready(function () {
  GttPrint.init();
});
