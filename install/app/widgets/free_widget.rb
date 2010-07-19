def free_generator(component, options)
  locals = {
    :content => component.content,
  }
  render_options = {}
  [locals, render_options]
end
