class Block < ActiveRecord::Base
  validates_presence_of :block_type, :page
  
  belongs_to :block_type
  has_many :components, :dependent => :destroy, :order => 'components.position ASC'
  
  belongs_to :page
  after_save :update_page
  after_destroy :update_page
  
  # Given a page and block_type, create and return a block
  def self.create_for_block_type_and_page(block_type, page, options = {})
    block_type = BlockType.find_by(block_type)
    options.reverse_merge!({:block_type_id => block_type.id, :page_id => page.id})
    created = self.create(options)
    page.reload
    created
  end
  
  private
  
  # When a block is saved, the associated page must change its modified attribute 
  def update_page
    self.page.reload.update_modified
  end
end
