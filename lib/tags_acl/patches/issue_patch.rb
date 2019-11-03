module TagsAcl
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)

        base.singleton_class.class_eval do
          # alias_method :visible_condition_without_acl_tags, :visible_condition
          # alias_method :visible_condition, :visible_condition_with_acl_tags
        end


        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :visible_without_acl_tags?, :visible?
          alias_method :visible?, :visible_with_acl_tags?
        end
      end

      module ClassMethods
        def visible_condition_with_acl_tags(user, options={})

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
      end
    end
  end
end

base = Issue
patch = TagsAcl::Patches::IssuePatch
base.send(:include, patch) unless base.included_modules.include?(patch)
