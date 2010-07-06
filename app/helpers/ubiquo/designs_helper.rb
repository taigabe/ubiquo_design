#= Page templates
#
#All pages on the design system belong to a page template which  holds the view structure for both the public and the ubiquo page. Page templates are located at <tt>app/templates</tt>.
#
#== Creating the page template and the block types
#
#Let's create an example template (called _main_) for our app:
#
#  #db/dev_bootstrap/page_templates.yml
#
#  main:
#    name: Main template
#    key: main
#    layout: standard
#
#The attributes of a _PageTemplate_ are:
#
#* name: descriptive name of the page template.
#* key: used to build the templates directory (<tt>app/templates/page_template_key</tt>
#* layout: layout to be rendered (if empty, it will take the default layout 'main')  
#   
#A page template will usually contain blocks. Let's imagine we want to create a page template containing three blocks: _top_, _column1_ and _banners_:
#
#  # db/dev_bootstrap/block_types.yml
#
#  top:
#    name: Top block
#    key: top
#    can_use_default_block: true
#
#  banners:
#    name: Banners block
#    key: banners
#    can_use_default_block: true
#
#  column1:
#    name: Column 1
#    key: column1
#    can_use_default_block: false
#
#The attribute _can_use_default_block_ is used to indicate if a given block is susceptible of being used on many pages (then it would use frontpage block components). 
#
#Now we need to associate these block types with the page template on the join table :
#
#  # db/dev_bootstrap/page_template_block_types.yml
#
#  page_template_block_type_001:
#    page_template: main
#    block_type: top
#  page_template_block_type_002:
#    page_template: main
#    block_type: column1
#  page_template_block_type_003:
#    page_template: main
#    block_type: banners
#
#== Public page template
#
#The public template should be placed at <tt>app/templates/page_template_key/public.html.erb</tt>. This template receives an instance variable (_@blocks_), a hash containing the output of each component on the block (each key corresponding to the block key name as a symbol):
#
#  <div id="top">
#    <%= @blocks[:top] %>
#  </div>
#  <div id="column1">
#    <%= @blocks[:column1] %>
#  </div>
#  <div id="banners">
#    <%= @blocks[:banners] %>
#  </div>
#
#== Ubiquo page template
#
#The ubiquo template should be placed at <tt>app/templates/page_template_key/ubiquo.html.erb</tt>. This template recevies the _page_ record as a local variable, and has to call one of theses Ubiquo::DesignsHelper:design_big_block, design_big_col_block or design_col_block.
#
#  <%= design_block_4cols page, 'top' %>
#  <%= design_block_3cols page, 'col1' %>
#  <%= design_block_1col page, 'banners' %>
module Ubiquo::DesignsHelper

  def design_block_4cols(page, type_key, options={})
    bt = BlockType.find_by(type_key)
    is_using_default = !page.blocks.as_hash.include?(bt.key)
    options.reverse_merge!({:class => "column_4"})
    s = "<div class='top_options'>"
    s << render(:partial => "ubiquo/designs/use_default_form", :locals => {:bt => bt, :page => page, :is_using_default => is_using_default, :style_class => options[:class]}) if bt.can_use_default_block? && !(page.url_name.blank?)
    s << "</div>"
    s << block_type_holder(page, bt, options)
    s
  end

  def design_block_1col(page, type_key, options={})
    options.reverse_merge!({:class => "column_1"})
    design_block_4cols(page, type_key, options)
  end
  
  def design_block_2cols(page, type_key, options={})
    options.reverse_merge!({:class => "column_2"})
    design_block_4cols(page, type_key, options)
  end
  
  def design_block_3cols(page, type_key, options={})
    options.reverse_merge!({:class => "column_3"})
    design_block_4cols(page, type_key, options)
  end

  def make_blocks_sortables(page)
    ids = page.page_template.block_types.map(&:id)
    page.blocks.collect do |block|
      sortable_block_type_holder block.block_type.id,  change_order_ubiquo_page_design_components_path(page), ids
    end
  end

  def block_type_holder(page, block_type, options = {})
    block = page.all_blocks_as_hash[block_type.key]
    options.merge!(:id => "block_#{block_type.id}" )
    options[:class] ||= ''
    if page.blocks.as_hash.include?(block_type.key)
      options[:class] << " draggable_target"
    else
      options[:class] << " non_draggable_target"
    end
    (content_tag :div, options do
      content_tag :ul, :id =>"block_type_holder_#{block_type.id}", :class => 'block_type_holder' do
        components_for_block_type_holder(block) unless options[:class].match /non_draggable/
      end
    end) +
    (page.blocks.as_hash.include?(block_type.key) ? drop_receiving_element(
    options[:id],
    :url => ubiquo_page_design_components_path(@page),
    :method => :post,
    :accept => 'component',
    :with => "'widget='+element.id.match(/\\d+/).first()+'&block=#{block.id}'"
    ) : "")
  end

  def components_for_block_type_holder(block)
    components = uhook_load_components(block)
    render :partial => "ubiquo/components/component", :collection => components
  end

  def sortable_block_type_holder_options(id, url, containments=[])
    ["block_type_holder_#{id}", {
      :url => url,
      :handle => "move",
      :containment => containments.map{|i|"block_type_holder_#{i}"},
      :dropOnEmpty => true,
      :constraint => false,
      :with => "Sortable.serialize('block_type_holder_#{id}',{name: 'block[#{id}]'})"}
    ]
  end
  def sortable_block_type_holder(id,url, containments=[])
    id, opts = sortable_block_type_holder_options(id,url, containments)
    sortable_element id, opts
  end

end
