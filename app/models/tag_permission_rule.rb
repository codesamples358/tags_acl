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
