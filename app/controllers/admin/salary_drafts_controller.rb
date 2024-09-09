module Admin

  class SalaryDraftsController < ApplicationController

    def index
      @salary_drafts = SalaryDraft.all.page(params[:page])
    end

    def show
      @salary_draft = SalaryDraft.find(params[:id])
      @participations = @salary_draft.participations.page(params[:page])
    end

    def new
      @salary_draft = SalaryDraft.new
      authorize @salary_draft
      @tournaments = Tournament.upcoming
    end

    def edit
      @salary_draft = SalaryDraft.find(params[:id])
      authorize @salary_draft
      @tournaments = Tournament.upcoming
    end

    def create
      @salary_draft = SalaryDraft.new(salary_draft_params)
      authorize @salary_draft
      if @salary_draft.save
        redirect_to admin_salary_draft_path(@salary_draft), notice: t('.success')
      else
        flash[:error] = t('.failed')
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @salary_draft = SalaryDraft.find(params[:id])
      authorize @salary_draft
      if @salary_draft.update(salary_draft_params)
        redirect_to admin_salary_draft_path(@salary_draft), notice: t('.success')
      else
        flash[:error] = t('.failed')
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @salary_draft = SalaryDraft.find(params[:id])
      authorize @salary_draft
      if @salary_draft.destroy
        redirect_to admin_salary_drafts_path, notice: t('.success')
      else
        redirect_to admin_salary_draft_path(@salary_draft), alert: t('.failed')
      end
    end

    private

    def salary_draft_params
      params.require(:salary_draft).permit(:roster_size, :price_cap, :tournament_id)
    end

  end

end
