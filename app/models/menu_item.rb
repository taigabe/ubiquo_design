class MenuItem < ActiveRecord::Base
  validates_presence_of :caption, :parent_id
  validates_presence_of :url, :if => Proc.new { |menuitem| menuitem.is_linkable }

  before_validation_on_create :initialize_position
  before_validation :clear_url
 
  has_many :children,
           :class_name => "MenuItem",
           :foreign_key => :parent_id,
           :order => :position,
           :dependent => :destroy

  belongs_to :parent,
             :class_name => "MenuItem",
             :foreign_key => :parent_id

  belongs_to :automatic_menu
  
  named_scope :active, :conditions => {:is_active => true}
  named_scope :roots, :conditions => {:parent_id => 0}, :order => "position ASC"
  
  # Returns true if is a root node
  def is_root?
    (self.parent_id == 0)
  end

  # Returns true if this node is allowed to have children.
  # For now, only root nodes with no automatic menu can have children.
  def can_have_children?
    (self.is_root? && !self.automatic_menu_id)  
  end

  # Return an array containing active root (first-level) menu items 
  def self.active_roots
    self.roots.active
  end    
  
  # Return active children for a node
  def active_children
    self.children.active
  end
  
  def clear_url
    self.url = "" unless self.is_linkable?
  end

  private
  
  # Before creating a menu_item record, set a sane position index (last + 1)
  def initialize_position
    conditions = ['parent_id = ?', (self.parent_id || 0)]
    max_position = MenuItem.maximum(:position, :conditions => conditions)
    self.position = (max_position || 0) + 1
  end
  
end
