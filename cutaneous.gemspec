## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'
  s.required_ruby_version = ">= 1.9.2"

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'cutaneous'
  s.version           = '0.1.4'
  s.date              = '2013-08-17'
  s.rubyforge_project = 'cutaneous'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "A Ruby templating language with Django style template inheritance"
  s.description = "Cutaneous is the Ruby templating language designed for " \
    "use with Spontaneous CMS. It has a simple syntax but powerful " \
    "features such as Djano style template inheritance through blocks."

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ["Garry Hill"]
  s.email    = 'garry@magnetised.net'
  s.homepage = 'https://github.com/SpontaneousCMS/cutaneous'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  ## If your gem includes any executables, list them here.
  # s.executables = ["name"]

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md LICENSE]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  # s.add_dependency('DEPNAME', [">= 1.1.0", "< 2.0.0"])

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  # s.add_development_dependency('DEVDEPNAME', [">= 1.1.0", "< 2.0.0"])

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE
    README.md
    Rakefile
    cutaneous.gemspec
    lib/cutaneous.rb
    lib/cutaneous/compiler.rb
    lib/cutaneous/compiler/expression.rb
    lib/cutaneous/context.rb
    lib/cutaneous/engine.rb
    lib/cutaneous/lexer.rb
    lib/cutaneous/loader.rb
    lib/cutaneous/syntax.rb
    lib/cutaneous/template.rb
    test/fixtures/a.html.cut
    test/fixtures/b.html.cut
    test/fixtures/c.html.cut
    test/fixtures/comments1.html.cut
    test/fixtures/comments2.html.cut
    test/fixtures/d.html.cut
    test/fixtures/e.html.cut
    test/fixtures/error.html.cut
    test/fixtures/expressions1.html.cut
    test/fixtures/expressions2.html.cut
    test/fixtures/include.html.cut
    test/fixtures/include.rss.cut
    test/fixtures/included_error.html.cut
    test/fixtures/instance.html.cut
    test/fixtures/instance_include.html.cut
    test/fixtures/locals/child.html.cut
    test/fixtures/locals/parent.html.cut
    test/fixtures/missing.html.cut
    test/fixtures/other/different.html.cut
    test/fixtures/other/error.html.cut
    test/fixtures/partial.html.cut
    test/fixtures/partial.rss.cut
    test/fixtures/render.html.cut
    test/fixtures/statements1.html.cut
    test/fixtures/statements2.html.cut
    test/fixtures/target.html.cut
    test/fixtures/whitespace1.html.cut
    test/fixtures/whitespace2.html.cut
    test/helper.rb
    test/test_blocks.rb
    test/test_cache.rb
    test/test_core.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
