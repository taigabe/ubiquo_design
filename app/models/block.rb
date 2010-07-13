class Block < ActiveRecord::Base
  validates_presence_of :block_type, :page

  has_many :block_uses, :class_name => 'Block', :foreign_key => 'shared_id'
  belongs_to :shared, :class_name => 'Block', :foreign_key => 'shared_id'
  has_many :components, :dependent => :destroy, :order => 'components.position ASC' 
  belongs_to :page
  after_save :update_page
  after_destroy :update_page
  
  # Given a page and block_type, create and return a block
  def self.create_for_block_type_and_page(block_type, page, options = {})
    options.reverse_merge!({:block_type => block_type, :page_id => page.id})
    created = self.create(options)
    page.reload
    created
  end

  def is_shared?
    self.block_uses.present?
  end 
 
  private

  # When a block is saved, the associated page must change its modified attribute 
  def update_page
    self.page.reload.update_modified
  end
end
