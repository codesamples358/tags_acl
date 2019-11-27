task :check_task_acl => :environment do
  TagPermissionRule.check
end