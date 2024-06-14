module ExternalData

  module Pokemon

    module Tcg

      class Players < Scraper

        def self.all
          player_pages = get_all_pages('/players')
          parse_players(player_pages)
        end

        def self.parse_players(html_content)
          players = []
          content = Nokogiri.HTML5(html_content)
          player_table_rows = content.search('tr')
          player_table_rows.each do |table_row|
            cells = table_row.search('td')
            next if cells.blank?

            players = parse_row(cells, players)
          end
          players
        end

        def self.parse_row(cells, players)
          player = Player.new
          return players unless cells[4].children[0]&.text

          name_cell = cells[1]
          player.name = name_cell.content
          player.external_id = name_cell.element_children[0].attribute_nodes[0].value
          player.country = cells[3].element_children[0].attribute_nodes[2].value
          player.external_points = cells[4].children[0].text
          players << player
          players
        end

      end

    end

  end

end
