module TagsAcl
  module Patches
    module MemberRolePatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          after_create  :update_prohibited
          after_destroy :update_prohibited
        end
      end

      module InstanceMethods
        def update_prohibited
          TagPermissionRule.update_prohibited_for_member_role(self)
        end
      end
    end
  end
end

base = MemberRole
patch = TagsAcl::Patches::MemberRolePatch
base.send(:include, patch) unless base.included_modules.include?(patch)
