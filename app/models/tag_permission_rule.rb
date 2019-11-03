class TagPermissionRule < ActiveRecord::Base
  acts_as_ordered_taggable
  validates :name, :presence => true, :uniqueness => true
  validates :role_id, :presence => true

  belongs_to :role
  after_save :update_prohibited

  has_many :prohibited_issues, dependent: :delete_all

  def issue_scope
    options = tag_not ? { :exclude => true, :wild => false } : { wild: false}
    Issue.tagged_with([ tag ], options)
  end

  def members_scope
    base = Member.joins(:member_roles)

    if !role_not
      base.where(member_roles: { role_id: self.role_id })
    else
      base.where('member_roles.role_id <> ?', self.role_id)
    end
  end

  def scope
    issue_scope
      .select("#{Issue.table_name}.*, #{Member.table_name}.user_id as membership_user_id")
      .joins(project: {memberships: :member_roles})
      .merge(members_scope)
  end

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

  def update_prohibited
    self.prohibited_issues.delete_all
    update_scope scope
  end

  def update_scope(scope)
    scope.each do |issue|
      pi         = self.prohibited_issues.new
      pi.issue   = issue
      pi.user_id = issue.membership_user_id
      pi.save
    end
  end

  # when issue's tags change
  # some permission rules may begin (or stop) to apply

  def self.update_prohibited_for_issue(issue)
    # return unless issue.tag_list_changed?
    issue.prohibited_issues.delete_all

    all.each do |rule|
      scope = rule.scope.where(issues: {id: issue.id})

      if scope.exists?
        rule.update_scope(scope)
      end
    end
  end

  # when we add or destroy a role to some member, 
  # some permission rules may begin (or stop) to apply
  
  def self.update_prohibited_for_member_role(member_role)
    ProhibitedIssue.where(user_id: member_role.member.user_id).delete_all

    all.each do |rule|
      scope = rule.scope.where(members: { id: member_role.member_id })

      if scope.exists?
        rule.update_scope(scope)
      end
    end
  end
end
