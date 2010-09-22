require 'active_record'
require 'logger'
require 'sqlite3'

require_relative 'log'

ActiveRecord::Base.logger = Logger.new(File.join(LOG_PATH, "application.log"))

file = File.join(ROOT_PATH, 'db', 'dbfile.sqlite3')
database_exists = File.exists? file

ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: file
)

require 'schema' unless database_exists