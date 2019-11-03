module TagsAcl
  module Patches
    module MemberPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          after_create  :update_prohibited
          after_destroy :update_prohibited
        end
      end

      module InstanceMethods
        def update_prohibited
          TagPermissionRule.update_prohibited_for_user(self.user)
        end
      end
    end
  end
end

base = Member
patch = TagsAcl::Patches::MemberPatch
# base.send(:include, patch) unless base.included_modules.include?(patch)
