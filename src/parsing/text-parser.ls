{ always-new, char, simple, any, $or, then-keep, then-ignore, then-array-concat, as-array, many, maybe, except, text, join-string, at-least-once, map, as-object-with-value, then-set, with-error-message, delay, convert-rule-to-function, fail, input-at-eof } = require 'parse-ls'

{ space, tab, cr, lf, angle-open, angle-close, minus, plus, underscore, dquote, squote, paren-open, paren-close, square-open, square-close, bracket-open, bracket-close, exclamation, dot, comma, semi, question, colon, star, bslash, fslash, percent, eq, at, pound, ws, digit, lower, upper, letter, identifier, eat-ws, eat-req-ws, $not, consume-until } = require './parser-utilities'

module.exports = (external-rule = null) ->
	if (!external-rule)
		external-rule = (input) -> fail 'Unexpected input', input
	
	html-resolved = null
	html = delay -> html-resolved

	escaped-at = at |> then-ignore at |> map -> { type: \encoded, value: it }
	external = at |> then-keep external-rule

	body-text = $not (angle-open |> $or at) |> map -> { type: \encoded, value: it }	

	end-comment = 
		minus
		|> then-ignore minus
		|> then-ignore angle-close

	comment = angle-open
		|> then-ignore exclamation
		|> then-ignore minus
		|> then-ignore minus
		|> then-keep (consume-until end-comment)
		|> map -> { type: \comment, value: it }

	declaration = 
		angle-open
		|> then-ignore exclamation
		|> then-keep (consume-until angle-close)
		|> map -> { type: \declaration, value: it }

	# Attributes
	non-quote = $not (dquote |> $or at) |> map -> { type: \encoded, value: it }
	quoted-attribute-value = dquote
		|> then-keep ((escaped-at |> $or external |> $or non-quote) |> many)
		|> then-ignore dquote

	tag-name = 
		(digit |> $or letter |> $or minus) 
		|> at-least-once
		|> join-string

	attribute = 
		always-new -> { type: \attribute }
		|> then-set \name, tag-name
		|> then-ignore eq
		|> then-set \parts, quoted-attribute-value
		|> eat-ws

	# Tag
	tag = (input) ->
		if input-at-eof input
			return fail 'at eof', input

		open-rule = 
			always-new -> { type: \tag }
			|> then-ignore angle-open
			|> then-set \name, tag-name
			|> eat-ws
			|> then-set \parts, ((attribute |> $or (external |> eat-ws)) |> many)
			|> then-set \selfClose, (fslash |> maybe |> map -> !!it)
			|> then-ignore angle-close

		open = open-rule input

		if !open.success
			return open

		open-tag = open.value

		if open-tag.self-close
			return open

		body = html open.remaining

		open-tag.body = if body.success then body.value else []

		
		close-rule = angle-open
			|> then-ignore fslash
			|> then-keep (text open-tag.name)
			|> then-ignore angle-close

		close = close-rule (if body.success then body.remaining else open.remaining)

		if !close.success
			return close

		return do
			success: true
			value: open-tag
			remaining: close.remaining

	element = escaped-at
		|> $or external
		|> $or tag
		|> $or comment
		|> $or declaration
		|> $or body-text

	html-resolved = element |> at-least-once

	{ element, declaration, comment, tag, html }