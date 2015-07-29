Lazor
=====

Lazor is yet another view engine for Javascript.  It's inspired by ASP.NET's Razor view engine and has similar semantics.  It's written in LiveScript and intended for use on the server-side with Node.

> DISCLAIMER: I made this as a learning exercise. As such, Lazor is beta quality and may not be suitable for production code.  Use at your own risk.

Getting Started
---------------

Take a look at this simple simple example:

```
// in app.js
var view = require('./src/lazor')('./example/views', './example/temp');

var model = {
	terms: 'about & stuff',
	searchResults: [
		{ url: '/about', name: 'About Us', summary: '<p>The <em>about</em> us page!</p>' },
		{ url: '/', name: 'Home Page', summary: '<p>Find out <em>about</em> our homepage!</p>' }
	]
};

var result = view('~/sample.lz.html', model);

console.log(result);
```

```
<!-- in sample.lz.html -->
@{
	layout = "~/sample.template.lz.html";
	viewState.title = "Search Results";
}

@section welcome {
	<h1>Search Results</h1>
}

<p>Your search for for <a href="/search/?q=@uri(model.terms)">@model.terms</a> resulted in @(model.searchResults.length) results:</p>

<div class="results">
	@for (result in model.searchResults) {
		partial('~/result.lz.html', result);
	}
</div>
```

```
<!-- in result.lz.html -->
<div class="result">
	<h2><a href="@model.url">@model.name</a></h2>
	<div class="summary">@raw(model.summary)</div>
</div>
```

```
<!-- In sample.template.lz.html -->
<!DOCTYPE html>
<html>
	<head>
		<title>@(viewState.pageName || 'Welcome!')</title>
	</head>
	<body>

	@render('welcome')

	@body()

	@render('footer', () -> <div class="footer">&copy; 2015</div>)

	</body>
</html>
```

Why Would I Use This?
---------------------

While this was written primarily as an academic exercise, it does offer a few advantages to other Razor-inspired view engines.  Namely:

* It has a full parser (instead of a regex-based parser), and is not confused by things like: `@raw("Hi :)")`
* It HTML-encodes everything by default.  You have to explicitly declare that something should not be HTML-encoded (by wrapping in a `raw()` call).
* Supports a very razor-like syntax for using layouts, helpers, and sections.
* Templates are compiled into javascript and cached.  A template is only ever parsed once during the lifetime of an application.

There are Caveats
-----------------

* Lazor is sometimes very "un-node", for example, during the transpile phrase, it reads templates and writes transpiled javascript synchronously.  This may be remedied in the future.
* Lazor does some not-so-effecient things, such as loading templates entirely into memory, buffering all output into memory, lots of string concatination.
* The HTML parser is far stricter than a normal HTML 5 parser.  Your HTML must be very well formed.
* Not everything supported by javascript is supported by the scripting language parser.
* The view engine does not pick up changes made to templates in real time (the application must be restarted).
* This was written by one guy in his free time, and may not be -- most certainly is not -- bug free.

How it Works
------------

Lazor has it's own language and parser.  The language itself is contextual; it has an HTML context and a scripting context.  When a view is processed, Lazor reads the template, parses it to an abstract syntax tree, transpiles that tree into javascript, writes the javascript to a temp directory, and then `require`s it as a node module.  Subsequent requests for that template use the cached javascript.

**HTML Context**

Inside an HTML context, tags and normal blocks of text are recognized.  Every Lazor template begins in an HTML context.

Tags are actually parsed and stored in a dom-like structure, so your HTML must be well-formed.  The Lazor parser is quite a bit stricter than an HTML 5 parser.

```html
<!-- This is fine -->
<head lang="en">
  <title>Example</title>
  <link rel="stylesheet" href="/styles/core.css" />
</head>

<!-- This will fail. -->
<head lang=en> <!-- Attributes must be quoted -->
  <title>Example</title>
  <link rel="stylesheet" href="/styles/core.css"> <!-- Self-closing tags must be explicity closed -->
</head>
```

You switch from an HTML context to a scripting context with an `@` symbol.  You escape an `@` symbol with another `@` symbol.  For example:

```html
<p>@username, please email info@@example.com for help</p>
```

The first `@` enters a scripting context and outputs a username variable, while the email address gets rendered as info@example.com.

From an HTML context, simple expressions can be embedded directly:

```html
<p>Hello @username, your city is: @data["city_name"](username).</p>
<p>Have a nice day. @raw("<b>:)</b>")!</p>
```

More complex expressions must be wrapped in parentheses:

```html
<p>There are @(7 - today.dayOfWeek) days left in this week.</p>
```

Blocks of code are entered with curly braces.

```
@{
	var title = 'Hello';
}
```

All output from scripting context is HTML-encoded unless it is wrapped in a `raw` function call.

HTML comments are stripped from the page output.

**Scripting Context**

Lazor's scripting language is a JavaScript-like syntax, but is not JavaScript.  There are a few major differences (some of which may change in subsequent releases):

* There is no `new` keyword.  Lazor is built around simple literals, including strings, integers, arrays, and objects.  There is no concept of prototyping.
* There is no `function` keyword.  In Lazor, all functions are declared as variables using a lambda syntax.  For example: `var wrapH1 = (name) -> <h1>@name</h1>;` declares a function called wrapH1 that accepts a name variable.
* There is no `return` keyword.
* Separators are technically optional - though recommended.  `t = [3, 4, 5]; t.push(6);` and `t = [3 4 5] t.push(6)` parse to the exact same thing.
* The conditional operator is not support (`condition ? result1 : result2`) -- this may be supported in the future.
* Parsing floating point numbers is not yet support - This is on the roadmap.
* No support for comments yet - This is also on the roadmap.

For loops are slightly different:

* There is no `for (var x = 0; x < source.length; x++) { }` form.
* You can loop through an array: `for(link in navigation) { ouptputNavLink(link); }`
* You can loop through an object: `for(key of keyValuePairs) { <div>@key = @keyValuePairs[key]</div> }`
* For all other loops, use `while`

You jump back into an HTML context simply by embedding a tag.  If you want to embed some text without using a tag, use a `text` tag, which will put you in HTML context without actually outputing a container tag.  For example:

```
@for(day in days) {
  day = day.toUpperCase();

  <text> | HAPPY @day!</text>
}
```

Roadmap
=======

Things to fix or add, in no particular order:

* Suport for parsing floats
* Support for some kind of simple string interpolation
* Support for recognizing common self-closing tags, and ignoring the fact that they are not explicitly self-closed.
* A for loop syntax for looping through a range
* Comments support inside a scripting context.
* Async support
* Add ability for view engine to detect template changes and automatically recompile
* Write tests for the transpiler
* Possibly support for something like `_ViewStart.cshtml` from Razor for setting global defaults.
