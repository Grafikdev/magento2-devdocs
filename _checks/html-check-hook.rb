# The hook runs html-proofer with options defined in the
#  _config.checks.yml file
#
# For more details about html-proofer, refer to: https://github.com/gjtorikian/html-proofer
# For more details about Jekyll hooks, refer to: https://jekyllrb.com/docs/plugins/hooks/
#
require 'html-proofer'
require 'yaml'
require 'erb'
require_relative '../rakelib/lib/double-slash-check.rb'

Jekyll::Hooks.register :site, :post_write do |site|
  # Do nothing unless 'site.check_links' is set
  next unless site.config['check_links']

  # Do not exit when html-proofer raises an error
  begin
    # Check 'url_ignore' in '_config.checks.yml'
    # and add 'excludes' from Jekyll configurtiuon.
    #
    template = ERB.new File.read '_config.checks.yml.erb'
    checks_config = YAML.safe_load template.result(binding), permitted_classes: [Symbol, Regexp]
    url_ignore = checks_config.dig('html-proofer', :url_ignore)
    jekyll_excludes = site.config['exclude']
    jekyll_excludes_as_regex = jekyll_excludes.map { |item| Regexp.new Regexp.escape(item) }

    if url_ignore
      url_ignore.push(jekyll_excludes_as_regex).flatten!.uniq!
    else
      checks_config['html-proofer'].merge!({ url_ignore: jekyll_excludes_as_regex })
    end

    # Read configuration options for html-proofer
    options = checks_config['html-proofer']

    # Run html-proofer to check the jekyll destination directory
    HTMLProofer.check_directory(site.dest, options).run

  # Show the message when html-proofer fails.
  # Expected that it fails when it finds broken links.
  rescue StandardError => msg
    puts msg
    puts 'Fix the broken links before you push the changes to remote branch.'.blue
  end
end
