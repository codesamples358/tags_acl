require File.expand_path('../../test_helper', __FILE__)

class ProhibitedIssueTest < ActiveSupport::TestCase
  fixtures :projects,
         :users, :email_addresses, :user_preferences,
         :roles,
         :members,
         :member_roles,
         :issues,
         :issue_statuses,
         :issue_relations,
         :versions,
         :trackers,
         :projects_trackers

  def setup
    Project.find(1).enabled_module_names = [:issue_tracking]
  end

  def visible_count
    Issue.visible.count
  end

  def issue
    Issue.find(1)
  end

  def visible
    Issue.visible
  end

  # Replace this with your real tests.
  def test_visibility
    User.current = User.find(2)
    issue = Issue.find(1)

    count_before = visible_count
    assert count_before > 0

    ProhibitedIssue.create!(user_id: 2, issue_id: 1)

    count_after = visible_count
    assert count_after == count_before - 1

    ProhibitedIssue.delete_all

    assert_equal count_before, visible_count
  end

  def test_rule
    User.current = User.find(2)
    assert_include issue, visible

    rule = TagPermissionRule.create!(role_id: 1, tag: 'prohibited', name: 'default')
    assert_include issue, visible

    issue.update_attributes!(tag_list: 'prohibited')
    assert_not_include issue, visible

    rule.update_attributes!(tag: 'another_tag')
    assert_include issue, visible

    rule.update_attributes!(tag: 'prohibited')
    assert_not_include issue, visible
  end
end
