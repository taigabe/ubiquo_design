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
  if($('save_publish')) {
    var save_publish_button = $('save_publish');
    save_publish_button.observe(
      "click",
      function() {
        $('publish_page').value = 'true';
        this.up('form').submit();
      }
    )
  }

	//Sidebar scroll
	var scrolling = false;
	var last_scroll;
	
	last_scroll = document.viewport.getScrollOffsets()[1];
	
  setInterval(function(){
    var current_scroll = document.viewport.getScrollOffsets()[1];
    if (scrolling){
      if (current_scroll == last_scroll){
        scrolling = false;
        slide_that_div();
      }
    } else if(current_scroll != last_scroll){
      scrolling = true;
    }
	last_scroll = current_scroll;
  }, 300);
});


function slide_that_div(){
  var scroll_offset = document.viewport.getScrollOffsets()[1];
	scroll_offset = (scroll_offset > 140) ? scroll_offset-140 : 0;
	new Effect.Move('slide_wrapper', { y: scroll_offset, mode: 'absolute', duration: '0.5' });
}

//------------
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

function update_error_on_widgets(widget_ids) {
  $$("#content .widget").each(function(i) {
    i.removeClassName("error");
  })
	
  widget_ids.each(function(id) {
    $("widget_" + id).addClassName("error");
  })
}

function toggleShareActions(id) {
  $(id).select('div').each(function(div) {
    div.toggle();
  });
}

//ALLOWED BLOCKS FOR EACH WIDGET
var allowedBlocks = new Array();
//for each widget specify allowed blocks
allowedBlocks['static_section'] = ['block_top','block_sidebar']; 
allowedBlocks['free'] = ['block_main']; 
