module UbiquoDesign
  module Connectors
    autoload :Base, "ubiquo_design/connectors/base"
    autoload :Standard, "ubiquo_design/connectors/standard"
    autoload :ComponentTranslation, "ubiquo_design/connectors/component_translation"
    
    def self.load!
      "UbiquoDesign::Connectors::#{Ubiquo::Config.context(:ubiquo_design).get(:connector).to_s.classify}".constantize.load!
    end
  end
end
