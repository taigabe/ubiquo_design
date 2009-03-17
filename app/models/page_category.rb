class PageCategory < ActiveRecord::Base
  validates_uniqueness_of :name, :url_name
  validates_format_of :url_name, :with => /^[a-zA-Z\d][a-zA-Z\d\-\_]*$/, :allow_blank => true
  
  has_many :pages
end
