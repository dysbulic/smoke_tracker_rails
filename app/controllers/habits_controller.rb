class HabitsController < ApplicationController
  before_action :set_habit, only: [:show, :edit, :update, :destroy]
  doorkeeper_for :all, if: lambda { request.headers["Content-Type"] == "application/json" }
  before_filter :authenticate_user!, unless: lambda { request.headers["Content-Type"] == "application/json" }
  skip_before_action :verify_authenticity_token, if: lambda { request.format.json? }

  # GET /habits
  # GET /habits.json
  def index
    user = current_user
    user ||= User.find(doorkeeper_token[:resource_owner_id]) if doorkeeper_token

    if params[:created_since]
      @habits = user.habits.where("created_at >= ?", Time.at(params[:created_since].to_i))
    elsif params[:updated_since]
      update_time = Time.at(params[:updated_since].to_i)
      @habits = user.habits.where("created_at < ? AND updated_at >= ?", update_time, update_time)
    else
      @habits = user.habits
    end
  end

  # GET /habits/1
  # GET /habits/1.json
  def show
  end

  # GET /habits/new
  def new
    @habit = Habit.new(user: current_user)
  end

  # GET /habits/1/edit
  def edit
  end

  # POST /habits
  # POST /habits.json
  def create
    user ||= current_user
    user ||= User.find(doorkeeper_token[:resource_owner_id]) if doorkeeper_token

    if params[:_json] and params[:_json].kind_of?(Array)
      params[:_json].each{ |habit| habit[:user] = user }
      begin
        @habits = Habit.create(params[:_json])

        respond_to do |format|
          format.html { render action: 'index' }
          format.json { render json: @habits, status: :created }
        end
      rescue SQLite3::ConstraintException => e
        puts e
      end
    else
      @habit = Habit.new(habit_params)

      respond_to do |format|
        if @habit.save
          format.html { redirect_to @habit, notice: 'Habit was successfully created.' }
          format.json { render action: 'show', status: :created, location: @habit }
        else
          format.html { render action: 'new' }
          format.json { render json: @habit.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /habits/1
  # PATCH/PUT /habits/1.json
  def update
    respond_to do |format|
      if @habit.update(habit_params)
        format.html { redirect_to @habit, notice: 'Habit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @habit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /habits/1
  # DELETE /habits/1.json
  def destroy
    @habit.destroy
    respond_to do |format|
      format.html { redirect_to habits_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_habit
      @habit = Habit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def habit_params
      params.require(:habit).permit(:id, :color, :name, :description)
    end
end
