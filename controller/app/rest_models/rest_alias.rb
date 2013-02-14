class RestAlias < OpenShift::Model
  attr_accessor :id, :has_private_certificate, :links
  
  def initialize(app, al1as, url, nolinks=false)
    self.id = al1as["id"]
    self.has_private_certificate = al1as["has_private_certificate"]
    domain_id = app.domain.namespace
    app_id = app.name
    unless nolinks      
      self.links = {
        "GET" => Link.new("Get alias", "GET", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/aliases/#{self.id}")),
        "UPDATE" => Link.new("Update alias", "PUT", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/aliases/#{self.id}"),
          [Param.new("ssl_certificate", "string", "Content of SSL Certificate"), 
            Param.new("private_key", "string", "Private key for the certifcate.  Required if adding a certificate")], 
            [OptionalParam.new("pass_phrase", "string", "Optional passphrase for the private key")]),
        "DELETE" => Link.new("Delete alias", "DELETE", URI::join(url, "domains/#{domain_id}/applications/#{app_id}/aliases/#{self.id}"))
      }
    end
  end
  
  def to_xml(options={})
    options[:tag_name] = "alias"
    super(options)
  end
end