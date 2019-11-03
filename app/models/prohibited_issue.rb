class ProhibitedIssue < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user
  belongs_to :tag_permission_rule
end
