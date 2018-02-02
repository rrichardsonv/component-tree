# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
1. Enter a directory
  - PATH_BASE = pwd
2. Read each file
  - current_path = PATH_BASE/file_name
  - pattern match for imports
    - name: /^import\s(?:\{\s|\*\sas\s)?([\w-]*)/gm
    - file_path: /from\s'([\w/_.-]*)';$/gm
      if file_path matches /\.{2}\//
        replace with parent directory
      if file_path matches \.\/
        replace with working directory
      if file_path has a /
        join it to project directory
      else
        its a package (leave it)

3. Write to log
  {
  name: file_name.replace(/\..*$/, '')
  file_path: current_path,
  imports: [
    {
      name: import_name,
      file_path: import_file_path
    }, {
    ...
    }
  ]

4. Create Component for each file
  - PWD + file_name

5. Create an Import for each import in each file
