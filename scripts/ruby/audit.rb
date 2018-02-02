IGNORE_DIR = ['node_modules', 'public', '__tests__', 'styles']
IGNORE_FILES_WITH = ['\.spec', '\.ignore', '\.test', '\.scss']
EXPORT_PARSE_RE = /export\s(?:{\s)?(const|default|function|class)\s([a-zA-Z]*)?/

def parse_exports(exportz, default)
  exportz.map do |export_str|
    matches = EXPORT_PARSE_RE.match(export_str)

    export_type = ""
    export_name = ""
  begin
    case matches
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
    puts export_str
  end
  {
        type: export_type,
        name: export_name
  }
  end
end

def parse_paths(importz, cur_path, base_path)
  importz.map do |import_str|
    case
    when (/'\.{2}\// =~ import_str) != nil
      import_to_name_path(import_str.sub(
        /\.{2}/,
        cur_path.sub(/\/[A-Za-z]+$/, "/")
      ).chomp, cur_path, base_path)
    when (/'\.\// =~ import_str) != nil
      import_to_name_path(import_str.sub(/\.{1}/, cur_path).chomp, cur_path, base_path)
    else
      import_to_name_path(import_str, base_path, base_path)
    end
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

  {
    name: name,
    path: path,
    default: !name.include?("{"),
  }
end

def select_import lines
  i = 0
  ans = []
  while i < lines.length
    if (/^import/ =~ lines[i]) != nil
      working = lines[i].chomp
      until (/;$/ =~ working) != nil
        i += 1
        working << lines[i].chomp
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
        acc.merge!(
          Hash["#{path_value}/#{file}",
            Hash[
            "path",
            "#{path_value}/#{file}",
            "imports",
            parse_paths(select_import(current_lines), current, script_dir),
            "exports",
            parse_exports(current_lines.select{|line|(/^export/ =~ line) != nil}, file),
            ]
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
  [
  #{str}
  ].each do |code_file|
    # Write in here    
  end

  puts "Seeds have sprouted"

  STR
  seed.gsub(/^\s/, '')
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