module SpreeGateway
  VERSION = '3.11.0'.freeze

  def self.version
    VERSION
  end

  def gem_version
    Gem::Version.new(VERSION)
  end
end
