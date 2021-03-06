module Ohcount #:nodoc:
	# The Detector determines which Monoglot or Polyglot should be
	# used to parse a source file.
	#
	# The Detector primarily uses filename extensions to identify languages.
	#
	# The hash EXTENSION_MAP maps a filename extension to the name of a parser.
	#
	# If a filename extension is not enough to determine the correct parser
	# (for instance, the *.m extension can indicate either a Matlab(TM),
	# Octave, or Objective-C file), then the EXTENSION_MAP hash will contain
	# a symbol identifying a Ruby method which will be invoked. This Ruby
	# method can examine the file contents and return the name of the
	# correct parser.
	#
	# Many source files do not have an extension. The method +disambiguate_nil+
	# is called in these cases. The +file+ command line tool is used to determine
	# the type of file and select a parser.
	#
	# The Detector is covered by DetectorTest.
	#
	class Detector

		# A performance hack -- once we've checked for the presence of *.m files, the result
		# is stored here to avoid checking twice.
		module ContainsM
			attr_accessor :contains_m
			# A performance hack -- once we've checked for the presence of *.pike and *.pmod files, the result
			# is stored here to avoid checking twice.
			attr_accessor :contains_pike_or_pmod
		end

		# A performance hack -- once we've checked for the presence of *.frx, *.frm and *.vbp files, the result
		# is stored here to avoid checking twice.
		module ContainsVB
			attr_accessor :contains_vb
		end

		# The primary entry point for the detector.
		# Given a file context containing the file name, content, and an array of
		# other filenames in the source tree, attempts to detect which
		# language family (Monoglot or Polyglot) is in use for this file.
		#
		# Returns nil if the language is not recognized or if the file does not
		# contain any code.
		#
		# Example:
		#
		#   # List all C files in the 'src' directory
		#   Dir.entries("src").each do |file|
		#     context = Ohcount::SimpleFileContext.new(file)
		#     polyglot = Ohcount::Detector.detect(context)
		#     puts "#{file}" if polyglot == 'c'
		#   end
		#
		def self.detect(source_file)
			return nil if binary_filename?(source_file.filename)
			return nil if binary_buffer?(source_file.contents)

			# start with filename and extension
			polyglot = [
				lambda { | f | FILENAME_MAP[File.basename(source_file.filename)] },
				lambda { | f | EXTENSION_MAP[File.extname(source_file.filename)] },
				lambda { | f | EXTENSION_MAP[File.extname(source_file.filename).downcase] }
			].inject(nil) { | a, f | a and break a or f.call(source_file) }
			case polyglot
			when String
				# simplest case
				return polyglot if polyglot.is_a?(String)
			when Symbol
				# extension is ambiguous - requires custom disambiguation
				self.send(polyglot, source_file)
			when NilClass
				return disambiguate_nil(source_file)
			else
				raise RuntimeError.new("Unknown file detection type")
			end
		end

		# Based solely on the filename, makes a judgment whether a file is a binary format.
		def self.binary_filename?(filename)
			ignore = [
				".aiff",
				".au",
				".avi",
				".bmp",
				".cache",
				".dat",
				".doc",
				".gif",
				".gz",
				".icns",
				".jar",
				".jpeg",
				".jpg",
				".m4a",
				".mov",
				".mp3",
				".mpg",
				".ogg",
				".pdf",
				".png",
				".pnt",
				".ppt",
				".qt",
				".ra",
				".svg",
				".svgz",
				".svn",
				".swf",
				".tar",
				".tgz",
				".tif",
				".tiff",
				".wav",
				".xls",
				".xlw",
				".zip"
				]
			ignore.include?(File.extname(filename).downcase)
		end

		# If an extension maps to a string, that string must be the name of a glot.
		# If an extension maps to a Ruby symbol, that symbol must be the name of a
		# Ruby method which will return the name of a glot.
		EXTENSION_MAP = {
			'.ada'        => "ada",
			'.adb'        => "ada",
			'.ads'        => "ada",
			'.as'         => "actionscript",
			'.ascx'       => :disambiguate_aspx,
			'.aspx'       => :disambiguate_aspx,
			'.asm'        => "assembler",
			'.awk'        => "awk",
			'.b'          => :disambiguate_b,
			'.bas'        => :disambiguate_basic,
			'.bat'        => "bat",
			'.bi'         => :disambiguate_non_visual_basic,
			'.bmx'        => "blitzmax",
			'.boo'        => "boo",
			'.c'          => "c",
			'.C'          => "cpp",
			'.cc'         => "cpp",
			'.cmake'      => "cmake",
			'.ctp'        => "php",
			'.cpp'        => "cpp",
			'.css'        => "css",
			'.c++'        => "cpp",
			'.cxx'        => "cpp",
			'.com'        => "dcl",
			'.cs'         => :disambiguate_cs,
			'.d'		      => 'dmd',
			'.di'		      => 'dmd',
			'.dylan'      => "dylan",
			'.e'	        => "eiffel",
			'.ebuild'     => "ebuild",
			'.eclass'     => "ebuild",
			'.el'         => "emacslisp",
			'.erl'        => "erlang",
			'.exheres-0'  => "exheres",
			'.exlib'      => "exheres",
			'.f'          => :disambiguate_fortran,
			'.factor'     => "factor",
			'.ftn'        => :disambiguate_fortran,
			'.f77'        => :disambiguate_fortran,
			'.f90'        => :disambiguate_fortran,
			'.f95'        => :disambiguate_fortran,
			'.f03'        => :disambiguate_fortran,
			'.frag'       => "glsl",
			'.frx'        => "visualbasic",
			'.frm'        => "visualbasic",
			'.glsl'       => "glsl",
			'.groovy'     => "groovy",
			'.h'          => :disambiguate_h_header,
			'.haml'       => 'haml',
			'.H'          => "cpp",
			'.hpp'        => "cpp",
			'.h++'        => "cpp",
			'.hs'         => "haskell",
			'.hx'         => "haxe",
			'.hxx'        => "cpp",
			'.hh'         => "cpp",
			'.hrl'        => "erlang",
			'.htm'        => "html",
			'.html'       => "html",
			'.in'         => :disambiguate_in,
			'.inc'        => :disambiguate_inc,
			'.j'          => "objective_j",
			'.java'       => "java",
			'.js'         => "javascript",
			'.jsp'        => "jsp",
			'.kdebuild-1' => "ebuild",
			'.latex'      => 'tex',
			'.lisp'       => "lisp",
			'.lsp'        => "lisp",
			'.ltx'        => 'tex',
			'.lua'        => "lua",
			'.m'          => :disambiguate_m,
			'.mf'         => 'metafont',
			'.mk'         => 'make',
			'.ml'         => "ocaml",
			'.mli'        => "ocaml",
			'.mm'         => "objective_c",
			'.mp'         => 'metapost_with_tex',
			'.mxml'       => 'mxml',
			'.nix'        => 'nix',
			'.nse'        => 'lua',
			'.pas'        => "pascal",
			'.pp'         => "pascal",
			'.php'        => "php",
			'.php3'       => "php",
			'.php4'       => "php",
			'.php5'       => "php",
			'.p6'         => "perl",
			'.pl'         => "perl",
			'.pm'         => "perl",
			'.perl'       => "perl",
			'.ph'         => "perl",
			'.pod'        => "perl",
			'.t'          => "perl",
			'.pike'       => "pike",
			'.pmc'        => "c",
			'.pmod'       => "pike",
			'.py'         => "python",
			'.r'          => "r",
			'.rhtml'      => "rhtml",
			'.rb'         => "ruby",
			'.rex'        => "rexx",
			'.rexx'       => "rexx",
			'.s'          => "assembler",
			'.sc'         => "scheme",
			'.scala'      => "scala",
			'.sci'        => "scilab",
			'.sce'        => "scilab",
			'.scm'        => "scheme",
			'.sps'        => "scheme",
			'.sls'        => "scheme",
			'.ss'         => "scheme",
			'.sh'         => "shell",
			'.sql'        => "sql",
			'.st'         => :disambiguate_smalltalk,
			'.str'        => "stratego",
			'.tcl'        => "tcl",
			'.tex'        => 'tex',
			'.tpl'        => "html",
			'.vala'       => "vala",
			'.vb'         => "visualbasic",
			'.vba'        => "visualbasic",
			'.vbs'        => "visualbasic",
			'.vert'       => "glsl",
			'.vhd'        => "vhdl",
			'.vhdl'       => "vhdl",
			'.vim'        => "vim",
			'.xaml'       => "xaml",
			'.xml'        => "xml",
			'.xs'         => "c",
			'.xsd'        => "xmlschema",
			'.xsl'        => "xslt",
			'.z80'        => "assembler"
		}

		# Map full filenames to glots. The right hand side is a string or symbol as
		# for EXTENSION_MAP.
		FILENAME_MAP = {
			'CMakeLists.txt'=> 'cmake',
			'Makefile'      => 'make',
			'GNUmakefile'   => 'make',
			'makefile'      => 'make',
			'Makefile.am'   => 'automake',
			'configure.in'  => 'autoconf',
			'configure.ac'  => 'autoconf',
			'configure'     => 'autoconf'
		}

		protected

		# Returns a count of lines in the buffer matching the given regular expression.
		def self.lines_matching(buffer, re)
			buffer.inject(0) { |total, line| line =~ re ? total+1 : total }
		end

		# For *.m files, differentiates between Matlab(TM), Octave, Limbo, and Objective-C.
		#
		# This is done with a weighted heuristic that
		# scans the *.m file contents for keywords,
		# and also checks for the presence of matching *.h files.
		def self.disambiguate_m(source_file)

			# '//', '/*', '@interface', or '@implementation' are likely objective_c
			objective_c_signatures = /(^\s*\/\/\s*)|(^\s*\/\*)|(^[+-])|(@interface)|(@implementation)/
			objective_c_score = lines_matching(source_file.contents, objective_c_signatures)

			# If there are .h files in same directory and no C or C++ source files,
			# this probably isn't Matlab(TM) or Octave.  Both allow compiled extensions
			# that often live in the same directory, so checking .h alone does not suffice.
			objective_c_score += 5 if has_h_headers?(source_file.filenames) && !has_c_files?(source_file.filenames)

			# 'function (' is likely to be Octave or Matlab(TM).
			# Lines starting with '%' or '#' are likely comments in Octave or Matlab(TM).
			# Note that '#' might begin '#import', so we count it as a comment only if it
			# is followed by a space.
			matlab_signatures = /(^\s*function\s*\()|(^\s*%)|(^\s*\#+\s+)/
			matlab_score = lines_matching(source_file.contents, matlab_signatures)

			# Lines starting with # are limbo comments
			# Declarations are of the form:  <name>: <type> (with type commonly module/adt/fn(/con)
			# Some .m files only have a list of includes.
			limbo_signatures = /(^[ \t]*#\s)|(:[ \t]+(module|adt|fn ?\(|con[ \t]))|(^include[ \t]+"[^"]+\.m";)/
			limbo_score = lines_matching(source_file.contents, limbo_signatures)

			if limbo_score > objective_c_score && limbo_score > matlab_score
				'limbo'
			elsif objective_c_score > matlab_score
				'objective_c'
			else
				disambiguate_matlab_octave(source_file)
			end
		end

		def self.disambiguate_matlab_octave(source_file)
			# Octave-specific keywords: endfunction, endwhile, end_try_catch, end_unwind_protect
			# Also, # is only an Octave comment character.
			oct_specific_sigs = /(\bend(function|while|_try_catch|unwind_protect))|(^\s*\#)/

			if lines_matching(source_file.contents, oct_specific_sigs) > 0
				'octave'
			else
				'matlab'
			end
		end

		def self.has_h_headers?(filenames)
			filenames.each { |a| return true if a =~ /\.h$/ }
			false
		end

		def self.has_c_files?(filenames)
			filenames.each { |a| return true if a =~ /\.(c|cpp|C|c\+\+|cxx|cc)$/ }
			false
		end

		# For *.h files, differentiates C, C++ and Objective-C.
		#
		# This is done with a weighted heuristic that
		# scans the *.h file contents for Objective-C keywords,
		# C++ keywords and C++ headers, and also checks for the
		# presence of matching *.m files.
		def self.disambiguate_h_header(source_file)
			buffer = source_file.contents

			# could it be realistically be objective_c ? are there any .m files at all?
			# Speed hack - remember our findings in case we get the same filenames over and over
			unless defined?(source_file.filenames.contains_m)
				source_file.filenames.extend(ContainsM)
				source_file.filenames.contains_m = source_file.filenames.select { |a| a =~ /\.m$/ }.any?
				source_file.filenames.contains_pike_or_pmod = source_file.filenames.select { |a| a =~ /\.p(ike|mod)$/ }.any?
			end

			if source_file.filenames.contains_m
				# if the dir contains a matching *.m file, likely objective_c
				if source_file.filename =~ /\.h$/
					m_counterpart = source_file.filename.gsub(/\.h$/, ".m")
					return 'objective_c' if source_file.filenames.include?(m_counterpart)
				end

				# ok - it just might be objective_c, let's check contents for objective_c signatures
				objective_c_signatures = /(^\s*@interface)|(^\s*@end)/
				objective_c = lines_matching(buffer, objective_c_signatures)
				return 'objective_c' if objective_c > 1
			end

			if source_file.filenames.contains_pike_or_pmod
				# The string "pike" and a selection of common Pike keywords.
				pike_signatures = /([Pp][Ii][Kk][Ee])|(string )|(mapping)|(multiset)|(import )|(inherit )|(predef)/
				pike = lines_matching(buffer, pike_signatures)
				return 'pike' if pike > 0
			end

			disambiguate_c_cpp(buffer)
		end

		# A map of headers that indicate C++, but that do not have C++-specific file
		# extensions. This list is made from the Standard, plus Technical Report 1.
		CPP_HEADERS_MAP = %w[
			algorithm
			array
			bitset
			cassert
			ccomplex
			cctype
			cerrno
			cfenv
			cfloat
			cinttypes
			ciso646
			climits
			clocale
			cmath
			csetjmp
			csignal
			cstdarg
			cstdbool
			cstddef
			cstdint
			cstdio
			cstdlib
			cstring
			ctgmath
			ctime
			cwchar
			cwctype
			deque
			exception
			fstream
			functional
			iomanip
			ios
			iosfwd
			iostream
			istream
			iterator
			limits
			list
			locale
			map
			memory
			new
			numeric
			ostream
			queue
			random
			regex
			set
			sstream
			stack
			stdexcept
			streambuf
			string
			system_error
			tuple
			type_traits
			typeinfo
			unordered_map
			unordered_set
			utility
			valarray
			vector
			tr1/array
			tr1/ccomplex
			tr1/cctype
			tr1/cfenv
			tr1/cfloat
			tr1/cinttypes
			tr1/climits
			tr1/cmath
			tr1/complex
			tr1/cstdarg
			tr1/cstdbool
			tr1/cstdint
			tr1/cstdio
			tr1/cstdlib
			tr1/ctgmath
			tr1/ctime
			tr1/cwchar
			tr1/cwctype
			tr1/memory
			tr1/random
			tr1/regex
			tr1/tuple
			tr1/type_traits
			tr1/unordered_map
			tr1/unordered_set
			tr1/utility
		].inject({}) { | h, k | h[k] = true ; h }

		# A map of keywords that indicate C++.
		CPP_KEYWORDS_MAP = %w[
			template
			typename
			class
			namespace
		].inject({}) { | h, k | h[k] = true ; h }

		# For *.h files that we know aren't Objective-C, differentiates C and C++.
		#
		# This is done with a weighted heuristic that
		# scans the *.h file contents for C++ keywords and C++ headers.
		def self.disambiguate_c_cpp(buffer)
			# Look for C++ headers
			return 'cpp' if extract_c_cpp_headers(buffer).detect do | header |
				EXTENSION_MAP[File.extname(header)] == 'cpp' or CPP_HEADERS_MAP.include? header
			end

			# Look for C++ keywords. This could check for comments, but doesn't.
			return 'cpp' if buffer.find do | line |
				line.split(/\W/).find do | word |
					CPP_KEYWORDS_MAP.include? word
				end
			end

			# Nothing to suggest C++
			'c'
		end

		# Return a list of files included in a C or C++ source file.
		def self.extract_c_cpp_headers(buffer)
			buffer.map do | line |
				m = line.match(/^#\s*include\s+[<"](.*)[>"]/) and m[1]
			end.find_all { | a | a }
		end

		# Tests whether the provided buffer contains binary or text content.
		# This is not fool-proof -- we basically just check for zero values
		# in the early bytes of the buffer. If we find a zero, we know it
		# is not (ascii) text.
		def self.binary_buffer?(buffer)
			100.times do |i|
				return true if buffer[i] == 0
			end
			false
		end

		# True if the provided buffer includes a '?php' directive
		def self.php_instruction?(buffer)
			buffer =~ /\?php/
		end

		# For *.in files, checks the prior extension.
		# Typically used for template files (eg Makefile.in, auto.c.in, etc).
		def self.disambiguate_in(source_file)
			# only if the filename has an extension prior to the .in
			return nil unless source_file.filename =~ /(.+\.(.*))\.in$/

			undecorated_source = source_file.clone
			undecorated_source.filename = $1

			detect(undecorated_source)
		end

		# For *.inc files, checks for a PHP class.
		def self.disambiguate_inc(source_file)
			buffer = source_file.contents
			return nil if binary_buffer?(buffer)
			return 'php' if php_instruction?(buffer)
			nil
		end

		# For files with extention *.cs, differentiates C# from Clearsilver.
		def self.disambiguate_cs(source_file)
			buffer = source_file.contents
			return 'clearsilver_template' if lines_matching(source_file.contents, /\<\?cs/) > 0
			return 'csharp'
		end

		def self.disambiguate_fortran(source_file)
			buffer = source_file.contents

			definitely_not_f77 = /^ [^0-9 ]{5}/
			return 'fortranfixed' if lines_matching(buffer, definitely_not_f77) > 0

			free_form_continuation = /&\s*\n\s*&/m
			return 'fortranfree' if buffer.match(free_form_continuation)

			possibly_fixed = /^ [0-9 ]{5}/
			contig_number = /^\s*\d+\s*$/
			buffer.scan(possibly_fixed) {|leader|
				return 'fortranfixed' if !(leader =~ contig_number) }
			# Might as well be free-form.
			return 'fortranfree'
		end

		# A *.aspx file may be scripted with either C# or VB.NET.
		def self.disambiguate_aspx(source_file)
			if source_file.contents.match(/<%@\s*Page[^>]+Language="VB"[^>]+%>/i)
				'vb_aspx'
			else
				'cs_aspx'
			end
		end

		# Attempts to tell apart VB, classic BASIC and structured BASIC.
		# First, checks if it is classic BASIC based on syntax.
		# If not checks for .vb, .bp, .frx and .frm files (associated with VB)
		# in file context
		#
		# If these files are absent, assumes structured BASIC
		#
		def self.disambiguate_basic(source_file)
			classic_basic_line = /^\d+\s+\w+.*$/
			vb_filename = /\.fr[mx]$|\.vb([aps]?)$/
			buffer = source_file.contents
			if lines_matching(buffer,classic_basic_line) > 0
				return 'classic_basic'
			else
				unless defined?(source_file.filenames.contains_vb)
					source_file.filenames.extend(ContainsVB)
					source_file.filenames.contains_vb = source_file.filenames.select { |a| a =~ vb_filename }.any?
				end
				if source_file.filenames.contains_vb
					return 'visualbasic'
				else
					return 'structured_basic'
				end
			end
		end

		def self.disambiguate_non_visual_basic(source_file)
			classic_basic_line = /^\d+\s+\w+.*$/
			buffer = source_file.contents

			if lines_matching(buffer,classic_basic_line) > 0
				return 'classic_basic'
			else
				return 'structured_basic'
			end
		end

		# Attempts to determine the Polyglot for files that do not have a filename
		# extension.
		#
		# Relies on the bash +file+ command line tool as its primary method.
		#
		# There must be a file at <tt>source_file.file_location</tt> for +file+ to
		# operate on.
		#
		def self.disambiguate_nil(source_file)
			script = disambiguate_using_emacs_mode(source_file)
			return script if script

			file_output = source_file.realize_file { |f| `file -b '#{ f }'` }
			case file_output
			when /([\w\/]+)(?: -[\w_]+)* script text/, /script text(?: executable)? for ([\w\/]+)/
				script = $1
				if script =~ /\/(\w*)$/
					script = $1
				end
				known_languages = EXTENSION_MAP.values
				return script.downcase if known_languages.include?(script.downcase)
			when /([\w\-]*) shell script text/
				case $1
				when "Bourne-Again"
					return "shell"
				end
			when /XML( 1\.0| )? document text/, /^XML$/
				return 'xml'
			end
			# dang... no dice
			nil
		end

		def self.disambiguate_using_emacs_mode(source_file)
			begin
				mode = nil

				# find the first line
				if source_file.contents =~ /^#!/
					# fetch 2 lines
					source_file.contents =~ /^(.*\n.*)\n/
				else
					# first line only
					source_file.contents =~ /^(.*)\n/
				end
				head = $1

				mode = case head
							 when /-\*-.*\bmode\s*:\s*([^\s;]+).*-\*-/i
								 $1
							 when /-\*-\s*(\S+)\s*-\*-/
								 $1
							 end
				if mode
					remap = {
						'c++' => 'cpp',
						'caml' => 'ocaml',
					}
					script = remap[mode] || mode

					known_languages = EXTENSION_MAP.values
					return script.downcase if known_languages.include?(script.downcase)
				end
			rescue
				nil
			end
		end

		# Check if a file looks like it's really smalltalk rather than just
		# happening to have a ".st" extension.
		def self.disambiguate_smalltalk(source_file)
			buffer = source_file.contents
			if buffer =~ /:=/ && buffer =~ /: *\[/ && buffer =~ /\]\./
				return 'smalltalk'
			end
			nil
		end

		def self.disambiguate_b(source_file)
			# implement and include lines are good indicators, but not always present
			# return|break|continue statements, or pick & case constructs are good differentiators with basic
			limbo_b_line = /(implement[ \t])|(include[ \t]+"[^"]*";)|((return|break|continue).*;|(pick|case).*\{)/

			if lines_matching(source_file.contents, limbo_b_line) > 0
				'limbo'
			else
				disambiguate_non_visual_basic(source_file)
			end
		end

	end
end
