module TagsAcl
  module Patches
    module IssueRelationPatch
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def _joining_prohibited_issues(&block)
          @_join_pi = true
          block.call
          @_join_pi = false
        end

        def joins(*args)
          pi_table = ProhibitedIssue.table_name

          if self == IssueRelation && @_join_pi
            super("LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{Issue.table_name}.id AND #{pi_table}.user_id = #{User.current.id}").
              joins(*args)
          else
            super(*args)
          end
        end
      end
    end
  end
end

base = IssueRelation
patch = TagsAcl::Patches::IssueRelationPatch
base.send(:include, patch) unless base.included_modules.include?(patch)
