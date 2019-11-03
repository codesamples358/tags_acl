module TagsAcl
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)

        base.singleton_class.class_eval do
          alias_method :visible_condition_without_acl_tags, :visible_condition
          alias_method :visible_condition, :visible_condition_with_acl_tags
        end


        base.send(:include, InstanceMethods)

        pi_table = ProhibitedIssue.table_name

        base.class_eval do
          default_scope { 
            joins("LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{self.table_name}.id AND #{pi_table}.user_id = #{User.current.id}")
            # .where("#{pi_table}.id IS NULL")
          }

          alias_method :visible_without_acl_tags?, :visible?
          alias_method :visible?, :visible_with_acl_tags?

          has_many :prohibited_issues, dependent: :delete_all
          after_save :update_prohibited
        end
      end

      module ClassMethods
        def visible_condition_with_acl_tags(user, options={})
          sql = visible_condition_without_acl_tags(user, options)

          "((#{sql}) AND prohibited_issues.id IS NULL)"
        end
      end

      module InstanceMethods
        def visible_with_acl_tags?(user = nil)
          user ||= User.current
          all_rules = TagPermissionRule.all

          forbidden = TagPermissionRule.forbid?(user, self)
          return false if forbidden

          visible_without_acl_tags?(user)
        end

        def update_prohibited
          TagPermissionRule.update_prohibited_for_issue(self)
        end
      end
    end
  end
end

base = Issue
patch = TagsAcl::Patches::IssuePatch
base.send(:include, patch) unless base.included_modules.include?(patch)
