require 'sequel'
require 'bcrypt'
require 'hashids'

class College < Sequel::Model

  # model associations
  one_to_many :users
end

class User < Sequel::Model
  include BCrypt

  # model associations
  many_to_one :college

  plugin :single_table_inheritance, :type
  plugin :json_serializer

  def authenticate(password)
    return self.password == password
  end

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

end

class Tutor < User

  one_to_many :appointments

  many_to_many :students, :join_table => :users_users

end

class Student < User

  one_to_many :appointments

  many_to_many :tutors, :join_table => :users_users

end

class Appointment < Sequel::Model

  many_to_one :tutor
  many_to_one :student

end
