require 'prawn/qrcode'
class AppointmentsController < ApplicationController
  before_action :set_appointment, only: [:show, :edit, :update, :destroy]

  # GET /appointments
  # GET /appointments.json
  def index
    @appointments = Appointment.order('created_at DESC').paginate(
      page: params[:page], per_page: 10
    )
  end

  # GET /appointments/1
  # GET /appointments/1.json
  def show
    respond_to do |format|
      format.html
      format.pdf do
        @qr = RQRCode::QRCode.new(
          "#{@appointment.datetime} #{@appointment.vendor.name}",
          level: :h, size: 20
        )
        pdf = AppointmentPdf.new(@appointment, @qr, view_context)
        send_data pdf.render, filename:
        "appointment_#{@appointment.created_at.strftime('%d/%m/%Y')}.pdf",
                              type: 'application/pdf', dispostion: 'inline'
      end
    end
  end

  # GET /appointments/new
  def new
    @appointment = Appointment.new
  end

  # GET /appointments/1/edit
  def edit; end

  # POST /appointments
  # POST /appointments.json
  def create
    if params[:appointment][:dock_id].empty?
      redirect_to :back, notice: 'Select Dock'
    else
      puts params[:appointment][:dock_id].length
      @date = Date.new params['appointment']['datetime(1i)'].to_i, params['appointment']['datetime(2i)'].to_i, params['appointment']['datetime(3i)'].to_i
      @dock = Dock.find(params[:appointment][:dock_id])
      @time = '2000-01-01 ' + params['appointment']['datetime(4i)'] + ':' + params['appointment']['datetime(5i)'] + ':00'
      @timeslot = Timeslot.where(date: @date, time: @time).first_or_create
      if @dock.timeslots.include?(@timeslot)
        redirect_to(:back, notice: 'This timeslot not available. Please select different Timeslot') && return
      end
      @appointment = Appointment.new(appointment_params)
      @appointment.timeslot = @timeslot
      respond_to do |format|
        if @appointment.save
          @dock.dock_schedules.create(timeslot_id: @timeslot.id)
          format.html { redirect_to(@appointment, notice: 'Appointment was successfully created.') && return }
          format.json { render :show, status: :created, location: @appointment }
        else
          format.html { render :new }
          format.json { render json: @appointment.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /appointments/1
  # PATCH/PUT /appointments/1.json
  def update
    respond_to do |format|
      if @appointment.update(appointment_params)
        format.html do
          redirect_to @appointment,
                      notice: 'Appointment was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @appointment }
      else
        format.html { render :edit }
        format.json do
          render json: @appointment.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /appointments/1
  # DELETE /appointments/1.json
  def destroy
    @appointment.destroy
    respond_to do |format|
      format.html do
        redirect_to appointments_url,
                    notice: 'Appointment was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  def check
    @date = Date.new params['check']['date(1i)'].to_i,
                     params['check']['date(2i)'].to_i,
                     params['check']['date(3i)'].to_i
    @dock = Dock.find(params[:check][:dock_id])
    @time = '2000-01-01 ' + params['check']['time(4i)'] +
            ':' + params['check']['time(4i)'] + ':00'
    @timeslot = Timeslot.where(date: params[:check][:date],
                               time: @time).first_or_create
    puts @time
    @flag = if @dock.timeslots.include?(@timeslot)
              true
            else
              false
            end

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  private

  # Use callbacks to share common
  # setup or constraints between actions.
  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  def appointment_params
    params.require(:appointment).permit(:datetime, :vendor_id, :name, :dock_id)
  end
end
