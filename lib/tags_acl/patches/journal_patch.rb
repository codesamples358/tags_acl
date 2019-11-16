module TagsAcl
  module Patches
    module JournalPatch
      def self.included(base)
        pi_table = ProhibitedIssue.table_name

        base.class_eval do
          # alias_method :visible_without_acl_tags, :visible
          scope_before = method(:visible).to_proc

          scope :visible, lambda {|*args|
            scope_before.call(*args).
              joins("LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{Issue.table_name}.id AND #{pi_table}.user_id = #{User.current.id}")
          }
        end
      end
    end
  end
end

base = Journal
patch = TagsAcl::Patches::JournalPatch
base.send(:include, patch) unless base.included_modules.include?(patch)
