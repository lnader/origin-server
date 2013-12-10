require_relative '../test_helper'

class TeamTest < ActiveSupport::TestCase

  setup do 
    Lock.stubs(:lock_application).returns(true)
    Lock.stubs(:unlock_application).returns(true)
  end

  def with_membership(&block)
    yield
  end

  def without_membership(&block)
    # do nothing
  end

  def with_config(sym, value, base=:openshift, &block)
    c = Rails.configuration.send(base)
    @old =  c[sym]
    c[sym] = value
    yield
  ensure
    c[sym] = @old
  end

  def test_non_member_team_destroy
    Team.where(:name => 'non-member-team-destroy').delete
    assert t = Team.create(:name => 'non-member-team-destroy')
    assert t.destroy
  end

  def test_member_team_destroy
    Domain.where(:namespace => 'test').delete
    assert d = Domain.create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser.create(:login => 'team-member-1')

    CloudUser.where(:login => 'team-member-2').delete
    assert u2 = CloudUser.create(:login => 'team-member-2')

    # Set up a team with one member
    Team.where(:name => 'member-team-destroy').delete
    assert t = Team.create(:name => 'member-team-destroy')
    assert t.add_members u1, :admin
    assert t.save
    assert t.run_jobs

    # Ensure membership expands to the domain with the team role
    d.add_members t, :edit
    assert d.save, d.inspect
    assert d.run_jobs
    assert_equal 2, d.members.count, d.inspect
    assert d.reload
    assert_equal 2, d.members.count
    assert_equal :edit, d.role_for(t)
    assert_equal :edit, d.role_for(u1)

    # Add a member explicitly to the domain
    assert d.add_members u2, :view
    assert d.save, d.inspect
    assert d.run_jobs

    # Add the same member to the team
    assert t.add_members u2, :view
    assert t.save
    assert t.run_jobs

    # Ensure team membership grants higher role to user which is also an explicit domain member
    assert d.reload
    assert_equal 3, d.members.count
    assert_equal :edit, d.role_for(u2)

    # Ensure we can't destroy the team directly when it is a domain member
    assert_raise(RuntimeError) { t.destroy }
    assert t.destroy_team

    # Ensure team members are removed from the domain, and explicit domain members go back to their lowered roles
    assert d.reload
    assert_equal 1, d.members.count
    assert_equal nil, d.role_for(t)
    assert_equal nil, d.role_for(u1)
    assert_equal :view, d.role_for(u2)
  end

end