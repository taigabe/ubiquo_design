document.observe("dom:loaded", function() {
  //Add observers for url compose in pages form
  if($('page_parent_id')) {
    var parent_page_select = $('page_parent_id');
    parent_page_select.observe(
      "change",
      function() {
        update_url_example();
      }
    )
  }
  if($('page_url_name')) {
    update_url_example();
    var url_name_field = $('page_url_name');
    url_name_field.observe(
      "keyup",
      function() {
        update_url_example();
      }
    );
  } 
});

function update_url_example() {
  var selected_parent = $('page_parent_id').options[$('page_parent_id').selectedIndex].title;
  var host = $('url_example').textContent.match(/http\:\/\/.*\.[a-z]{2,3}\//).first();
  var page_value = $('page_url_name').value;
  if (selected_parent != "") {
    var replace = "^" + selected_parent + "/";
    page_value = page_value.gsub(replace, '');
    $('page_url_name').value = page_value;
    var value = host + selected_parent + "/" + page_value;
  } else {
    var value = host + page_value;
  }
  $('url_example').update(value);
} 
