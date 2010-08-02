class StaticSection < Widget
  self.allowed_options = [:title, :summary, :body]
  media_attachment :image, :size => 1, :types => ["image"]
  media_attachment :docs, :size => :many
end
