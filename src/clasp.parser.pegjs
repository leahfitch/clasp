{
	var recursive_join = function (parts)
	{
		var s = ''
		
		for (var i=0; i<parts.length; i++)
		{
			if (parts[i].constructor == Array)
			{
				s += recursive_join(parts[i])
			}
			else
			{
				s += parts[i]
			}
		}
		
		return s
	}
}

stylesheet = 
	charset:charset?
	imports:import*
	namespaces:namespace*
	contents:(ruleset / media / page / font_face / at_rule)*
	post:ignore*
	{
		return new clasp.model.Stylesheet(charset, imports, namespaces, contents, post)
	}

charset =
	pre:ignore* 
	sym:CHARSET_SYM 
	charset:string 
	post:ignore* 
	terminator:terminator
	{
		return new clasp.model.Charset(pre, sym, charset, post, terminator)
	}

import =
	pre:ignore*
	sym:IMPORT_SYM
	uri:(string / uri)
	media:media_list?
	terminator:terminator
	{
		return new clasp.model.Import(pre, sym, uri, media, terminator)
	}

namespace = 
	pre:ignore*
	sym:NAMESPACE_SYM
	prefix:identifier?
	uri:(string / uri)
	terminator:terminator
	{
		return new clasp.model.Namespace(pre, sym, prefix, uri, terminator)
	}
	
media =
	pre:ignore*
	sym:MEDIA_SYM
	media:media_list
	brace_open:brace_open
	rulesets:ruleset*
	brace_close:brace_close
	{
		return new clasp.model.Media(pre, sym, media, brace_open, rulesets, brace_close)
	}
	
media_list = 
	head:medium
	tail:(separator medium)*
	{
		var list = [head]
		
		for (var i=0; i<tail.length; i++)
		{
			list = list.concat(tail[i])
		}
		
		return list
	}
	
medium =
	pre:ignore*
	medium:IDENT
	{
		return new clasp.model.Medium(pre, medium)
	}

page = 
	pre:ignore*
	sym:PAGE_SYM
	identifier:identifier?
	psuedo_page:psuedo_page?
	brace_open:brace_open
	declarations:declaration_list
	brace_close:brace_close
	{
		return new clasp.model.Page(pre, sym, identifier, psuedo_page, brace_open, declarations, brace_close)
	}
	
psuedo_page =
	pre:ignore*
	prefix:':'
	value:IDENT
	{
		return new clasp.model.PsuedoPage(pre, prefix, value)
	}

font_face =
	pre:ignore*
	sym:FONT_FACE_SYM
	brace_open:brace_open
	declarations:declaration_list
	brace_close:brace_close
	{
		return new clasp.model.FontFace(pre, sym, brace_open, declarations, brace_close)
	}

at_rule = 
	keyword:at_keyword
	terms:term*
	block:(block / terminator)?
	{
		return new clasp.model.AtRule(keyword, terms, block)
	}
	
at_keyword =
	pre:ignore*
	prefix:'@'
	name:identifier
	{
		return new clasp.model.AtKeyword(pre, prefix, name)
	}
	
block =
	pre:ignore*
	brace_open:brace_open
	contents:(ruleset / at_rule / block / term / terminator)*
	brace_close:brace_close
	{
		return new clasp.model.Block(pre, brace_open, contents, brace_close)
	}

operator = 
	result:(
		ignore*
		('/' / ',')
		/
		comment*
		required_space
	)
	{
		return new clasp.model.Operator(result[0], result[1])
	}
	
combinator = 
	result:(
		ignore*
		('+' / '>')
		/
		comment*
		required_space
	)
	{
		return new clasp.model.Combinator(result[0], result[1])
	}
	
unary_operator = 
	pre:ignore*
	value:('-' / '+')
	{
		return new clasp.model.UnaryOperator(pre, value)
	}

property =
	pre:ignore*
	value:IDENT
	{
		return new clasp.model.Property(pre, value)
	}

ruleset = 
	pre:ignore*
	selectors:selector_list
	brace_open:brace_open
	declarations:declaration_list?
	brace_close:brace_close
	{
		return new clasp.model.Ruleset(pre, selectors, brace_open, declarations, brace_close)
	}
	
declaration = 
	pre:ignore*
	declaration:(
		property
		property_separator
		expr
		prio?
	)
	{
		property = declaration[0]
		separator = declaration[1]
		expression = declaration[2]
		priority = declaration[3]
		return new clasp.model.Declaration(pre, property, separator, expression, priority, '')
	}

declaration_list =
	head:declaration
	tail:(terminator declaration)*
	terminator:terminator?
	{
		var list = [head],
			last = head
		
		for (var i=0; i<tail.length; i++)
		{
			last.set_terminator(tail[i][0])
			last = tail[i][1]
			list.push(last)
		}
		
		if (terminator)
		{
			last.set_terminator(terminator)
		}
		
		return list
	}

selector_list = 
	percentage
	/
	head:selector
	tail:(separator selector)*
	{
		var list = [head]
		
		for (var i=0; i<tail.length; i++)
		{
			list = list.concat(tail[i])
		}
		
		return list
	}
	
selector = 
	head:simple_selector
	tail:( combinator simple_selector )*
	{
		var parts = [head]
		
		if (tail)
		{
			for (var i=0; i<tail.length; i++)
			{
				parts = parts.concat(tail[i])
			}
		}
		
		return new clasp.model.Selector(parts)
	}
	
simple_selector =
	head:element_name
	tail:(hash / class / attrib / psuedo)*
	{
		tail.unshift(head)
		return new clasp.model.SimpleSelector(tail) 
	}
	/
	parts:(hash / class / attrib / psuedo)+
	{
		return new clasp.model.SimpleSelector(parts)
	}
	
hash =
	pre:ignore*
	prefix:'#'
	name:name
	{
		return new clasp.model.Hash(pre, prefix, name)
	}

class =
	pre:ignore*
	prefix:'.'
	name:IDENT
	{
		return new clasp.model.ClassName(pre, prefix, name)
	}
	
element_name =
	prefix:namespace_prefix?
	name:element_identifier
	{
		return new clasp.model.ElementName(prefix, name)
	}
	
namespace_prefix =
	name:identifier?
	inter:ignore*
	combinator:'|'
	{
		return new clasp.model.NamespacePrefix(name, inter, combinator)
	}
	
element_identifier =
	pre:ignore*
	value:(IDENT / '*')
	{
		return new clasp.model.Identifier(pre, value)
	}
	
attrib =
	bracket_open:bracket_open
	identifier:identifier
	value:(attrib_operator attrib_value)?
	bracket_close:bracket_close
	{
		var value = value || [null,null]
		return new clasp.model.Attribute(bracket_open, identifier, value[0], value[1], bracket_close)
	}
	
attrib_operator =
	pre:ignore*
	value:('=' / '~=' / '|=')
	{
		return new clasp.model.AttributeOperator(pre, value)
	}
	
attrib_value = 
	pre:ignore*
	value:(identifier / string)
	{
		return new clasp.model.AttributeValue(pre, value)
	}
	
psuedo =
	pre:ignore*
	prefix:':'+
	value:(identifier / psuedo_function)
	{
		return new clasp.model.Psuedo(pre, prefix, value)
	}
	
psuedo_function = 
	name:identifier
	parameter: psuedo_parameter
	{
		return new clasp.model.PsuedoFunction(name, parameter)
	}
	
psuedo_parameter = 
	pre:ignore*
	paren_open:paren_open
	value:identifier
	paren_close:paren_close
	{
		return new clasp.model.PsuedoParameter(pre, paren_open, value, paren_close)
	}

prio =
	pre:ignore*
	sym:IMPORTANT_SYM
	{
		return new clasp.model.Priority(pre, sym)
	}

expr =
	head:term
	tail:(operator term)*
	{
		var parts = [head]
		
		for (var i=0; i<tail.length; i++)
		{
			parts = parts.concat(tail[i])
		}
		
		return new clasp.model.Expression(parts)
	}
	
term = 
	unary_operator:unary_operator?
	value:(
		percentage
		/ length
		/ ems
		/ exs
		/ angle
		/ time
		/ freq
		/ number
		/ function
	)
	{
		var unary_operator = unary_operator || ''
		return new clasp.model.Term(unary_operator, value)
	}
	/
	value:(
		  string
		/ uri
		/ unicoderange
		/ hexcolor
		/ identifier
	)
	{
		return new clasp.model.Term(null, value)
	}
	
percentage = 
	pre:ignore*
	value:NUMBER
	suffix:'%'
	{
		return new clasp.model.Percentage(pre, value, suffix)
	}
	
length = 
	pre:ignore*
	value:NUMBER
	unit:('px'/'cm'/'nm'/'in'/'pt'/'pc')
	{
		return new clasp.model.Length(pre, value, unit)
	}
	
ems = 
	pre:ignore*
	value:NUMBER
	unit:'em'
	{
		return new clasp.model.Ems(pre, value, unit)
	}
	
exs = 
	pre:ignore*
	value:NUMBER
	unit:'ex'
	{
		return new clasp.model.Exs(pre, value, unit)
	}
	
angle = 
	pre:ignore*
	value:NUMBER
	unit:('deg'/'rad'/'grad')
	{
		return new clasp.model.Angle(pre, value, unit)
	}
	
time = 
	pre:ignore*
	value:NUMBER
	unit:('s'/'ms')
	{
		return new clasp.model.Time(pre, value, unit)
	}
	
freq = 
	pre:ignore*
	value:NUMBER
	unit:('Hz'/'kHz')
	{
		return new clasp.model.Frequency(pre, value, unit)
	}
	
number = 
	pre:ignore*
	value:NUMBER
	{
		return new clasp.model.Number(pre, value)
	}
	
function =
	name:identifier
	paren_open:paren_open
	expr:expr
	paren_close:paren_close
	{
		return new clasp.model.Function(name, paren_open, expr, paren_close)
	}

string = string_1 / string_2
	
string_1 =
	pre:ignore*
	quote:'"'
	value:([\t !#$%&(-~]/'\\'nl/"'"/nonascii/escape)*
	'"'
	{ return new clasp.model.String(pre, quote, value.join('')) }

string_2 =
	pre:ignore*
	quote:"'"
	value:([\t !#$%&(-~]/'\\'nl/'"'/nonascii/escape)*
	"'"
	{ return new clasp.model.String(pre, quote, value.join('')) }

identifier =
	pre:ignore*
	value:IDENT
	{
		return new clasp.model.Identifier(pre, value)
	}

uri = 
	pre:ignore*
	prefix:"url" 
	paren_open:paren_open
	value:(string/url)?
	paren_close:paren_close
	{
		return new clasp.model.URI(pre, prefix, paren_open, value, paren_close)
	}

url = 
	pre:ignore*
	parts:([!#$%&*-~] / nonascii / escape)+
	{ return new clasp.model.URL(pre, parts.join('')) }
	
unicoderange = 
	pre:ignore*
	prefix:'U+'
	value:(
		h? '?'+
		/
		h+ '-' h+
	)
	{
		return new clasp.model.UnicodeRange(pre, prefix, value)
	}
	
hexcolor = 
	pre:ignore*
	prefix:'#'
	value:name
	{
		return new clasp.model.HexColor(pre, prefix, value)
	}

brace_open =
	pre:ignore*
	brace:'{'
	{
		return new clasp.model.BraceOpen(pre, brace)
	}

brace_close =
	pre:ignore*
	brace:'}'
	{
		return new clasp.model.BraceClose(pre, brace)
	}
	
bracket_open =
	pre:ignore*
	bracket:'['
	{
		return new clasp.model.BracketOpen(pre, bracket)
	}

bracket_close =
	pre:ignore*
	bracket:']'
	{
		return new clasp.model.BracketClose(pre, bracket)
	}
	
paren_open =
	pre:ignore*
	paren:'('
	{
		return new clasp.model.ParenOpen(pre, paren)
	}

paren_close =
	pre:ignore*
	paren:')'
	{
		return new clasp.model.ParenClose(pre, paren)
	}

terminator =
	pre:ignore*
	terminator:';'
	{
		return new clasp.model.Terminator(pre, terminator)
	}
	
separator =
	pre:ignore*
	separator:','
	{
		return new clasp.model.Separator(pre, separator)
	}
	
property_separator =
	pre:ignore*
	separator:':'
	{
		return new clasp.model.Separator(pre, separator)
	}

ignore = 
	chunk:(comment/S/CDO/CDC)
	{
		return new clasp.model.Ignore(chunk)
	}
	
comment = 
	comment:("/*" [^*]* "*"+ ([^/*] [^*]* "*"+)* "/")
	{
		return new clasp.model.Comment(recursive_join(comment))
	}
	
required_space = 
	space:S+
	{
		return new clasp.model.RequiredSpace(space.join(''))
	}

name = parts:nmchar+ { return parts.join('') }
nl = '\n'/'\r\n'/'\r'/'\f'
nonascii = [\x80-\xff]
escape = unicode / "\\" [ -~\x80-\xff]
w = parts:([ \t\r\n\f]*) { return parts.join('') }
h = [0-9a-f]
nmchar = [a-zA-Z0-9-_] / nonascii / escape
nmstart = [a-zA-Z_] / nonascii / escape
unicode = parts:("\\" h+ [ \t\r\n\f]?) { return recursive_join(parts) }

CHARSET_SYM = '@charset'
IMPORT_SYM = '@import'
NAMESPACE_SYM = '@namespace'
MEDIA_SYM = '@media'
PAGE_SYM = '@page'
FONT_FACE_SYM = '@font-face'
IMPORTANT_SYM = '!' w 'important'
NUMBER = parts:("." [0-9]+ / [0-9]* "." [0-9]+ / [0-9]+) { return recursive_join(parts) }
IDENT = parts:([-*]? nmstart nmchar*) { return recursive_join(parts) }
S = parts:[ \t\r\n\f]+ { return parts.join('') }
CDO = '<!--'
CDC = '-->'