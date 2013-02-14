class Alias
  include Mongoid::Document
  embedded_in :application
  
  attr_accessor :name, :has_private_certificate
end