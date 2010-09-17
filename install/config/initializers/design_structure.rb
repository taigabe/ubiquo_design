UbiquoDesign::Structure.define do
  page_template :home do
    block :top
    block :sidebar, :cols => 1
    block :main, :cols => 3
  end
  page_template :static do
    block :top, :main
  end
  widget :free, :automatic_menu
  widget :static_section
end