module Admin

  class DataSubjectRequestsController < ApplicationController

    def index
      @data_subject_requests = DataSubjectRequest.includes(:player)
                                                 .order(status: :asc, created_at: :desc)
                                                 .page(params[:page])
    end

    def show
      @data_subject_request = DataSubjectRequest.find(params[:id])
    end

    def update
      @data_subject_request = DataSubjectRequest.find(params[:id])
      authorize @data_subject_request
      if update_params[:status] == 'actioned' && @data_subject_request.mark_actioned!
        redirect_to admin_data_subject_request_path(@data_subject_request), notice: t('.success')
      else
        redirect_to admin_data_subject_request_path(@data_subject_request), alert: t('.failed')
      end
    end

    private

    def update_params
      params.require(:data_subject_request).permit(:status)
    end

  end

end
