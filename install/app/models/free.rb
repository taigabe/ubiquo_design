# == Schema Information
# Schema version: 20081016064309
#
# Table name: components
#
#  id                :integer         not null, primary key
#  options           :text
#  component_type_id :integer
#  block_id          :integer
#  position          :integer
#  type              :string(255)
#  name              :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

class Free < Component
  self.allowed_options = [:content]
  
  validates_presence_of :content
end
