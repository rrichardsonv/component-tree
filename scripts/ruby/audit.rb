IGNORE_DIR = ['node_modules', 'public', '__tests__', 'styles', 'config', '.tmp']
IGNORE_FILES_WITH = ['\.spec', '\.ignore', '\.test', '\.scss', '\.xml']
EXPORT_PARSE_RE = /export\s(?:\{\s)?(const|default|function|class)\s([a-zA-Z]*)?/
IMPORT_PARSE_RE = /^\s*{\s?([a-zA-Z,\s_-]+)[\s,]}/
FULL_IMPORT_PARSE_RE = /^import\s(?:\*\sas)?([a-zA-Z{\s,\}]+)\sfrom\s'(.*)'/


# TODO: clean up your god damn code rich

def parse_exports(exportz, default)
  exportz.map do |export_str|
    matches = EXPORT_PARSE_RE.match(export_str)

    export_type = ""
    export_name = ""
  begin
    case true
      when !matches
        export_type = "unknown"
        export_name = export_str
      when !matches[1] && !!matches[2]
        export_type = "unknown"
        export_name = matches[2] 
      when !matches[2]
        export_type = matches[1]
        export_name = default
      else
        export_type = matches[1]
        export_name = matches[2]
      end
  rescue Exception => e
    puts e
    p matches
    p export_str
  end
  {
        type: export_type,
        name: export_name
  }
  end
end

def parse_named_imports(import_match_name, import_match_path)
  named_import_match = IMPORT_PARSE_RE.match(import_match_name)[1]
  named_import_match
    .strip
    .split(',')
    .map do |named_import|
      {
        import_name: named_import,
        import_path: import_match_path,
      }
    end
end

def split_imports(importz)
  results = []
  importz.each do |import_str|
    import_match = FULL_IMPORT_PARSE_RE.match(import_str)
    next unless import_match != nil
    
    if /^\s*{/ =~ import_match[1]
      parse_named_imports(
        import_match[1],
        import_match[2]
      ).each{|imp| results.push(imp)}
    else
      results.push({
        import_name: import_match[1],
        import_path: import_match[2],
      })
    end
  end
  results
end



def parse_paths(importz, cur_path, base_path)
  importz.map do |import_str|
    case
    # when ../
    when (/'\.{2}\// =~ import_str) != nil
      import_to_name_path(import_str.sub(
        /\.{2}/,
        cur_path.sub(/\/[A-Za-z]+$/, "/")
      ).chomp, cur_path, base_path).flatten
    when (/'\.\// =~ import_str) != nil
      import_to_name_path(import_str.sub(/\.{1}/, cur_path).chomp, cur_path, base_path).flatten
    else
      import_to_name_path(import_str, base_path, base_path).flatten
    end
  end
end

def relative_to_project_path(import)
  case
  when (/'\.{2}\// =~ import[:import_name]) != nil
    import[:import_path] = import[:import_path].sub(/\.{2}/, folder_path.sub(/\/[a-zA-Z]+$/, ''))
    import
  when (/\.\// =~ import[:import_name]) != nil
    import[:import_path] = import[:import_path].sub(/\./, folder_path)
    import
  else
    import
  end
end

def import_to_name_path(import_str, cur_path, base_path)
  parsed_import = import_str
    .split('import')[1]
    .gsub(/[;']/, '')
    .split('from')
    .map(&:strip)

  return parsed_import unless parsed_import.length == 2

  name = 
    if parsed_import[1].include?('@gamut')
      parsed_import[1].split('/')[1]
    elsif parsed_import[0].include?("as")
      parsed_import[1]
    else
      parsed_import[0]
    end

  path =
    if (/^[a-zA-Z]+\// =~ parsed_import[1]) != nil
      "#{cur_path}/#{parsed_import[1]}".sub(Regexp.new(base_path), '')
    else
      parsed_import[1]
    end
  non_default_imports = IMPORT_PARSE_RE.match(name)
  if non_default_imports != nil
    non_default_imports[1]
      .chop
      .sub(/,$/, '')
      .split(/,\s?/)
      .map do |parsed_named_import|
        {
          :name => parsed_named_import,
          :path => path
        }
      end
  else
    {
      :name => name,
      :path => path,
    }
  end
end

def deal_with_import_bullshit importz
  if importz.is_a? Array
    return importz unless importz.length > 0
    if importz[0].length == 4
      importz[0].each_slice(2).to_h
    end
  else 
    importz
  end
end

def safe_line(lines, index)
  lines[index].encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
end

# Selects imports and concats multi line imports
def select_import lines
  i = 0
  ans = []
  while i < lines.length
    line = safe_line(lines, i)
    if (/^import/ =~ line) != nil
      working = line.chomp
      until (/;$/ =~ working) != nil
        i += 1
        working << line.chomp
        line = safe_line(lines, i)
      end
      ans << working
    end
    i += 1
  end
  ans
end

def audit(current, base_path)
  acc = {}
	Dir.chdir current
	folders = Dir["*/"].each {|s| s.chop!}
	files = Dir["*"] - folders
  files.each do |file|
    if (Regexp.new("(" << IGNORE_FILES_WITH.join('|') << ")") =~ file) != nil
      next
    end

    File.open(file, "r") do |f|
        current_lines = f.readlines
        script_dir = base_path.split('/')[0..-2].join('/')
        path_value = current.sub(Regexp.new(script_dir), '')
        questionable_imports = parse_paths(select_import(current_lines), current, script_dir)
        
        acc.merge!(
          Hash["#{path_value}/#{file}".to_sym,
            {
            :path => "#{path_value}/#{file}",
            :imports => [deal_with_import_bullshit(questionable_imports)].flatten.compact,
            :exports => parse_exports(current_lines.select{|line|(/^export/ =~ line) != nil}, file),
            }
          ]
        )
    end
  end

  folders.each do |folder|
    next if IGNORE_DIR.include?(folder)
		acc.merge!(audit("#{current}/#{folder}", base_path))
  end
  
  acc
end

# DataModel
# File = {
# has_many exports
# has_many imports
#   id: String,
#   name: String,
#   path: String,
# }

# Package = {
# has_many imports
#   name: String,
# }

# Import = {
#   belongs_to file as importable

#   importer_id: String,
#   importer_type: String,
#   name: String,
# }

# Export = {
#   belongs_to file
#   file_id: String,

#   name: String,
#   isDefault: Bool,
#   type: ['default', 'const', 'unknown', 'function']
# }

def seed_template str
  seed = <<-STR
  # generated by scripts/audit

  CodeFile.destroy_all
  Export.destroy_all
  Import.destroy_all
  Package.destroy_all

  SEEDZ = [
  #{str}
  ]

  SEEDZ.each do |cf, i|
    begin
      code_file = CodeFile.create!({
        file_path: cf[:path],
        file_name: cf[:name],
      })
      cf[:exports].each do |ex|
        code_file.exports.create!({
          name: ex[:name],
          variety: ex[:type],
        })
      end
      cf[:imports].each do |imp|
        if imp[:path].include?('@gamut') || !imp[:path].include?('/')
          Package.create!({
            path: imp[:path],
          }).exports.create({
            name: imp[:name],
            variety: imp[:type],
          })
        end
      end
    rescue Exception => e
      puts e
      puts cf
      puts i
    end
  end

  SEEDZ.each do |cfs, i|
    current_code_file = CodeFile.find_by(file_path: cfs[:path])

    next if !current_code_file

    cfs[:imports].each do |imp|
      next if imp[:path].include?('@gamut') || !imp[:path].include?('/')

      defined_file = Package.find_by(path: imp[:path])
      if defined_file.nil?
        defined_file = CodeFile.find_by(file_path: imp[:path])
      end

      export = defined_file&.export
      if export
        begin
        export.imports.create!({
          code_file_id: current_code_file.id,
          name: imp[:name],
        })
        rescue Exception => e
          puts e
          puts imp
        end
      end
    end
  end

  puts "Seeds have sprouted"

  STR
  seed.gsub(/^\s{1,2}/, '')
end


File.open(
  File.dirname(__FILE__).sub(Regexp.new('scripts/ruby'), 'db/seeds.rb'),
  "w+",
) do |f|
  f.write(
    seed_template(
      audit(Dir.pwd, Dir.pwd).values.join(",\n\n")
    )
  )
end