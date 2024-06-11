class PlayersController < ApplicationController

  def index
    @players = Player.order('external_points::integer desc').page(params[:page])
  end

end
