require 'tags_acl'

ActiveSupport::Reloader.to_prepare do
  paths = '/lib/tags_acl/{patches/*_patch,hooks/*_hook}.rb'

  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end
end

Redmine::Plugin.register :tags_acl do
  name 'Tags Acl plugin'
  author 'Alexander Podgorbunskiy'
  description 'Access control based on tags and roles'
  version '0.0.1'
  # url 'http://example.com/path/to/plugin'
  # author_url 'http://example.com/about'

  requires_redmine version_or_higher: '4.0.0'

  settings \
    default:  {
      issues_sidebar:    'none',
      issues_show_count: 0,
      issues_open_only:  0,
      issues_sort_by:    'name',
      issues_sort_order: 'asc'
    },

    partial: 'tags_acl/settings'
end
