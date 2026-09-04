module Admin

  class ScoreModifiersController < ApplicationController

    def index
      @score_modifiers = ScoreModifier.kept.order(:name).page(params[:page])
    end

    def show
      @score_modifier = ScoreModifier.kept.find(params[:id])
      @player_season_modifiers = @score_modifier.player_season_modifiers.includes(player_season: %i[player season])
    end

    def new
      @score_modifier = ScoreModifier.new
      authorize @score_modifier
    end

    def edit
      @score_modifier = ScoreModifier.kept.find(params[:id])
      authorize @score_modifier
    end

    def create
      @score_modifier = ScoreModifier.new(score_modifier_params)
      authorize @score_modifier
      if @score_modifier.save
        redirect_to admin_score_modifier_path(@score_modifier), notice: t('.success')
      else
        flash.now[:error] = t('.failed')
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @score_modifier = ScoreModifier.kept.find(params[:id])
      authorize @score_modifier
      @score_modifier = retyped_for_update(@score_modifier)
      if @score_modifier.update(score_modifier_params)
        redirect_to admin_score_modifier_path(@score_modifier), notice: t('.success')
      else
        flash.now[:error] = t('.failed')
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @score_modifier = ScoreModifier.kept.find(params[:id])
      authorize @score_modifier
      if @score_modifier.discard
        redirect_to admin_score_modifiers_path, notice: t('.success')
      else
        redirect_to admin_score_modifier_path(@score_modifier), alert: t('.failed')
      end
    end

    private

    def score_modifier_params
      params.require(:score_modifier).permit(:name, :value).merge(type: requested_type&.name)
    end

    # Coerces against the closed family so an unknown type fails validation, not ActiveRecord::SubclassNotFound.
    def requested_type
      type = params.dig(:score_modifier, :type)
      ScoreModifier.subclasses.find { |modifier_type| modifier_type.name == type }
    end

    # ScoreModifier.find instantiates a record as its CURRENT STI subtype, so
    # a plain #update only ever runs that old class's validations. When Kind
    # is changing to a different, known-good subtype, reinstantiate the
    # record as the target class first so the target's own validations (e.g.
    # Multiplier's greater-than-0 check) actually run before save.
    def retyped_for_update(score_modifier)
      target_type = requested_type
      return score_modifier if target_type.nil? || score_modifier.instance_of?(target_type)

      score_modifier.becomes!(target_type)
    end

  end

end
