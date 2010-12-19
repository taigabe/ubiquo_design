module PagesHelper
  def metatags(page)
    tag(:meta, :name => 'description', :content => page.meta_description) +
      tag(:meta, :name => 'keywords', :content => page.meta_keywords)
  end
end
