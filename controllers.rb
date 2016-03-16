require 'sinatra'
require 'sinatra/json'

configure do
  # load our database schema first
  require_relative 'schema.rb'
  # load our models
  require_relative 'models.rb'

  # tutor app relies on use of sessions
  enable :sessions
end

# directory we will serve static files from
set :public_folder, Proc.new { File.join(root, "public") }

before do
  # if there is an active session then
  # load an instance of the current user
  if session[:user_id] != nil
    @user = User.where(:id => session[:user_id]).first
  end
end

get '/' do
  erb :index
end

get '/signup' do
  @page_title = "Signup | Tutor Scheduler"
  erb :signup
end

post '/signup' do

  if(params[:type] == "tutor")
    user = Tutor.create(
      :name => params[:name],
      :username => params[:username],
      :college_id => params[:college_id],
      :email => params[:email],
      :created_at => DateTime.now,
      :updated_at => DateTime.now
    )
  elsif (params[:type] == "student")
    user = Student.create(
      :name => params[:name],
      :username => params[:username],
      :college_id => params[:college_id],
      :email => params[:email],
      :created_at => DateTime.now,
      :updated_at => DateTime.now
    )
  end

  # update their password and save
  user.password = params[:password]
  user.save

  # login the user
  session[:user_id] = user.id

  redirect to ('/appointments')
end

get '/login' do
  erb :login
end

post '/login' do
  # find the user by the email address
  user = User.where(:email => params[:email]).first

  if user and user.authenticate(params[:password])
    # store the users session information
    session[:user_id] = user.id
    redirect to ('/appointments')
  else
    redirect to ('/login?incorrect_login')
  end
end

get '/logout' do
  session[:user_id] = nil
  @user = nil
  redirect to('/login')
end

get '/appointments/new' do
  @page_title = "Create Appointment | Tutor Scheduler"
  @tutors = @user.tutors

  if @tutors.count == 0
    redirect to('/tutors?tutors_needed=true')
  end

  erb :appointments_new
end

post '/appointments' do
  if session[:user_id] and @user

    # create a formatted when timestamp
    w_date = Date.parse(params[:when_date])
    w_time = Time.parse(params[:when_time])

    # merge the two time zones together
    w_merged = DateTime.new(w_date.year, w_date.month, w_date.day,
      w_time.hour, w_time.min, w_time.sec, w_time.zone)
    w_merged_to_s = w_merged.strftime("%Y-%m-%d %H:%M:%S")

    # check to see if this tutor is
    # already booked for this session
    has_appointment = false
    tutor = Tutor.where(:id => params[:tutor_id]).first
    tutor.appointments.each do |appt|
      when_to_s = appt.when.strftime("%Y-%m-%d %H:%M:%S")
      puts "#{when_to_s} == #{w_merged_to_s}"
      if when_to_s == w_merged_to_s
        has_appointment = true
        break
      end
    end

    if has_appointment
      return redirect to ('/appointments/new?schedule_conflict=true')
    end

    # create the appointment
    appointment = Appointment.create(
      :student_id => @user.id,
      :tutor_id => params[:tutor_id],
      :where => params[:where],
      :when => w_merged
    )

    return redirect to ('/appointments')
  end
end

get '/appointments' do
  # print in reverse order as they were created
  @appointments = @user.appointments.reverse
  erb :appointments
end

post '/appointments/cancel' do
  # delete the appointment
  Appointment.where(:id => params[:appt_id]).first.delete
  return json [:success => "true", :message => "Canceled this appointment"]
end

post '/appointments/attend' do

  # mark the appointment as being attended
  appt = Appointment.where(:id => params[:appt_id]).first
  appt.student_attended = true
  appt.save

  return json [:success => "true", :message => "Marked this appointment as attended"]
end

get '/tutors' do
  if @user and @user.type == "Student"
    @tutors = @user.tutors
    erb :tutors
  else
    redirect to ('/appointments?unauthorized_error=true')
  end
end

get '/tutors/search' do
  # if the user is authorized to
  # access this page
  if session[:user_id] and @user

    # possible sql injection attack?
    # since params[:query] is not parameterized
    @tutors = Tutor.where(
      Sequel.like(:name, "%#{params[:query]}%") |
      Sequel.like(:email, "%#{params[:query]}%") |
      Sequel.like(:username, "%#{params[:query]}%")
    )

    return json @tutors
  end
end

post '/tutors/add' do
  if session[:user_id] and @user

    # find the tutor that is being requested
    @tutor = Tutor.where(:id => params[:tutor_id]).first

    if @user.type == "Student"

      # save the student/tutor relationship
      # @user.tutors << @tutor
      # @user.save

      # since sequel was giving me problems
      # saving the relationship through model
      # associations, I am directly inserting
      # into my join table
      users_users = DB[:users_users]
      users_users.insert(:student_id => @user.id, :tutor_id => @tutor.id)

      return json @user.tutors
    end
  end
end

get '/students' do
  if @user and @user.type == "Tutor"

    @students = @user.students
    erb :students
  else
    redirect to ('/appointments?unauthorized_error=true')
  end
end
