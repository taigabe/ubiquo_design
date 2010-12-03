module PagesHelper
  def metatags(page)
    "<meta name='description' content='#{page.meta_description}'" +
      "<meta name='keywords' content='#{page.meta_keywords}'"
  end
end
