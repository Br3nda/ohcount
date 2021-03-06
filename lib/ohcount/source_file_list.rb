module Ohcount

	# Use a SourceFileList to collect information about multiple files. Example:
	#
	#  # find out the number of Ruby lines of code in project 'foo'
	#  sfl = SourceFileList.new(:dir => '/foo')
	#  sfl.loc_list.loc(:ruby).code
	#
	class SourceFileList < Array
		attr_reader :loc_list, :java_facts

		# pass an array of filenames you want to process.
		#
		# Options:
		#
		# :paths directory name from which to populate all files from (deep).
		# :files exact files to analyze
		#
		def initialize(options = {})
			files = options.inject([]) do |memo,(k,v)|
				memo + case k
					when :path then files_from_paths([v])
					when :paths then files_from_paths(v)
					when :files then v
					else raise(ArgumentError, "Unrecognized option: #{ k }")
				end
			end.flatten.uniq.compact
			super(files)
		end

		def files_from_paths(paths=[])
			paths.collect { |p| files_from_path(File.expand_path(p)) }.flatten
		end

		def files_from_path(path)
			s = File.lstat(path)
			if s.directory?
				if File.basename(path) =~ /^\./ # Don't recurse into hidden dirs
					[]
				else
					Dir[File.join(path,"{.,?}*")].collect { |d| files_from_path(d) } # Include hidden files
				end
			elsif s.file?
				path
			end
		end

		#
		# call analyze to generate facts from a collection of files (typically a
		# project directory). Because deducing different facts often requires doing
		# similar work, this function allows multiple facts to be extracted in one
		# single pass
		#
		# *Fact* *Types*
		#
		# :gestalt:: platform dependencies and tools usage
		# :languages:: detailed programming languages facts
		# :java:: java-related dependencies (jars & imports)
		#
		# Examples
		#
		#  sfl = SourceFileList.new(:dir => '/foo/bar')
		#  sfl.analyze(:languages)
		#  puts sfl.ruby.code.count
		#
		#
		def analyze(what = [:*])
			what = [what] unless what.is_a?(Array)

			do_gestalt   = what.include?(:gestalt)   || what.include?(:*)
			do_languages = what.include?(:language)  || what.include?(:*)

			@loc_list = LocList.new if do_languages
			@gestalt_engine = Gestalt::GestaltEngine.new if do_gestalt

			self.each do |file|
				# we process each file - even if its not a source_code - for
				# library rules sake - they sometimes want 'jar' files or something
				source_file = SourceFile.new(file, :filename => self)
				@loc_list += source_file.loc_list if do_languages
				@gestalt_engine.process(source_file) if do_gestalt
				yield source_file if block_given?
			end

      @gestalt_engine.calc_gestalts if do_gestalt
		end

    def gestalts
      raise "No gestalts analyzed yet" unless @gestalt_engine
      @gestalt_engine.gestalts
    end

		def each_source_file
			self.each do |file|
				sf = SourceFile.new(file, :filename => self)
				next unless sf.polyglot
				yield sf
			end
		end

	end
end
