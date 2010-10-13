$(function () {
  $.jstree._themes = "stylesheets/jstree/";
  function getId (e) {
    return { id: e.attr ?  /^remoteFileId_(\d+)$/.exec(e.attr("id"))[1] : 0 }
  }
  var editor = null;
  $("#directory").bind("select_node.jstree", function (e, data) {
    var params = getId(data.rslt.obj);
    $.get("file", params, function (data) {
      if (data) {
        editor = new CodeMirror($("#editor").get(0), {
          parserfile: "parsecss.js",
          stylesheet: "javascripts/codemirror/css/csscolors.css",
          path: "javascripts/codemirror/js/",
          content: data
        });
      }
    });
  }).jstree(
  { "json_data":
    { "ajax":
      { "url": "directory.json"
      , "data": getId
      }
    }
  , "plugins" : [ "themes", "json_data", "ui" ]
  });
});
