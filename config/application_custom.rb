module Consul
  class Application < Rails::Application
    config.i18n.default_locale = :hu
    config.i18n.available_locales = [:en, :ro, :hu]
  end
end
