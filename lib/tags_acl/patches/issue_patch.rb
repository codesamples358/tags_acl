module TagsAcl
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)

        base.singleton_class.class_eval do
          alias_method :visible_condition_without_acl_tags, :visible_condition
          alias_method :visible_condition, :visible_condition_with_acl_tags


          alias_method :load_visible_relations_without_acl_tags, :load_visible_relations
          alias_method :load_visible_relations, :load_visible_relations_with_acl_tags

        end

        pi_table = ProhibitedIssue.table_name

        base.class_eval do
          scope_before = method(:visible).to_proc

          scope :visible, lambda {|*args|
            current_scope = scope_before.call(*args)

            unless current_scope.to_sql.include?("LEFT OUTER JOIN #{pi_table}")
              current_scope.joins("LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{self.table_name}.id AND #{pi_table}.user_id = #{User.current.id}")
            else
              current_scope
            end
            
          }
        end

        base.send(:include, InstanceMethods)

        base.class_eval do
          # default_scope { 
          #   migrated = User.columns.map(&:name).include?('identity_url')

          #   if migrated # && User.current.logged?
          #     joins("LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{self.table_name}.id AND #{pi_table}.user_id = #{User.current.id}")
          #   else
          #     where("1=1")
          #   end
          # }

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

        def load_visible_relations_with_acl_tags(*args)
          IssueRelation._joining_prohibited_issues { 
            load_visible_relations_without_acl_tags(*args) 
          }
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
