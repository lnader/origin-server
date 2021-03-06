require File.expand_path('../../test_helper', __FILE__)

class DomainMembersControllerTest < ActionController::TestCase

  def setup
    @user = with_unique_user
    with_domain
  end

  def with_domain
    @domain = Domain.first :as => @user
    unless @domain
      @domain = Domain.new(get_post_form.merge(:as => @user))
      flunk @domain.errors.inspect unless @domain.save
    end
    @domain
  end

  def test_get_index_redirects
    get :index, {:domain_id => @domain}
    assert_redirected_to domain_path(@domain)
  end

  def test_update_without_params
    Domain.any_instance.expects(:update_members).never
    put :update, {:domain_id => @domain}
    assert_redirected_to domain_path(@domain)    
  end

  def test_update_single_member_error
    put :update, {
      :domain_id => @domain,
      :members => {:type => 'user', :role => 'view', :login => 'x', :adding => 'true'}
    }
    assert_response :success
    assert_template 'domains/show'
    assert_equal "The domain members could not be updated.", flash[:error]
    assert new_members = assigns[:new_members]
    assert_equal 1, new_members.count
    assert new_members[0].errors[:login].to_s =~ /x/

    assert_select '.members.editing'
    assert_select "input[name='members[][login]']", :count => 2
    assert_select "tr.template input[name='members[][login]']", :count => 1
  end

  def test_update_multi_member_error
    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(1)
    
    put :update, {
      :domain_id => @domain,
      :members => [
        {:type => 'user', :role => 'view', :login => 'x', :adding => 'true'},
        {:type => 'user', :role => 'view', :login => 'y', :adding => 'true'},
        {:type => 'team', :role => 'view', :name => 'team1', :id => 'tid1', :adding => 'true'}
      ]
    }
    assert_response :success
    assert_template 'domains/show'
    assert_equal "The domain members could not be updated.", flash[:error]
    assert new_members = assigns[:new_members]
    assert_equal 3, new_members.count
    assert new_members[0].errors[:login].to_s =~ /x/
    assert new_members[1].errors[:login].to_s =~ /y/
    assert new_members[2].errors[:id].to_s =~ /tid1/

    assert_select '.members.editing'

    assert_select "input[name='members[][login]']", :count => 3
    assert_select "tr.template input[name='members[][login]']", :count => 1

    assert_select "input[name='members[][name]']", :count => 2
    assert_select "tr.template input[name='members[][name]']", :count => 1
  end

  def test_update_single_member_success
    Domain.any_instance.expects(:update_members).returns(true)
    put :update, {
      :domain_id => @domain,
      :members => {:type => 'user', :role => 'view', :login => 'x'}
    }
    assert_redirected_to domain_path(@domain) 
    assert flash[:success]
  end

  def test_update_multi_member_success
    Domain.any_instance.expects(:update_members).returns(true)
    put :update, {
      :domain_id => @domain,
      :members => [
        {:type => 'user', :role => 'view', :login => 'x'},
        {:type => 'user', :role => 'none', :login => 'y'}
      ]
    }
    assert_redirected_to domain_path(@domain) 
    assert flash[:success]
  end

  def test_leave
    Domain.any_instance.expects(:leave).never
    get :leave, {:domain_id => @domain}
    assert_response :success
    assert_template 'members/leave'

    Domain.any_instance.expects(:leave).once.returns(false)
    post :leave, {:domain_id => @domain}
    assert_redirected_to domain_path(@domain)
    assert flash[:error]

    Domain.any_instance.expects(:leave).once.returns(true)
    post :leave, {:domain_id => @domain}
    assert_redirected_to console_path
    assert flash[:success]
  end

  protected
    def get_post_form
      {:name => "d#{uuid[0..12]}"}
    end

end
