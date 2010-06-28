# -*- coding: utf-8 -*-
class CreateExampleDesignStructure < ActiveRecord::Migration
  def self.up
    pt_simple = PageTemplate.create(:name => "Simple",
                                    :key => "simple",
                                    :layout => "main",
                                    :thumbnail_file_name => "simple.png")
    pt_interior = PageTemplate.create(:name => "Interior",
                                      :key => "interior",
                                      :layout => "main",
                                      :thumbnail_file_name => "interior.png")
    bt_top = BlockType.create(:name => "Top block",
                              :key => "top",
                              :can_use_default_block => true)
    bt_sidebar = BlockType.create(:name => "Sidebar block",
                              :key => "sidebar",
                              :can_use_default_block => true)
    bt_main = BlockType.create(:name => "Main block",
                              :key => "main",
                              :can_use_default_block => false)
    
    ct_free = Widget.create(:name => "Free component",
                                   :key => "free",
                                   :is_configurable => true,
                                   :subclass_type => "Free")
    ct_assets_automatic_menu = Widget.create(:name => "Menu automàtic per recursos",
                                                    :key => "assets_automatic_menu",
                                                    :is_configurable => true,
                                                    :subclass_type => "AssetsAutomaticMenu")
    
    # relate page templates with block types
    
    pt_simple.block_types << [bt_top, bt_sidebar, bt_main]
    pt_interior.block_types << [bt_top, bt_sidebar, bt_main]
    
    # relate page templates with component types
    
    pt_simple.widgets << [ct_free, ct_assets_automatic_menu]
    pt_interior.widgets << [ct_free, ct_assets_automatic_menu]
  end

  def self.down
    PageTemplate.find_by_key("simple").destroy
    PageTemplate.find_by_key("interior").destroy    
  end
end
