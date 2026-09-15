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

  end

end
