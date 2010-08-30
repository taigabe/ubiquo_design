require File.dirname(__FILE__) + '/../test_helper'

class UbiquoDesign::Extensions::HelperTest < ActionView::TestCase

  test 'url_for_page given a page' do
    self.expects(:url_for).with do |options|
      options[:controller] = '/pages' &&
        options[:action] = 'show' &&
        options[:url] = pages(:one_design).url_name
    end
    url_for_page(pages(:one_design))
  end

  test 'url_for_page given a key' do
    self.expects(:url_for).with do |options|
      options[:controller] = '/pages' &&
        options[:action] = 'show' &&
        options[:url] = pages(:one_design).url_name
    end
    url_for_page(pages(:one_design).key)
  end

  test 'link_to_page relies in url_for_page' do
    caption = 'caption'
    page_key = pages(:one_design).key
    url_for_options = {:controller => '/pages'}
    link_to_options = {:class => 'example'}

    self.expects(:url_for_page).with(page_key, url_for_options).returns('url')
    self.expects(:link_to).with(caption, 'url', link_to_options)

    link_to_page(caption, page_key, url_for_options, link_to_options)
  end

end
