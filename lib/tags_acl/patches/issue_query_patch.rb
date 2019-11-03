module TagsAcl
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :joins_for_order_statement_without_tags_acl, :joins_for_order_statement
          alias_method :joins_for_order_statement, :joins_for_order_statement_with_tags_acl
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def joins_for_order_statement_with_tags_acl(order_options)
          joins = [ joins_for_order_statement_without_tags_acl(order_options) ]

          pi_table = ProhibitedIssue.table_name

          if User.current.logged?
            joins << "LEFT OUTER JOIN #{pi_table} ON #{pi_table}.issue_id = #{queried_table_name}.id AND #{pi_table}.user_id = #{User.current.id}"
          end

          joins.any? ? joins.compact.join(' ') : nil
        end
      end
    end
  end
end

base  = IssueQuery
patch = TagsAcl::Patches::IssueQueryPatch
# base.send(:include, patch) unless base.included_modules.include?(patch)
