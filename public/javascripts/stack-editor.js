$(function () {
  $.jstree._themes = "stylesheets/jstree/";
  $("some-selector-to-container-node-here").jstree({
    core : { /* core options go here */ },
    plugins : [ "themes", "html_data" ]
  });
  $(function () {
    $("#directory").jstree(
    { "json_data":
      { "ajax":
        { "url": "directory.json"
        , "data": function (n) {
            return { directory: n.attr ?  /^remoteFileId_(\d+)$/.exec(n.attr("id"))[1] : 0 }
          }
        }
      }
    , "plugins" : [ "themes", "json_data" ]
    });
  });
});
