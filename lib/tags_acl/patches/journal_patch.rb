module TagsAcl
  module Patches
    module JournalPatch
      def self.included(base)
        pi_table = ProhibitedIssue.table_name

        base.class_eval do
          # alias_method :visible_without_acl_tags, :visible
          scope_before = method(:visible).to_proc

          scope :visible, lambda {|*args|
            current_scope = scope_before.call(*args)

            unless current_scope.to_sql.include?("LEFT OUTER JOIN #{pi_table}")
              current_scope.joins("LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{Issue.table_name}.id AND #{pi_table}.user_id = #{User.current.id}")
            else
              current_scope
            end
          }
        end
      end
    end
  end
end

base = Journal
patch = TagsAcl::Patches::JournalPatch
base.send(:include, patch) unless base.included_modules.include?(patch)
