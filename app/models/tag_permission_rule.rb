class TagPermissionRule < ActiveRecord::Base
  acts_as_ordered_taggable
  validates :name, :presence => true, :uniqueness => true
  validates :role_id, :presence => true

  belongs_to :role

  def matches?(user, issue)
    return false unless matches_issue?(issue)

    member     = user.membership(issue.project)
    return false unless member

    role_match = member.roles.include?(self.role) ^ self.role_not

    return role_match
  end

  def matches_role?(role)
    (role == self.role) ^ self.role_not
  end

  def matches_issue?(issue)
    # tag_match = (issue.tags & self.tags).any? ^ self.tag_not
    tag_match = issue.tags.map(&:name).include?(self.tag) ^ self.tag_not
  end

  def self.forbid?(user, issue)
    all.any? {|rule| rule.matches?(user, issue) }
  end

  def self.visible_issues_sql(user, options = {})

    # .joins("LEFT JOIN taggings ON taggings.taggable_id = issues.id AND taggings.context = 'tags' AND taggings.taggable_type = 'Issue'")
    # .joins('LEFT JOIN tags ON tags.id = taggings.tag_id')

    issues_table = Issue.table_name
    all_rules    = self.all

    Project.allowed_to_condition(user, :view_issues, options) do |role, user|

      # sql = if user.id && user.logged?
      #   case role.issues_visibility
      #   when 'all'
      #     '1=1'
      #   when 'default'
      #     user_ids = [user.id] + user.groups.pluck(:id).compact
      #     "(#{issues_table}.is_private = #{connection.quoted_false} OR #{issues_table}.author_id = #{user.id} OR #{issues_table}.assigned_to_id IN (#{user_ids.join(',')}))"
      #   when 'own'
      #     user_ids = [user.id] + user.groups.pluck(:id).compact
      #     "(#{issues_table}.author_id = #{user.id} OR #{issues_table}.assigned_to_id IN (#{user_ids.join(',')}))"
      #   else
      #     '1=0'
      #   end
      # else
      #   "(#{issues_table}.is_private = #{connection.quoted_false})"
      # end
      # unless role.permissions_all_trackers?(:view_issues)
      #   tracker_ids = role.permissions_tracker_ids(:view_issues)
      #   if tracker_ids.any?
      #     sql = "(#{sql} AND #{issues_table}.tracker_id IN (#{tracker_ids.join(',')}))"
      #   else
      #     sql = '1=0'
      #   end
      # end

      all_rules.map do |rule|
        if rule.matches_role?(role)
          op = !rule.tag_not ? '<>' : '='
          "(tags.name #{op} '#{rule.tag}')"
        end
      end.compact.join(' AND ')
    end
  end
end
