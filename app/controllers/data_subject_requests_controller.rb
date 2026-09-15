class DataSubjectRequestsController < ApplicationController

  layout 'no_header'

  def new
    @data_subject_request = DataSubjectRequest.new(request_type: :erase_or_object)
    @players = players_for_selection
  end

  def create
    @data_subject_request = DataSubjectRequest.new(data_subject_request_params.merge(request_type: :erase_or_object))
    if @data_subject_request.save
      redirect_to root_path, notice: t('.success')
    else
      @players = players_for_selection
      flash.now[:error] = t('.failed')
      render :new, status: :unprocessable_entity
    end
  end

  private

  def players_for_selection
    Player.not_suppressed.includes(:game).order(:name)
  end

  def data_subject_request_params
    params.require(:data_subject_request).permit(:player_id, :contact_email, :identity_proof)
  end

end
