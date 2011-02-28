class GenericDetail < Widget
  self.allowed_options = [:model]
  write_inheritable_attribute :previewable, true
  validates_presence_of :model

  # Returns the element to be shown
  # If the model of the generic detail has a +generic_detail_element+ method,
  # this method will take precedence.
  def element(id)
    model = self.model.constantize
    model.respond_to?(:generic_detail_element) ? model.generic_detail_element(id) : model.find(id)
  end

  def preview_params
    { :url => [self.model.constantize.first.try(:id)] }
  end
  
end
