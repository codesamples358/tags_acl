task :check_tags_acl => :environment do
  TagPermissionRule.check
end