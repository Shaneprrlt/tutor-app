require 'sequel'

# setup our connection to the database
DB = Sequel.connect('sqlite://tutor-app.db')

# load extensions
DB.extension(:current_datetime_timestamp)

# setup our colleges table
DB.create_table? :colleges do
  primary_key :id
  String :public_id, :unique => true
  String :name
  DateTime :created_at, :default => Sequel.datetime_class.now
  DateTime :updated_at, :default => Sequel.datetime_class.now
end

# setup our users table
DB.create_table? :users do
  primary_key :id
  String :public_id, :unique => true
  String :email, :unique => true
  String :username, :unique => true
  String :name
  foreign_key :college_id, :colleges
  String :type # will either be 'tutor' or 'student'
  String :password_salt
  String :password_hash
  DateTime :created_at, :default => Sequel.datetime_class.now
  DateTime :updated_at, :default => Sequel.datetime_class.now
end

# join table for students and tutors
DB.create_join_table?(:tutor_id=>:users, :student_id=>:users)

# setup our appointments table
DB.create_table? :appointments do
  primary_key :id
  String :public_id, :unique => true
  foreign_key :tutor_id, :users
  foreign_key :student_id, :users
  DateTime :when
  String :where
  TrueClass :student_attended, :default => false
  String :notes, :text => true
  DateTime :created_at, :default => Sequel.datetime_class.now
  DateTime :updated_at, :default => Sequel.datetime_class.now
end
