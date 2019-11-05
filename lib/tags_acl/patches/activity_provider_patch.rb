module TagsAcl
  module Patches
    module ActivityProviderPatch
      def self.included(base)
        base.include(ModuleMethods)

        base.module_eval do
          alias_method :find_events_without_tags_acl, :find_events
          alias_method :find_events, :find_events_with_tags_acl
        end
      end

      module ModuleMethods
        def find_events_with_tags_acl(event_type, user, from, to, options)
          if event_type == "issues"
            pi_table = ProhibitedIssue.table_name
            p_options = self.activity_provider_options["issues"]

            if !@__default_activity_scope
              @__default_activity_scope = p_options[:scope]
            end

            p_options[:scope] = @__default_activity_scope.joins("LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{Issue.table_name}.id AND #{pi_table}.user_id = #{User.current.id}")
          end

          find_events_without_tags_acl(event_type, user, from, to, options)
        end
      end
    end
  end
end

base = Redmine::Acts::ActivityProvider::InstanceMethods::ClassMethods
patch = TagsAcl::Patches::ActivityProviderPatch
base.send(:include, patch) unless base.included_modules.include?(patch)
