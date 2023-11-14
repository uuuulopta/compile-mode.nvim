---@alias StringRange { start: integer, end_: integer }
---@alias Error { highlighted: boolean, level: level, full: StringRange, filename: { value: string, range: StringRange }, row: { value: integer, range: StringRange }?, end_row: { value: integer, range: StringRange }?, col: { value: integer, range: StringRange }?, end_col: { value: integer, range: StringRange }?, group: string }
---@alias RegexpMatcher { regex: string, filename: integer, row: integer|IntByInt|nil, col: integer|IntByInt|nil, type: nil|level|IntByInt }
---@alias ErrorRegexpTable table<string, RegexpMatcher>

local utils = require("compile-mode.utils")

local M = {}

---@enum level
M.level = {
	ERROR = 2,
	WARNING = 1,
	INFO = 0,
}

---@type table<integer, Error>
M.error_list = {}

M.ignore_file_list = {
	"/bin/[a-z]*sh$",
}

---This mirrors the `error_regexp_alist` variable from Emacs.
---See `error_regexp_table` in the README to understand this more in depth.
---
---@type ErrorRegexpTable
M.error_regexp_table = {
	absoft = {
		regex = '^\\%([Ee]rror on \\|[Ww]arning on\\( \\)\\)\\?[Ll]ine[ \t]\\+\\([0-9]\\+\\)[ \t]\\+of[ \t]\\+"\\?\\([a-zA-Z]\\?:\\?[^":\n]\\+\\)"\\?:',
		filename = 3,
		row = 2,
		type = { 1 },
	},
	ada = {
		regex = "\\(warning: .*\\)\\? at \\([^ \n]\\+\\):\\([0-9]\\+\\)$",
		filename = 2,
		row = 3,
		type = { 1 },
	},
	aix = {
		regex = " in line \\([0-9]\\+\\) of file \\([^ \n]\\+[^. \n]\\)\\.\\? ",
		filename = 2,
		row = 1,
	},
	ant = {
		regex = "^[ \t]*\\%(\\[[^] \n]\\+\\][ \t]*\\)\\{1,2\\}\\(\\%([A-Za-z]:\\)\\?[^: \n]\\+\\):\\([0-9]\\+\\):\\%(\\([0-9]\\+\\):\\([0-9]\\+\\):\\([0-9]\\+\\):\\)\\?\\( warning\\)\\?",
		filename = 1,
		row = { 2, 4 },
		col = { 3, 5 },
		type = { 6 },
	},
	bash = {
		regex = "^\\([^: \n\t]\\+\\): line \\([0-9]\\+\\):",
		filename = 1,
		row = 2,
	},
	borland = {
		regex = "^\\%(Error\\|Warnin\\(g\\)\\) \\%([FEW][0-9]\\+ \\)\\?\\([a-zA-Z]\\?:\\?[^:( \t\n]\\+\\) \\([0-9]\\+\\)\\%([) \t]\\|:[^0-9\n]\\)",
		filename = 2,
		row = 3,
		type = { 1 },
	},
	python_tracebacks_and_caml = {
		regex = '^[ \t]*File \\("\\?\\)\\([^," \n\t<>]\\+\\)\\1, lines\\? \\([0-9]\\+\\)-\\?\\([0-9]\\+\\)\\?\\%($\\|,\\%( characters\\? \\([0-9]\\+\\)-\\?\\([0-9]\\+\\)\\?:\\)\\?\\([ \n]Warning\\%( [0-9]\\+\\)\\?:\\)\\?\\)',
		filename = 2,
		row = { 3, 4 },
		col = { 5, 6 },
		type = { 7 },
	},
	cmake = {
		regex = "^CMake \\%(Error\\|\\(Warning\\)\\) at \\(.*\\):\\([1-9][0-9]*\\) ([^)]\\+):$",
		filename = 2,
		row = 3,
		type = { 1 },
	},
	cmake_info = {
		regex = "^  \\%( \\*\\)\\?\\(.*\\):\\([1-9][0-9]*\\) ([^)]\\+)$",
		filename = 1,
		row = 2,
		type = M.level.INFO,
	},
	comma = {
		regex = '^"\\([^," \n\t]\\+\\)", line \\([0-9]\\+\\)\\%([(. pos]\\+\\([0-9]\\+\\))\\?\\)\\?[:.,; (-]\\( warning:\\|[-0-9 ]*(W)\\)\\?',
		filename = 1,
		row = 2,
		col = 3,
		type = { 4 },
	},
	cucumber = {
		regex = "\\%(^cucumber\\%( -p [^[:space:]]\\+\\)\\?\\|#\\)\\%( \\)\\([^(].*\\):\\([1-9][0-9]*\\)",
		filename = 1,
		row = 2,
	},
	msft = {
		regex = "^ *\\([0-9]\\+>\\)\\?\\(\\%([a-zA-Z]:\\)\\?[^ :(\t\n][^:(\t\n]*\\)(\\([0-9]\\+\\)) \\?: \\%(see declaration\\|\\%(warnin\\(g\\)\\|[a-z ]\\+\\) C[0-9]\\+:\\)",
		filename = 2,
		row = 3,
		type = { 4 },
	},
	edg_1 = {
		regex = "^\\([^ \n]\\+\\)(\\([0-9]\\+\\)): \\%(error\\|warnin\\(g\\)\\|remar\\(k\\)\\)",
		filename = 1,
		row = 2,
		type = { 3, 4 },
	},
	edg_2 = {
		regex = 'at line \\([0-9]\\+\\) of "\\([^ \n]\\+\\)"$',
		filename = 2,
		row = 1,
		type = M.level.INFO,
	},
	epc = {
		regex = "^Error [0-9]\\+ at (\\([0-9]\\+\\):\\([^)\n]\\+\\))",
		filename = 2,
		row = 1,
	},
	ftnchek = {
		regex = "\\(^Warning .*\\)\\? line[ \n]\\([0-9]\\+\\)[ \n]\\%(col \\([0-9]\\+\\)[ \n]\\)\\?file \\([^ :;\n]\\+\\)",
		filename = 4,
		row = 2,
		col = 3,
		type = { 1 },
	},
	gradle_kotlin = {
		regex = "^\\%(\\(w\\)\\|.\\): *\\(\\%([A-Za-z]:\\)\\?[^:\n]\\+\\): *(\\([0-9]\\+\\), *\\([0-9]\\+\\))",
		filename = 2,
		row = 3,
		col = 4,
		type = { 1 },
	},
	iar = {
		regex = '^"\\(.*\\)",\\([0-9]\\+\\)\\s-\\+\\%(Error\\|Warnin\\(g\\)\\)\\[[0-9]\\+\\]:',
		filename = 1,
		row = 2,
		type = { 3 },
	},
	ibm = {
		regex = "^\\([^( \n\t]\\+\\)(\\([0-9]\\+\\):\\([0-9]\\+\\)) : \\%(warnin\\(g\\)\\|informationa\\(l\\)\\)\\?",
		filename = 1,
		row = 2,
		col = 3,
		type = { 4, 5 },
	},
	irix = {
		regex = '^[-[:alnum:]_/ ]\\+: \\%(\\%([sS]evere\\|[eE]rror\\|[wW]arnin\\(g\\)\\|[iI]nf\\(o\\)\\)[0-9 ]*: \\)\\?\\([^," \n\t]\\+\\)\\%(, line\\|:\\) \\([0-9]\\+\\):',
		filename = 3,
		row = 4,
		type = { 1, 2 },
	},
	java = {
		regex = "^\\%([ \t]\\+at \\|==[0-9]\\+== \\+\\%(at\\|b\\(y\\)\\)\\).\\+(\\([^()\n]\\+\\):\\([0-9]\\+\\))$",
		filename = 2,
		row = 3,
		type = { 1 },
	},
	jikes_file = {
		regex = '^\\%(Found\\|Issued\\) .* compiling "\\(.\\+\\)":$',
		filename = 1,
		type = M.level.INFO,
	},
	maven = {
		regex = "^\\%(\\[\\%(ERROR\\|\\(WARNING\\)\\|\\(INFO\\)\\)] \\)\\?\\([^\n []\\%([^\n :]\\| [^\n/-]\\|:[^\n []\\)*\\):\\[\\([[:digit:]]\\+\\),\\([[:digit:]]\\+\\)] ",
		filename = 3,
		row = 4,
		col = 5,
		type = { 1, 2 },
	},
	-- TODO: make this relevant with some sort of priority system
	clang_include = {
		regex = "^In file included from \\([^\n:]\\+\\):\\([0-9]\\+\\):$",
		filename = 1,
		row = 2,
		type = M.level.INFO,
	},
	gcc_include = {
		regex = "^\\%(In file included \\|                 \\|\t\\)from \\([0-9]*[^0-9\n]\\%([^\n :]\\| [^-/\n]\\|:[^ \n]\\)\\{-}\\):\\([0-9]\\+\\)\\%(:\\([0-9]\\+\\)\\)\\?\\%(\\(:\\)\\|\\(,\\|$\\)\\)\\?",
		filename = 1,
		row = 2,
		col = 3,
		type = { 4, 5 },
	},
	["ruby_Test::Unit"] = {
		regex = "^    [[ ]\\?\\([^ (].*\\):\\([1-9][0-9]*\\)\\(\\]\\)\\?:in ",
		filename = 1,
		row = 2,
	},
	gmake = {
		regex = ": \\*\\*\\* \\[\\%(\\(.\\{-1,}\\):\\([0-9]\\+\\): .\\+\\)\\]",
		filename = 1,
		row = 2,
		type = M.level.INFO,
	},
	gnu = {
		regex = "^\\%([[:alpha:]][-[:alnum:].]\\+: \\?\\|[ \t]\\%(in \\| from\\)\\)\\?\\(\\%([0-9]*[^0-9\\n]\\)\\%([^\\n :]\\| [^-/\\n]\\|:[^ \\n]\\)\\{-}\\)\\%(: \\?\\)\\([0-9]\\+\\)\\%(-\\([0-9]\\+\\)\\%(\\.\\([0-9]\\+\\)\\)\\?\\|[.:]\\([0-9]\\+\\)\\%(-\\%(\\([0-9]\\+\\)\\.\\)\\([0-9]\\+\\)\\)\\?\\)\\?:\\%( *\\(\\%(FutureWarning\\|RuntimeWarning\\|W\\%(arning\\)\\|warning\\)\\)\\| *\\([Ii]nfo\\%(\\>\\|formationa\\?l\\?\\)\\|I:\\|\\[ skipping .\\+ ]\\|instantiated from\\|required from\\|[Nn]ote\\)\\| *\\%([Ee]rror\\)\\|\\%([0-9]\\?\\)\\%([^0-9\\n]\\|$\\)\\|[0-9][0-9][0-9]\\)",
		filename = 1,
		row = { 2, 3 },
		col = { 5, 4 },
		type = { 8, 9 },
	},
	lcc = {
		regex = "^\\%(E\\|\\(W\\)\\), \\([^(\n]\\+\\)(\\([0-9]\\+\\),[ \t]*\\([0-9]\\+\\)",
		filename = 2,
		row = 3,
		col = 4,
		type = { 1 },
	},
	makepp = {
		regex = "^makepp\\%(\\%(: warning\\(:\\).\\{-}\\|\\(: Scanning\\|: [LR]e\\?l\\?oading makefile\\|: Imported\\|log:.\\{-}\\) \\|: .\\{-}\\)`\\(\\(\\S \\{-1,}\\)\\%(:\\([0-9]\\+\\)\\)\\?\\)['(]\\)",
		filename = 4,
		row = 5,
		type = { 1, 2 },
	},
	mips_1 = {
		regex = " (\\([0-9]\\+\\)) in \\([^ \n]\\+\\)",
		filename = 2,
		row = 1,
	},
	mips_2 = {
		regex = " in \\([^()\n ]\\+\\)(\\([0-9]\\+\\))$",
		filename = 1,
		row = 2,
	},
	omake = {
		regex = "^\\*\\*\\* omake: file \\(.*\\) changed",
		filename = 1,
	},
	oracle = {
		regex = "^\\%(Semantic error\\|Error\\|PCC-[0-9]\\+:\\).* line \\([0-9]\\+\\)\\%(\\%(,\\| at\\)\\? column \\([0-9]\\+\\)\\)\\?\\%(,\\| in\\| of\\)\\? file \\(.\\{-}\\):\\?$",
		filename = 3,
		row = 1,
		col = 2,
	},
	perl = {
		regex = " at \\([^ \n]\\+\\) line \\([0-9]\\+\\)\\%([,.]\\|$\\| during global destruction\\.$\\)",
		filename = 1,
		row = 2,
	},
	php = {
		regex = "\\%(Parse\\|Fatal\\) error: \\(.*\\) in \\(.*\\) on line \\([0-9]\\+\\)",
		filename = 2,
		row = 3,
	},
	-- TODO: support multi-line errors
	rxp = {
		regex = "^\\%(Error\\|Warnin\\(g\\)\\):.*\n.* line \\([0-9]\\+\\) char \\([0-9]\\+\\) of file://\\(.\\+\\)",
		filename = 4,
		row = 2,
		col = 3,
		type = { 1 },
	},
	sun = {
		regex = ": \\%(ERROR\\|WARNIN\\(G\\)\\|REMAR\\(K\\)\\) \\%([[:alnum:] ]\\+, \\)\\?File = \\(.\\+\\), Line = \\([0-9]\\+\\)\\%(, Column = \\([0-9]\\+\\)\\)\\?",
		filename = 3,
		row = 4,
		col = 5,
		type = { 1, 2 },
	},
	sun_ada = {
		regex = "^\\([^, \n\t]\\+\\), line \\([0-9]\\+\\), char \\([0-9]\\+\\)[:., (-]",
		filename = 1,
		row = 2,
		col = 3,
	},
	watcom = {
		regex = "^[ \t]*\\(\\%([a-zA-Z]:\\)\\?[^ :(\t\n][^:(\t\n]*\\)(\\([0-9]\\+\\)): \\?\\%(\\(Error! E[0-9]\\+\\)\\|\\(Warning! W[0-9]\\+\\)\\):",
		filename = 1,
		row = 2,
		type = { 4 },
	},
	["4bsd"] = {
		regex = "\\%(^\\|::  \\|\\S ( \\)\\(/[^ \n\t()]\\+\\)(\\([0-9]\\+\\))\\%(: \\(warning:\\)\\?\\|$\\| ),\\)",
		filename = 1,
		row = 2,
		type = { 3 },
	},
	["perl__Pod::Checker"] = {
		regex = "^\\*\\*\\* \\%(ERROR\\|\\(WARNING\\)\\).* \\%(at\\|on\\) line \\([0-9]\\+\\) \\%(.* \\)\\?in file \\([^ \t\n]\\+\\)",
		filename = 3,
		row = 2,
		type = { 1 },
	},
}

---Given a `matchlistpos` result and a capture-group matcher, return the location of the relevant capture group(s).
---
---@param result (StringRange|nil)[]
---@param group integer|IntByInt|nil
---@return StringRange|nil
---@return StringRange|nil
local function parse_matcher_group(result, group)
	if not group then
		return nil
	elseif type(group) == "number" then
		return result[group + 1]
	elseif type(group) == "table" then
		local first = group[1] + 1
		local second = group[2] + 1

		return result[first], result[second]
	end
end

---Get the range and its value from a certain line
---@param line string
---@param range StringRange
---@return { value: any, range: StringRange }
local function range_and_value(line, range)
	return {
		value = line:sub(range.start, range.end_),
		range = range,
	}
end

---Get the range and its numeric value, if it contains a number.
---@param line string
---@param range StringRange|nil
---@return ({ value: number, range: StringRange })|nil
local function numeric_range_and_value(line, range)
	if not range then
		return nil
	end

	local raw = range_and_value(line, range)

	raw.value = tonumber(raw.value)
	if not raw.value then
		return nil
	end

	return raw
end

---Parse a line for errors using a specific matcher from `error_regexp_table`.
---@param matcher RegexpMatcher|nil
---@param line string
---@return Error|nil
local function parse_matcher(matcher, line)
	if not matcher then
		return nil
	end

	local regex = matcher.regex
	local result = utils.matchlistpos(line, regex)
	if not result then
		return nil
	end

	local filename_range = result[matcher.filename + 1]
	if not filename_range then
		return nil
	end

	local row_range, end_row_range = parse_matcher_group(result, matcher.row)
	local col_range, end_col_range = parse_matcher_group(result, matcher.col)

	local error_level
	if not matcher.type then
		error_level = M.level.ERROR
	elseif type(matcher.type) == "number" then
		error_level = matcher[5]
	elseif type(matcher.type) == "table" then
		if result[matcher.type[1] + 1] then
			error_level = M.level.WARNING
		elseif matcher.type[2] and result[matcher.type[2] + 1] then
			error_level = M.level.INFO
		else
			error_level = M.level.ERROR
		end
	end

	return {
		highlighted = false,
		level = error_level,
		full = result[1],
		filename = range_and_value(line, filename_range),
		row = numeric_range_and_value(line, row_range),
		col = numeric_range_and_value(line, col_range),
		end_row = numeric_range_and_value(line, end_row_range),
		end_col = numeric_range_and_value(line, end_col_range),
		group = nil,
	}
end

---Parses error syntax from a given line.
---@param line string the line to parse
---@return Error|nil
function M.parse(line)
	for group, matcher in pairs(M.error_regexp_table) do
		local result = parse_matcher(matcher, line)

		if result then
			for _, pattern in ipairs(M.ignore_file_list) do
				if vim.fn.match(result.filename.value, pattern) ~= -1 then
					return nil
				end
			end

			result.group = group

			return result
		end
	end

	return nil
end

---Highlight a single error in the compilation buffer.
---@param bufnr integer
---@param error Error
---@param linenum integer
local function highlight_error(bufnr, error, linenum)
	if error.highlighted then
		return
	end

	error.highlighted = true

	local full_range = error.full
	utils.add_highlight(bufnr, "CompileModeError", linenum, full_range)

	local hlgroup = "CompileMode"
	if error.level == M.level.WARNING then
		hlgroup = hlgroup .. "Warning"
	elseif error.level == M.level.INFO then
		hlgroup = hlgroup .. "Info"
	else
		hlgroup = hlgroup .. "Error"
	end
	hlgroup = hlgroup .. "Filename"

	local filename_range = error.filename.range
	utils.add_highlight(bufnr, hlgroup, linenum, filename_range)

	local row_range = error.row and error.row.range
	if row_range then
		utils.add_highlight(bufnr, "CompileModeErrorRow", linenum, row_range)
	end
	local end_row_range = error.end_row and error.end_row.range
	if end_row_range then
		utils.add_highlight(bufnr, "CompileModeErrorRow", linenum, end_row_range)
	end

	local col_range = error.col and error.col.range
	if col_range then
		utils.add_highlight(bufnr, "CompileModeErrorCol", linenum, col_range)
	end
	local end_col_range = error.end_col and error.end_col.range
	if end_col_range then
		utils.add_highlight(bufnr, "CompileModeErrorCol", linenum, end_col_range)
	end
end

---Highlight all errors in the compilation buffer.
---@param bufnr integer
function M.highlight(bufnr)
	for linenum, error in pairs(M.error_list) do
		highlight_error(bufnr, error, linenum)
	end
end

return M
