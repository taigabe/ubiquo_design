UbiquoDesign::Structure.define do
  page_template :default do
    block :top
    block :sidebar, :cols => 1
    block :main, :cols => 3
  end
  widget :free, :assets_automatic_menu
end
