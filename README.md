# Cutaneous

**Cutaneous** _adj._ Of the skin.

Cutaneous is a Ruby (1.9+) templating engine designed for flexibility and simplicity.

It supports having multiple output formats, multiple syntaxes and borrows a template inheritance mechanism from Python template engines such as  [Django's](https://docs.djangoproject.com/en/dev/topics/templates/), [Jinja](http://jinja.pocoo.org/) and [Mako](http://www.makotemplates.org/).

Cutaneous is the template engine designed for and used by [Spontaneous CMS](http://spontaneouscms.org).

## Quickstart

<script src="https://gist.github.com/3169319.js"> </script>

<script src="https://gist.github.com/3169327.js"> </script>

The `Cutaneous::Engine` class provides two core methods:

- `Cutaneous::Engine#render(template_path, context, format)`  
  
  This renders the template at `template_path` using the context `context` (which must be an instance of Cutaneous::Context (or a subclass)) and the format `format`.
  
  `template_path` should be specified as either a relative path which will be resolved using a search through the template roots specified in the engine's initialisation call. See below for more information about how templates are specified & resolved.
  
- `Cutaneous::Engine#render_string(template, context, format)`  
  
  This takes the input string as the template and renders it. If this string references other templates through includes (see below) these are resolved as if you had made a call to `Engine#render`.

### Template Naming & Resolution

By default Cutaneous templates should be given a `.cut` file extension.

Cutaneous generally relies upon relative template names. If we consider the following code:

```ruby

engine  = Cutaneous::Engine.new([
	"/home/user/templates",
	"/home/user/shared_templates"
])

context = Cutaneous::Context.new(Object.new, title: "Welcome")

result  = engine.render("welcome", context, "html")
```

The `#render` call will look for a file called `welcome.html.cut` under each of the supplied template roots & return the first one it finds:

```ruby

# The template resolution is equivalent to the following Ruby code:
search_paths =  [
	"/home/user/templates/welcome.html.cut",
	"/home/user/shared_templates/welcome.html.cut"
]

template_path = search_paths.detect { |path| File.exist?(path) }

```

Template filenames are derived from `[template_relative_path, format, "cut"].join(".")`.

If you specified a different format for the render call, e.g. `engine.render("welcome", context, "txt")` then the engine would instead look for a file named `welcome.txt.cut`.

If you want to organise your templates into subdirectories then you are completely free to do so, you just need to add the subdirectory name onto the relative path:

```ruby
    
result  = engine.render("layouts/welcome", context, "html")

#=> Renders the file "/home/user/templates/layouts/welcome.html.cut"
```

#### Includes

To include one template file into another you use the `include` directive within your template:

    %{ include 'partial/header' }

This will include the output of rendering the file "/home/user/templates/partial/header.html.cut" directly in your original template's output (assuming you're rendering the "html" format).

Note that Cutaneous has no special treatment of "partials", there is no special `partial` command and no preceeding underscore in the template name.

#### Passing a Proc as a Template

If you want to switch between rendering file based & string based templates then Cutaneous provides a way of using the same `Engine#render` call by passing a Proc as the template path:

```ruby

# This
template = "Hello ${ name }!"
engine.render(Proc.new { template }, context)

# is the same as:
engine.render_string(template, context)

```

This allows us to use simple strings as template paths and still use a consistent calling mechanism.


## Features

### Template Inheritance

Cutaneous features a block based template inheritance mechanism.

Including a `%{ extends "parent" }` tag at the start of a template
makes it inherit from the named template ("parent" in this case).

Parent templates define a series of blocks using a `%{ block :block_name}
... %{ endblock}` syntax. Child templates can then override any of
these individual blocks with their own content.

Calling `%{ blocksuper }` within a child template's block allows you
to insert the code from the parent template (much like calling `super`
in an object subclass).

So for example using the following templates:

<script src="https://gist.github.com/3169196.js"> </script>

<script src="https://gist.github.com/3169203.js"> </script>

`engine.render("child", context, "html")` would result in the following output:


    Title

    Template inheritance is great!
    Template inheritance is great!

    Do it like this...

    And like this...

The template hierarchy can be as long as you need/like. Template 'd' could extend 'c' which extends 'b' which extends 'a' etc..



### Formats

Cutaneous allows templates for multiple formats to exist alongside each other. In the examples above the `html` format is exclsuively used but instead of this I could render the same template as `txt`

    result = engine.render("quickstart", context, "txt")

This would look for a `quickstart.txt.cut` template under the template roots. The format used is maintained across both `include` and `extend` calls so when using these you should reference them without any extension.

If your standard format isn't "html" then you can set a new default when creating your template engine instance:

    engine = Cutaneous::Engine.new("/template/root", Cutaneous::FirstPassSyntax, "txt")


### Whitespace

If you want to remove trailing whitespace after a tag, then suffix it with a `-` character, e.g.

    %{ include "something" -}

### Caching

If you create an instance of `Cutaneous::CachingEngine` instead of the default `Engine` class then the compiled templates will be cached in-memory for the lifetime of the engine. In order to render templates Cutaneous converts them to simple Ruby code. As part of the caching this generated code will be written to disk alongside the original template with the extension `.format.rb`.

If you want to turn off the writing of the compiled Ruby files (such as in a development environment), set `write_compiled_scripts` to false:

    engine.write_compiled_scripts = false

The cached ruby will only be used if it is fresher than the template it was compiled from so updating the template will re-write the `.rb` equivalent.


### Syntaxes

Cutaneous supports the concept of syntaxes. This is used by Spontaneous to provide a two-stage rendering process (first-pass templates output second-pass templates which are rendered on demand -- in this way you can create a very responsive dynamic site because you have precached 99% of the page).

The two syntaxes are:

#### First-pass

- Statements: `%{ ruby code... }`
- Expressions: `${ value }`
- Escaped expressions: `$${ unsafe value }`
- Comments: `!{ comment... }`

#### Second-pass

- Statements: `{% ruby code... %}`
- Expressions: `{{ value }}`
- Escaped expressions: `{$ unsafe value $}`
- Comments: `!{ comment... }`

You choose which one of these you wish to use when you create your `Cutaneous::Engine` instance:

    engine = Cutaneous::Engine.new("/template/root", Cutaneous::SecondPassSyntax)

## Contexts

Cutaneous doesn't try to remove code from your templates it instead allows you to write as much Ruby as you want directly in-place. This is done in order to make the development of your front-end code as quick as possible. If you later want to clean up your template code you can instead use helper methods either on the context you pass to the renderer or the object you wrap that context around.

If you want to add features to your context, or `helpers` as they would be known in Rails-land then create a new Context class and include your helper methods there:

```ruby

module MyHelperMethods
 def my_helpful_method
	 # ... do something complex that you want to keep out of the template
 end
end

# You *must* inherit from Cutaneous::Context!
class MyContext < Cutaneous::Context
	include MyHelperMethods
end

context = MyContext.new(instance, parameter: "value")

result  = engine.render("template", context)
```

### Errors

Cutaneous silently swallows errors about missing expressions in templates. If you want to instead report these errors override the `__handle_error` context method:

```ruby
class MyContext < Cutaneous::Context
	def __handle_error(e)
		logger.warn(e)
	end
end
```

Cutaneous will do its best to keep the line numbers consistent between templates and the generated code (although see "Bugs" below...). This will hopefully make debugging easier.

## Bugs/TODO

- Make the Syntax more powerful and capable of dealing with any syntax (e.g. implement an ERB like syntax). At the moment they only deal with brace-based syntaxes and brace counting is built into the Lexer.
- Using template inheritance messes up the line numbers of errors... Not sure what to do about that...

## License

Cutaneous is released under an MIT license (see LICENSE).
