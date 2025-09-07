class ReloadingSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reloading_session, only: [:show, :edit, :update, :destroy]

  def index
    authorize ReloadingSession
    @pagy, @reloading_sessions = pagy(policy_scope(ReloadingSession).includes(:bullet, :powder, :primer, :cartridge).order(created_at: :desc))
  end

  def show
    authorize @reloading_session
  end

  def new
    @reloading_session = current_account.reloading_sessions.new
    authorize @reloading_session
  end

  def edit
    authorize @reloading_session
  end

  def create
    @reloading_session = current_account.reloading_sessions.new(reloading_session_params)
    authorize @reloading_session

    handle_custom_data_source

    if @reloading_session.save
      redirect_to @reloading_session, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @reloading_session
    handle_custom_data_source

    if @reloading_session.update(reloading_session_params)
      redirect_to @reloading_session, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @reloading_session
    @reloading_session.destroy
    redirect_to reloading_sessions_url, notice: t(".destroyed"), status: :see_other
  end

  private

  def set_reloading_session
    @reloading_session = current_account.reloading_sessions.find(params[:id])
  end

  def reloading_session_params
    params.require(:reloading_session).permit(
      :cartridge_id,
      :cartridge_type_id,
      :loaded_at,
      :reloading_data_source_id,
      :bullet_id,
      :bullet_type,
      :bullet_weight_id,
      :bullet_weight_other,
      :powder_id,
      :powder_weight,
      :primer_id,
      :primer_type_id,
      :cartridge_overall_length,
      :quantity,
      :notes,
      :custom_data_source_name
    )
  end

  def handle_custom_data_source
    # Check if "Other" was selected
    other_data_source = ReloadingDataSource.find_by(name: "Other")
    return unless other_data_source && @reloading_session.reloading_data_source_id == other_data_source.id

    # If Other is selected but no custom name provided, clear any existing custom name
    if params[:reloading_session][:custom_data_source_name].blank?
      @reloading_session.custom_data_source_name = nil
    else
      # Save the custom name directly to the reloading_session
      custom_name = params[:reloading_session][:custom_data_source_name].strip
      @reloading_session.custom_data_source_name = custom_name unless custom_name.blank?
    end
  end
end
