class AliasController < BaseController
  include RestModelHelper

  # GET /domains/[domain id]/applications
  def index
    domain_id = params[:domain_id]
    id = params[:application_id]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_APP_ALIASES")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
      render_success(:ok, "aliases", get_rest_aliases(application, application.aliases), "LIST_APP_ALIASES", "Listing aliases for application #{id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "LIST_APP_ALIASES")
    end
  end
  
  # GET /domains/[domain_id]/applications/<id>
  def show   
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_APP_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
      application.aliases.each do |a|
        
      end
      render_success(:ok, "alias", get_rest_aliases(application, application.aliases), "SHOW_APP_ALIAS", "Showing alias #{id} for application #{application_id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "SHOW_APP_ALIAS")
    end
  end
  

  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    server_alias = params[:alias]
    ssl_certificate = params[:ssl_certificate]
    private_key = params[:private_key]
    pass_phrase = params[:pass_phrase]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "ADD_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "ADD_ALIAS")
    end
    
    begin 
      reply = application.add_alias(server_alias, ssl_certificate, private_key, pass_phrase)
      rest_alias = get_rest_aliases(application, server_alias)
      messages = []
      log_msg = "Added #{server_alias} to application #{id}"
      messages.push(Message.new(:info, log_msg))
      messages.push(Message.new(:info, reply.resultIO.string, 0, :result))
      return render_success(:created, "alias", rest_alias, "ADD_ALIAS", log_msg, nil, nil, messages)
    rescue OpenShift::UserException => e
      Rails.logger.debug "Exception while adding alias #{e.message}"
      return render_error(:unprocessable_entity, "Alias #{server_alias} is already in use.", 140, "ADD_ALIAS", "id")
    end
  end
  
  def update
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    server_alias = params[:id]
    ssl_certificate = params[:ssl_certificate]
    private_key = params[:private_key]
    pass_phrase = params[:pass_phrase]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "UPDATE_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
      return render_error(:not_found, "Alias #{server_alias} not found", 173, "UPDATE_ALIAS") unless application.aliases.include? server_alias
      
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "UPDATE_ALIAS")
    end
    
    begin 
      reply = application.add_alias(server_alias, ssl_certificate, private_key, pass_phrase)
      rest_alias = RestAlias.new()
      messages = []
      log_msg = "Added #{server_alias} to application #{application_id}"
      messages.push(Message.new(:info, log_msg))
      messages.push(Message.new(:info, reply.resultIO.string, 0, :result))
      return render_success(:created, "alias", rest_alias, "UPDATE_ALIAS", log_msg, nil, nil, messages)
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, "Alias #{server_alias} is already in use.", 140, "UPDATE_ALIAS", "id")
    end
  end
  
  def destroy
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    server_alias = params[:id]
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "DELETE_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "DELETE_ALIAS")
    end
    
    begin
      application.remove_alias(server_alias)
    rescue Exception => e
      Rails.logger.error "Exception #{e.message}"
    end

  end
end
