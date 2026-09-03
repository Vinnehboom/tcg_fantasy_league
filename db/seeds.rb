# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Backstop every existing game with a default season, so scoring always has
# a covering Season to read config from (see Season.default_for). A no-op
# for a game that already has seasons of its own.
Game.find_each { |game| Season.default_for(game:) }
