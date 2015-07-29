{ always-new, char, simple, any, $or, then-keep, then-ignore, then-array-concat, as-array, many, maybe, except, text, join-string, at-least-once, map, as-object-with-value, then-set, with-error-message, delay, convert-rule-to-function, fail } = require 'parse-ls'

{ space, tab, cr, lf, minus, plus, underscore, dquote, squote, paren-open, paren-close, square-open, square-close, bracket-open, bracket-close, exclamation, dot, comma, semi, question, colon, star, bslash, fslash, percent, eq, ws, digit, lower, upper, letter, identifier, eat-ws, eat-req-ws, create-list, build-quoted-string-parser, build-binary-expression } = require './parser-utilities'


module.exports = (statement = null) ->

	if (!statement)
		statement = (input) -> fail 'Unexpected input', input

	# Top-level rule, with lists
	expression-resolved = null
	expression = delay -> expression-resolved

	expression-list = create-list expression, comma
	identifier-list = create-list identifier, comma

	# Identifiers
	double-quoted-string = build-quoted-string-parser dquote, bslash
	single-quoted-string = build-quoted-string-parser squote, bslash
	quoted-string = double-quoted-string |> $or single-quoted-string

	integer = digit |> at-least-once |> join-string |> map -> parse-int it, 10
	boolean = (text 'true' |> map -> true) |> $or (text 'false' |> map -> false)

	integer-literal = integer |> map -> { type: \integer-literal, value: it }
	string-literal = quoted-string |> map -> { type: \string-literal, value: it }
	boolean-literal = boolean |> map -> { type: \boolean-literal, value: it }
	identifier-literal = identifier |> map -> { type: \identifier, value: it }
	nill-literal = (text 'null') |> map -> { type: \null-literal }

	# Complex literals
	array-literal = 
		always-new -> { type: \array-literal }
		|> then-ignore square-open
		|> eat-ws
		|> then-set \value, expression-list
		|> eat-ws
		|> then-ignore square-close

	key-value-pair = 
		always-new -> { }
		|> then-set \key, (identifier |> $or quoted-string)
		|> eat-ws
		|> then-ignore colon
		|> eat-ws
		|> then-set \value, expression
		|> eat-ws

	kvp-list = create-list key-value-pair, comma

	object-literal = 
		bracket-open
		|> eat-ws
		|> then-keep kvp-list
		|> eat-ws
		|> then-ignore bracket-close
		|> map ->
			res = { type: \object-literal, value: { } }
			for kvp in it
				res.value[kvp.key] = kvp.value
			res

	argument-list = paren-open
		|> eat-ws
		|> then-keep identifier-list
		|> eat-ws
		|> then-ignore paren-close


	lambda = 
		always-new -> { type: \lambda }
		|> then-set \arguments, argument-list
		|> eat-ws
		|> then-ignore (text '->')
		|> eat-ws
		|> then-set \value, statement

	group = 
		paren-open
		|> eat-ws
		|> then-keep expression
		|> eat-ws
		|> then-ignore paren-close

	term = 
		nill-literal
		|> $or boolean-literal
		|> $or array-literal
		|> $or object-literal
		|> $or identifier-literal
		|> $or string-literal
		|> $or integer-literal
		|> $or lambda
		|> $or group

	# !
	negate =
		always-new -> { }
		|> then-set \type, (exclamation |> many |> map -> if it.length % 2 == 0 then \nop else \negate )
		|> then-set \value, term
		|> map -> if (it.type == \nop) then it.value else it

	# -
	negative =
		always-new -> { }
		|> then-set \type, (minus |> many |> map -> if it.length % 2 == 0 then \nop else \negative)
		|> then-set \value, negate
		|> map -> if (it.type == \nop) then it.value else it

	# Methods (direct property, index, and method calling)
	direct-access = 
		always-new -> { type: \property }
		|> then-ignore dot
		|> then-set \value, identifier

	indexed-access = 
		always-new -> { type: \index }
		|> then-ignore square-open
		|> eat-ws
		|> then-set \value, expression
		|> eat-ws
		|> then-ignore square-close

	function-call = 
		always-new -> { type: \call }
		|> then-ignore paren-open
		|> eat-ws
		|> then-set \value, expression-list
		|> eat-ws
		|> then-ignore paren-close

	method-call = 
		always-new -> { type: \binary }
		|> then-set \left, negative
		|> then-set \right, ((direct-access |> $or indexed-access |> $or function-call) |> many)
		|> map -> if it.right.length == 0 then it.left else it

	# Arithmetic
	multiplication = build-binary-expression method-call, (star |> $or fslash |> $or percent)
	addition = build-binary-expression multiplication, (plus |> $or minus)

	# Comparisons
	valid-comparisons = 
		text '=='
		|> $or (text '===')
		|> $or (text '!=')
		|> $or (text '!==')
		|> $or (text '>=')
		|> $or (text '<=')
		|> $or (text '>')
		|> $or (text '<')

	comparison = build-binary-expression addition, valid-comparisons

	logic = build-binary-expression comparison, ((text '||') |> $or (text '&&'))

	assignment = build-binary-expression logic, (text '=')

	expression-resolved = assignment

	{ expression, integer-literal, string-literal, boolean-literal, identifier-literal, nill-literal, array-literal, object-literal, group, argument-list, method-call }
