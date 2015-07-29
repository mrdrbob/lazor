{ always-new, char, simple, any, $or, then-keep, then-ignore, then-array-concat, as-array, many, maybe, except, text, join-string, at-least-once, map, as-object-with-value, then-set, with-error-message, delay, convert-rule-to-function, fail } = require 'parse-ls'

# Characters
space = char ' '
tab = char '\t'
cr = char '\r'
lf = char '\n'
angle-open = char '<'
angle-close = char '>'
minus = char '-'
plus = char '+'
underscore = char '_'
dquote = char '"'
squote = char "'"
paren-open = char '('
paren-close = char ')'
square-open = char '['
square-close = char ']'
bracket-open = char '{'
bracket-close = char '}'
exclamation = char '!'
dot = char '.'
comma = char ','
semi = char ';'
question = char '?'
colon = char ':'
star = char '*'
bslash = char '\\'
fslash = char '/'
percent = char '%'
eq = char '='
at = char '@'
pound = char '#'

# Character classifications
ws = space |> $or tab |> $or cr |> $or lf
digit = (simple -> it >= \0 and it <= \9) |> with-error-message 'expected a digit'
lower = (simple -> it >= \a and it <= \z) |> with-error-message 'lowercase letter'
upper = (simple -> it >= \A and it <= \Z) |> with-error-message 'uppercase letter'
letter = upper |> $or lower

ident-first-char = (underscore |> $or letter |> $or minus)
ident-other-char = (ident-first-char |> $or digit)
identifier = 
	ident-first-char
	|> as-array
	|> then-array-concat (ident-other-char |> many)
	|> join-string

# Ignore ws
eat-ws = (rule) -> rule |> then-ignore (ws |> many)
eat-req-ws = (rule) -> rule |> then-ignore (ws |> at-least-once)

# Helper functions
create-list = (item-type, separator) ->
	# Let's go full crazy and make all separators optional.
	item = item-type 
		|> eat-ws 
		|> then-ignore (separator |> many)
		|> eat-ws

	item |> many

build-quoted-string-parser = (quote, escape) ->
	escapable = quote |> $or escape
	escaped-character = escape |> then-keep escapable
	unescaped-character = any! |> except escapable
	valid-character = escaped-character |> $or unescaped-character
	inner-content = valid-character |> many |> join-string

	quote
		|> then-keep inner-content
		|> then-ignore quote

build-binary-expression = (previous-rule, operator) ->
	right-side =
		always-new -> { }
		|> then-set \type, operator
		|> eat-req-ws
		|> then-set \value, previous-rule
		|> eat-ws

	always-new -> { type: \binary }
		|> then-set \left, previous-rule
		|> eat-ws
		|> then-set \right, (right-side |> many)
		|> map -> if it.right.length == 0 then it.left else it

build-conditional-part = (expression, statement, type) -->
	always-new -> { type: type }
	|> then-ignore (text  type)
	|> eat-ws
	|> then-ignore paren-open
	|> eat-ws
	|> then-set \condition, expression
	|> eat-ws
	|> then-ignore paren-close
	|> eat-ws
	|> then-set \value, statement
	|> eat-ws

$not = (rule) -> (any! |> except rule) |> at-least-once |> join-string
consume-until = (rule) -> ($not rule) |> then-ignore rule

module.exports = { space, tab, cr, lf, angle-open, angle-close, minus, plus, underscore, dquote, squote, paren-open, paren-close, square-open, square-close, bracket-open, bracket-close, exclamation, dot, comma, semi, question, colon, star, bslash, fslash, percent, eq, at, pound, ws, digit, lower, upper, letter, identifier, eat-ws, eat-req-ws, $not, consume-until, create-list, build-quoted-string-parser, build-binary-expression, build-conditional-part }
